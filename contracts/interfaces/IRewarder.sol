// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewarder {
    function onReward(uint256 pid, address user, address recipient, uint256 amount, uint256 newLpAmount) external;
}
