// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHatchyReward {
    function updateUserWeight(address _account, uint256 newWeight,address referrer) external;
}
