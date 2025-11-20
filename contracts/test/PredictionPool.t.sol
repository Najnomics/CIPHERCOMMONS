// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CoFheTest} from "cofhe-mock-contracts/CoFheTest.sol";
import {PredictionPool} from "../src/prediction/PredictionPool.sol";
import {IdentityGate} from "../src/identity/IdentityGate.sol";
import {InEuint128, InEbool} from "@fhenixprotocol/cofhe-contracts/ICofhe.sol";

contract PredictionPoolTest is CoFheTest {
    IdentityGate private gate;
    PredictionPool private pool;

    address private creator;
    address private alice;
    address private bob;

    function setUp() public {
        gate = new IdentityGate();
        pool = new PredictionPool(gate);
        gate.setCoordinator(address(pool), true);

        creator = makeAddr("creator");
        alice = vm.addr(0xA11CE);
        bob = vm.addr(0xB0B);

        vm.prank(alice);
        gate.registerProof(keccak256("alice-proof"));
        vm.prank(bob);
        gate.registerProof(keccak256("bob-proof"));

        assertTrue(gate.isVerified(alice));
        assertTrue(gate.isVerified(bob));
    }

    function testStakeAggregatesEncryptedVotes() public {
        bytes32 topic = keccak256("prediction:eth");
        bytes32 marketId;
        {
            InEuint128 memory minStake = createInEuint128(5, creator);
            vm.prank(creator);
            marketId = pool.createMarket(topic, block.timestamp + 3 days, minStake);
        }

        InEuint128 memory aliceStake = createInEuint128(12, alice);
        InEbool memory aliceVote = createInEbool(true, alice);
        vm.prank(alice);
        pool.stake(marketId, aliceStake, aliceVote);

        InEuint128 memory bobStake = createInEuint128(7, bob);
        InEbool memory bobVote = createInEbool(false, bob);
        vm.prank(bob);
        pool.stake(marketId, bobStake, bobVote);

        PredictionPool.MarketView memory marketData = pool.marketView(marketId);
        assertHashValue(marketData.totalStake, 19);
        assertHashValue(marketData.yesStake, 12);
        assertHashValue(marketData.noStake, 7);

        InEuint128 memory repeatStake = createInEuint128(1, alice);
        InEbool memory repeatVote = createInEbool(true, alice);
        vm.expectRevert("PredictionPool:repeat");
        vm.prank(alice);
        pool.stake(marketId, repeatStake, repeatVote);
    }

    function testSettlementDecryptsAggregates() public {
        bytes32 topic = keccak256("prediction:settle");
        InEuint128 memory minStake = createInEuint128(1, creator);
        vm.prank(creator);
        bytes32 marketId = pool.createMarket(topic, block.timestamp + 2 days, minStake);

        InEuint128 memory stake = createInEuint128(4, alice);
        InEbool memory voteYes = createInEbool(true, alice);
        vm.prank(alice);
        pool.stake(marketId, stake, voteYes);

        vm.warp(block.timestamp + 2 days);

        pool.settle(marketId, "ora");

        PredictionPool.MarketView memory settledData = pool.marketView(marketId);
        assertTrue(settledData.settled);
        assertHashValue(settledData.totalStake, 4);
        assertHashValue(settledData.yesStake, 4);
        assertHashValue(settledData.noStake, 0);
    }

    function testCannotSettleBeforeDeadline() public {
        bytes32 topic = keccak256("prediction:early");
        InEuint128 memory minStake = createInEuint128(1, creator);
        vm.prank(creator);
        bytes32 marketId = pool.createMarket(topic, block.timestamp + 1 days, minStake);

        vm.expectRevert("PredictionPool:open");
        pool.settle(marketId, "");
    }
}

