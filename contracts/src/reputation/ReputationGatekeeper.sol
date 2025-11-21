// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ReputationGatekeeper
/// @notice Simple allowlist contract that maps market scopes to eligible addresses.
/// @dev Off-chain attestors (e.g. capability aggregators) update eligibility after verifying encrypted scores.
contract ReputationGatekeeper is Ownable {
    event EligibilityUpdated(bytes32 indexed scope, address indexed account, bool allowed);

    mapping(bytes32 => mapping(address => bool)) private _eligible;

    constructor() Ownable(msg.sender) {}

    /// @notice Mark whether an account can join a given capability scope.
    function setEligibility(bytes32 scope, address account, bool allowed) public onlyOwner {
        require(scope != bytes32(0), "Gatekeeper:scope-zero");
        require(account != address(0), "Gatekeeper:account-zero");

        _eligible[scope][account] = allowed;
        emit EligibilityUpdated(scope, account, allowed);
    }

    /// @notice Batch update helper for off-chain attestors.
    function setEligibilityBatch(bytes32 scope, address[] calldata accounts, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            setEligibility(scope, accounts[i], allowed);
        }
    }

    /// @notice Returns whether an address has been cleared for the provided scope.
    function isEligible(bytes32 scope, address account) external view returns (bool) {
        return _eligible[scope][account];
    }
}
