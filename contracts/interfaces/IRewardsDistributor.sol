// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardsDistributor {
    function checkpoint_token() external;

    function voting_escrow() external view returns (address);

    function checkpoint_total_supply() external;

    function claimable(uint256 _tokenId) external view returns (uint256);
}
