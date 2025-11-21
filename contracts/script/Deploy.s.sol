// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {IdentityGate} from "../src/identity/IdentityGate.sol";
import {PredictionPool} from "../src/prediction/PredictionPool.sol";
import {ReputationEngine} from "../src/reputation/ReputationEngine.sol";
import {CipherCommonsRegistry} from "../src/registry/CipherCommonsRegistry.sol";

/// @notice Deploys the core CipherCommons stack and wires dependencies.
contract DeployScript is Script {
    struct Deployment {
        IdentityGate identity;
        PredictionPool pool;
        ReputationEngine reputation;
        CipherCommonsRegistry registry;
    }

    function run() public returns (Deployment memory deployment) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        IdentityGate identity = new IdentityGate();
        PredictionPool pool = new PredictionPool(identity);
        ReputationEngine reputation = new ReputationEngine();
        CipherCommonsRegistry registry = new CipherCommonsRegistry(reputation, pool, identity);

        reputation.setRegistry(address(registry));
        identity.setCoordinator(address(pool), true);

        vm.stopBroadcast();

        console2.log("IdentityGate:", address(identity));
        console2.log("PredictionPool:", address(pool));
        console2.log("ReputationEngine:", address(reputation));
        console2.log("CipherCommonsRegistry:", address(registry));
        console2.log("Configured by deployer:", deployer);

        deployment = Deployment({identity: identity, pool: pool, reputation: reputation, registry: registry});
    }
}
