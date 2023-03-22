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
        address holdToken = 0xeC12d79597967aeBAf9b1bE75A8D51D29424DE15;
        uint256 holdAmount = 1000 ether;
        HibikiLocker locker = new HibikiLocker(feeReceiver, gasFee, holdToken, holdAmount);

        vm.stopBroadcast();
    }
}
