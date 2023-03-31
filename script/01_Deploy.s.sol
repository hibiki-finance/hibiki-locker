// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import { HibikiLocker } from "../src/HibikiLocker.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

		(address holdToken, uint256 holdAmount) = _getHoldConfig();
        (address feeReceiver, uint256 gasFee) = _getFeeConfig();
        
        new HibikiLocker(feeReceiver, gasFee, holdToken, holdAmount, _getURIPart());

        vm.stopBroadcast();
    }

	function _getHoldConfig() internal view returns (address, uint256) {
		if (block.chainid == 1) {
			return (0xA693032e8cfDB8115c6E72B60Ae77a1A592fe4bD, 1000 ether);
		}
		if (block.chainid == 56) {
			return (0xA532cfaA916c465A094DAF29fEa07a13e41E5B36, 1000 ether);
		}
		if (block.chainid == 97) {
			return (0xeC12d79597967aeBAf9b1bE75A8D51D29424DE15, 1000 ether);
		}
		if (block.chainid == 25) {
			return (0x6B66fCB66Dba37F99876a15303b759c73fc54ed0, 1000 ether);
		}

		return (address(0), 0);
	}

	function _getFeeConfig() internal view returns (address, uint256) {
		address feeReceiver = 0xe5C0157c35c3a1746F62E0146745Bf03e8413cdC;
		// Base fee for BSC and BSC Testnet
		uint256 feeAmount = 0.00034 ether;
		// ETH mainnet
		if (block.chainid == 1) {
			feeReceiver = 0xCf5BEf994507cE385360DA775b5c82799F31652A;
			feeAmount = 0.0000569 ether;
		}
		// BSC
		if (block.chainid == 56) {
			feeReceiver = 0xdB720C653119AD3227F4C2fbe614654B7b7d97E2;
		}
		// Cronos
		if (block.chainid == 25) {
			feeAmount = 1.5 ether;
		}
		// Arbitrum
		if (block.chainid == 42161) {
			feeAmount = 0.0000569 ether;
		}
		// Polygon
		if (block.chainid == 137) {
			feeAmount = 0.1 ether;
		}
		// FTM
		if (block.chainid == 250) {
			feeAmount = 0.222 ether;
		}
		// KCC
		if (block.chainid == 321) {
			feeAmount = 0.015 ether;
		}
		// AVAX
		if (block.chainid == 43114) {
			feeAmount = 0.0075 ether;
		}
		// Empire network
		if (block.chainid == 3693) {
			feeAmount = 0.4 ether;
		}
		// Bonerium
		if (block.chainid == 9117) {
			feeAmount = 0.1 ether;
		}

		return (feeReceiver, feeAmount);
	}

	function _getURIPart() internal view returns (string memory) {
		if (block.chainid == 97) {
			return "bsctest";
		}
		if (block.chainid == 56) {
			return "bsc";
		}
		if (block.chainid == 25) {
			return "cro";
		}
		if (block.chainid == 42161) {
			return "arb";
		}
		if (block.chainid == 137) {
			return "matic";
		}
		if (block.chainid == 250) {
			return "ftm";
		}
		if (block.chainid == 321) {
			return "kcc";
		}
		if (block.chainid == 43114) {
			return "avax";
		}
		if (block.chainid == 3693) {
			return "empire";
		}
		if (block.chainid == 9117) {
			return "bone";
		}

		return "eth";
	}
}
