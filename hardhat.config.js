require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-ethers")
require("@nomiclabs/hardhat-web3")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const WEB3_INFURA_PROJECT_ID = process.env.WEB3_INFURA_PROJECT_ID
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_KEY = process.env.ETHERSCAN_TOKEN

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.7.0",
      },
      {
        version: "0.8.7",
      },
    ],
  },
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${WEB3_INFURA_PROJECT_ID}`,
      accounts: [PRIVATE_KEY]
    },
    local: {
      chainId: 1337,
      url: "http://127.0.0.1:7545",
      accounts: ["cf094bf165c10b02a8fadf63ff34285cb10b79492ff3991b4095c4429ff275fa"],
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD"
  },
  etherscan: {
    apiKey: ETHERSCAN_KEY
  },
  mocha: {
    timeout: 1000000
  }
}
