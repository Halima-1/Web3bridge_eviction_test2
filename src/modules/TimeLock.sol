// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLock {

    uint256 public constant DELAY = 2 days;

    mapping(bytes32 => uint256) public eta;

    event Queued(bytes32 id,uint256 eta);

    function _queue(bytes32 id) internal {

        require(eta[id] == 0,"queued");

        uint256 executionTime = block.timestamp + DELAY;

        eta[id] = executionTime;

        emit Queued(id,executionTime);
    }

    function _ready(bytes32 id) internal view {

        uint256 executionTime = eta[id];

        require(executionTime != 0,"not queued");

        require(block.timestamp >= executionTime,"delay active");
    }
}