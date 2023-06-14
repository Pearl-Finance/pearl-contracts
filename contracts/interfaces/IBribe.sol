// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribe {
    function _deposit(uint256 amount, uint256 tokenId) external;

    function _withdraw(uint256 amount, uint256 tokenId) external;

    function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint256 amount) external;

    function addReward(address) external;

    function setVoter(address _Voter) external;

    function setMinter(address _Voter) external;

    function setOwner(address _Voter) external;

    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external;
}
