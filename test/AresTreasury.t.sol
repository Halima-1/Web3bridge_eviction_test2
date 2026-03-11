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

        (, , , , , , bool executed, ) = treasury.proposals(id);
        assertTrue(executed);
    }

    function testCancelSuccessfully() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        vm.prank(governor);
        treasury.cancel(id);

        (, , , , , , , bool cancelled) = treasury.proposals(id);
        assertTrue(cancelled);
    }

    function testExecuteTransfersValue() public {
        address payable receiver = payable(makeAddr("receiver"));
        uint256 initialBal = receiver.balance;

        vm.prank(governor);
        bytes32 id = treasury.propose(receiver, 1 ether, "");

        vm.prank(governor);
        treasury.queue(id);

        vm.warp(block.timestamp + 2 days);

        bytes32 digest = _getDigest(id, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(governor);
        treasury.execute(id, sig);

        assertEq(receiver.balance, initialBal + 1 ether);
    }

    function testRewardClaim() public {
        // setup merkle root with a real 2-leaf tree
        (bytes32 root, bytes32[] memory proof1, ) = _generateMerkleTree(user1, 1 ether, user2, 2 ether);
        
        vm.prank(governor);
        treasury.updateMerkleRoot(root);

        vm.prank(user1);
        treasury.claim(1 ether, proof1);

        assertTrue(treasury.claimed(user1));
    }

    function testMultipleSuccessfulClaims() public {
        (bytes32 root, bytes32[] memory proof1, bytes32[] memory proof2) = _generateMerkleTree(user1, 1 ether, user2, 2 ether);
        
        vm.prank(governor);
        treasury.updateMerkleRoot(root);

        uint256 bal1 = user1.balance;
        uint256 bal2 = user2.balance;

        vm.prank(user1);
        treasury.claim(1 ether, proof1);

        vm.prank(user2);
        treasury.claim(2 ether, proof2);

        assertTrue(treasury.claimed(user1));
        assertTrue(treasury.claimed(user2));
        assertEq(user1.balance, bal1 + 1 ether);
        assertEq(user2.balance, bal2 + 2 ether);
    }

    function testDoubleClaimReverts() public {
        (bytes32 root, bytes32[] memory proof1, ) = _generateMerkleTree(user1, 1 ether, user2, 2 ether);
        
        vm.prank(governor);
        treasury.updateMerkleRoot(root);

        vm.prank(user1);
        treasury.claim(1 ether, proof1);

        vm.prank(user1);
        vm.expectRevert("already claimed");
        treasury.claim(1 ether, proof1);
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
    function testProposeMaxLimit() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 100 ether, "");
        (, , uint256 value, , , , , ) = treasury.proposals(id);
        assertEq(value, 100 ether);
    }

    function testProposeValueExceedsLimitReverts() public {
        vm.prank(governor);
        vm.expectRevert();
        treasury.propose(address(this), 101 ether, "");
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

    function testQueueSetsEtaCorrectly() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");

        uint256 expectedEta = block.timestamp + 2 days;
        vm.prank(governor);
        treasury.queue(id);

        assertEq(treasury.eta(id), expectedEta);
    }

    function testMultipleProposalsConcurrently() public {
        vm.prank(governor);
        bytes32 id1 = treasury.propose(address(this), 1 ether, "");
        vm.prank(governor);
        bytes32 id2 = treasury.propose(address(this), 2 ether, "");

        vm.prank(governor);
        treasury.queue(id1);
        vm.prank(governor);
        treasury.queue(id2);

        vm.warp(block.timestamp + 2 days);

        bytes32 digest1 = _getDigest(id1, 0);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(governorPk, digest1);
        vm.prank(governor);
        treasury.execute(id1, abi.encodePacked(r1, s1, v1));

        bytes32 digest2 = _getDigest(id2, 1);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(governorPk, digest2);
        vm.prank(governor);
        treasury.execute(id2, abi.encodePacked(r2, s2, v2));

        (, , , , , , bool executed1, ) = treasury.proposals(id1);
        (, , , , , , bool executed2, ) = treasury.proposals(id2);
        assertTrue(executed1);
        assertTrue(executed2);
    }

    // function testExecuteAlreadyExecutedReverts() public {
    //     vm.prank(governor);
    //     bytes32 id = treasury.propose(address(this), 1 ether, "");

    //     vm.prank(governor);
    //     treasury.queue(id);
        
    //     vm.warp(block.timestamp + 2 days);

    //     bytes32 digest = _getDigest(id, 0);
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
    //     bytes memory sig = abi.encodePacked(r, s, v);

    //     vm.prank(governor);
    //     treasury.execute(id, sig);

    //     // Try again
    //     vm.prank(governor);
    //     vm.expectRevert();
    //     treasury.execute(id, sig);
    // }


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

    function testQueueAlreadyQueuedReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");
        
        vm.prank(governor);
        treasury.queue(id);

        vm.prank(governor);
        vm.expectRevert("queued");
        treasury.queue(id);
    }

    function testClaimTransferFails() public {
        RevertingClaimer claimer = new RevertingClaimer(treasury);
        // Fund the treasury so it can pay
        vm.deal(address(treasury), 1 ether);

        bytes32 root = keccak256(abi.encode(address(claimer), 1 ether));
        vm.prank(governor);
        treasury.updateMerkleRoot(root);

        bytes32[] memory proof; 
        
        vm.expectRevert(AresTreasury.transaction_failed.selector);
        claimer.tryClaim();
    }

    function testExecuteInvalidSignatureLengthReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");
        vm.prank(governor);
        treasury.queue(id);
        vm.warp(block.timestamp + 2 days);

        bytes memory sig = new bytes(64); // Invalid length
        
        vm.expectRevert(abi.encodeWithSignature("InvalidSignature()"));
        treasury.execute(id, sig);
    }

    function testExecuteSignatureInvalidSReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");
        vm.prank(governor);
        treasury.queue(id);
        vm.warp(block.timestamp + 2 days);

        bytes32 digest = _getDigest(id, 0);
        (uint8 v, bytes32 r, ) = vm.sign(governorPk, digest);
        
        // Malleable S signature
        uint256 invalidS = 0x8000000000000000000000000000000000000000000000000000000000000000;
        bytes memory sig = abi.encodePacked(r, bytes32(invalidS), v);

        vm.expectRevert(abi.encodeWithSignature("InvalidSignature()"));
        treasury.execute(id, sig);
    }

    function testExecuteSignatureInvalidVReverts() public {
        vm.prank(governor);
        bytes32 id = treasury.propose(address(this), 1 ether, "");
        vm.prank(governor);
        treasury.queue(id);
        vm.warp(block.timestamp + 2 days);

        bytes32 digest = _getDigest(id, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
        v = 29; // Invalid V

        bytes memory sig = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSignature("InvalidSignature()"));
        treasury.execute(id, sig);
    }

    function testExecuteReentrancyFails() public {
        ReentrantTarget target = new ReentrantTarget(treasury);
        vm.prank(governor);
        bytes32 id = treasury.propose(address(target), 0, "");
        vm.prank(governor);
        treasury.queue(id);
        vm.warp(block.timestamp + 2 days);

        bytes32 digest = _getDigest(id, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorPk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        target.setParams(id, sig);

        vm.expectRevert(AresTreasury.transaction_failed.selector);
        treasury.execute(id, sig);
    }

    function testClaimReentrancyFails() public {
        ReentrantClaimer claimer = new ReentrantClaimer(treasury);
        (bytes32 root, bytes32[] memory proof1, ) = _generateMerkleTree(address(claimer), 1 ether, user2, 2 ether);
        
        vm.prank(governor);
        treasury.updateMerkleRoot(root);
        
        vm.expectRevert(AresTreasury.transaction_failed.selector);
        claimer.tryClaim(proof1);
    }

    function _generateMerkleTree(
        address account1, uint256 amount1, 
        address account2, uint256 amount2
    ) internal pure returns (bytes32 root, bytes32[] memory proof1, bytes32[] memory proof2) {
        bytes32 leaf1 = keccak256(abi.encode(account1, amount1));
        bytes32 leaf2 = keccak256(abi.encode(account2, amount2));
        
        root = leaf1 < leaf2 
            ? keccak256(abi.encodePacked(leaf1, leaf2)) 
            : keccak256(abi.encodePacked(leaf2, leaf1));
            
        proof1 = new bytes32[](1);
        proof1[0] = leaf2;
        
        proof2 = new bytes32[](1);
        proof2[0] = leaf1;
    }
}

contract RevertingClaimer {
    AresTreasury public treasury;

    constructor(AresTreasury _treasury) {
        treasury = _treasury;
    }

    function tryClaim() external {
        bytes32[] memory proof;
        treasury.claim(1 ether, proof);
    }

    receive() external payable {
        revert("I reject ETH");
    }
}

contract ReentrantTarget {
    AresTreasury public treasury;
    bytes32 public id;
    bytes public sig;

    constructor(AresTreasury _treasury) {
        treasury = _treasury;
    }

    function setParams(bytes32 _id, bytes memory _sig) external {
        id = _id;
        sig = _sig;
    }

    fallback() external payable {
        treasury.execute(id, sig);
    }
}

contract ReentrantClaimer {
    AresTreasury public treasury;
    bytes32[] public savedProof;

    constructor(AresTreasury _treasury) {
        treasury = _treasury;
    }

    function tryClaim(bytes32[] memory proof) external {
        for (uint i = 0; i < proof.length; i++) {
            savedProof.push(proof[i]);
        }
        treasury.claim(1 ether, proof);
    }

    receive() external payable {
        bytes32[] memory memProof = new bytes32[](savedProof.length);
        for (uint i = 0; i < savedProof.length; i++) {
            memProof[i] = savedProof[i];
        }
        treasury.claim(1 ether, memProof);
    }
}