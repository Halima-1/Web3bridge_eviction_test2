// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/AresTreasury.sol";

contract AresTreasuryTest is Test {

    AresTreasury treasury;
    address governor;
    address user1;
    address user2;
    address attacker;

    function setUp() public {

        // deterministically create addresses
        governor = makeAddr("governor");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        attacker = makeAddr("attacker");

        treasury = new AresTreasury();

        // fund treasury for reward claims
        vm.deal(address(treasury), 100 ether);

        // mock governor role (assuming AresTreasury has addGovernor)
        treasury.addGovernor(governor);
    }

    ////////////////////////////
    // Functional Tests
    ////////////////////////////

    function testProposalLifecycle() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(governor);
        treasury.queue(id);

        vm.warp(block.timestamp + 2 days);

        bytes memory sig;
        vm.prank(governor);
        treasury.execute(id, sig);
    }

    function testRewardClaim() public {
        // setup merkle root
        bytes32 root = keccak256(abi.encode(user1, 1 ether));
        vm.prank(governor);
        treasury.updateMerkleRoot(root);

        bytes32[] memory proof;
        vm.prank(user1);
        treasury.claim(1 ether, proof);

        assertTrue(treasury.claimed(user1));
    }

    ////////////////////////////
    // Exploit / Negative Tests
    ////////////////////////////

    function testDoubleClaimReverts() public {
        bytes32 root = keccak256(abi.encode(user1, 1 ether));
        vm.prank(governor);
        treasury.updateMerkleRoot(root);

        bytes32[] memory proof;

        vm.prank(user1);
        treasury.claim(1 ether, proof);

        vm.prank(user1);
        vm.expectRevert();
        treasury.claim(1 ether, proof);
    }

    function testUnauthorizedExecutionFails() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");
        vm.prank(governor);
        treasury.queue(id);

        vm.warp(block.timestamp + 2 days);

        vm.prank(attacker);
        bytes memory sig;
        vm.expectRevert();
        treasury.execute(id, sig);
    }

    function testPrematureExecutionFails() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");
        vm.prank(governor);
        treasury.queue(id);

        bytes memory sig;
        vm.expectRevert();
        treasury.execute(id, sig);
    }
}