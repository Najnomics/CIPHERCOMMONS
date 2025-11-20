// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {CoFheTest} from "cofhe-mock-contracts/CoFheTest.sol";
import {CipherCommonsRegistry} from "../src/registry/CipherCommonsRegistry.sol";
import {ReputationEngine} from "../src/reputation/ReputationEngine.sol";
import {PredictionPool} from "../src/prediction/PredictionPool.sol";
import {IdentityGate} from "../src/identity/IdentityGate.sol";
import {Permission, PermissionUtils} from "cofhe-mock-contracts/Permissioned.sol";
import {InEuint64} from "@fhenixprotocol/cofhe-contracts/ICofhe.sol";

contract CipherCommonsRegistryTest is CoFheTest {
    ReputationEngine private reputation;
    IdentityGate private identity;
    PredictionPool private pool;
    CipherCommonsRegistry private registry;

    uint256 private constant USER_KEY = 0xA11C3;
    uint256 private constant AGGREGATOR_KEY = 0xBEEF;

    address private user;
    address private aggregator;

    function setUp() public {
        reputation = new ReputationEngine();
        identity = new IdentityGate();
        pool = new PredictionPool(identity);
        registry = new CipherCommonsRegistry(reputation, pool, identity);

        reputation.setRegistry(address(registry));
        identity.setCoordinator(address(pool), true);

        user = vm.addr(USER_KEY);
        aggregator = vm.addr(AGGREGATOR_KEY);
    }

    function testFetchReputationWithPermission() public {
        InEuint64 memory score = createInEuint64(55, user);
        vm.prank(user);
        reputation.submitBadge(keccak256("sismo"), score);

        Permission memory permission = createPermissionShared(user, aggregator);
        bytes32 issuerStruct = PermissionUtils.issuerSharedHash(permission);
        permission.issuerSignature = signPermission(registry.hashTypedDataV4(issuerStruct), USER_KEY);

        bytes32 recipientStruct = PermissionUtils.recipientHash(permission);
        permission.recipientSignature = signPermission(registry.hashTypedDataV4(recipientStruct), AGGREGATOR_KEY);

        vm.prank(aggregator);
        uint256 pointer = registry.fetchReputation(user, permission);

        assertHashValue(pointer, 55);
    }

    function testCapabilityAttestationReturnsEncryptedResult() public {
        InEuint64 memory trust = createInEuint64(30, user);
        vm.prank(user);
        reputation.submitBadge(keccak256("brightid"), trust);

        Permission memory permission = createPermissionShared(user, aggregator);
        bytes32 issuerStruct = PermissionUtils.issuerSharedHash(permission);
        permission.issuerSignature = signPermission(registry.hashTypedDataV4(issuerStruct), USER_KEY);
        bytes32 recipientStruct = PermissionUtils.recipientHash(permission);
        permission.recipientSignature = signPermission(registry.hashTypedDataV4(recipientStruct), AGGREGATOR_KEY);

        InEuint64 memory passingThreshold = createInEuint64(25, address(registry));
        vm.prank(aggregator);
        (, uint256 attestationPointer) = registry.capabilityAttestation(user, passingThreshold, permission);

        assertHashValue(attestationPointer, 1);

        InEuint64 memory failingThreshold = createInEuint64(50, address(registry));
        vm.prank(aggregator);
        (, uint256 failedPointer) = registry.capabilityAttestation(user, failingThreshold, permission);

        assertHashValue(failedPointer, 0);
    }
}

