// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribeAPI {
    struct Reward {
        uint256 periodFinish;
        uint256 rewardsPerEpoch;
        uint256 lastUpdateTime;
    }

    function rewardData(address _token, uint256 ts) external view returns (Reward memory _Reward);

    function _deposit(uint256 amount, uint256 tokenId) external;

    function _withdraw(uint256 amount, uint256 tokenId) external;

    function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint256 amount) external;

    function left(address token) external view returns (uint256);

    function rewardsListLength() external view returns (uint256);

    function supplyNumCheckpoints() external view returns (uint256);

    function getEpochStart() external pure returns (uint256);

    function getNextEpochStart() external pure returns (uint256);

    function getPriorSupplyIndex(uint256 timestamp) external view returns (uint256);

    function rewardTokens(uint256 index) external view returns (address);

    function rewardsPerEpoch(address token, uint256 ts) external view returns (uint256);

    function supplyCheckpoints(uint256 _index) external view returns (uint256 timestamp, uint256 supplyd);

    function earned(uint256 tokenId, address token) external view returns (uint256);

    function firstBribeTimestamp() external view returns (uint256);

    function totalSupplyAt(uint256 _timestamp) external view returns (uint256);

    function balanceOfAt(uint256 tokenId, uint256 _timestamp) external view returns (uint256);
}
