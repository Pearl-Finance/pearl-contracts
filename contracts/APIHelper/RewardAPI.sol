// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IBribe.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";

contract RewardAPI is Initializable {
    IPairFactory public pairFactory;
    IVoter public voter;
    address public underlyingToken;
    address public owner;

    mapping(address => bool) public notReward;

    constructor() {}

    function initialize(address _voter) public initializer {
        owner = msg.sender;
        voter = IVoter(_voter);
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }

    struct Bribes {
        address[] tokens;
        string[] symbols;
        uint256[] decimals;
        uint256[] amounts;
    }

    struct Rewards {
        Bribes[] bribes;
    }

    function hasPendingRewards(uint256 _tokenId, address[] calldata _pairs) external view returns (bool) {
        uint256 _numPairs = _pairs.length;

        for (uint256 i = 0; i < _numPairs; ) {
            address _gauge = voter.gauges(_pairs[i]);
            if (_gauge != address(0)) {
                // external
                address _bribe = voter.external_bribes(_gauge);
                uint256 _epochStart = IBribe(_bribe).getEpochStart();
                uint256 _balance = IBribe(_bribe).balanceOfAt(_tokenId, _epochStart);

                if (_balance != 0) {
                    uint256 _numTokens = IBribe(_bribe).rewardsListLength();
                    uint256 _supply = IBribe(_bribe).totalSupplyAt(_epochStart);

                    for (uint256 j; j < _numTokens; ) {
                        address _token = IBribe(_bribe).rewardTokens(j);
                        if (!notReward[_token]) {
                            IBribe.Reward memory _reward = IBribe(_bribe).rewardData(_token, _epochStart);
                            uint256 _amount = (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) / 1e18;
                            if (_amount != 0) return true;
                        }
                        unchecked {
                            ++j;
                        }
                    }
                }

                // internal
                _bribe = voter.internal_bribes(_gauge);
                _balance = IBribe(_bribe).balanceOfAt(_tokenId, _epochStart);

                if (_balance != 0) {
                    uint256 _numTokens = IBribe(_bribe).rewardsListLength();
                    uint256 _supply = IBribe(_bribe).totalSupplyAt(_epochStart);

                    for (uint256 j; j < _numTokens; ) {
                        address _token = IBribe(_bribe).rewardTokens(j);
                        if (!notReward[_token]) {
                            IBribe.Reward memory _reward = IBribe(_bribe).rewardData(_token, _epochStart);
                            uint256 _amount = (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) / 1e18;
                            if (_amount != 0) return true;
                        }
                        unchecked {
                            ++j;
                        }
                    }
                }
            }
            unchecked {
                ++i;
            }
        }

        return false;
    }

    // @Notice Get the rewards available the next epoch.
    function getExpectedClaimForNextEpoch(uint256 tokenId, address[] memory pairs) external view returns (Rewards[] memory) {
        uint256 i;
        uint256 len = pairs.length;
        address _gauge;
        address _bribe;

        Bribes[] memory _tempReward = new Bribes[](2);
        Rewards[] memory _rewards = new Rewards[](len);

        //external
        for (i = 0; i < len; i++) {
            _gauge = voter.gauges(pairs[i]);

            // get external
            _bribe = voter.external_bribes(_gauge);
            _tempReward[0] = _getEpochRewards(tokenId, _bribe);

            // get internal
            _bribe = voter.internal_bribes(_gauge);
            _tempReward[1] = _getEpochRewards(tokenId, _bribe);
            _rewards[i].bribes = _tempReward;
        }

        return _rewards;
    }

    function _getEpochRewards(uint256 tokenId, address _bribe) internal view returns (Bribes memory _rewards) {
        uint256 totTokens = IBribe(_bribe).rewardsListLength();
        uint256[] memory _amounts = new uint256[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint256[] memory _decimals = new uint256[](totTokens);
        uint256 ts = IBribe(_bribe).getEpochStart();
        uint256 i = 0;
        uint256 _supply = IBribe(_bribe).totalSupplyAt(ts);
        uint256 _balance = IBribe(_bribe).balanceOfAt(tokenId, ts);
        address _token;
        IBribe.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribe(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if (_balance == 0 || notReward[_token]) {
                _amounts[i] = 0;
                _symbol[i] = "";
                _decimals[i] = 0;
            } else {
                _symbol[i] = IERC20MetadataUpgradeable(_token).symbol();
                _decimals[i] = IERC20MetadataUpgradeable(_token).decimals();
                _reward = IBribe(_bribe).rewardData(_token, ts);
                _amounts[i] = (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) / 1e18;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    // read all the bribe available for a pair
    function getPairBribe(address pair) external view returns (Bribes[] memory) {
        address _gauge;
        address _bribe;

        Bribes[] memory _tempReward = new Bribes[](2);

        // get external
        _gauge = voter.gauges(pair);
        _bribe = voter.external_bribes(_gauge);
        _tempReward[0] = _getNextEpochRewards(_bribe);

        // get internal
        _bribe = voter.internal_bribes(_gauge);
        _tempReward[1] = _getNextEpochRewards(_bribe);
        return _tempReward;
    }

    function _getNextEpochRewards(address _bribe) internal view returns (Bribes memory _rewards) {
        uint256 totTokens = IBribe(_bribe).rewardsListLength();
        uint256[] memory _amounts = new uint256[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint256[] memory _decimals = new uint256[](totTokens);
        uint256 ts = IBribe(_bribe).getNextEpochStart();
        uint256 i = 0;
        address _token;
        IBribe.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribe(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if (notReward[_token]) {
                _amounts[i] = 0;
                _tokens[i] = address(0);
                _symbol[i] = "";
                _decimals[i] = 0;
            } else {
                _symbol[i] = IERC20MetadataUpgradeable(_token).symbol();
                _decimals[i] = IERC20MetadataUpgradeable(_token).decimals();
                _reward = IBribe(_bribe).rewardData(_token, ts);
                _amounts[i] = _reward.rewardsPerEpoch;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    function addNotReward(address _token) external {
        require(msg.sender == owner, "not owner");
        notReward[_token] = true;
    }

    function removeNotReward(address _token) external {
        require(msg.sender == owner, "not owner");
        notReward[_token] = false;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, "not owner");
        require(_voter != address(0), "zeroAddr");
        voter = IVoter(_voter);
        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }
}
