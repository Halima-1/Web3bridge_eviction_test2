// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../modules/Proposal.sol";
import "../modules/TimeLock.sol";
import "../modules/AresRewards.sol";
import "../libraries/SignatureLibraries.sol";

contract AresTreasury is
    ProposalModule,
    TimeLock,
    AresRewards
{

 error  not_governor();
      error treasuryLimit_Exceeded();
      error Already_executed();
      error not_queued();
      error replay_Detected();
     error Invalid_signer();
     error execution_failed();
     
    using SignatureLibraries for bytes32;

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 constant EXEC_TYPEHASH =
        keccak256(
            "Execute(bytes32 proposal,uint256 nonce)"
        );

    mapping(address => bool) public governors;

    mapping(bytes32 => bool) public usedDigests;

    uint256 public treasuryLimit = 100 ether;

    bool internal locked;

    modifier nonReentrant(){
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    modifier onlyGovernor(){
        require(governors[msg.sender]);
        _;
    }

    constructor(){

        governors[msg.sender] = true;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                block.chainid,
                address(this)
            )
        );
    }

    function propose(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyGovernor returns(bytes32){

        require(value <= treasuryLimit);

        return _createProposal(target,value,data);
    }

    function queue(bytes32 id) external onlyGovernor {

        Proposal storage p = proposals[id];

        require(!p.cancelled);

        _queue(id);

        p.queued = true;
    }

    function execute(
        bytes32 id,
        bytes calldata sig
    ) external nonReentrant {

        Proposal storage p = proposals[id];

        require(p.queued);
        require(!p.executed);
        require(!p.cancelled);

        _ready(id);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        EXEC_TYPEHASH,
                        id,
                        p.nonce
                    )
                )
            )
        );

        require(!usedDigests[digest]);

        address signer = digest.recover(sig);

        require(governors[signer]);

        usedDigests[digest] = true;

        p.executed = true;

        (bool success,) =
            p.target.call{value:p.value}(p.data);

        require(success);
    }

    function cancel(bytes32 id)
        external
        onlyGovernor
    {
        _cancelProposal(id);
    }

    function claim(
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant {

        _claim(amount,proof);

       (bool success,) = payable(msg.sender).call{value:amount}("");
       require(success,"transfer failed");
    }

    function updateMerkleRoot(bytes32 root)
        external
        onlyGovernor
    {
        _updateRoot(root);
    }

    receive() external payable {}
}