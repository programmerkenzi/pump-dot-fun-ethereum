// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import "./Token.sol";

contract TokenFactory {
    uint public constant DECIMALS = 10 ** 18;
    uint public constant TOTAL_COLLATERAL = 30 * DECIMALS;
    uint public constant MAX_SUPPLY = 10 ** 9 * DECIMALS;
    uint public constant INITIAL_MINT = (MAX_SUPPLY * 20) / 100;
    uint public constant ICO_SUPPLY = MAX_SUPPLY - INITIAL_MINT;
    uint public constant SCALING_FACTOR = 10 ** 39;
    uint public constant OFFSET = 18750000000000000000000000000000;
    uint public constant K = 46875;
    mapping(address => bool) public tokens;

    // Create a new token and store it in the mapping
    function createToken(
        string memory name,
        string memory ticker
    ) external returns (address) {
        Token token = new Token(name, ticker, INITIAL_MINT);
        tokens[address(token)] = true;
        return address(token);
    }

    // Handle token purchase
    function buy(address tokenAddress, uint amount) external payable {
        require(tokens[tokenAddress] == true, "Token does not exist");
        Token token = Token(tokenAddress);
        uint availableSupply = MAX_SUPPLY - INITIAL_MINT - token.totalSupply();
        require(availableSupply >= amount, "Not enough tokens available");
    }

    // Calculate the ETH price for a given token amount
    function calculateBuyPrice(
        address tokenAddress,
        uint amount
    ) public view returns (uint) {

        Token token = Token(tokenAddress);

        uint totalSupply = token.totalSupply();

        uint b = totalSupply + amount;
        uint a = totalSupply;

        // Adjust `f_a` and `f_b` calculations
        uint f_b = K * b + OFFSET;
        uint f_a = K * a;

        // Compute the price
        uint price = ((b - a) * (f_a + f_b)) / (2 * SCALING_FACTOR);

        return price;
    }
}
