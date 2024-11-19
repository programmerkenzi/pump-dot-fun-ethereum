// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import "./Token.sol";
import "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenFactory {
    enum  TokenState {
        NOT_CREATED,
        ICO,
        TRADING
    }
    uint public constant DECIMALS = 10 ** 18;
    uint public constant FUNDING_GOAL = 30 ether;
    uint public constant MAX_SUPPLY = 10 ** 9 * DECIMALS;
    uint public constant INITIAL_MINT = (MAX_SUPPLY * 20) / 100;
    uint public constant ICO_SUPPLY = MAX_SUPPLY - INITIAL_MINT;
    uint public constant SCALING_FACTOR = 10 ** 39;
    uint public constant OFFSET = 18750000000000000000000000000000;
    uint public constant K = 46875;
    address public constant UINISWAP_V2_FACTORY_ADDRESS =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UINISWAP_V2_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => TokenState) public tokens;
    mapping(address => uint) public collateral; // total collateral for each token
    mapping(address => mapping(address => uint)) public balance; // user balances for each token

    function createToken(
        string memory name,
        string memory ticker
    ) external returns (address) {
        Token token = new Token(name, ticker, INITIAL_MINT);
        tokens[address(token)] = TokenState.ICO;
        return address(token);
    }

    // Handle token purchase
    function buy(address tokenAddress, uint amount) external payable {
        require(tokens[tokenAddress] == TokenState.ICO, "Token does not exist or not in ICO state");
        Token token = Token(tokenAddress);
        uint availableSupply = MAX_SUPPLY - token.totalSupply();
        require(availableSupply >= amount, "Not enough tokens available");
        uint buyPrice = calculateBuyPrice(tokenAddress, amount);
        require(msg.value <= buyPrice, "Insufficient funds");
        collateral[tokenAddress] += buyPrice;
        balance[tokenAddress][msg.sender] += amount;
        token.mint(msg.sender, amount);

        if (collateral[tokenAddress] >= FUNDING_GOAL) {
            address pool = _createLiquidityPool(tokenAddress);
            // provide liquidity
            uint liquidity = _provideLiquidty(
                tokenAddress,
                INITIAL_MINT,
                collateral[tokenAddress]
            );
            // burn lp tokens
            _burnLPTokens(pool, liquidity);
        }
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

        uint f_b = K * b + OFFSET;
        uint f_a = K * a;

        uint price = ((b - a) * (f_a + f_b)) / (2 * SCALING_FACTOR);

        return price;
    }

    function withdraw(address tokenAddress, address to) external {
        require(tokens[tokenAddress] == TokenState.TRADING, "Token does not exist, or not reached the funding goal");
        uint userBalance = balance[tokenAddress][msg.sender];
        require(userBalance > 0, "No balance to withdraw");
        balance[tokenAddress][msg.sender] = 0;
        Token token = Token(tokenAddress);
        token.transfer(to, userBalance);
    }

    function _createLiquidityPool(
        address tokenAddress
    ) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(
            UINISWAP_V2_FACTORY_ADDRESS
        );
        IUniswapV2Router02 router = IUniswapV2Router02(
            UINISWAP_V2_ROUTER_ADDRESS
        );
        address pair = factory.createPair(tokenAddress, router.WETH());
        return pair;
    }

    function _provideLiquidty(
        address tokenAddress,
        uint tokenAmount,
        uint ethAmount
    ) internal returns (uint) {
        Token token = Token(tokenAddress);
        IUniswapV2Router02 router = IUniswapV2Router02(
            UINISWAP_V2_ROUTER_ADDRESS
        );

        token.approve(UINISWAP_V2_ROUTER_ADDRESS, tokenAmount);

        (, , uint liquidity) = router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp
        );

        return liquidity;
    }

    function _burnLPTokens(address poolAddress, uint amount) internal {
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        pool.transfer(address(0), amount);
    }
}
