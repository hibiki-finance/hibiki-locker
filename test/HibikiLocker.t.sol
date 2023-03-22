// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { HibikiLocker } from "../src/HibikiLocker.sol";
import "./mock/TestERC20.sol";
import { TaxedERC20 } from "./mock/TaxedERC20.sol";

contract LockerTest is Test {

    HibikiLocker public locker;
    TestERC20 public erc20t;
    TaxedERC20 public taxedERC20;
    uint256 private gasFee = 333333333333333 wei;

    function setUp() public {
        locker = new HibikiLocker(gasFee, address(0));
        erc20t = new TestERC20();
        erc20t.approve(address(locker), type(uint256).max);
        taxedERC20 = new TaxedERC20();
        taxedERC20.approve(address(locker), type(uint256).max);
    }

    function test_RevertWhen_NoFeePaid() public {
        vm.expectRevert(abi.encodeWithSelector(HibikiLocker.WrongFee.selector, 0, locker.getGasFee()));
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
        for (uint256 i = 0; i < 5; i++) {
            locker.lock{value: locker.getGasFee()}(address(erc20t), lockAmount, unlockDate);
            locker.lock{value: locker.getGasFee()}(address(taxedERC20), lockAmount, unlockDate);
        }
        assertEq(locker.balanceOf(address(this)), 10);
        assertEq(locker.countLocks(address(erc20t)), 5);
        assertEq(locker.countLocks(address(taxedERC20)), 5);
    }
}
