// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IManagement {
    function isAuthorized(address account) external view returns (bool);
}
