// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/AresTreasury.sol";

contract AresTreasuryTest is Test {

    AresTreasury treasury;
    address governor;
    uint256 governorPk;
    address user1;
    address user2;
    address attacker;
    uint256 attackerPk;

    function setUp() public {

        // deterministically create addresses
        (governor, governorPk) = makeAddrAndKey("governor");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        (attacker, attackerPk) = makeAddrAndKey("attacker");
        
        vm.prank(governor);
        treasury = new AresTreasury();

        // fund treasury for reward claimsc
        vm.deal(address(treasury), 100 ether);
    }

    receive() external payable {}


    function testProposalLifecycle() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(governor);
        treasury.queue(id);

        vm.warp(block.timestamp + 2 days);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                treasury.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Execute(bytes32 proposal,uint256 nonce)"),
                        id,
                        0 // nonce 0
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

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

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                treasury.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Execute(bytes32 proposal,uint256 nonce)"),
                        id,
                        0 // nonce 0
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(attackerPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(attacker);
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
    function testProposeNonGovernorReverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        treasury.propose(address(this), 1 ether, "");
    }

    function testProposeValueExceedsLimitReverts() public {
        vm.prank(governor);
        vm.expectRevert();
        treasury.propose(address(this), 101 ether, "");
    }

    function testQueueNonGovernorReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(attacker);
        vm.expectRevert();
        treasury.queue(id);
    }

    function testQueueCanceledProposalReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(governor);
        treasury.cancel(id);

        vm.prank(governor);
        vm.expectRevert();
        treasury.queue(id);
    }

    function testExecuteUnqueuedProposalReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        bytes32 digest = _getDigest(id, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(governor);
        vm.expectRevert();
        treasury.execute(id, sig);
    }

    function testExecuteCanceledProposalReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(governor);
        treasury.queue(id);
        
        vm.prank(governor);
        treasury.cancel(id);

        vm.warp(block.timestamp + 2 days);

        bytes32 digest = _getDigest(id, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(governor);
        vm.expectRevert();
        treasury.execute(id, sig);
    }

    function testExecuteAlreadyExecutedReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(governor);
        treasury.queue(id);
        
        vm.warp(block.timestamp + 2 days);

        bytes32 digest = _getDigest(id, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(governor);
        treasury.execute(id, sig);

        // Try again
        vm.prank(governor);
        vm.expectRevert();
        treasury.execute(id, sig);
    }

    function testCancelNonGovernorReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(attacker);
        vm.expectRevert();
        treasury.cancel(id);
    }

    function testUpdateMerkleRootNonGovernorReverts() public {
        bytes32 root = keccak256("newRoot");
        vm.prank(attacker);
        vm.expectRevert();
        treasury.updateMerkleRoot(root);
    }

    function testClaimInvalidProofReverts() public {
        bytes32 root = keccak256(abi.encode(user1, 1 ether));
        vm.prank(governor);
        treasury.updateMerkleRoot(root);

        bytes32[] memory proof; // empty proof

        vm.prank(user2); // user2 invalid
        vm.expectRevert();
        treasury.claim(1 ether, proof);
    }

    function _getDigest(bytes32 id, uint256 nonce) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                treasury.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Execute(bytes32 proposal,uint256 nonce)"),
                        id,
                        nonce
                    )
                )
            )
        );
    }
}