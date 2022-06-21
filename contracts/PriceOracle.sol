//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IAggregator.sol";
import "./interfaces/IERC20.sol";
import "./lib/UniswapV2OracleLibrary.sol";
import "./lib/FixedPoint.sol";
import "./utils/Ownable.sol";
contract PriceOracle is Ownable {
    using FixedPoint for *;
    uint256 public constant PERIOD = 10 seconds; // Need to be change
    mapping(address => address) public tokenPriceFeed;
    mapping(address => TokenInfoFallBack) public tokenInfoFallbacks;
    event PriceUpdate(address token, uint256 tokenPrice);
    IUniswapV2Factory public immutable factory;
    address public immutable usdt;
    address public immutable usdc;
    struct TokenInfoFallBack {
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
        bool isInit;
    }
    constructor(
        address _usdt,
        address _usdc,
        address _factory
    ) {
        usdt = _usdt;
        usdc = _usdc;
        factory = IUniswapV2Factory(_factory);
    }
    function addDataFeedAddress(
        address[] memory _tokenAddress,
        address[] memory _dataFeed
    ) public onlyOwner {
        _addDataFeedAddress(_tokenAddress, _dataFeed);
    }
    function _addDataFeedAddress(
        address[] memory _tokenAddress,
        address[] memory _dataFeed
    ) public onlyOwner {
        require(_tokenAddress.length == _dataFeed.length, "Not matches");
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                _tokenAddress[i] != address(0) || _dataFeed[i] != address(0),
                "Address 0x detected!"
            );
            tokenPriceFeed[_tokenAddress[i]] = _dataFeed[i];
        }
    }

    /*
        Return Decimals, And price 10^decimal value
    */
    function getPriceOfTokenInUsd(address tokenIn)
        public
        view
        returns (uint8, uint256)
    {
        require(
            tokenIn != usdc || tokenIn != usdt || tokenIn != address(0),
            "Token Address Error!"
        );
        IAggregatorV2V3 aggregator = IAggregatorV2V3(tokenPriceFeed[tokenIn]);
        if (tokenPriceFeed[tokenIn] == address(0)) {
            return _estimateAmountTwap(tokenIn);
        }
        return (aggregator.decimals(), uint256(aggregator.latestAnswer()));
    }
    function update(address _token) public {
        (address pair, ) = _getPairAndTokenOut(_token);
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        TokenInfoFallBack storage _tokenInfoFallBack = tokenInfoFallbacks[
            _token
        ];
        if (!_tokenInfoFallBack.isInit) {
            (
                uint112 reserve0,
                uint112 reserve1,
                uint32 blockTimestampLast
            ) = IUniswapV2Pair(pair).getReserves();
            if(reserve0 != 0 && reserve1 != 0){
                _tokenInfoFallBack.isInit = true;
                _tokenInfoFallBack.blockTimestampLast = blockTimestampLast;
                _tokenInfoFallBack.price0CumulativeLast = price0Cumulative;
                _tokenInfoFallBack.price1CumulativeLast = price1Cumulative;
            }
            // ensure that there's liquidity in the pair
            return;
        }
        uint32 timeElapsed = blockTimestamp -
            _tokenInfoFallBack.blockTimestampLast; // overflow is desired
        // ensure that at least one full period has passed since the last update
        if (timeElapsed >= PERIOD) {
            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            _tokenInfoFallBack.price0Average = FixedPoint.uq112x112(
                uint224(
                    (price0Cumulative -
                        _tokenInfoFallBack.price0CumulativeLast) / timeElapsed
                )
            );
            _tokenInfoFallBack.price1Average = FixedPoint.uq112x112(
                uint224(
                    (price1Cumulative -
                        _tokenInfoFallBack.price1CumulativeLast) / timeElapsed
                )
            );
            _tokenInfoFallBack.price0CumulativeLast = price0Cumulative;
            _tokenInfoFallBack.price1CumulativeLast = price1Cumulative;
            _tokenInfoFallBack.blockTimestampLast = blockTimestamp;
        }
    }

    function massUpdate(address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            update(_tokens[i]);
        }
    }
    
    function _estimateAmountTwap(address tokenIn)
        private
        view
        returns (uint8 decimals, uint256 amountOut)
    {
        (address _pairAddr, address tokenOut) = _getPairAndTokenOut(tokenIn);
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddr);
        uint8 _tokenInDecimals = decimals = IERC20(tokenIn).decimals();
        if (tokenIn == pair.token0()) {
            amountOut = tokenInfoFallbacks[tokenIn].price0Average.mul(10**_tokenInDecimals).decode144();
        } else {
            require(tokenIn == pair.token1(), "INVALID_TOKEN");
            amountOut = tokenInfoFallbacks[tokenIn].price1Average.mul(10**_tokenInDecimals).decode144();
        }
        decimals = IERC20(tokenOut).decimals();
    }
    function _getPairAndTokenOut(address _tokenIn)
        private
        view
        returns (address pool, address tokenOut)
    {
        pool = factory.getPair(_tokenIn, usdc);
        tokenOut = usdc;
        if (pool == address(0)) {
            pool = factory.getPair(_tokenIn, usdt);
            tokenOut = usdt;
            if (pool == address(0)) {
                revert("pool doesn't exist");
            }
        }
    }
}