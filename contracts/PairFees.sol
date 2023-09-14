// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Pair Fees contract is used as a 1:1 pair relationship to split out fees, this ensures that the curve does not need to be modified for LP shares
contract PairFees {
    address internal immutable pair; // The pair it is bonded to
    address internal immutable token0; // token0 of pair, saved localy and statically for gas optimization
    address internal immutable token1; // Token1 of pair, saved localy and statically for gas optimization

    uint256 private _reserve0;
    uint256 private _reserve1;

    constructor(address _token0, address _token1) {
        pair = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        if (value != 0) {
            require(token.code.length != 0);
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
    }

    // Allow the pair to transfer fees to users
    function claimFeesFor(address recipient, uint256 amount0, uint256 amount1) external {
        require(msg.sender == pair);
        if (amount0 != 0) {
            uint256 reserve0 = _reserve0;
            if (reserve0 >= amount0) {
                unchecked {
                    _reserve0 = reserve0 - amount0;
                    _safeTransfer(token0, recipient, amount0);
                }
            }
        }
        if (amount1 != 0) {
            uint256 reserve1 = _reserve1;
            if (reserve1 >= amount1) {
                unchecked {
                    _reserve1 = reserve1 - amount1;
                    _safeTransfer(token1, recipient, amount1);
                }
            }
        }
    }

    function skim() external returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 reserve0 = _reserve0;
        uint256 reserve1 = _reserve1;
        if (balance0 > reserve0) {
            unchecked {
                _safeTransfer(token0, msg.sender, amount0 = balance0 - reserve0);
            }
        }
        if (balance1 > reserve1) {
            unchecked {
                _safeTransfer(token1, msg.sender, amount1 = balance1 - reserve1);
            }
        }
    }

    function notifyFeeAmounts(uint256 amount0, uint256 amount1) external {
        require(msg.sender == pair);
        if (amount0 != 0) _reserve0 = _reserve0 + amount0;
        if (amount1 != 0) _reserve1 = _reserve1 + amount1;
    }
}
