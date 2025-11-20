// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title IdentityGate
/// @notice Tracks proof-of-personhood attestations and enforces single-participation rules per scope.
contract IdentityGate is Ownable {
    event ProofRegistered(address indexed account, bytes32 indexed proofId);
    event CoordinatorUpdated(address indexed coordinator, bool allowed);

    mapping(address => bool) private _verified;
    mapping(bytes32 => address) public proofOwner;
    mapping(bytes32 => mapping(address => bool)) private _scopeUsage;
    mapping(address => bool) public coordinator;

    constructor() Ownable(msg.sender) {}

    /// @notice Registers a proof-of-personhood or ceremony attestation.
    /// @param proofId Unique identifier representing the external verification proof.
    function registerProof(bytes32 proofId) external {
        require(proofId != bytes32(0), "IdentityGate:proof-zero");
        require(proofOwner[proofId] == address(0), "IdentityGate:proof-used");

        proofOwner[proofId] = msg.sender;
        _verified[msg.sender] = true;

        emit ProofRegistered(msg.sender, proofId);
    }

    /// @notice Returns whether an account has passed verification.
    function isVerified(address account) external view returns (bool) {
        return _verified[account];
    }

    /// @notice Authorise or revoke a coordinator that can consume scoped participation.
    function setCoordinator(address coordinator_, bool allowed) external onlyOwner {
        require(coordinator_ != address(0), "IdentityGate:coordinator-zero");
        coordinator[coordinator_] = allowed;
        emit CoordinatorUpdated(coordinator_, allowed);
    }

    /// @notice Consume a user's participation allowance for a given scope (e.g. market id).
    /// @dev Only authorised coordinators (prediction pools, gated dapps) may call this.
    function consumeScope(address account, bytes32 scope) external returns (bool) {
        require(coordinator[msg.sender], "IdentityGate:not-coordinator");
        require(_verified[account], "IdentityGate:not-verified");
        require(!_scopeUsage[scope][account], "IdentityGate:scope-used");

        _scopeUsage[scope][account] = true;
        return true;
    }

    /// @notice Check if an account has already used their participation allowance for a scope.
    function hasConsumed(bytes32 scope, address account) external view returns (bool) {
        return _scopeUsage[scope][account];
    }
}

