// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/HibikiLocker.sol";

contract CounterTest is Test {
    HibikiLocker public locker;

    function setUp() public {
        locker = new HibikiLocker();
    }

    function testLock() public {

    }
}
