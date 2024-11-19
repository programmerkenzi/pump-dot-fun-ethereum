// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {TokenFactory} from "src/TokenFactory.sol";
import {Token} from "src/Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;

    function setUp() public {
        factory = new TokenFactory();
    }

    function test_CreateToken() public {
        string memory name = "My awesome token";
        string memory ticker = "MAK";
        address tokenAddress = factory.createToken(name, ticker);
        Token token = Token(tokenAddress);

        assertEq(factory.tokens(tokenAddress), true);
        assertEq(token.totalSupply(), factory.INITIAL_MINT());
        assertEq(token.balanceOf(address(factory)), factory.INITIAL_MINT());
    }

    function test_CalculateBuyPrice() public {
        // Token details
        string memory name = "My awesome token";
        string memory ticker = "MAK";

        // Create a new token contract
        address tokenAddress = factory.createToken(name, ticker);

        // Calculate the total supply left to be sold
        uint remainingTokens = factory.MAX_SUPPLY() - factory.INITIAL_MINT();

        // Calculate the buy price for the remaining tokens
        uint buyPrice = factory.calculateBuyPrice(
            tokenAddress,
            remainingTokens
        );

        // Assert that the calculated price equals the total collateral
        assertEq(
            buyPrice,
            factory.TOTAL_COLLATERAL(),
            "Buy price for remaining tokens does not match total collateral"
        );
    }
}
