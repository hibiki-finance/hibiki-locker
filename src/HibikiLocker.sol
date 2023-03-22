// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Auth.sol";
import "./ERC721Enumerable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @dev Contract to lock assets for a time and receive a token
 */
contract HibikiLocker is ERC721Enumerable {

    struct Lock {
        address token;
        uint256 amount;
        uint32 unlockDate;
    }

    uint256 public gasFee = 333333333333333 wei;
    mapping (uint256 => Lock) private _locks;
    uint256 private _mintIndex;

    event Locked(address indexed token, uint256 amount, uint32 unlockDate);
    event Unlocked(uint256 indexed lockId, uint256 amount);
    event Relocked(uint256 indexed lockId, uint32 newUnlockDate);

    error WrongTimestamp();
    error CannotManage();
    error WrongFee(uint256 sent, uint256 expected);
    error LockActive();

    modifier futureDate(uint32 attemptedDate) {
        if (attemptedDate > 10000000000 || attemptedDate <= block.timestamp) {
            revert WrongTimestamp();
        }
        _;
    }

    modifier canManageLock(uint256 lockId) {
        if (ownerOf(lockId) != msg.sender) {
            revert CannotManage();
        }
        _;
    }

    modifier correctGas {
        if (msg.value != gasFee) {
            revert WrongFee(msg.value, gasFee);
        }
        _;
    }

    constructor() ERC721("Hibiki.finance Lock", "LOCK") {
        _setBaseURI("https://hibiki.finance/bsc/lock/");
    }

    /**
     * @dev Lock an ERC20 asset.
     */
    function lock(address token, uint256 amount, uint32 unlockDate) external payable futureDate(unlockDate) correctGas {
        uint256 lockId = _mintIndex++;
        _mint(msg.sender, lockId);
        _lock(lockId, token, amount, unlockDate);
        // Some tokens are always taxed.
        // If the tax cannot be avoided, `transferFrom` will leave less tokens in the locker than stored.
        // Then, when unlocking, the transaction would either revert or take someone else's tokens, if any.
        IERC20 tokenToLock = IERC20(token);
        uint256 balanceBefore = 0;
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Locked(token, amount, unlockDate);
    }

    /**
     * @dev Extend an existing lock.
     */
    function relock(uint256 lockId, uint32 newDate) external futureDate(newDate) canManageLock(lockId) {
        Lock storage l = _locks[lockId];
        require(newDate > l.unlockDate, "New date must be after the current date.");
        l.unlockDate = newDate;

        emit Relocked(lockId, newDate);
    }

    /**
     * @dev Writes lock status. Check in other functions for data sanity.
     */
    function _lock(uint256 lockId, address token, uint256 amount, uint32 unlockDate) internal  {
        Lock storage l = _locks[lockId];
        l.token = token;
        l.amount = amount;
        l.unlockDate = unlockDate;
    }

    /**
     * @dev Unlock a locked ERC20.
     */
    function unlock(uint256 index) external canManageLock(index) {
        Lock storage l = _locks[index];
        if (block.timestamp < l.unlockDate) {
            revert LockActive();
        }
        uint256 lockedAmount = l.amount;
        _burn(index);
        l.amount = 0;
        IERC20(l.token).transfer(msg.sender, lockedAmount);
    }
}
