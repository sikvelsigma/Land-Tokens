// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ILendingToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);
}

contract LendingContracts is Ownable {
    uint256 public immutable borrowRatio;
    uint256 public immutable minDuration;
    uint256 public immutable maxDuration;
    uint256 public immutable maxFee;
    uint256 public immutable minFee;
    uint256 public immutable overdraftPercentDuration; // 50% allowed overdraft as base
    uint256 public immutable overdraftFee; // additional fee each day
    ILendingToken token;

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
    mapping(uint256 => address) idToAddress;
    uint256 totalIds = 0;
    uint256 lowerId = 1;

    modifier onlyInitial() {
        require(customers[msg.sender].state == UserState.INITIAL, "CANNOT_BORROW_TWICE");
        _;
    }
    modifier onlyBorrowed() {
        require(customers[msg.sender].state == UserState.BORROWED, "ONLY_ACTIVE_BORROWERS");
        _;
    }
    modifier onlyReturned() {
        require(customers[msg.sender].state == UserState.RETURNED, "ONLY_AFTER_TOKENS_RETURN");
        _;
    }
    modifier tokenSet() {
        require(address(token) != address(0), "TOKEN_CONTRACT_NOT_SET");
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
    event OverdraftFeeUpdated(uint _amount);

    constructor(
        uint256 _borrowRatio,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _maxFee,
        uint256 _minFee,
        uint256 _overdraftPercentDuration,
        uint256 _overdraftFee
        // ILendingToken _token
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
        // token = _token;
        // _token.transferOwnership(address(this));
    }

    function setToken (ILendingToken _token) external onlyOwner {
        require(address(token) == address(0), "TOKEN_ALREADY_SET");
        require(address(this) == _token.owner(), "INCORRECT_TOKEN_OWNER");
        token = _token;
    }

    function borrowTokens(uint256 _durationDays) external payable tokenSet onlyInitial {
        require(msg.value > minFee, "ETH_AMOUNT_TOO_SMALL");
        require(_durationDays >= minDuration, "DURATION_TOO_SMALL");
        require(_durationDays <= maxDuration, "DURATION_TOO_LARGE");

        uint256 _fee = minFee +
            (_durationDays - minDuration) / (maxDuration - minDuration) * (maxFee - minFee);

        customers[msg.sender].amount = msg.value * borrowRatio;
        customers[msg.sender].eth = msg.value - _fee;
        customers[msg.sender].untilTime = block.timestamp + _durationDays * 1 days;
        customers[msg.sender].state = UserState.BORROWED;
        customers[msg.sender].overdraftTime = block.timestamp + (_durationDays * (100 + overdraftPercentDuration) / 100) * 1 days;

        totalIds++;
        customers[msg.sender].id = totalIds ;
        idToAddress[totalIds ] = msg.sender;
        
        token.mint(msg.sender, msg.value * borrowRatio);
        totalFees += _fee;
        emit TokensBorrowed(msg.sender, customers[msg.sender].amount, _durationDays);
    }

    function returnTokens() external tokenSet onlyBorrowed {
        uint256 _balance = token.balanceOf(msg.sender);
        require(_balance >= customers[msg.sender].amount, "NOT_ENOUGH_TOKENS_TO_RETURN");
        if (block.timestamp > customers[msg.sender].overdraftTime) {
            totalOverdraft += customers[msg.sender].eth;
            _trimCustomerMap(msg.sender);
            delete customers[msg.sender];
            emit OverdraftExpired(msg.sender);
            return;
        }
        uint256 _overdraftFee = 0;
        if (block.timestamp > customers[msg.sender].untilTime) {
            _overdraftFee = overdraftFee * uint((block.timestamp - customers[msg.sender].untilTime) / 1 days);

            if (_overdraftFee > customers[msg.sender].eth)  {
                totalOverdraft += customers[msg.sender].eth;
                _trimCustomerMap(msg.sender);
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

    function withdrawEth() external tokenSet onlyReturned {
        require(block.timestamp > customers[msg.sender].untilTime, "REQUIRED_TIME_NOT_PASSED");
        address payable _customer = payable(msg.sender);
        _customer.transfer(customers[msg.sender].eth);
        emit EthReturnedSuccess(msg.sender, customers[msg.sender].eth);
        _trimCustomerMap(msg.sender);
        delete customers[msg.sender];
    }

    function _trimCustomerMap(address _customer) internal {
        if (customers[_customer].id == totalIds) {
            totalIds--;
        } else if (customers[_customer].id == lowerId) {
            lowerId++;
        }
    }

    function withdrawFeeContractEth() external tokenSet onlyOwner {
        address payable _owner = payable(owner());
        require(totalFees > 0, "NO_FEE_TO_WITHDRAW");

        _owner.transfer(totalFees);
        emit EthOwnerWithdraw(totalFees);
        totalFees = 0;
    }

    function withdrawOverdraftContractEth() external tokenSet onlyOwner {
        address payable _owner = payable(owner());
        require(totalOverdraft > 0, "NO_OVERDRAFT_TO_WITHDRAW");
        require(token.balanceOf(_owner) >= totalOverdraft * borrowRatio, "NOT_ENOUGH_TOKENS_TO_BURN");

        token.burn(_owner, totalOverdraft * borrowRatio);
        _owner.transfer(totalOverdraft);
        emit OverdraftOwnerWithdraw(totalOverdraft);
        totalOverdraft = 0;
    }

    function calculateOverdraft() external tokenSet onlyOwner {
        address _customer;
        uint256 _newTotalIds = totalIds;
        uint256 _newLowerId = lowerId;
        bool _reduceIds = true;
        for (uint i = lowerId; i <= totalIds; i++) {
            _customer = idToAddress[i];
            if (customers[_customer].id == 0) {
                _newLowerId++;
                continue;
            } else if (customers[_customer].state == UserState.RETURNED ||
                       customers[_customer].untilTime >= block.timestamp) {
                break;
            }  else if (customers[_customer].state == UserState.BORROWED &&
                        customers[_customer].overdraftTime < block.timestamp) {
                totalOverdraft += customers[_customer].eth;
                emit OverdraftExpired(_customer);
                delete customers[_customer];
                _newLowerId++;

            } else {
                break;
            }
        }
        lowerId = _newLowerId;
        for (uint i = totalIds; i > lowerId; i--) {
            _customer = idToAddress[i];
            if (customers[_customer].id == 0 && _reduceIds == true) {
                _newTotalIds--;
                continue;
            } else if (customers[_customer].id == 0) {
                continue;
            } else if (customers[_customer].state == UserState.RETURNED ||
                       customers[_customer].untilTime >= block.timestamp) {
                _reduceIds = false;
                continue;
            }  else if (customers[_customer].state == UserState.BORROWED &&
                        customers[_customer].overdraftTime < block.timestamp) {
                totalOverdraft += customers[_customer].eth;
                emit OverdraftExpired(_customer);
                delete customers[_customer];
                if (_reduceIds == true) {
                    _newTotalIds--;
                }
            } else {
                _reduceIds = false;
            }
        }
        totalIds = _newTotalIds;
        emit OverdraftFeeUpdated(totalOverdraft);
    }
}
