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
    }

    mapping(bytes32 => Proposal) public proposals;

    uint256 public proposalNonce;

    event Proposed(bytes32 id,address proposer);

    function _createProposal(
        address target,
        uint256 value,
        bytes memory data
    ) internal returns(bytes32 id) {

        proposalNonce++;

        id = keccak256(
            abi.encode(
                msg.sender,
                target,
                value,
                data,
                proposalNonce
            )
        );

        proposals[id] = Proposal({
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            nonce: proposalNonce,
            queued:false,
            executed:false
        });

        emit Proposed(id,msg.sender);
    }
}