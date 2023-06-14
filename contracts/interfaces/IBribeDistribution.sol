// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribeDistribution {
    function _deposit(uint256 amount, uint256 tokenId) external;

    function _withdraw(uint256 amount, uint256 tokenId) external;

    function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint256 amount) external;

    function left(address token) external view returns (uint256);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setOwner(address _owner) external;
}
