// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { HibikiLocker, HibikiFeeManager } from "../src/HibikiLocker.sol";
import "./mock/TestERC20.sol";
import { TaxedERC20 } from "./mock/TaxedERC20.sol";

contract LockerTest is Test {

    HibikiLocker public locker;
    TestERC20 public erc20t;
    TaxedERC20 public taxedERC20;
    uint256 private gasFee = 333333333333333 wei;

    function setUp() public {
        TestERC20 feeToken = new TestERC20();
        feeToken.transfer(address(0xdead), feeToken.balanceOf(address(this)));
        locker = new HibikiLocker(address(this), gasFee, address(feeToken), 1);
        erc20t = new TestERC20();
        erc20t.approve(address(locker), type(uint256).max);
        taxedERC20 = new TaxedERC20();
        taxedERC20.approve(address(locker), type(uint256).max);
    }

    function test_RevertWhen_NoFeePaid() public {
        vm.expectRevert(abi.encodeWithSelector(HibikiFeeManager.WrongFee.selector, 0, locker.getGasFee()));
        locker.lock(address(erc20t), 1 ether, uint32(block.timestamp + 60));
    }

    function test_RevertWhen_TimeInThePast() public {
        vm.expectRevert(HibikiLocker.WrongTimestamp.selector);
        locker.lock(address(erc20t), 1 ether, uint32(block.timestamp - 1));
    }

    function test_LockTokens() public {
        uint256 balanceBefore = erc20t.balanceOf(address(this));
        uint256 lockAmount = 1 ether;
        locker.lock{value: locker.getGasFee()}(address(erc20t), lockAmount, uint32(block.timestamp + 60));
        uint256 balanceAfter = erc20t.balanceOf(address(this));
        assertEq(balanceAfter, balanceBefore - lockAmount);
        assertEq(erc20t.balanceOf(address(locker)), lockAmount);
    }

    function test_RevertWhen_UnlockBeforeTime() public {
        locker.lock{value: locker.getGasFee()}(address(erc20t), 1 ether, uint32(block.timestamp + 200));
        vm.expectRevert(HibikiLocker.LockActive.selector);
        locker.unlock(0);
    }

    function test_RevertWhen_UnlockByNonOwner() public {
        locker.lock{value: locker.getGasFee()}(address(erc20t), 1 ether, uint32(block.timestamp + 200));
        vm.prank(address(0));
        vm.expectRevert(HibikiLocker.CannotManage.selector);
        locker.unlock(0);
    }

    function test_TokenUnlock() public {
        uint32 unlockTime = uint32(block.timestamp + 200);
        locker.lock{value: locker.getGasFee()}(address(erc20t), 1 ether, unlockTime);
        vm.warp(unlockTime + 1);
        locker.unlock(0);
        assertEq(erc20t.balanceOf(address(locker)), 0);
    }

    function test_LockSendTokenThenUnlock() public {
        address tokenReceiver = address(0xbeef);
        uint32 unlockTime = uint32(block.timestamp + 200);
        locker.lock{value: locker.getGasFee()}(address(erc20t), 1 ether, unlockTime);
        locker.transferFrom(address(this), tokenReceiver, 0);
        vm.warp(unlockTime + 1);
        vm.prank(tokenReceiver);
        locker.unlock(0);
    }

    function test_RevertWhen_UnlockAfterTokenTransfer() public {
        address tokenReceiver = address(0xbeef);
        uint32 unlockTime = uint32(block.timestamp + 200);
        locker.lock{value: locker.getGasFee()}(address(erc20t), 1 ether, unlockTime);
        locker.transferFrom(address(this), tokenReceiver, 0);
        vm.warp(unlockTime + 1);
        vm.expectRevert(HibikiLocker.CannotManage.selector);
        locker.unlock(0);
    }

    function test_Relock() public {
        uint32 unlockTime = uint32(block.timestamp + 200);
        locker.lock{value: locker.getGasFee()}(address(erc20t), 1 ether, unlockTime);
        locker.relock(0, unlockTime + 1);
    }

    function test_RevertWhen_RelockDateBeforeUnlockDate() public {
        uint32 unlockTime = uint32(block.timestamp + 200);
        locker.lock{value: locker.getGasFee()}(address(erc20t), 1 ether, unlockTime);
        vm.expectRevert(HibikiLocker.WrongTimestamp.selector);
        locker.relock(0, unlockTime - 1);
    }

    function test_LockTaxedTokens() public {
        uint256 balanceBefore = taxedERC20.balanceOf(address(this));
        uint256 lockAmount = 1 ether;
        locker.lock{value: locker.getGasFee()}(address(taxedERC20), lockAmount, uint32(block.timestamp + 60));
        uint256 balanceAfter = taxedERC20.balanceOf(address(this));
        assertEq(balanceAfter, balanceBefore - lockAmount);
    }

    function test_TaxedTokenUnlock() public {
        uint32 unlockTime = uint32(block.timestamp + 200);
        locker.lock{value: locker.getGasFee()}(address(taxedERC20), 1 ether, unlockTime);
        vm.warp(unlockTime + 1);
        locker.unlock(0);
        assertEq(taxedERC20.balanceOf(address(locker)), 0);
    }

    function test_ManyLocks() public {
        uint256 lockAmount = 1 ether;
        uint32 unlockDate = uint32(block.timestamp + 60);
        address erc20Token = address(erc20t);
        address taxedErc20 = address(taxedERC20);
        address testContract = address(this);
        for (uint256 i = 0; i < 5; i++) {
            locker.lock{value: locker.getGasFee()}(erc20Token, lockAmount, unlockDate);
            locker.lock{value: locker.getGasFee()}(taxedErc20, lockAmount, unlockDate);
        }
        // Check number of lock tokens created in total and for each token.
        assertEq(locker.balanceOf(testContract), 10);
        assertEq(locker.countLocks(erc20Token), 5);
        assertEq(locker.countLocks(taxedErc20), 5);

        // Check the lock data fits with the locks.
        uint256[] memory lockIds = locker.getAllLocks(erc20Token);
        uint256 lockId = lockIds[1];
        assertEq(locker.ownerOf(lockId), testContract);
        HibikiLocker.Lock memory oneLock = locker.viewLock(lockId);
        assertEq(oneLock.token, erc20Token);
    }

    function test_LockDataCorrect() public {
        uint32 unlockDate = uint32(block.timestamp + 60);
        uint256 lockAmount = 1 ether;
        locker.lock{value: locker.getGasFee()}(address(erc20t), lockAmount, unlockDate);
        HibikiLocker.Lock memory oneLock = locker.viewLock(0);
        assertEq(oneLock.token, address(erc20t));
        assertEq(oneLock.amount, lockAmount);
        assertEq(oneLock.unlockDate, unlockDate);
    }

    function test_LockDataCorrectTaxedToken() public {
        uint32 unlockDate = uint32(block.timestamp + 60);
        uint256 lockAmount = 1 ether;
        uint256 balanceBefore = taxedERC20.balanceOf(address(locker));
        locker.lock{value: locker.getGasFee()}(address(taxedERC20), lockAmount, unlockDate);
        uint256 balanceAfter = taxedERC20.balanceOf(address(locker));
        HibikiLocker.Lock memory oneLock = locker.viewLock(0);
        assertEq(oneLock.token, address(taxedERC20));
        // Check that the lock is stored with the taxed amount rather than the asked one.
        assertEq(oneLock.amount, balanceAfter - balanceBefore);
        assertEq(oneLock.unlockDate, unlockDate);
    }
}
