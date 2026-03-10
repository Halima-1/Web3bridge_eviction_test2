// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/cryptoLibraries.sol";

contract AresRewards {

    using CryptoLib for bytes32[];

    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;

    event Claimed(address user,uint256 amount);

    error AlreadyClaimed();
    error InvalidProof();

    function _setRoot(bytes32 root) internal {
        merkleRoot = root;
    }

    function claim(
        uint256 amount,
        bytes32[] calldata proof
    ) external {

        if(claimed[msg.sender]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(
            abi.encode(msg.sender,amount)
        );

        bool valid = proof.verify(merkleRoot,leaf);

        if(!valid) revert InvalidProof();

        claimed[msg.sender] = true;

        payable(msg.sender).transfer(amount);

        emit Claimed(msg.sender,amount);
    }
}