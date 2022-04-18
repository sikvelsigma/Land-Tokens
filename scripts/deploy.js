"use strict"
const { ethers } = require("hardhat")
const { utils } = require("ethers")

async function deployToken(initMint, owner) {
    // deploy Token contract
    console.log("Deploying token contract...")

    // const [owner] = await ethers.getSigners()
    const Token = await ethers.getContractFactory("LendingToken", owner)
    const token = await Token.deploy()
    await token.deployed()

    console.log(`Token deployed at ${token.address}\n`)

    console.log(`Minting ${utils.formatUnits(initMint, "ether")} eth tokens to owner..`)
    await token.mint(owner.address, initMint)
    console.log(`Done\n`)

    return token
}

async function deployLending(data, token, owner) {
    // deploy Lending contract
    console.log("Deploying lending contract...")

    const args = [
        data.borrowRatio,
        data.minDuration,
        data.maxDuration,
        data.minFee,
        data.maxFee,
        data.overdraftPercentDuration,
        data.overdraftFee
    ]
    // const [owner] = await ethers.getSigners()
    const Lending = await ethers.getContractFactory("LendingContract", owner)
    const lending = await Lending.deploy(...args)
    await lending.deployed()

    console.log(`Lending contract deployed at ${lending.address}\n`)

    console.log(`Setting token and transfering ownership...`)
    await token.connect(owner).transferOwnership(lending.address)
    await lending.connect(owner).setToken(token.address)
    console.log(`Done\n`)

    return lending
}



async function borrowTokens(contract, user, amount, days) {
    console.log(`Borrowing tokens to ${user.address}`)

    const tx = await contract.connect(user).borrowTokens(days, {value: amount})
    const receipt = await tx.wait(1)

    const balance = await contract.connect(user).balanceOf(user.address)
    console.log(`Tokens successfully borrowed, address balance: ${utils.formatUnits(balance, "ether")} eth\n`)
    return receipt
}

async function returnTokens(contract, user) {
    console.log(`Returning tokens from ${user.address}`)
    
    let receipt
    let tx
    
    try {
        tx = await contract.connect(user).returnTokens()
        receipt = await tx.wait(1)
        const balance = await contract.connect(user).balanceOf(user.address)
        console.log(`Tokens successfully burnt, address balance: ${utils.formatUnits(balance, "ether")} eth\n`)
    } catch (err) {
        console.log(err.toString())
        console.log(`Failed to return tokens\n`)
    }

    
    return receipt
}

async function withdrawEth(contract, user) {
    console.log(`Withdrawing remaining eth of ${user.address}`)

    let receipt = undefined
    
    try {
        const tx = await contract.connect(user).withdrawEth()
        receipt = await tx.wait(1)
        console.log(`Eth successfully returned\n`)
    } catch (err) {
        console.log(err.toString())
        console.log(`Error returning eth\n`)
    }

    return receipt
}

async function withdrawFeeContractEth(contract, owner) {
    console.log(`Withdrawing fees...`)

    const fees = await contract.connect(owner).getTotalFees()
    console.log(`Total fees: ${utils.formatUnits(fees, "ether")} eth`)
    
    let receipt = undefined
    
    if (fees > 0) {
        const tx = await contract.connect(owner).withdrawFeeContractEth()
        receipt = await tx.wait(1)
        console.log(`Fees successfully withdrawn\n`)
    } else {
        console.log(`No fee to withdraw\n`)
    }
    
    return receipt
}

async function withdrawOverdraft(contract, owner) {
    let tx, receipt

    console.log(`Withdrawing overdraft...`)
    console.log(`Calculating...`)
    tx = await contract.connect(owner).calculateOverdraft()
    receipt = await tx.wait(1)
    // console.log(receipt)
    console.log(`Done`)
    
    const fees = await contract.connect(owner).getTotalOverdraft()
    console.log(`Total overdraft: ${utils.formatUnits(fees, "ether")} eth`)
    let balance
    if (fees > 0) {
        balance = await contract.connect(owner).balanceOf(owner.address)
        console.log(`Owner token balance: ${utils.formatUnits(balance, "ether")} eth`)

        tx = await contract.connect(owner).withdrawOverdraftContractEth()
        receipt = await tx.wait(1)
        balance = await contract.connect(owner).balanceOf(owner.address)

        console.log(`Owner token new balance: ${utils.formatUnits(balance, "ether")} eth`)    
        console.log(`Overdraft successfully withdrawn\n`)
    } else {
        console.log(`No overdraft to withdraw\n`)
    }
    
    return receipt
}

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