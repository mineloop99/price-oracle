import { expect } from "chai";
import { Address } from "ethereumjs-util";
import { network } from "hardhat";
const { ethers } = require("hardhat");
import getConfig from "../config.json";

const NETWORKS:Array<string> = ["avalanche", "ethereum"];
const ADDRESS_ZERO = Address.fromString("0x0000000000000000000000000000000000000000");
const config = getConfig[NETWORKS[0] as keyof typeof getConfig]; 
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
      config.usdt,
      config.usdc,
      config.factory
    );
    await priceOracle.deployed();
    expect(priceOracle.usdt != config.usdt);
    expect(priceOracle.usdc != config.usdc)
    expect(priceOracle.factory != config.factory)
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
        config.usdt,
        config.usdc,
        config.factory
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
      [config.wrappedEth],
      [config.dataFeed["eth"]]
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
      config.wrappedEth
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
        config.usdt,
        config.usdc,
        config.factory
    );
    await priceOracle.deployed();
    let update = await priceOracle.update(
      config.wrappedEth
    )
    await update.wait();
    await new Promise(f => setTimeout(f, 30000));
    await priceOracle.deployed();
    update = await priceOracle.update(
      config.wrappedEth
    )
    await update.wait();
    let priceInUsd = await priceOracle.getPriceOfTokenInUsd(
      config.wrappedEth
    )
    console.log("Price: ", priceInUsd[1]," Decimals: ", priceInUsd[0]);
    expect(priceInUsd[1] > 0);
  });
});