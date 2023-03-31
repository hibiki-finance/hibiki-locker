// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

abstract contract HibikiFeeManager {

    uint256 internal _gasForCall = 34000;
    uint256 internal _gasFee;
    address internal _feeReceiver;
    address internal _holdToken;
    uint256 internal _holdAmount;

    error WrongFee(uint256 sent, uint256 expected);

    modifier correctGas {
		address token = _holdToken;
        uint256 amount = _holdAmount;
		bool needsToCheck = token == address(0) || amount == 0 || IERC20(token).balanceOf(msg.sender) < amount;
        uint256 sent = msg.value;
		uint256 fee = _gasFee;
        if (needsToCheck && fee != sent) {
			revert WrongFee(sent, fee);
        }
        _;
		if (address(this).balance > 0) {
            _sendGas(_feeReceiver, address(this).balance);
        }
    }

    constructor(address feeReceiver, uint256 gasFee, address holdToken, uint256 holdAmount) {
        _feeReceiver = feeReceiver;
        _gasFee = gasFee;
        _holdToken = holdToken;
        _holdAmount = holdAmount;
    }

    receive() external payable {}

    /**
     * @dev Returns the current extra fee to send alongside a lock transaction.
     */
    function getGasFee() external view returns (uint256) {
        return _gasFee;
    }

    function _setGasFee(uint256 fee) internal {
        _gasFee = fee;
    }

    function getFeeReceiver() external view returns (address) {
        return _feeReceiver;
    }

    function _setFeeReceiver(address receiver) internal {
        _feeReceiver = receiver;
    }

    function getHoldToken() external view returns (address) {
        return _holdToken;
    }

    function _setHoldToken(address token) internal {
        _holdToken = token;
    }

    function getHoldAmount() external view returns (uint256) {
        return _holdAmount;
    }

    function _setHoldAmount(uint256 amount) internal {
        _holdAmount = amount;
    }

    function _setSendGas(uint256 gas) internal {
        _gasForCall = gas;
    }

    function _sendGas(address receiver, uint256 val) internal returns (bool result) {
		(result,) = receiver.call{value: val, gas: _gasForCall}("");
	}

    function sendAll() external {
        _sendGas(_feeReceiver, address(this).balance);
    }
}
