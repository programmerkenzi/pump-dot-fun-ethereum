// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin-contracts-5.1.0/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    address public admin;

    constructor(string memory name, string memory ticker, uint256 initialMint) ERC20(name, ticker) {
        _mint(msg.sender, initialMint);
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin can mint");
        _mint(to, amount);
    }
}
