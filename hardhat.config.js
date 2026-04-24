require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("solidity-coverage");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      evmVersion: "cancun",
    },
  },
  paths: {
    sources: "./src",
    tests: "./test_hardhat",
    cache: "./cache_hardhat",
    artifacts: "./artifacts_hardhat",
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    outputFile: "relatorio_gas_hardhat.txt",
    noColors: true,
  },
};
