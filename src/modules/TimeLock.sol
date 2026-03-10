// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimelockModule {

    uint256 public constant DELAY = 2 days;

    mapping(bytes32 => uint256) public proposalOnQueue;

    event Queued(bytes32 id,uint256 eta);
    event Executed(bytes32 id);

    function _queue(bytes32 id) internal {

        require(proposalOnQueue[id] == 0,"already queued");

        proposalOnQueue[id] = block.timestamp + DELAY;

        emit Queued(id,proposalOnQueue[id]);
    }

    function _validateExecution(bytes32 id) internal view {

        require(proposalOnQueue[id] != 0,"not queued");
        require(block.timestamp >= proposalOnQueue[id],"timelock");
    }
}