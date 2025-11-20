// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockPermissioned, Permission} from "cofhe-mock-contracts/Permissioned.sol";
import {ReputationEngine} from "../reputation/ReputationEngine.sol";
import {PredictionPool} from "../prediction/PredictionPool.sol";
import {IdentityGate} from "../identity/IdentityGate.sol";
import {InEuint64} from "@fhenixprotocol/cofhe-contracts/ICofhe.sol";

/// @title CipherCommonsRegistry
/// @notice Central broker that applies permission checks before sharing encrypted state.
contract CipherCommonsRegistry is MockPermissioned, Ownable {
    ReputationEngine public reputation;
    PredictionPool public predictionPool;
    IdentityGate public identity;

    event ComponentsUpdated(address indexed reputation, address indexed predictionPool, address indexed identity);

    constructor(ReputationEngine reputation_, PredictionPool predictionPool_, IdentityGate identity_)
        Ownable(msg.sender)
    {
        reputation = reputation_;
        predictionPool = predictionPool_;
        identity = identity_;
    }

    /// @notice Update the component addresses. Owner must ensure invariants beforehand.
    function setComponents(ReputationEngine reputation_, PredictionPool predictionPool_, IdentityGate identity_)
        external
        onlyOwner
    {
        reputation = reputation_;
        predictionPool = predictionPool_;
        identity = identity_;

        emit ComponentsUpdated(address(reputation_), address(predictionPool_), address(identity_));
    }

    /// @notice Share an encrypted reputation score after verifying permissions.
    function fetchReputation(address account, Permission memory permission)
        external
        withPermission(permission)
        returns (uint256)
    {
        require(permission.issuer == account, "Registry:issuer-mismatch");
        require(permission.recipient == address(0) || permission.recipient == msg.sender, "Registry:recipient-mismatch");

        return reputation.shareScore(account, msg.sender);
    }

    /// @notice Evaluate whether an account meets an encrypted capability threshold.
    function capabilityAttestation(address account, InEuint64 memory threshold, Permission memory permission)
        external
        withPermission(permission)
        returns (uint256 scorePointer, uint256 attestationPointer)
    {
        require(permission.issuer == account, "Registry:issuer-mismatch");
        require(permission.recipient == address(0) || permission.recipient == msg.sender, "Registry:recipient-mismatch");

        return reputation.evaluateCapability(account, threshold, msg.sender);
    }

    /// @notice Surface lightweight identity verification status.
    function isVerified(address account) external view returns (bool) {
        return identity.isVerified(account);
    }
}

