//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/IUniswapV3Factory.sol";
import "./lib/UniswapV3OracleLibrary.sol";
import "./interfaces/IAggregator.sol";
import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";

contract PriceOracle is Ownable {
    IUniswapV3Factory public immutable factory;
    mapping (address => address) public tokenPriceFeed;
    address public immutable usdt;
    address public immutable usdc;

    constructor(address _usdt, address _usdc, address _factory) {
        usdt = _usdt;
        usdc = _usdc;
        factory = IUniswapV3Factory(_factory);
    }

    function addDataFeedAddress(address[] memory _tokenAddress, address[] memory _dataFeed) public onlyOwner {
        _addDataFeedAddress(_tokenAddress, _dataFeed);
    }

    function _addDataFeedAddress(address[] memory _tokenAddress, address[] memory _dataFeed) public onlyOwner {
        require(_tokenAddress.length == _dataFeed.length, "Not matches");
        
        for(uint256 i = 0; i < _tokenAddress.length; i++) {
            require(_tokenAddress[i] != address(0) || _dataFeed[i] != address(0), "Address 0x detected!");
            tokenPriceFeed[_tokenAddress[i]] = _dataFeed[i];
        }
    }

    function update() external {
        
    }

    function getPriceOfTokenInUsd(
            address tokenIn
        )
        public view returns(uint8 decimals, int256 amountOut)
    {
        require(tokenIn != usdc || tokenIn != usdt || tokenIn != address(0), "Token Address Error!");
        IAggregatorV2V3 aggregator = IAggregatorV2V3(tokenPriceFeed[tokenIn]);
        if(tokenPriceFeed[tokenIn] == address(0)) {
            return _estimateAmountTwap(tokenIn);
        }
        return (aggregator.decimals(), aggregator.latestAnswer());
    }

    function _estimateAmountTwap(
        address tokenIn
    ) private view returns(uint8 decimals, int256 amountOut) {
        address _pool = factory.getPool(
            tokenIn,
            usdc,
            3000
        );
        address tokenOut = usdc;
        if(_pool == address(0)) {
            _pool = factory.getPool(
                tokenIn,
                usdt,
                3000
            );
            tokenOut = usdt;
            if(_pool == address(0)) {
                revert("pool doesn't exist");
            }
        }

        // (int24 tick, ) = OracleLibrary.consult(pool, secondsAgo);

        // Code copied from OracleLibrary.sol, consult()
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = 86400;
        secondsAgos[1] = 0;

        // int56 since tick * time = int24 * uint32
        // 56 = 24 + 32
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(_pool).observe(
            secondsAgos
        );

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        // int56 / uint32 = int24
        int24 tick = int24(tickCumulativesDelta / int56(int32(10)));
        if (
            tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(int32(86400)) != 0)
        ) {
            tick--;
        }
        decimals = IERC20(tokenOut).decimals();
        amountOut = int256(OracleLibrary.getQuoteAtTick(
            tick,
            1,
            tokenIn,
            tokenOut
        ));
    }
}