// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Interface for Management Authorization
interface IManagement {
    function isAuthorized(address account) external view returns (bool);
}

/// @title Enhanced ERC20 Token
/// @notice Implements a secure ERC20 token with added features for minting, burning, pausing, and robust validations.
contract EnhancedERC20 is ReentrancyGuard {
    // State Variables
    string public name;
    string public symbol;
    uint8 public constant decimals = 18; // 18 decimals for ERC20 standard
    uint256 public totalSupply;
    uint256 public immutable maxSupply;
    address public owner;
    IManagement public management;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    bool private pausedFlag; // Optimized: bool for paused state

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed recipient, uint256 amount, string transactionDetails);
    event Burn(address indexed account, uint256 amount, string transactionDetails);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event ManagementUpdated(address indexed previousManagement, address indexed newManagement);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can call this function");
        _;
    }

    modifier onlyAuthorized() {
        require(management.isAuthorized(msg.sender), "Access denied: Not an authorized address");
        _;
    }

    modifier whenNotPaused() {
        require(!pausedFlag, "Contract is paused");
        _;
    }

    /// @dev Constructor to initialize the contract
    /// @param _name Token name
    /// @param _symbol Token symbol
    /// @param _management Address of the management contract
    constructor(string memory _name, string memory _symbol, address _management) {
        require(_management != address(0), "Invalid management address");
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        maxSupply = 500_000 * 10**decimals; // Max supply: 500,000 tokens with decimals
        totalSupply = maxSupply;
        balances[msg.sender] = totalSupply;
        management = IManagement(_management);
    }

    /// @notice Transfer tokens to a recipient
    function transfer(address recipient, uint256 amount) external whenNotPaused returns (bool) {
        require(recipient != msg.sender, "Self-transfer not allowed");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Approve an address to spend tokens
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Transfer tokens from one address to another
    function transferFrom(address sender, address recipient, uint256 amount) external whenNotPaused returns (bool) {
        uint256 senderBalance = balances[sender];
        uint256 allowanceAmount = allowances[sender][msg.sender];

        require(senderBalance >= amount, "Insufficient balance");
        require(allowanceAmount >= amount, "Allowance exceeded");

        _transfer(sender, recipient, amount);
        allowances[sender][msg.sender] = allowanceAmount - amount;
        return true;
    }

    /// @notice Mint new tokens to a specified account
    function mint(address recipient, uint256 amount) external onlyAuthorized whenNotPaused nonReentrant {
        require(totalSupply + amount <= maxSupply, "Max supply exceeded");
        totalSupply += amount;
        balances[recipient] += amount;
        emit Mint(recipient, amount, "Tokens minted successfully");
        emit Transfer(address(0), recipient, amount);
    }

    /// @notice Burn tokens from the caller's account
    function burn(uint256 amount) external whenNotPaused nonReentrant {
        uint256 senderBalance = balances[msg.sender];
        require(senderBalance >= amount, "Insufficient balance");

        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount, "Tokens burnt successfully.");
        emit Transfer(msg.sender, address(0), amount);
    }

    /// @notice Pause the contract
    function pause() external onlyAuthorized whenNotPaused {
        pausedFlag = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpause the contract
    function unpause() external onlyAuthorized {
        require(pausedFlag, "Contract is not paused");
        pausedFlag = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Update the management contract address
    /// @param newManagement Address of the new management contract
    function updateManagement(address newManagement) external onlyOwner {
        require(newManagement != address(0), "Invalid new management address");
        emit ManagementUpdated(address(management), newManagement);
        management = IManagement(newManagement);
    }

    /// @notice Transfer ownership of the contract
    /// @param newOwner Address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice View the balance of an account
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /// @notice View the allowance for a spender
    function allowance(address ownerAddress, address spender) external view returns (uint256) {
        return allowances[ownerAddress][spender];
    }

    /// @notice Increase allowance for a spender
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /// @notice Decrease allowance for a spender
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        allowances[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /// @dev Internal function to transfer tokens
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero account");
        require(recipient != address(0), "ERC20: transfer to the zero account");
        require(amount > 0, "Zero tokens are not allowed");

        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}

