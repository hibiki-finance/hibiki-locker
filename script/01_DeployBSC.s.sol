// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import { HibikiLocker } from "../src/HibikiLocker.sol";

contract DeployBSCTestnet is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address feeReceiver = 0x9aa0BC6E3ae67ad878410CcE332FD8C680F953C2;
        uint256 gasFee = 333333333333333 wei;
        address holdToken = 0xA532cfaA916c465A094DAF29fEa07a13e41E5B36;
        uint256 holdAmount = 1000 ether;
        new HibikiLocker(feeReceiver, gasFee, holdToken, holdAmount);

        vm.stopBroadcast();
    }
}
