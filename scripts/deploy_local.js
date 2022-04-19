"use strict"
const { ethers } = require("hardhat")
const { utils } = require("ethers")
const color = require("./color")

const { 
    deployToken,
    deployLending,
    borrowTokens,
    returnTokens,
    withdrawEth,
    withdrawFeeContractEth,
    withdrawOverdraft
} = require("./deploy_functions")

async function main() {
    const lendingInit = {
        borrowRatio: 100,
        minDuration: 1,
        maxDuration: 10,
        minFee: utils.parseUnits("0.1", "ether"),
        maxFee: utils.parseUnits("0.2", "ether"),
        overdraftPercentDuration: 50,
        overdraftFee: utils.parseUnits("0.1", "ether")
    }
    const users = await ethers.getSigners()
    const owner = users[0]

    const token = await deployToken(utils.parseEther("10000"), owner)
    const lending = await deployLending(lendingInit, token, owner)
    
    await borrowTokens(lending, users[1], utils.parseEther("1"), 4)
    await borrowTokens(lending, users[2], utils.parseEther("1"), 5)
    await borrowTokens(lending, users[3], utils.parseEther("1"), 10)
    
    await ethers.provider.send('evm_increaseTime', [5 * 24 * 3600])

    await returnTokens(lending, users[1])
    await returnTokens(lending, users[2])
    await returnTokens(lending, users[3])

    await ethers.provider.send('evm_increaseTime', [1 * 24 * 3600])

    await withdrawEth(lending, users[1])
    await withdrawEth(lending, users[2])
    await withdrawEth(lending, users[3])

    await withdrawFeeContractEth(lending, owner)
    await withdrawOverdraft(lending, owner)

    
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })