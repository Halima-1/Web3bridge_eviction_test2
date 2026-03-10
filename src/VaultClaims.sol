// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VaultTransactions.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract VaultClaims is VaultTransactions {

    event Claim(address indexed claimant, uint256 amount);
    event MerkleRootSet(bytes32 indexed newRoot);

    function setMerkleRoot(bytes32 root)
        external
        onlyOwner
    {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount)
        external
        whenNotPaused
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        bytes32 computed = MerkleProof.processProof(proof, leaf);

        require(computed == merkleRoot, "invalid proof");

        require(!claimed[msg.sender], "already claimed");

        claimed[msg.sender] = true;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, "transfer failed");

        totalVaultValue -= amount;

        emit Claim(msg.sender, amount);
    }
}