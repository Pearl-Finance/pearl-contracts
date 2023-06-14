// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Bribe.sol";

contract BribeFactoryV3 is AccessControlUpgradeable {
    bytes32 public constant BRIBE_ADMIN_ROLE = keccak256("BRIBE_ADMIN");

    address public last_bribe;
    address[] internal _bribes;
    address public voter;

    address[] public defaultRewardToken;

    mapping(address => bool) public isDefaultRewardToken;

    constructor() {}

    function initialize(address _voter, address[] calldata defaultRewardTokens) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BRIBE_ADMIN_ROLE, _msgSender());
        voter = _voter;

        //bribe default tokens
        for (uint256 i = 0; i < defaultRewardTokens.length; i++) {
            _pushDefaultRewardToken(defaultRewardTokens[i]);
        }
    }

    /// @notice create a bribe contract
    /// @dev    _owner must be teamMultisig
    function createBribe(address _owner, address _token0, address _token1, string memory _type) external returns (address) {
        if (msg.sender != voter) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        }

        Bribe lastBribe = new Bribe(_owner, voter, address(this), _type);

        if (_token0 != address(0)) lastBribe.addReward(_token0);
        if (_token1 != address(0)) lastBribe.addReward(_token1);

        lastBribe.addRewards(defaultRewardToken);

        last_bribe = address(lastBribe);
        _bribes.push(last_bribe);
        return last_bribe;
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice set the bribe factory voter
    function setVoter(address _Voter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_Voter != address(0));
        voter = _Voter;
    }

    function pushDefaultRewardToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pushDefaultRewardToken(_token);
    }

    function _pushDefaultRewardToken(address _token) internal {
        require(_token != address(0), "zero address not allowed");
        require(!isDefaultRewardToken[_token], "token already added");
        isDefaultRewardToken[_token] = true;
        defaultRewardToken.push(_token);
    }

    function removeDefaultRewardToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isDefaultRewardToken[_token], "not a default reward token");
        uint256 i = 0;
        for (i; i < defaultRewardToken.length; i++) {
            if (defaultRewardToken[i] == _token) {
                defaultRewardToken[i] = defaultRewardToken[defaultRewardToken.length - 1];
                defaultRewardToken.pop();
                isDefaultRewardToken[_token] = false;
                break;
            }
        }
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER or BRIBE ADMIN
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice Add a reward token to a given bribe
    function addRewardToBribe(address _token, address __bribe) external onlyRole(BRIBE_ADMIN_ROLE) {
        IBribe(__bribe).addReward(_token);
    }

    /// @notice Add multiple reward token to a given bribe
    function addRewardsToBribe(address[] memory _token, address __bribe) external onlyRole(BRIBE_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _token.length; i++) {
            IBribe(__bribe).addReward(_token[i]);
        }
    }

    /// @notice Add a reward token to given bribes
    function addRewardToBribes(address _token, address[] memory __bribes) external onlyRole(BRIBE_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < __bribes.length; i++) {
            IBribe(__bribes[i]).addReward(_token);
        }
    }

    /// @notice Add multiple reward tokens to given bribes
    function addRewardsToBribes(address[][] memory _token, address[] memory __bribes) external onlyRole(BRIBE_ADMIN_ROLE) {
        uint256 i = 0;
        uint256 k;
        for (i; i < __bribes.length; i++) {
            address _br = __bribes[i];
            for (k = 0; k < _token.length; k++) {
                IBribe(_br).addReward(_token[i][k]);
            }
        }
    }

    /// @notice set a new voter in given bribes
    function setBribeVoter(address[] memory _bribe, address _voter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _bribe.length; i++) {
            IBribe(_bribe[i]).setVoter(_voter);
        }
    }

    /// @notice set a new minter in given bribes
    function setBribeMinter(address[] memory _bribe, address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _bribe.length; i++) {
            IBribe(_bribe[i]).setMinter(_minter);
        }
    }

    /// @notice set a new owner in given bribes
    function setBribeOwner(address[] memory _bribe, address _owner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _bribe.length; i++) {
            IBribe(_bribe[i]).setOwner(_owner);
        }
    }

    /// @notice recover an ERC20 from bribe contracts.
    function recoverERC20From(
        address[] memory _bribe,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        require(_bribe.length == _tokens.length, "mismatch len");
        require(_tokens.length == _amounts.length, "mismatch len");

        for (i; i < _bribe.length; i++) {
            if (_amounts[i] > 0) IBribe(_bribe[i]).emergencyRecoverERC20(_tokens[i], _amounts[i]);
        }
    }

    /// @notice recover an ERC20 from bribe contracts and update.
    function recoverERC20AndUpdateData(
        address[] memory _bribe,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        require(_bribe.length == _tokens.length, "mismatch len");
        require(_tokens.length == _amounts.length, "mismatch len");

        for (i; i < _bribe.length; i++) {
            if (_amounts[i] > 0) IBribe(_bribe[i]).emergencyRecoverERC20(_tokens[i], _amounts[i]);
        }
    }
}
