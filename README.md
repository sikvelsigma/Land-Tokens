# Lending contract in Solidity using Hardhat

## How-to-use

As an owner:

1. Deploy token contract
2. Deploy lending contract
3. Make lending contract the owner of the token contract
4. Set token using `setToken()`
5. Withdraw eth fees with `withdrawFeeContractEth()`
6. Calculate overdraft fees with `calculateOverdraft()`
7. Withdraw overdraft fees with `withdrawOverdraftContractEth()`

Note: mint some tokens to your account before transfering ownership for testing overdraft fee withdraw since it requires the owner to burn tokens.

As a user:

1. Send eth using `borrowTokens()` to get tokens for a duration
2. Return tokens with `returnTokens()`
3. Withdraw remaining eth with `withdrawEth()`



