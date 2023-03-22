// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract TaxedERC20 is ERC20 {
    constructor() ERC20("Taxed Test Token", "TTEST") {
        _mint(msg.sender, 10000 ether);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        uint256 fee = amount * 5 / 100;
        uint256 newAmount = amount - fee;
        super._transfer(from, to, newAmount);
        super._transfer(from, address(this), fee);
    }
}
