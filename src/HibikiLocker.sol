// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Auth.sol";
import "./ERC721Enumerable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @dev Contract to lock assets for a time and receive a token
 */
contract HibikiLocker is Auth, ERC721Enumerable {

    struct Lock {
        address token;
        uint256 amount;
        uint32 unlockDate;
    }

    uint256 private _gasFee;
    mapping (uint256 => Lock) private _locks;
    uint256 private _mintIndex;
    address public gasFeeReceiver;
    mapping (address => uint256[]) private _tokenLocks;

    event Locked(address indexed token, uint256 amount, uint32 unlockDate);
    event Unlocked(uint256 indexed lockId, uint256 amount);
    event Relocked(uint256 indexed lockId, uint32 newUnlockDate);

    error WrongTimestamp();
    error CannotManage();
    error WrongFee(uint256 sent, uint256 expected);
    error LockActive();

    modifier futureDate(uint32 attemptedDate) {
        if (attemptedDate <= block.timestamp) {
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
        if (msg.value != _gasFee) {
            revert WrongFee(msg.value, _gasFee);
        }
        _;
    }

    constructor(uint256 gasFee, address receiver) Auth(msg.sender) ERC721("Hibiki.finance Lock", "LOCK") {
        _gasFee = gasFee;
        gasFeeReceiver = receiver;
        _setBaseURI("https://hibiki.finance/lock/");
    }

    /**
     * @dev Returns the current extra fee to send alongside a lock transaction.
     */
    function getGasFee() external view returns (uint256) {
        return _gasFee;
    }

    /**
     * @dev Lock an ERC20 asset.
     */
    function lock(address token, uint256 amount, uint32 unlockDate) external payable futureDate(unlockDate) correctGas {
        uint256 lockId = _mintIndex++;
        _mint(msg.sender, lockId);
        // Some tokens are always taxed.
        // If the tax cannot be avoided, `transferFrom` will leave less tokens in the locker than stored.
        // Then, when unlocking, the transaction would either revert or take someone else's tokens, if any.
        IERC20 tokenToLock = IERC20(token);
        uint256 balanceBefore = tokenToLock.balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = tokenToLock.balanceOf(address(this));
        uint256 actuallyTransfered = balanceAfter - balanceBefore;
        _lock(lockId, token, actuallyTransfered, unlockDate);

        emit Locked(token, actuallyTransfered, unlockDate);
    }

    /**
     * @dev Extend an existing lock.
     */
    function relock(uint256 lockId, uint32 newDate) external futureDate(newDate) canManageLock(lockId) {
        Lock storage l = _locks[lockId];
        if (newDate < l.unlockDate) {
            revert WrongTimestamp();
        }
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

    /**
     * @dev Returns the lock data at the index.
     */
    function viewLock(uint256 index) external view returns (Lock memory) {
        return _locks[index];
    }

    /**
     * @dev Get an array of locks from the specified IDs in the indices array.
     */
    function viewLocks(uint256[] calldata indices) external view returns (Lock[] memory) {
        Lock[] memory locks = new Lock[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            locks[i] = _locks[indices[i]];
        }

        return locks;
    }

    /**
     * @dev Returns the amount of locks existing for a token.
     */
    function countLocks(address token) external view returns (uint256) {
        return _tokenLocks[token].length;
    }

    /**
     * @dev Returns all lock IDs for a specific token address.
     */
    function getAllLocks(address token) external view returns (uint256[] memory) {
        return _tokenLocks[token];
    }

    /**
     * @dev Returns the lock ID for token at the specific index.
     */
    function getLockIDForToken(address token, uint256 index) external view returns (uint256) {
        return _tokenLocks[token][index];
    }
}
