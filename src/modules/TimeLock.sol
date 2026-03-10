// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimelockModule {

    uint256 public constant DELAY = 2 days;

    mapping(bytes32 => uint256) public eta;

    event Queued(bytes32 id,uint256 eta);
    event Executed(bytes32 id);

    function _queue(bytes32 id) internal {

        require(eta[id] == 0,"already queued");

        eta[id] = block.timestamp + DELAY;

        emit Queued(id,eta[id]);
    }

    function _validateExecution(bytes32 id) internal view {

        require(eta[id] != 0,"not queued");
        require(block.timestamp >= eta[id],"timelock");
    }
}