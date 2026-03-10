// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProposalModule} from "../modules/Proposal.sol";
import {TimelockModule} from "../modules/TimeLock.sol";
import {AresRewards} from "../modules/AresRewards.sol";
import {SigLib} from "../libraries/signatureLibraries.sol";

contract AresTreasury is ProposalModule,
       TimelockModule,
       AresRewards
       {


      error  not_governor();
      error treasuryLimit_Exceeded();
      error Already_executed();
      error not_queued();
      error replay_Detected();
      Invalid_signer();

    using SigLib for bytes32;

    mapping(address => bool) public governors;

    mapping(bytes32 => bool) public usedDigests;

    uint256 public treasuryLimit = 10 ether;

    event GovernorAdded(address gov);

    constructor(address _newgov) {
        governors[_newgov] = true;
    }

    modifier onlyGovernor() {
        require(governors[msg.sender], not_governor());
        _;
    }

    receive() external payable {}

    function proposeGovernor(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyGovernor returns(bytes32){

        require(value <= treasuryLimit, treasuryLimit_Exceeded());

        return _createProposal(target,value,data);
    }

    function queue(bytes32 id) external onlyGovernor {

        Proposal storage proposal = proposals[id];

        require(!proposal.executed, Already_executed());

        _queue(id);

        proposal.queued = true;
    }

    function executeProposal(
        bytes32 id,
        bytes calldata sig
    ) external {

        Proposal storage proposal = proposals[id];

        require(proposal.queued, not_queued());
        require(!proposal.executed, Already_executed());

        _validateExecution(id);

        bytes32 digest = keccak256(
            abi.encode(id,block.chainid)
        );

        require(!usedDigests[digest], replay_Detected());

        address signer = digest.recover(sig);

        require(governors[signer], Invalid_signer());

        usedDigests[digest] = true;

        proposal.executed = true;

        (bool success,) = proposal.target.call{value:proposal.value}(proposal.data);

        require(success,"exec fail");
    }
}