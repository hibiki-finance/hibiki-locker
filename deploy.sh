#!/bin/bash
source .env

case $1 in
	testnet)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $BSC_TESTNET_RPC --broadcast --chain-id 97
		;;
	bsc)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $BSC_RPC --broadcast --chain-id 56
		;;
	eth)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $ETH_RPC --broadcast --chain-id 1
		;;
	cro)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $CRONOS_RPC --broadcast --chain-id 25
		;;
	arb)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $ARB_RPC --broadcast --chain-id 42161
		;;
	matic)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $POLYGON_RPC --broadcast --chain-id 137
		;;
	ftm)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $FTM_RPC --broadcast --chain-id 250
		;;
	kcc)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $KCC_RPC --broadcast --chain-id 321
		;;
	avax)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $AVAX_RPC --broadcast --chain-id 43114
		;;
	empire)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $EMPIRE_RPC --broadcast --chain-id 3693
		;;
	bone)
		forge script script/01_Deploy.s.sol:Deploy --rpc-url $BONERIUM_RPC --broadcast --chain-id 9117
		;;
	*)
		echo "Please specify the chain to deploy in.";
		;;
esac
