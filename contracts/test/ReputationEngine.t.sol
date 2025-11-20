// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CoFheTest} from "cofhe-mock-contracts/CoFheTest.sol";
import {ReputationEngine} from "../src/reputation/ReputationEngine.sol";
import {InEuint64} from "@fhenixprotocol/cofhe-contracts/ICofhe.sol";

contract ReputationEngineTest is CoFheTest {
    ReputationEngine private engine;
    address private registry;

    address private alice;

    function setUp() public {
        engine = new ReputationEngine();
        registry = address(this);
        engine.setRegistry(registry);

        alice = makeAddr("alice");
    }

    function testSubmitBadgeAggregatesWeights() public {
        bytes32 badgeOne = keccak256("sismo");
        bytes32 badgeTwo = keccak256("gitcoin");

        InEuint64 memory weightOne = createInEuint64(15, alice);
        InEuint64 memory weightTwo = createInEuint64(20, alice);

        vm.prank(alice);
        engine.submitBadge(badgeOne, weightOne);
        vm.prank(alice);
        engine.submitBadge(badgeTwo, weightTwo);

        uint256 pointer = engine.scorePointer(alice);
        assertHashValue(pointer, 35);
    }

    function testSubmitBadgeRevertsWhenResubmitted() public {
        bytes32 badgeId = keccak256("exp");
        InEuint64 memory weight = createInEuint64(10, alice);

        vm.prank(alice);
        engine.submitBadge(badgeId, weight);

        vm.expectRevert("ReputationEngine:badge-used");
        vm.prank(alice);
        engine.submitBadge(badgeId, weight);
    }

    function testEvaluateCapabilityGrantsReaderAccess() public {
        bytes32 badgeId = keccak256("brightid");
        InEuint64 memory weight = createInEuint64(42, alice);

        vm.prank(alice);
        engine.submitBadge(badgeId, weight);

        address verifier = makeAddr("verifier");
        (uint256 scorePointer, uint256 attestPointer) =
            engine.evaluateCapability(alice, createInEuint64(40, address(this)), verifier);

        assertHashValue(scorePointer, 42);
        assertHashValue(attestPointer, 1);
    }
}

