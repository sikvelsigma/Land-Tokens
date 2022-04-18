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
      accounts: [
        "fa8c9fb50563b6ded7f45451fdf211b05be24e518f5dba6d621be367f87672f8",
        "ca7c58b1e83d0276db22f44c01cba942813ec0c1eceb872d2cecf06b06dd0c41",
        "8f1d9afa5aa1889248f754fbc585aaea8a2cee49ab8b50197a13c02ab113447c",
        "aa9b865602c5c75fa31fc5d3412158abddefcb1a7309a827cc9afaa5ad3d4253"
      ],
    }
  },
  // gasReporter: {
  //   enabled: process.env.REPORT_GAS !== undefined,
  //   currency: "USD"
  // },
  etherscan: {
    apiKey: ETHERSCAN_KEY
  },
  mocha: {
    timeout: 1000000
  }
}
