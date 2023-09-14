// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "./interfaces/IPair.sol";
import "./interfaces/IPairFactory.sol";

/// @title SingleTokenLiquidityProvider
/// @notice Provides liquidity to Uniswap v2 style pairs using a single token
contract SingleTokenLiquidityProvider is MulticallUpgradeable, OwnableUpgradeable {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant FEE_PRECISION = 1e18;

    // Factory contract to create and manage pairs
    IPairFactory public factory;

    // Whether the contract requires whitelisting
    bool public requiresWhitelisting;

    // Max swap percentage of reserves
    uint256 public maxSwapRatio;

    // Mapping of addresses to their whitelisted status
    mapping(address => bool) public isWhitelisted;

    event LiquidityAdded(
        address indexed pair,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 swapAmount,
        uint256 amountOut,
        uint256 liquidity
    );

    event Whitelisted(address indexed _account, bool _status);

    event FactoryUpdated(address indexed _factory);

    event MaxSwapRatioUpdated(uint256 _ratio);

    /// @notice Initializes the contract with the pair factory and whitelisting requirement.
    /// @param _pairFactory Address of the pair factory.
    /// @param _requiresWhitelisting Whether whitelisting is required.
    function initialize(address _pairFactory, bool _requiresWhitelisting) public initializer {
        __Multicall_init();
        __Ownable_init();
        factory = IPairFactory(_pairFactory);
        requiresWhitelisting = _requiresWhitelisting;
        maxSwapRatio = 3000; // 30%
    }

    /// @notice Updates the pair factory.
    /// @param _pairFactory Address of the new pair factory.
    function setPairFactory(address _pairFactory) external onlyOwner {
        factory = IPairFactory(_pairFactory);
        emit FactoryUpdated(_pairFactory);
    }

    /// @notice Whitelists or removes an address from the whitelist.
    /// @param _account Address to whitelist.
    /// @param _status Whether to whitelist the address.
    function whitelist(address _account, bool _status) external onlyOwner {
        isWhitelisted[_account] = _status;
        emit Whitelisted(_account, _status);
    }

    /// @dev Sets the maximum swap ratio allowed as a percentage of reserves
    /// @param _ratio The max swap ratio to set, out of 10,000 (100% = 10,000)
    function setMaxSwapRatio(uint256 _ratio) external onlyOwner {
        // Validate input ratio
        require(_ratio > 0 && _ratio <= 10000, "invalid ratio");
        maxSwapRatio = _ratio;
        emit MaxSwapRatioUpdated(_ratio);
    }

    /// @notice Adds liquidity for a given pair using a given token.
    /// @param _pair Pair to provide liquidity for.
    /// @param _token Token address to provide liquidity with.
    /// @param _amount Amount of token to provide.
    /// @param _swapAmount The amount of tokens to swap for the other pair token.
    /// @param _minLiquidity Minimum liquidity to provide.
    /// @return _liquidity The amount of liquidity added.
    function addLiquidity(
        IPair _pair,
        address _token,
        uint256 _amount,
        uint256 _swapAmount,
        uint256 _minLiquidity
    ) external returns (uint256 _liquidity) {
        // Validate whitelisting
        require(!requiresWhitelisting || isWhitelisted[msg.sender], "not whitelisted");

        // Validate pair contract
        require(factory.isPair(address(_pair)), "invalid pair");

        (address _token0, address _token1) = _pair.tokens();
        bool _zeroForOne = _token == _token0;
        if (_swapAmount == 0) {
            _swapAmount = _optimizeSwapAmount(_pair, _zeroForOne ? _amount : 0, _zeroForOne ? 0 : _amount);
            _checkSwapAmount(_pair, _swapAmount);
        }
        uint256 _amountOut = _pair.getAmountOut(_swapAmount, _token);
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(_pair), _swapAmount);
        _pair.swap(_zeroForOne ? 0 : _amountOut, _zeroForOne ? _amountOut : 0, address(this), "");
        unchecked {
            IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(_pair), _amount - _swapAmount);
            IERC20Upgradeable(_zeroForOne ? _token1 : _token0).safeTransfer(address(_pair), _amountOut);
        }
        _liquidity = _pair.mint(msg.sender);
        require(_liquidity >= _minLiquidity, "insufficient amount");
        emit LiquidityAdded(address(_pair), _token, _amount, _swapAmount, _amountOut, _liquidity);
    }

    /// @dev Checks that the swap amount is below the allowed ratio of total reserves
    /// @param _pair The pair to get reserves from
    /// @param _swapAmount The amount of tokens to swap
    function _checkSwapAmount(IPair _pair, uint256 _swapAmount) internal view {
        (uint256 reserve0, uint256 reserve1, ) = _pair.getReserves();

        uint256 decimals0 = ERC20Upgradeable(_pair.token0()).decimals();
        uint256 decimals1 = ERC20Upgradeable(_pair.token1()).decimals();

        // Adjust reserves to 18 decimals
        uint256 normalizedReserve0 = reserve0 * 10 ** (18 - decimals0);
        uint256 normalizedReserve1 = reserve1 * 10 ** (18 - decimals1);

        uint256 totalReserves = normalizedReserve0 + normalizedReserve1;

        // Check swap ratio
        require(_swapAmount <= (totalReserves * maxSwapRatio) / 10000, "swap too large");
    }

    /// @dev Find optimal swap amount
    function _optimizeSwapAmount(IPair _pair, uint256 _amount0In, uint256 _amount1In) internal view returns (uint256 _swapAmount) {
        bool _stable = _pair.stable();
        bool _zeroForOne = _amount0In != 0;

        require((_zeroForOne ? _amount1In : _amount0In) == 0, "invalid input");

        uint256 _fee = factory.isPrivileged(address(this)) ? 0 : (_stable ? factory.stableFee() : factory.volatileFee());
        (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();

        uint256 _decimals0;
        uint256 _decimals1;

        {
            (address _token0, address _token1) = _pair.tokens();
            _decimals0 = 10 ** ERC20Upgradeable(_token0).decimals();
            _decimals1 = 10 ** ERC20Upgradeable(_token1).decimals();
        }

        uint256 _lowerBoundary;
        uint256 _upperBoundary = _zeroForOne ? _amount0In : _amount1In;
        uint256 _bestDiff = type(uint256).max;

        for (uint256 _i = 100; _i != 0; ) {
            _swapAmount = (_lowerBoundary + _upperBoundary) / 2;

            (uint256 _amount0Out, uint256 _amount1Out, uint256 _reserve0_, uint256 _reserve1_) = _computeSwapResult(
                _amount0In,
                _amount1In,
                _zeroForOne ? _swapAmount : 0,
                _zeroForOne ? 0 : _swapAmount,
                _decimals0,
                _decimals1,
                _reserve0,
                _reserve1,
                _stable,
                _fee
            );

            uint256 _proportion0 = _reserve0_ * _amount1Out;
            uint256 _proportion1 = _reserve1_ * _amount0Out;

            if (_proportion0 == _proportion1) {
                break;
            }

            unchecked {
                if (_proportion0 > _proportion1) {
                    uint256 _diff = _proportion0 - _proportion1;
                    if (_diff == _bestDiff) {
                        break;
                    }
                    _bestDiff = _diff;
                    if (_zeroForOne) {
                        _upperBoundary = _swapAmount;
                    } else {
                        _lowerBoundary = _swapAmount;
                    }
                } else {
                    uint256 _diff = _proportion1 - _proportion0;
                    if (_diff == _bestDiff) {
                        break;
                    }
                    _bestDiff = _diff;
                    if (_zeroForOne) {
                        _lowerBoundary = _swapAmount;
                    } else {
                        _upperBoundary = _swapAmount;
                    }
                }
                --_i;
            }
        }
    }

    /// @dev Formula for stable swap invariant k
    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (x0 * ((((y * y) / 1e18) * y) / 1e18)) / 1e18 + (((((x0 * x0) / 1e18) * x0) / 1e18) * y) / 1e18;
    }

    /// @dev Derivative of f(x0, y) with respect to y
    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    /// @dev Newton's method to find y that gives desired invariant k
    function _get_y(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint256) {
        for (uint256 i = 255; i != 0; ) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y); // Calculate invariant k
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y); // Update y based on derivative
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    // Check for convergence
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
            unchecked {
                --i;
            }
        }
        return y;
    }

    /// @dev Formula for invariant k given reserves
    function _k(uint256 x, uint256 y, uint256 _decimals0, uint256 _decimals1) internal pure returns (uint256) {
        uint256 _x = (x * 1e18) / _decimals0;
        uint256 _y = (y * 1e18) / _decimals1;
        uint256 _a = (_x * _y) / 1e18;
        uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
        return (_a * _b) / 1e18;
    }

    /// @dev Get swap output amount
    function _getAmountOut(
        uint256 _amountIn,
        bool _zeroForOne,
        uint256 _decimals0,
        uint256 _decimals1,
        uint256 _reserve0,
        uint256 _reserve1,
        bool _stable
    ) internal pure returns (uint256) {
        if (_stable) {
            // Use stable swap math
            uint256 xy = _k(_reserve0, _reserve1, _decimals0, _decimals1);
            _reserve0 = (_reserve0 * 1e18) / _decimals0;
            _reserve1 = (_reserve1 * 1e18) / _decimals1;
            (uint256 reserveA, uint256 reserveB) = _zeroForOne ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            _amountIn = _zeroForOne ? (_amountIn * 1e18) / _decimals0 : (_amountIn * 1e18) / _decimals1;
            uint256 y = reserveB - _get_y(_amountIn + reserveA, xy, reserveB);
            return (y * (_zeroForOne ? _decimals1 : _decimals0)) / 1e18;
        } else {
            // Use standard constant product math
            (uint256 reserveA, uint256 reserveB) = _zeroForOne ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return (_amountIn * reserveB) / (reserveA + _amountIn);
        }
    }

    /// @dev Compute swap amounts and new reserves
    function _computeSwapResult(
        uint256 amount0In,
        uint256 amount1In,
        uint256 _swapAmount0,
        uint256 _swapAmount1,
        uint256 _decimals0,
        uint256 _decimals1,
        uint256 _reserve0,
        uint256 _reserve1,
        bool _stable,
        uint256 _swapFee
    ) internal pure returns (uint256 _amount0Out, uint256 _amount1Out, uint256 _reserve0_, uint256 _reserve1_) {
        _amount0Out = amount0In - _swapAmount0;
        _amount1Out = amount1In - _swapAmount1;

        (_reserve0_, _reserve1_) = (_reserve0, _reserve1);

        if (_swapAmount0 != 0) {
            uint256 _amountOut = _getAmountOut(_swapAmount0, true, _decimals0, _decimals1, _reserve0, _reserve1, _stable);
            _amount1Out += _amountOut;
            _reserve1_ -= _amountOut;
            _reserve0_ += _swapAmount0 - _swapAmount0.mulDiv(_swapFee, FEE_PRECISION);
        }

        if (_swapAmount1 != 0) {
            uint256 _amountOut = _getAmountOut(_swapAmount1, false, _decimals0, _decimals1, _reserve0, _reserve1, _stable);
            _amount0Out += _amountOut;
            _reserve0_ -= _amountOut;
            _reserve1_ += _swapAmount1 - _swapAmount1.mulDiv(_swapFee, FEE_PRECISION);
        }
    }
}
