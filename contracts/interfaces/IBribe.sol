// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribe {
    struct Reward {
        uint256 periodFinish;
        uint256 rewardsPerEpoch;
        uint256 lastUpdateTime;
    }

    function _deposit(uint256 amount, uint256 tokenId) external;

    function _withdraw(uint256 amount, uint256 tokenId) external;

    function addReward(address) external;

    function balanceOfAt(uint256 tokenId, uint256 _timestamp) external view returns (uint256);

    function earned(uint256 tokenId, address _rewardToken) external view returns (uint256);

    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function firstBribeTimestamp() external view returns (uint256);

    function getEpochStart() external view returns (uint256);

    function getNextEpochStart() external view returns (uint256);

    function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint256 amount) external;

    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external;

    function rewardData(address _token, uint256 _timestamp) external view returns (Reward memory);

    function rewardTokens(uint256 _index) external view returns (address);

    function rewardsListLength() external view returns (uint256);

    function setMinter(address _minter) external;

    function setOwner(address _owner) external;

    function setVoter(address _voter) external;

    function totalSupplyAt(uint256 _timestamp) external view returns (uint256);
}
