// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IVotingEscrow.sol";
import "../Epoch.sol";

/**
 * @title Airdrop Contract
 * @dev A contract for distributing tokens through an airdrop mechanism.
 */
contract Airdrop {
    using SafeERC20 for ERC20Burnable;

    uint256 public constant LOCK_PERIOD = 2 * 365 * 86400;
    uint256 public constant START_TIME = 1686268800; // 6/9/23
    uint256 public constant END_TIME = START_TIME + 2 * EPOCH_DURATION;

    address public immutable owner;

    mapping(address => uint256) private _claimable; // Amount claimable by each address
    mapping(address => address) private _creatorOf; // Addresses of contract creators

    ERC20Burnable private token;
    IVotingEscrow private ve;

    uint256 public unclaimed;

    event Claimed(address indexed claimer, address indexed onBehalf, uint256 amount);

    constructor(address _token, address _ve) {
        owner = msg.sender;
        token = ERC20Burnable(_token);
        ve = IVotingEscrow(_ve);
    }

    /**
     * @dev Initializes the mappings `_claimable` and `_creatorOf`.
     * @notice This function is called by the contract owner to initialize the contract with data.
     * @param data The initialization data encoded as a bytes array.
     * @dev The data is parsed and stored in the contract's storage using inline assembly to significantly reduce gas costs.
     */
    function init(bytes calldata data) external {
        require(msg.sender == owner, "callable only by owner");
        uint256 len = data.length;
        require(len % 52 == 0, "invalid data length");

        assembly {
            let ptr := 0x44 // Skip function selector, the offset and the length field in calldata
            let end := add(ptr, len)

            for {

            } lt(ptr, end) {

            } {
                let slot := calldataload(ptr)
                let value := shr(96, calldataload(add(ptr, 0x20)))
                sstore(slot, value)
                ptr := add(ptr, 0x34) // move to the next tuple
            }
        }
    }

    /**
     * @dev Funds the contract with the specified amount of tokens.
     * @param amount The amount of tokens to fund.
     * @notice This function can only be called by the contract owner.
     * @notice The tokens are transferred from the owner's address to the contract address.
     * @notice The approved amount of tokens for voting escrow is increased.
     */
    function fund(uint256 amount) external {
        require(msg.sender == owner, "callable only by owner");
        require(block.timestamp < END_TIME, "Airdrop period is over");
        token.safeTransferFrom(msg.sender, address(this), amount);
        unclaimed += amount;
        token.approve(address(ve), unclaimed);
    }

    /**
     * @dev Shuts down the airdrop and burns any remaining unclaimed tokens.
     * @notice This function can only be called by the contract owner.
     * @notice The function can only be called after the end time of the airdrop.
     * @notice All unclaimed tokens are burned and the approval for voting escrow is reset.
     */
    function shutdown() external {
        require(msg.sender == owner, "callable only by owner");
        require(block.timestamp >= END_TIME, "Airdrop period is not over");
        uint256 burnAmount = unclaimed;
        require(burnAmount > 0, "nothing to burn");
        unclaimed = 0;
        token.approve(address(ve), 0);
        token.burn(burnAmount);
    }

    /**
     * @dev Returns the amount of tokens claimable by the specified account.
     * @param account The account to check for claimable tokens.
     * @return amount The amount of tokens claimable.
     */
    function claimable(address account) public view returns (uint256 amount) {
        if (_isActive()) {
            amount = _claimable[account];
            if (amount > unclaimed) {
                amount = unclaimed;
            }
        }
    }

    /**
     * @dev Allows an account to claim their tokens.
     *
     * The tokens will be locked in the voting escrow for the specified lock period.
     *
     * @notice The caller must have claimable tokens.
     * @notice The tokens are locked in the voting escrow contract and ownership is transferred to the claimer.
     */
    function claim() external {
        uint256 claimableAmount = claimable(msg.sender);
        require(claimableAmount > 0, "nothing to claim");
        delete _claimable[msg.sender];
        emit Claimed(msg.sender, msg.sender, claimableAmount);
        _lockAndSend(claimableAmount, msg.sender);
    }

    /**
     * @dev Allows the creator of an account (contract) to claim tokens on behalf of that account.
     *
     * The tokens will be locked in the voting escrow for the specified lock period.
     *
     * @param account The account to claim tokens on behalf of.
     * @notice The caller must be the creator of the specified account.
     * @notice The tokens are locked in the voting escrow contract and ownership is transferred to the claimer.
     */
    function claimOnBehalf(address account) external {
        uint256 claimableAmount = claimable(account);
        require(claimableAmount > 0, "nothing to claim");
        address creator = _creatorOf[account];
        require(msg.sender == creator, "not allowed");
        delete _claimable[account];
        delete _creatorOf[account];
        emit Claimed(msg.sender, account, claimableAmount);
        _lockAndSend(claimableAmount, msg.sender);
    }

    /**
     * @dev Locks the specified amount of tokens in the voting escrow and sends them to the specified address.
     * @param amount The amount of tokens to lock and send.
     * @param to The address to send the locked tokens to.
     * @notice The specified amount of tokens is subtracted from the unclaimed token balance.
     * @notice A new lock is created in the voting escrow contract with the specified amount, lock period, and receiver address.
     */
    function _lockAndSend(uint256 amount, address to) internal {
        unclaimed -= amount;
        uint256 tokenId = ve.create_lock_for(amount, LOCK_PERIOD, to);
        require(tokenId != 0 && ve.ownerOf(tokenId) == to, "minting failed");
    }

    /**
     * @dev Checks if the airdrop is currently active.
     * @return A boolean indicating whether the airdrop is active.
     * @notice The airdrop is active if the current timestamp is within the start and end time of the airdrop.
     */
    function _isActive() internal view returns (bool) {
        return block.timestamp >= START_TIME && block.timestamp < END_TIME;
    }
}
