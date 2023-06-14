// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20Mintable is ERC20Upgradeable {
    uint8 private _decimals;

    function initialize(string memory name, string memory symbol, uint8 decimals_) external initializer {
        __ERC20_init(name, symbol);
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
