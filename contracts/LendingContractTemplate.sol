// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface LendingToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferOwnership(address newOwner) external;
}

contract LendingContractsTemplate is Ownable {
    constructor(
        uint256 _borrowRatio,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _maxFee,
        uint256 _minFee,
        uint256 _overdraftPercentDuration,
        uint256 _overdraftFee,
        LendingToken _token
    ) {}

    function borrowTokens(uint256 _durationDays) external payable {}

    function returnTokens() external {}

    function withdrawEth() external {}

    function withdrawFeeContractEth() external onlyOwner {}

    function withdrawOverdraftContractEth() external onlyOwner {}

    function calculateOverdraft() external onlyOwner {}
}
