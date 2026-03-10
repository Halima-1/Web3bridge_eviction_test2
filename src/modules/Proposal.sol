// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProposalModule {

    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes data;
        uint256 nonce;
        bool queued;
        bool executed;
        bool cancelled;
    }

    mapping(bytes32 => Proposal) public proposals;
    uint256 public proposalNonce;

    event ProposalCreated(bytes32 id,address proposer);
    event ProposalCancelled(bytes32 id);

    function _createProposal(
        address target,
        uint256 value,
        bytes memory data
    ) internal returns(bytes32 id){

        uint256 nonce = proposalNonce++;

        id = keccak256(
            abi.encode(msg.sender,target,value,data,nonce)
        );

        proposals[id] = Proposal(
            msg.sender,
            target,
            value,
            data,
            nonce,
            false,
            false,
            false
        );

        emit ProposalCreated(id,msg.sender);
    }

    function _cancelProposal(bytes32 id) internal {

        Proposal storage proposal = proposals[id];

        require(!proposal.executed,"executed");

        proposal.cancelled = true;

        emit ProposalCancelled(id);
    }
}