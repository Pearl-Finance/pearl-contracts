// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/IPairFactory.sol";
import "../Pair.sol";

contract PairFactory is IPairFactory, OwnableUpgradeable {
    using MathUpgradeable for uint256;

    uint256 public constant FEE_PRECISION = 1e18;
    uint256 public constant MAX_FEE = 0.5e16; // 0.5%

    bool public isPaused;

    uint256 public stableFee;
    uint256 public volatileFee;

    address public feeManager;
    address public pendingFeeManager;

    mapping(address => mapping(address => mapping(bool => address))) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    address internal _temp0;
    address internal _temp1;
    bool internal _temp;

    event PairCreated(address indexed token0, address indexed token1, bool stable, address pair, uint256);

    modifier onlyManager() {
        require(msg.sender == feeManager);
        _;
    }

    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
        isPaused = false;
        feeManager = msg.sender;
        stableFee = 0.04e16; // 0.04%
        volatileFee = 0.18e16; // 0.18%
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function pairs() external view returns (address[] memory) {
        return allPairs;
    }

    function setPause(bool _state) external {
        require(msg.sender == owner());
        isPaused = _state;
    }

    function setFeeManager(address _feeManager) external onlyManager {
        pendingFeeManager = _feeManager;
    }

    function acceptFeeManager() external {
        require(msg.sender == pendingFeeManager);
        feeManager = pendingFeeManager;
    }

    function setFee(bool _stable, uint256 _fee) external onlyManager {
        require(_fee <= MAX_FEE, "fee");
        require(_fee != 0);
        if (_stable) {
            stableFee = _fee;
        } else {
            volatileFee = _fee;
        }
    }

    function getFee(bool _stable) public view returns (uint256) {
        return _stable ? stableFee : volatileFee;
    }

    function getFeeAmount(bool _stable, uint256 _amount) external view returns (uint256) {
        return getFee(_stable).mulDiv(_amount, FEE_PRECISION);
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(Pair).creationCode);
    }

    function getInitializable() external view returns (address, address, bool) {
        return (_temp0, _temp1, _temp);
    }

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair) {
        require(tokenA != tokenB, "IA"); // Pair: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZA"); // Pair: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), "PE"); // Pair: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
        (_temp0, _temp1, _temp) = (token0, token1, stable);
        pair = address(new Pair{salt: salt}());
        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }
}
