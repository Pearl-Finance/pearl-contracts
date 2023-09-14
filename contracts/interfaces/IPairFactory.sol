// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPairFactory {
    function allPairsLength() external view returns (uint256);

    function isPair(address pair) external view returns (bool);

    function allPairs(uint256 index) external view returns (address);

    function getPair(address tokenA, address token, bool stable) external view returns (address);

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);

    function getFeeAmount(bool _stable, uint256 _amount, address _account) external view returns (uint256);

    function stableFee() external view returns (uint256);

    function volatileFee() external view returns (uint256);

    function isPrivileged(address _account) external view returns (bool);
}
