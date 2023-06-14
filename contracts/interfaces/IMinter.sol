// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinter {
    function update_period() external returns (uint256);

    function check() external view returns (bool);

    function period() external view returns (uint256);

    function active_period() external view returns (uint256);
}
