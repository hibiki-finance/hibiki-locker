#!/bin/bash
source .env

case $1 in
    testnet)
        forge script script/01_Deploy.s.sol:Deploy --rpc-url $BSC_TESTNET_RPC --broadcast --chain-id 97 -vvvv
        ;;
	bsc)
        forge script script/01_Deploy.s.sol:Deploy --rpc-url $BSC_RPC --broadcast --chain-id 56 -vvvv
        ;;
	eth)
        forge script script/01_Deploy.s.sol:Deploy --rpc-url $ETH_RPC --broadcast --chain-id 1 -vvvv
        ;;
	cro)
        forge script script/01_Deploy.s.sol:Deploy --rpc-url $CRONOS_RPC --broadcast --chain-id 25 -vvvv
        ;;
    *)
        echo "Please specify the chain to deploy in.";
        ;;
esac
