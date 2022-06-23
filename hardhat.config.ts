require("@nomiclabs/hardhat-waffle");

module.exports = {
  networks: {
    hardhat: {
      forking: {
        url: "https://api.avax.network/ext/bc/C/rpc",//Eth"https://speedy-nodes-nyc.moralis.io/9485086d85846cac9a1e6060/eth/mainnet/archive",
        blockNumber: 16401849,//Eth 14977426,
        accounts: {
          accountsBalance: "10000000000000000000000000000",
        },
      },
    },
    avalanche: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      blockNumber: 16401849
    },
  },
  mocha: {
    timeout: 50000
  },
  solidity:  {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999
          }
        }
      },
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999
          }
        }
      }
    ]
  },
};
