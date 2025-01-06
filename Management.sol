// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IManagement.sol";  // Importing the interface

contract Management is IManagement {
    address public owner;
    mapping(address => bool) public authorizedAddresses;

    event AddressAuthorized(address indexed account);
    event AddressDeauthorized(address indexed account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Authorize an address (can only be done by the contract owner)
    function authorizeAddress(address account) public onlyOwner {
        authorizedAddresses[account] = true;
        emit AddressAuthorized(account);
    }

    // Deauthorize an address (can only be done by the contract owner)
    function deauthorizeAddress(address account) public onlyOwner {
        authorizedAddresses[account] = false;
        emit AddressDeauthorized(account);
    }

    // Check if an address is authorized
    function isAuthorized(address account) public view override returns (bool) {
        return authorizedAddresses[account];
    }
}
