// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITreasury {
    function propose(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes32);

    function queue(bytes32 proposalId) external;

    function execute(bytes32 proposalId) external;

    function cancel(bytes32 proposalId) external;
}