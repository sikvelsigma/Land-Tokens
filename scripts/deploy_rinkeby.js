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
    withdrawOverdraft,
    verifyContract
} = require("./deploy_functions")

async function main() {
    const lendingInit = {
        borrowRatio: 100,
        minDuration: 1,
        maxDuration: 10,
        minFee: utils.parseUnits("0.01", "ether"),
        maxFee: utils.parseUnits("0.02", "ether"),
        overdraftPercentDuration: 50,
        overdraftFee: utils.parseUnits("0.01", "ether")
    }
    const users = await ethers.getSigners()
    const owner = users[0]

    /*
    const token = await deployToken(utils.parseEther("100"), owner, true)
    // const token = await ethers.getContractAt("LendingToken", "0xccaB35f09c7dBe4Dae82C2ED6F80729F5F14FD01")
    
    const lending = await deployLending(lendingInit, token, owner)
    // const lending = await ethers.getContractAt("LendingContract", "0x0000")
    
    await borrowTokens(lending, users[1], utils.parseEther("1"), 4)

    await returnTokens(lending, users[1])

    await withdrawFeeContractEth(lending, owner)
    */


    /*
    const lArgs = [
        lendingInit.borrowRatio,
        lendingInit.minDuration,
        lendingInit.maxDuration,
        lendingInit.minFee,
        lendingInit.maxFee,
        lendingInit.overdraftPercentDuration,
        lendingInit.overdraftFee
    ]
    await verifyContract("0x01fA8B08Ff74D1b980E279Bdb0409cbE328b3613", [])
    await verifyContract("0xFed71b0e06b84BAAB1B70E339d406fc199234Dbe", [...lArgs])
    */

    await withdrawEth(lending, users[1])
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })