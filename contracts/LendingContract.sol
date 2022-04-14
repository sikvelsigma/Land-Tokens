// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface LendingToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external returns (uint256);
}

contract LendingContracts is Ownable {
    uint256 public immutable borrowRatio;
    uint256 public immutable minDuration;
    uint256 public immutable maxDuration;
    uint256 public immutable maxFee;
    uint256 public immutable minFee;
    uint256 public immutable overdraftPercentDuration; // 50% allowed overdraft as base
    uint256 public immutable overdraftFee; // additional fee each day
    LendingToken public immutable token;

    uint256 totalFees;
    uint256 totalOverdraft;

    struct Customer {
        uint256 amount;
        uint256 fee;
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
        uint256 _borrowRatio,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _maxFee,
        uint256 _minFee,
        uint256 _overdraftPercentDuration,
        uint256 _overdraftFee,
        LendingToken _token
    ) {
        borrowRatio = _borrowRatio;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        maxFee = _maxFee;
        minFee = _minFee;
        overdraftPercentDuration = _overdraftPercentDuration;
        overdraftFee = _overdraftFee;
        token = _token;
    }

    function borrowTokens(uint256 _amount, uint256 _duration)
        external
        payable
        notActive
    {
        require(msg.value > minFee, "ETH amount too small");
        customers[msg.sender].amount = _amount;
        customers[msg.sender].amount = minFee;
        customers[msg.sender].duration = _duration;
        customers[msg.sender].active = true;
        token.mint(msg.sender, msg.value * borrowRatio);
        totalFees += minFee;
    }

    function returnTokens() external onlyActive {
        // return tokens logic here
    }

    function withdrawEth() external onlyActive {
        // return eth to customer logic here
    }

    function withdrawFeeContractEth() external onlyOwner {
        address payable _owner = payable(owner());
        require(totalFees > 0, "NO_FEE_TO_WITHDRAW");
        _owner.transfer(totalFees);
    }

    function withdrawOverdraftContractEth() external onlyOwner {
        address payable _owner = payable(owner());
        require(totalOverdraft > 0, "NO_OVERDRAFT_TO_WITHDRAW");
        require(
            token.balanceOf(_owner) >= totalOverdraft * borrowRatio,
            "NOT_ENOUGH_TOKENS_TO_BURN"
        );
        // overdraft logic here
        _owner.transfer(totalOverdraft);
    }
}
