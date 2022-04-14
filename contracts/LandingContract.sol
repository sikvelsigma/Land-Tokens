// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface LandingToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract LandingContracts is Ownable {
    uint256 public immutable minDuration;
    uint256 public immutable maxDuration;
    uint256 public immutable maxFee;
    uint256 public immutable minFee;
    LandingToken public immutable token;

    struct Customer {
        uint256 amount;
        uint256 duration;
        bool active;
    }

    mapping(address => Customer) customers;

    modifier notActive() {
        require(customers[msg.sender].active == false);
        _;
    }
    modifier onlyActive() {
        require(customers[msg.sender].active == true);
        _;
    }

    constructor(
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _maxFee,
        uint256 _minFee,
        LandingToken _token
    ) {
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        maxFee = _maxFee;
        minFee = _minFee;
        token = _token;
    }

    function borrowTokens(uint256 _amount, uint256 _duration)
        external
        payable
        notActive
    {
        customers[msg.sender].amount = _amount;
        customers[msg.sender].duration = _duration;
        customers[msg.sender].active = true;
    }

    function returnTokens() external onlyActive {}

    function withdrawEth() external onlyActive {}

    function withdrawFeeContractEth() external onlyOwner {}

    function withdrawOverdraftContractEth() external onlyOwner {}
}
