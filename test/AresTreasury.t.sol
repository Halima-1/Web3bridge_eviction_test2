// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/AresTreasury.sol";

contract AresTreasuryTest is Test {

    AresTreasury treasury;

    address gov = address(1);

    function setUp() public {

        vm.prank(gov);
        treasury = new AresTreasury(gov);

        vm.deal(address(treasury),100 ether);
    }

    function testProposalLifecycle() public {

        vm.prank(gov);

        bytes32 id = treasury.propose(
            address(2),
            1 ether,
            ""
        );

        vm.prank(gov);

        treasury.queue(id);

        vm.warp(block.timestamp + 2 days + 1);

        bytes memory sig = new bytes(65);

        vm.expectRevert();

        treasury.execute(id,sig);
    }

    function testClaim() public {

        bytes32 leaf =
            keccak256(abi.encode(address(this),1 ether));

        treasury._setRoot(leaf);

        bytes32;

        treasury.claim(1 ether,proof);
    }
}