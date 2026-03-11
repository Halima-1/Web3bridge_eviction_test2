// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAresTreasury {
    function propose(address target, uint256 value, bytes calldata data) external returns (bytes32);

    function queueProposal(bytes32 id) external;

    function executeProposal(bytes32 id, bytes calldata sig) external;

    function cancelProposal(bytes32 id) external;

    function claim(uint256 amount, bytes32[] calldata proof) external;
}
