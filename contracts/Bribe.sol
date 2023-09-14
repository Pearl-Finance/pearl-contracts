// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBribe.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./Epoch.sol";

contract Bribe is IBribe, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public firstBribeTimestamp;

    /* ========== STATE VARIABLES ========== */

    mapping(address => mapping(uint256 => IBribe.Reward)) private _rewardData; // token -> startTimestamp -> Reward
    mapping(address => uint256) _reserves;
    mapping(address => bool) public isRewardToken;
    address[] public rewardTokens;
    address public voter;
    address public bribeFactory;
    address public minter;
    address public ve;
    address public owner;

    string public TYPE;

    // tokenId -> reward token -> lastTime
    mapping(uint256 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(uint256 => mapping(address => uint256)) public userTimestamp;

    mapping(uint256 => uint256) public _totalSupply;
    mapping(uint256 => mapping(uint256 => uint256)) private _balances; // tokenId -> timestamp -> amount

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAllowed() {
        require((msg.sender == owner || msg.sender == bribeFactory), "permission is denied!");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _voter, address _bribeFactory, string memory _type) {
        require(_bribeFactory != address(0) && _voter != address(0) && _owner != address(0));
        voter = _voter;
        bribeFactory = _bribeFactory;
        firstBribeTimestamp = 0;
        ve = IVoter(_voter)._ve();
        minter = IVoter(_voter).minter();
        require(minter != address(0));
        owner = _owner;

        TYPE = _type;
    }

    function getEpochStart() public view returns (uint256) {
        return IMinter(minter).active_period();
    }

    function getNextEpochStart() public view returns (uint256) {
        return getEpochStart() + EPOCH_DURATION;
    }

    /* ========== VIEWS ========== */

    function rewardData(address _token, uint256 _timestamp) external view override returns (Reward memory) {
        return _rewardData[_token][_timestamp];
    }

    function rewardsListLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply[getNextEpochStart()];
    }

    function totalSupplyAt(uint256 _timestamp) external view returns (uint256) {
        return _totalSupply[_timestamp];
    }

    function balanceOfAt(uint256 tokenId, uint256 _timestamp) public view returns (uint256) {
        return _balances[tokenId][_timestamp];
    }

    // get last deposit available balance (getNextEpochStart)
    function balanceOf(uint256 tokenId) public view returns (uint256) {
        uint256 _timestamp = getNextEpochStart();
        return _balances[tokenId][_timestamp];
    }

    function earned(uint256 tokenId, address _rewardToken) public view returns (uint256) {
        uint256 k = 0;
        uint256 reward = 0;
        uint256 _endTimestamp = getNextEpochStart();
        uint256 _userLastTime = userTimestamp[tokenId][_rewardToken];

        if (_endTimestamp == _userLastTime) {
            return 0;
        }

        // if user first time then set it to first bribe - week to avoid any timestamp problem
        if (_userLastTime < firstBribeTimestamp) {
            _userLastTime = firstBribeTimestamp - EPOCH_DURATION;
        }

        for (k; k < 50; k++) {
            if (_userLastTime == _endTimestamp) {
                // if we reach the current epoch, exit
                break;
            }
            reward += _earned(tokenId, _rewardToken, _userLastTime);
            _userLastTime += EPOCH_DURATION;
        }
        return reward;
    }

    function _earned(uint256 tokenId, address _rewardToken, uint256 _timestamp) internal view returns (uint256) {
        uint256 _balance = balanceOfAt(tokenId, _timestamp);
        if (_balance == 0) {
            return 0;
        } else {
            uint256 _rewardPerToken = rewardPerToken(_rewardToken, _timestamp);
            uint256 _rewards = (_rewardPerToken * _balance) / 1e18;
            return _rewards;
        }
    }

    function rewardPerToken(address _rewardsToken, uint256 _timestamp) public view returns (uint256) {
        if (_totalSupply[_timestamp] == 0) {
            return _rewardData[_rewardsToken][_timestamp].rewardsPerEpoch;
        }
        return (_rewardData[_rewardsToken][_timestamp].rewardsPerEpoch * 1e18) / _totalSupply[_timestamp];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _deposit(uint256 amount, uint256 tokenId) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(msg.sender == voter);
        uint256 _startTimestamp = getNextEpochStart();
        uint256 _oldSupply = _totalSupply[_startTimestamp];
        _totalSupply[_startTimestamp] = _oldSupply + amount;
        _balances[tokenId][_startTimestamp] = _balances[tokenId][_startTimestamp] + amount;
        emit Staked(tokenId, amount);
    }

    function _withdraw(uint256 amount, uint256 tokenId) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(msg.sender == voter);
        uint256 _startTimestamp = getNextEpochStart();
        // incase of bribe contract reset in gauge proxy
        if (amount <= _balances[tokenId][_startTimestamp]) {
            uint256 _oldSupply = _totalSupply[_startTimestamp];
            uint256 _oldBalance = _balances[tokenId][_startTimestamp];
            _totalSupply[_startTimestamp] = _oldSupply - amount;
            _balances[tokenId][_startTimestamp] = _oldBalance - amount;
            emit Withdrawn(tokenId, amount);
        }
    }

    function getReward(uint256 tokenId, address[] calldata tokens) external nonReentrant {
        require(IVotingEscrow(ve).isApprovedOrOwner(msg.sender, tokenId));
        _getReward(tokenId, tokens);
    }

    function getRewardForOwner(uint256 tokenId, address[] calldata tokens) public nonReentrant {
        require(msg.sender == voter);
        _getReward(tokenId, tokens);
    }

    function _getReward(uint256 tokenId, address[] calldata tokens) internal {
        uint256 _endTimestamp = getNextEpochStart();
        uint256 reward = 0;

        IVotingEscrow _ve = IVotingEscrow(ve);
        address _receiver = _ve.ownerOf(tokenId);

        for (uint256 i = tokens.length; i != 0; ) {
            unchecked {
                --i;
            }
            address _rewardToken = tokens[i];
            reward = earned(tokenId, _rewardToken);
            if (reward > 0) {
                _reserves[_rewardToken] -= reward;
                IERC20(_rewardToken).safeTransfer(_receiver, reward);
                emit RewardPaid(_receiver, _rewardToken, reward);
            }
            userTimestamp[tokenId][_rewardToken] = _endTimestamp;
        }
    }

    function notifyRewardAmount(address _rewardsToken, uint256 reward) external nonReentrant {
        require(isRewardToken[_rewardsToken], "reward token not verified");
        IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), reward);

        _reserves[_rewardsToken] += reward;

        uint256 _startTimestamp = getNextEpochStart();
        if (firstBribeTimestamp == 0) {
            firstBribeTimestamp = _startTimestamp;
        }

        uint256 _lastReward = _rewardData[_rewardsToken][_startTimestamp].rewardsPerEpoch;

        _rewardData[_rewardsToken][_startTimestamp].rewardsPerEpoch = _lastReward + reward;
        _rewardData[_rewardsToken][_startTimestamp].lastUpdateTime = block.timestamp;
        _rewardData[_rewardsToken][_startTimestamp].periodFinish = _startTimestamp + EPOCH_DURATION;

        emit RewardAdded(_rewardsToken, reward, _startTimestamp);
    }

    function skim(address _to) external returns (uint256[] memory _amounts) {
        uint256 _numTokens = rewardTokens.length;
        _amounts = new uint256[](_numTokens);
        for (uint256 i = _numTokens; i != 0; ) {
            unchecked {
                --i;
            }
            address _rewardToken = rewardTokens[i];
            uint256 _reserve = _reserves[_rewardToken];
            uint256 _balance = IERC20(_rewardToken).balanceOf(address(this));
            if (_balance > _reserve) {
                uint256 _amount;
                unchecked {
                    _amount = _balance - _reserve;
                }
                _amounts[i] = _amount;
                IERC20(_rewardToken).safeTransfer(_to, _amount);
            }
        }
    }

    function skim(address _rewardsToken, address _to) external returns (uint256 _amount) {
        uint256 _reserve = _reserves[_rewardsToken];
        uint256 _balance = IERC20(_rewardsToken).balanceOf(address(this));
        if (_balance > _reserve) {
            unchecked {
                _amount = _balance - _reserve;
            }
            IERC20(_rewardsToken).safeTransfer(_to, _amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice add rewards tokens
    function addRewards(address[] memory _rewardsToken) public onlyAllowed {
        for (uint256 i = _rewardsToken.length; i != 0; ) {
            unchecked {
                --i;
            }
            _addReward(_rewardsToken[i]);
        }
    }

    /// @notice add a single reward token
    function addReward(address _rewardsToken) public onlyAllowed {
        _addReward(_rewardsToken);
    }

    function _addReward(address _rewardsToken) internal {
        if (!isRewardToken[_rewardsToken]) {
            isRewardToken[_rewardsToken] = true;
            rewardTokens.push(_rewardsToken);
        }
    }

    /// @notice Recover some ERC20 from the contract and updated given bribe
    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external onlyAllowed {
        require(tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)));

        uint256 _startTimestamp = IMinter(minter).active_period() + EPOCH_DURATION;
        uint256 _lastReward = _rewardData[tokenAddress][_startTimestamp].rewardsPerEpoch;
        _rewardData[tokenAddress][_startTimestamp].rewardsPerEpoch = _lastReward - tokenAmount;
        _rewardData[tokenAddress][_startTimestamp].lastUpdateTime = block.timestamp;

        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// @notice Recover some ERC20 from the contract.
    /// @dev    Be careful --> if called then getReward() at last epoch will fail because some reward are missing!
    ///         Think about calling recoverERC20AndUpdateData()
    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external onlyAllowed {
        require(tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)));
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setVoter(address _Voter) external onlyOwner {
        require(_Voter != address(0));
        voter = _Voter;
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }

    /* ========== MODIFIERS ========== */

    /* ========== EVENTS ========== */

    event RewardAdded(address rewardToken, uint256 reward, uint256 startTimestamp);
    event Staked(uint256 indexed tokenId, uint256 amount);
    event Withdrawn(uint256 indexed tokenId, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event Recovered(address token, uint256 amount);
}
