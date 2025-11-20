// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {IdentityGate} from "../src/identity/IdentityGate.sol";

contract IdentityGateTest is Test {
    IdentityGate private gate;
    address private coordinator;

    function setUp() public {
        gate = new IdentityGate();
        coordinator = address(this);
        gate.setCoordinator(coordinator, true);
    }

    function testRegisterProofAndConsumeScope() public {
        address alice = makeAddr("alice");
        bytes32 proof = keccak256("alice-proof");
        bytes32 scope = keccak256("market-1");

        vm.prank(alice);
        gate.registerProof(proof);
        assertTrue(gate.isVerified(alice));

        gate.consumeScope(alice, scope);
        assertTrue(gate.hasConsumed(scope, alice));

        vm.expectRevert("IdentityGate:scope-used");
        gate.consumeScope(alice, scope);
    }

    function testRegisteringSameProofFails() public {
        address alice = makeAddr("alice");
        bytes32 proof = keccak256("proof");

        vm.prank(alice);
        gate.registerProof(proof);

        vm.prank(alice);
        vm.expectRevert("IdentityGate:proof-used");
        gate.registerProof(proof);
    }
}

