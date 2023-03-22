#!/bin/bash
source .env

case $1 in
    testnet)
        forge script script/01_DeployBSCTestnet.s.sol:DeployBSCTestnet --rpc-url $BSC_TESTNET_RPC --broadcast -vvvv
        ;;
    *)
        echo "Please specify the chain to deploy in.";
        ;;
esac
