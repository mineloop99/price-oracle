import { expect } from "chai"; 
import { Address } from "ethereumjs-util";
const { ethers } = require("hardhat");
import config from "./config.json";
const ADDRESS_ZERO = Address.fromString("0x0000000000000000000000000000000000000000");
describe("Testing Price Oracle", function () {
  it("Deploy", async function () {
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    
    // Deploy Args:
    /*
        address _usdt,
        address _usdc,
        address _factory
    */
    const priceOracle = await PriceOracle.deploy(
      config.ethereum.usdt,
      config.ethereum.usdc,
      config.ethereum.factory
    );
    await priceOracle.deployed();
    expect(priceOracle.usdt != config.ethereum.usdt);
    expect(priceOracle.usdc != config.ethereum.usdc)
    expect(priceOracle.factory != config.ethereum.factory)
  });
  /*
    Price check if Chainlink provide existing Address
  */
  it("Check Price Aggregator ChainLink", async function () {
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    
    // Deploy Args:
    /*
        address _usdt,
        address _usdc,
        address _factory
    */
    const priceOracle = await PriceOracle.deploy(
        config.ethereum.usdt,
        config.ethereum.usdc,
        config.ethereum.factory
    );
    await priceOracle.deployed();
    // Add data feed base on price of token Address use Token/USD data Feed only
    // AddDataFeedAddress Args:
    /*
      [
        address Token
      ],
      [
        address DataFeed Token/USD
      ]
    */
    const addDataFeedAddress = await priceOracle.addDataFeedAddress(
      [config.ethereum.wrappedEth],
      [config.ethereum.dataFeed["eth"]]
    )
    await addDataFeedAddress.wait();
    // Check Price Feed with return func
    // getPriceOfTokenInUsd Args:
    /*
      address tokenIn(token address to be checked Ex:WrappedEth)
    */
    // getPriceOfTokenInUsd returns:
    /*
      [
        uint8 decimals,
        uint256 priceInUsd
      ]
    */
    let priceInUsd = await priceOracle.getPriceOfTokenInUsd(
      config.ethereum.wrappedEth
    )
    console.log("Price: ",priceInUsd[1]," Decimals: ", priceInUsd[0]);
    expect(priceInUsd[1] > 0);
  });

  /*
    Price check if Chainlink provide 0x Address or priceInUsd = 0
  */
  it("Check Price UniswapV2 Twap", async function () {
    // Check Price Feed with return func
    // getPriceOfTokenInUsd Args:
    /*
      address tokenIn(token address to be checked Ex:WrappedEth)
    */
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    
    // Deploy Args:
    /*
        address _usdt,
        address _usdc,
        address _factory
    */
    const priceOracle = await PriceOracle.deploy(
        config.ethereum.usdt,
        config.ethereum.usdc,
        config.ethereum.factory
    );
    await priceOracle.deployed();
    let update = await priceOracle.update(
      config.ethereum.wrappedEth
    )
    await update.wait();
    let priceInUsd = await priceOracle.getPriceOfTokenInUsd(
      config.ethereum.wrappedEth
    )
    console.log("Price: ", priceInUsd[1], " Decimals: ", priceInUsd[0]);
    console.log("Price: ", priceInUsd[1]," Decimals: ", priceInUsd[0]);
    expect(priceInUsd[1] > 0);
  });
});
