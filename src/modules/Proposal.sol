// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Proposal{
    struct TreasuryProposal {
    uint256 id;
    address proposer;
    uint256 snapshotBlock;
    uint256 voteStart;
    uint256 voteEnd;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    bool executed;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
}

}