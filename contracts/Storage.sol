// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Storage
 * @dev This contract allows for the storage of key-value pairs.
 * Only an address with the DEFAULT_ADMIN_ROLE can set values.
 */
contract Storage is AccessControlUpgradeable {
    mapping(bytes32 => bytes32) private values;

    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "StorageContract: caller is not an admin");
        _;
    }

    /**
     * @dev Returns the raw bytes32 value associated with the given key.
     * @param key The key for the value.
     * @return The bytes32 value.
     */
    function get(bytes32 key) public view returns (bytes32) {
        return values[key];
    }

    /**
     * @dev Returns the address value associated with the given key.
     * @param key The key for the value.
     * @return The address value.
     */
    function getAddress(bytes32 key) public view returns (address) {
        return address(uint160(uint256(values[key])));
    }

    /**
     * @dev Returns the uint256 value associated with the given key.
     * @param key The key for the value.
     * @return The uint256 value.
     */
    function getUint256(bytes32 key) public view returns (uint256) {
        return uint256(values[key]);
    }

    /**
     * @dev Returns the int256 value associated with the given key.
     * @param key The key for the value.
     * @return The int256 value.
     */
    function getInt256(bytes32 key) public view returns (int256) {
        bytes32 value = values[key];
        int256 intValue;
        assembly {
            intValue := value
        }
        return intValue;
    }

    /**
     * @dev Stores a bytes32 value associated with the key.
     * @param key The key for the value.
     * @param value The bytes32 value to be stored.
     */
    function set(bytes32 key, bytes32 value) public onlyAdmin {
        values[key] = value;
    }

    /**
     * @dev Stores an address value associated with the key.
     * @param key The key for the value.
     * @param value The address value to be stored.
     */
    function setAddress(bytes32 key, address value) public onlyAdmin {
        values[key] = bytes32(uint256(uint160(value)));
    }

    /**
     * @dev Stores a uint256 value associated with the key.
     * @param key The key for the value.
     * @param value The uint256 value to be stored.
     */
    function setUint256(bytes32 key, uint256 value) public onlyAdmin {
        values[key] = bytes32(value);
    }

    /**
     * @dev Stores an int256 value associated with the key.
     * @param key The key for the value.
     * @param value The int256 value to be stored.
     */
    function setInt256(bytes32 key, int256 value) public onlyAdmin {
        bytes32 bytes32Value;
        assembly {
            bytes32Value := value
        }
        values[key] = bytes32Value;
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to a new admin.
     * @param newAdmin The address of the new admin.
     */
    function grantAdminRole(address newAdmin) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /**
     * @dev Revokes `DEFAULT_ADMIN_ROLE` from an address.
     * @param admin The address of the admin to be revoked.
     */
    function revokeAdminRole(address admin) public onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }
}
