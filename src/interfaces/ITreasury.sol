// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITreasury {
    function propose(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes32);

    function queueProposal(bytes32 proposalId) external;

    function executeProposal(bytes32 proposalId) external;

    function cancelProposal(bytes32 proposalId) external;
}