// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/IMinter.sol";
import "../interfaces/IVoter.sol";

contract EpochController is OwnableUpgradeable {
    IMinter public minter;
    IVoter public voter;
    uint256 public batchSize;

    uint256 private _lastProcessed;
    bool private _isDistributing;

    constructor() {}

    function initialize(address _minter, address _voter) public initializer {
        __Ownable_init();
        minter = IMinter(_minter);
        voter = IVoter(_voter);
        batchSize = 10;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        canExec = _isDistributing;
        if (!canExec) {
            canExec = minter.check();
            if (canExec) {
                canExec = voter.length() > 0;
            }
        }
        if (canExec) {
            execPayload = abi.encodeWithSelector(EpochController.distribute.selector);
        } else {
            execPayload = abi.encode(minter.active_period());
        }
    }

    function distribute() external {
        if (!_isDistributing) {
            _isDistributing = minter.check();
        }
        if (_isDistributing) {
            uint256 numPools = voter.length();
            uint256 from = _lastProcessed;
            uint256 to = MathUpgradeable.min(numPools, from + batchSize);
            voter.distribute(from, to);
            bool done = to == numPools;
            _lastProcessed = done ? 0 : to;
            _isDistributing = !done;
        }
    }

    function setBatchSize(uint256 _batchSize) external onlyOwner {
        require(_batchSize != 0, "batch size can not be 0");
        batchSize = _batchSize;
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0));
        minter = IMinter(_minter);
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = IVoter(_voter);
    }
}
