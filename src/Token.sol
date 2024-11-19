// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import "@openzeppelin-contracts-5.1.0/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory name,
        string memory ticker,
        uint initialMint
    ) ERC20(name, ticker) {
        _mint(msg.sender, initialMint);
    }
}
