// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface LendingToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferOwnership(address newOwner) external;
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

    enum UserState { INITIAL, BORROWED, RETURNED }

    struct Customer {
        uint256 id;
        uint256 amount;
        uint256 eth;
        uint256 untilTime;
        uint256 overdraftTime;
        UserState state;
    }

    mapping(address => Customer) customers;
    mapping(uint => address) idToAddress;
    uint totalIds = 0;

    modifier onlyInitial() {
        require(customers[msg.sender].state == UserState.INITIAL, "CANNOT_BORROW_TWICE");
        _;
    }
    modifier onlyBorrowed() {
        require(customers[msg.sender].state == UserState.BORROWED, "ONLY_ACTIVE_BORROWERS");
        _;
    }
    modifier onlyReturned() {
        require(customers[msg.sender].state == UserState.RETURNED, "TOKENS_NOT_RETURNED");
        _;
    }

    event TokensBorrowed(address _customer, uint _amount, uint _duration);
    event TokensReturnSuccess(address _customer, uint _amount);
    event OverdraftFeeSuccess(address _customer, uint _amount);
    event OverdraftExpired(address _customer);
    event NotEnoughEthForOverdraft(address _customer);
    event EthReturnedSuccess(address _customer, uint _amount);
    event EthOwnerWithdraw(uint _amount);
    event OverdraftOwnerWithdraw(uint _amount);

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
        require(_maxDuration > _minDuration, "MIN_DURATION_BIGGER_THAN_MAX");
        require(_minDuration > 0, "MIN_DURATION_ZERO");
        require(_borrowRatio > 0, "RATIO_ZERO");
        require(_maxFee > _minFee, "MIN_FEE_BIGGER_THAN_MAX");
        require(_overdraftPercentDuration <= 100, "OVERDRAFT_DURATION_TOO_LARGE");
        require(_overdraftFee > 0, "OVERDRAFT_FEE_ZERO");

        borrowRatio = _borrowRatio;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        maxFee = _maxFee;
        minFee = _minFee;
        overdraftPercentDuration = _overdraftPercentDuration;
        overdraftFee = _overdraftFee;
        token = _token;
        // _token.transferOwnership(address(this));
    }

    function borrowTokens(uint256 _durationDays) external payable onlyInitial {
        require(msg.value > minFee, "ETH_AMOUNT_TOO_SMALL");
        require(_durationDays >= minDuration, "DURATION_TOO_SMALL");
        require(_durationDays <= maxDuration, "DURATION_TOO_LARGE");

        uint256 _fee = minFee +
            ((_durationDays - minDuration) / (maxDuration - minDuration)) *
            (maxFee - minFee);

        customers[msg.sender].amount = msg.value * borrowRatio;
        customers[msg.sender].eth = msg.value - _fee;
        customers[msg.sender].untilTime = block.timestamp + _durationDays * 24 * 3600;
        customers[msg.sender].state = UserState.BORROWED;
        customers[msg.sender].overdraftTime = block.timestamp + (_durationDays * (100 + overdraftPercentDuration) / 100) * 24 * 3600;

        totalIds++;
        customers[msg.sender].id = totalIds ;
        idToAddress[totalIds ] = msg.sender;
        
        token.mint(msg.sender, msg.value * borrowRatio);
        totalFees += _fee;
        emit TokensBorrowed(msg.sender, customers[msg.sender].amount, _durationDays);
    }

    function returnTokens() external onlyBorrowed {
        uint256 _balance = token.balanceOf(msg.sender);
        require(_balance >= customers[msg.sender].amount, "NOT_ENOUGH_TOKENS_TO_RETURN");
        if (block.timestamp > customers[msg.sender].overdraftTime) {
            totalOverdraft += customers[msg.sender].eth;
            if (customers[msg.sender].id == totalIds) {
                totalIds--;
            }
            delete customers[msg.sender];
            emit OverdraftExpired(msg.sender);
            return;
        }
        uint256 _overdraftFee = 0;
        if (customers[msg.sender].untilTime < block.timestamp) {
            _overdraftFee = overdraftFee * ((block.timestamp - customers[msg.sender].untilTime) / uint(24 * 3600));

            if (_overdraftFee > customers[msg.sender].eth)  {
                totalOverdraft += customers[msg.sender].eth;
                if (customers[msg.sender].id == totalIds) {
                    totalIds--;
                }
                delete customers[msg.sender];
                emit NotEnoughEthForOverdraft(msg.sender);
                return;
            }

            customers[msg.sender].eth -= _overdraftFee;
            totalOverdraft += _overdraftFee;
            emit OverdraftFeeSuccess(msg.sender, _overdraftFee);
        }
        token.burn(msg.sender, customers[msg.sender].amount);
        customers[msg.sender].state = UserState.RETURNED;
        emit TokensReturnSuccess(msg.sender, customers[msg.sender].amount);
    }

    function withdrawEth() external onlyReturned {
        address payable _customer = payable(msg.sender);
        _customer.transfer(customers[msg.sender].eth);
        emit EthReturnedSuccess(msg.sender, customers[msg.sender].eth);
        if (customers[msg.sender].id == totalIds) {
            totalIds--;
        }
        delete customers[msg.sender];
    }

    function withdrawFeeContractEth() external onlyOwner {
        address payable _owner = payable(owner());
        require(totalFees > 0, "NO_FEE_TO_WITHDRAW");

        _owner.transfer(totalFees);
        emit EthOwnerWithdraw(totalFees);
        totalFees = 0;
    }

    function withdrawOverdraftContractEth() external onlyOwner {
        address payable _owner = payable(owner());
        require(totalOverdraft > 0, "NO_OVERDRAFT_TO_WITHDRAW");
        require(token.balanceOf(_owner) >= totalOverdraft * borrowRatio, "NOT_ENOUGH_TOKENS_TO_BURN");

        token.burn(_owner, totalOverdraft * borrowRatio);
        _owner.transfer(totalOverdraft);
        emit OverdraftOwnerWithdraw(totalOverdraft);
        totalOverdraft = 0;
    }

    function calculateOverdraft() external onlyOwner {
        address _customer;
        uint256 _newtotalIds = totalIds;
        bool _reduceIds = true;
        for (uint i = totalIds; i >= 1; i--) {
            _customer = idToAddress[i];
            if (customers[_customer].id == 0 && _reduceIds == true) {
                _newtotalIds--;
                continue;
            } else if (customers[_customer].id == 0) {
                continue;
            } else if (customers[_customer].state == UserState.RETURNED ||
                       customers[_customer].untilTime >= block.timestamp) {
                _reduceIds = false;
                continue;
            }  else if (customers[_customer].state == UserState.BORROWED &&
                        block.timestamp > customers[_customer].overdraftTime) {
                totalOverdraft += customers[_customer].eth;
                emit OverdraftExpired(_customer);
                delete customers[_customer];
                if (_reduceIds == true) {
                    _newtotalIds--;
                }
            }
        }
        totalIds = _newtotalIds;
    }
}
