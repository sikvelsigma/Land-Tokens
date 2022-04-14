// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface LandingToken {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

contract LandingContracts is Ownable {

    uint public immutable minimumDuration;
    uint public immutable maximumDuration;
    LandingToken public immutable token;

    struct Customer {
        uint amount;
        uint duration;
    } 

    mapping (address => Customer) customers;


    constructor(uint _minimumDuration, uint _maximumDuration, LandingToken _token) {
        minimumDuration = _minimumDuration;
        maximumDuration = _maximumDuration;
        token = _token;
    }

    function borrowTokens(uint _amount, uint _duration) external payable {

    }

    function returnTokens() external {

    }

    function withdrawEth() external {

    }

    function withdrawFeeContractEth() external onlyOwner {

    }

    function withdrawOverdraftContractEth() external onlyOwner {

    }

}