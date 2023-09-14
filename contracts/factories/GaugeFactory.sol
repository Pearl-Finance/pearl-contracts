// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IGauge.sol";
import "../interfaces/IGaugeFactory.sol";
import "../Gauge.sol";

contract GaugeFactory is IGaugeFactory, OwnableUpgradeable {
    address public last_gauge;

    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
    }

    function createGauge(
        address _rewardToken,
        address _ve,
        address _token,
        address _distribution,
        address _internal_bribe,
        address _external_bribe,
        bool _isPair
    ) external returns (address) {
        last_gauge = address(new Gauge(_rewardToken, _ve, _token, _distribution, _internal_bribe, _external_bribe, _isPair));
        return last_gauge;
    }

    function setDistribution(address _gauge, address _newDistribution) external onlyOwner {
        IGauge(_gauge).setDistribution(_newDistribution);
    }
}
