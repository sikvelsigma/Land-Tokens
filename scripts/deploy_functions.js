"use strict"
const { ethers } = require("hardhat")
const { utils } = require("ethers")
const color = require("./color")
const hre = require("hardhat")

async function deployToken(initMint, owner) {
    // deploy Token contract
    color.log("<g>Deploying token contract...")
    let tx
    // const [owner] = await ethers.getSigners()
    const Token = await ethers.getContractFactory("LendingToken", owner)
    const token = await Token.deploy()
    await token.deployed()

    color.log(`<g>Token deployed at <b>${token.address}\n`)

    color.log(`<g>Minting <b>${utils.formatUnits(initMint, "ether")} eth <g>tokens to owner..`)
    tx = await token.mint(owner.address, initMint)
    await tx.wait(1)
    color.log(`<g>Done\n`)

    return token
}

async function deployLending(data, token, owner, verify=false) {
    // deploy Lending contract
    color.log("<g>Deploying lending contract...")
    let tx
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

    color.log(`<g>Lending contract deployed at <b>${lending.address}\n`)

    color.log(`<g>Setting token and transfering ownership...`)
    tx = await token.connect(owner).transferOwnership(lending.address)
    await tx.wait(1)
    tx = await lending.connect(owner).setToken(token.address)
    await tx.wait(1)
    color.log(`<g>Done\n`)

    return lending
}


async function borrowTokens(contract, user, amount, days) {
    color.log(`<g>Borrowing tokens to <b>${user.address}`)

    const tx = await contract.connect(user).borrowTokens(days, {value: amount})
    const receipt = await tx.wait(1)

    const balance = await contract.connect(user).balanceOf(user.address)
    color.log(`<g>Tokens successfully borrowed, address balance: <b>${utils.formatUnits(balance, "ether")} eth\n`)
    return receipt
}

async function returnTokens(contract, user) {
    color.log(`<g>Returning tokens from <b>${user.address}`)
    
    let receipt
    let tx
    
    try {
        tx = await contract.connect(user).returnTokens()
        receipt = await tx.wait(1)
        const balance = await contract.connect(user).balanceOf(user.address)
        color.log(`<g>Tokens successfully burnt, address balance: <b>${utils.formatUnits(balance, "ether")} eth\n`)
    } catch (err) {
        color.log("<r>" + err.toString())
        color.log(`<r>Failed to return tokens\n`)
    }

    
    return receipt
}

async function withdrawEth(contract, user) {
    color.log(`<g>Withdrawing remaining eth of <b>${user.address}`)

    let receipt = undefined
    
    try {
        const tx = await contract.connect(user).withdrawEth()
        receipt = await tx.wait(1)
        color.log(`<g>Eth successfully returned\n`)
    } catch (err) {
        color.log("<r>" + err.toString())
        color.log(`<r>Error returning eth\n`)
    }

    return receipt
}

async function withdrawFeeContractEth(contract, owner) {
    color.log(`<g>Withdrawing fees...`)

    const fees = await contract.connect(owner).getTotalFees()
    color.log(`<g>Total fees: <b>${utils.formatUnits(fees, "ether")} eth`)
    
    let receipt = undefined
    
    if (fees > 0) {
        const tx = await contract.connect(owner).withdrawFeeContractEth()
        receipt = await tx.wait(1)
        color.log(`<g>Fees successfully withdrawn\n`)
    } else {
        color.log(`<r>No fee to withdraw\n`)
    }
    
    return receipt
}

async function withdrawOverdraft(contract, owner) {
    let tx, receipt

    color.log(`<g>Withdrawing overdraft...`)
    color.log(`<g>Calculating...`)
    tx = await contract.connect(owner).calculateOverdraft()
    receipt = await tx.wait(1)
    // console.log(receipt)
    color.log(`<g>Done`)
    
    const fees = await contract.connect(owner).getTotalOverdraft()
    color.log(`<g>Total overdraft: <b>${utils.formatUnits(fees, "ether")} eth`)
    let balance
    if (fees > 0) {
        balance = await contract.connect(owner).balanceOf(owner.address)
        color.log(`<g>Owner token balance: <b>${utils.formatUnits(balance, "ether")} eth`)

        tx = await contract.connect(owner).withdrawOverdraftContractEth()
        receipt = await tx.wait(1)
        balance = await contract.connect(owner).balanceOf(owner.address)

        color.log(`<g>Owner token new balance: <b>${utils.formatUnits(balance, "ether")} eth`)    
        color.log(`<g>Overdraft successfully withdrawn\n`)
    } else {
        color.log(`<r>No overdraft to withdraw\n`)
    }
    
    return receipt
}

async function verifyContract(address, args) {
    color.log(`<g>Verifying contract at: <b>${address}`)
    try {
        await hre.run("verify:verify", {
            address: address,
            constructorArguments: [...args],
          })
        color.log(`<g>Success\n`)
    } catch(err) {
        color.log("<r>" + err.toString())
        color.log(`<r>Error verifying contract\n`)
    }
    
}


module.exports = {
    deployToken,
    deployLending,
    borrowTokens,
    returnTokens,
    withdrawEth,
    withdrawFeeContractEth,
    withdrawOverdraft,
    verifyContract
}