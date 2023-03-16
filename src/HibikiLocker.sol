// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Auth.sol";
import "./ERC721Enumerable.sol";

interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @dev Contract to lock assets for a time and receive a token
 */
contract HibikiLocker is ERC721Enumerable {

    struct Lock {
        address token;
        uint256 index;
        uint32 unlockDate;
    }

    struct Vesting {
        address token;
        uint256 releaseIndex;
        uint256[] amounts;
        uint32[] releases;
    }

    uint256 public gasFee = 333333333333333 wei;
    mapping (uint256 => Lock) private _locks;
    mapping (uint256 => Vesting) private _vestings;
    uint256 private _mintIndex;

    event Locked(address indexed token, uint256 amount, uint32 unlockDate);
    event Vested(address indexed token, uint256 amount);
    event NFTLocked(address indexed token, uint256 indexed tokenId, uint32 unlockDate);
    event Unlocked(uint256 indexed lockId, uint256 amount);
    event NFTUnlocked(uint256 indexed lockId, uint256 indexed tokenId);
    event Relocked(uint256 indexed lockId, uint32 newUnlockDate);

    modifier futureDate(uint32 attemptedDate) {
        require(attemptedDate < 10000000000, "Timestamp must be in seconds.");
        require(attemptedDate > block.timestamp, "Must be a date in the future.");
        _;
    }

    modifier canManageLock(uint256 lockId) {
        require(ownerOf(lockId) == msg.sender, "Only the lock owner can unlock.");
        _;
    }

    modifier correctGas {
        require(msg.value == gasFee, "Wrong gas sent.");
        _;
    }

    constructor() ERC721("Hibiki.finance Lock", "LOCK") {
        _setBaseURI("https://hibiki.finance/bsc/lock/");
    }

    /**
     * @dev Lock an ERC20 asset.
     */
    function lock(address token, uint256 amount, uint32 unlockDate) external payable futureDate(unlockDate) correctGas {
        uint256 index = _mintIndex++;
        _mint(msg.sender, index);
        _lock(index, token, amount, unlockDate);
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
    function _lock(uint256 index, address token, uint256 amount, uint32 unlockDate) internal  {
        Lock storage l = _locks[index];
        l.token = token;
        l.index = amount;
        l.unlockDate = unlockDate;
    }

    /**
     * @dev Unlock a locked ERC20.
     */
    function unlock(uint256 index) external canManageLock(index) {
        Lock storage l = _locks[index];
        require(block.timestamp > l.unlockDate, "This lock is still active.");
        uint256 lockedAmount = l.index;
        _burn(index);
        l.index = 0;
        IERC20(l.token).transfer(msg.sender, lockedAmount);
    }

    function lockNFT(address token, uint256 tokenId, uint32 unlockDate) external payable futureDate(unlockDate) correctGas {
        uint256 index = _mintIndex++;
        _mint(msg.sender, index);
        _lock(index, token, tokenId, unlockDate);
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);

        emit NFTLocked(token, tokenId, unlockDate);
    }

    function unlockNFT(uint256 lockId) external canManageLock(lockId) {
        Lock storage l = _locks[lockId];
        require(block.timestamp > l.unlockDate, "This lock is still active.");
        uint256 tokenId = l.index;
        _burn(lockId);
        l.index = 0;
        IERC721(l.token).transferFrom(address(this), msg.sender, tokenId);

        emit NFTUnlocked(lockId, tokenId);
    }

    /**
     * @dev Linear vesting of an ERC20 token in specified parts.
     */
    function linearVest(address token, uint256 amount, uint256 parts, uint32 interval) external {
        uint256[] memory amounts = new uint256[](parts);
        uint32[] memory intervals = new uint32[](parts);
        for (uint256 i = 0; i < parts; i++) {

        }
    }

    /**
     * @dev Non-linear vesting of an ERC20 token.
     */
    function vest(address token, uint256[] calldata amounts, uint32[] calldata releases) external {
        require(amounts.length == releases.length, "Amount and release length mismatch.");
        uint256 index = _mintIndex++;
        _mint(msg.sender, index);
        //_vest(index, token, amount, unlockDate);
        //IERC20(token).transferFrom(msg.sender, address(this), amount);

        //emit Vested(token, amount);
    }

    function _vest(uint256 index, address token, uint256[] memory amounts, uint32[] memory releases) internal {
        Vesting storage v = _vestings[index];
        v.token = token;
        v.amounts = amounts;
        v.releases = releases;
    }

    function collectVestedTokens() external {

    }
}
