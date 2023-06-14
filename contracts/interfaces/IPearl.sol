// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPearl {
    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function mint(address, uint256) external returns (bool);

    function minter() external returns (address);
}
