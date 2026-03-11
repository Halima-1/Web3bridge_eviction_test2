// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CryptoLib} from "../libraries/CryptoLibraries.sol";

contract AresRewards {
    using CryptoLib for bytes32[];

    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;

    event Claimed(address user, uint256 amount);
    event RootUpdated(bytes32 newRoot);

    function _updateRoot(bytes32 root) internal {
        merkleRoot = root;
        emit RootUpdated(root);
    }

    function _claim(uint256 amount, bytes32[] memory proof) internal {
        require(!claimed[msg.sender], "already claimed");

        bytes32 leaf = keccak256(abi.encode(msg.sender, amount));

        require(proof.verify(merkleRoot, leaf), "invalid proof");

        claimed[msg.sender] = true;

        emit Claimed(msg.sender, amount);
    }
}
