// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGaugeFactory {
    function createGauge(
        address _rewardToken,
        address _ve,
        address _token,
        address _distribution,
        address _internal_bribe,
        address _external_bribe,
        bool _isPair
    ) external returns (address);
}
