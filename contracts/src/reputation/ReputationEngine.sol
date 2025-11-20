// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FHE, ebool, euint64, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title ReputationEngine
/// @notice Aggregates encrypted reputation weights submitted by participants via Fhenix CoFHE.
/// @dev All reputation math happens on encrypted values. The contract stores only ciphertext
///      pointers (hashes) provided by the FHE coprocessor. Consumers must request read access
///      through the configured registry which applies Permissioned checks before sharing values.
contract ReputationEngine is Ownable {
    event RegistryUpdated(address indexed registry);
    event BadgeSubmitted(address indexed account, bytes32 indexed badgeId, uint256 weightHash, uint256 newScoreHash);
    event CapabilityEvaluated(
        address indexed requester, address indexed account, uint256 thresholdHash, uint256 resultHash
    );

    /// @dev Mapping of participant -> aggregated encrypted reputation score.
    mapping(address => euint64) private _scores;

    /// @dev Tracks whether a user has already submitted a badge to avoid double counting.
    mapping(address => mapping(bytes32 => bool)) public badgeConsumed;

    /// @dev Address of the registry contract that is allowed to broker read access.
    address public registry;

    modifier onlyRegistry() {
        require(msg.sender == registry, "ReputationEngine:unauthorised");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @notice Configure the registry contract allowed to broker read access.
    /// @param registry_ Address of the registry contract.
    function setRegistry(address registry_) external onlyOwner {
        require(registry_ != address(0), "ReputationEngine:registry-zero");
        registry = registry_;
        emit RegistryUpdated(registry_);
    }

    /// @notice Submit an encrypted badge weight once per badge identifier.
    /// @param badgeId Unique identifier of the badge being submitted.
    /// @param encryptedWeight Encrypted weight created with the Fhenix SDK helpers.
    function submitBadge(bytes32 badgeId, InEuint64 memory encryptedWeight) external {
        require(!badgeConsumed[msg.sender][badgeId], "ReputationEngine:badge-used");

        euint64 weight = FHE.asEuint64(encryptedWeight);
        euint64 current = _scores[msg.sender];
        euint64 updated = FHE.add(current, weight);

        _scores[msg.sender] = updated;
        badgeConsumed[msg.sender][badgeId] = true;

        // Preserve usability for subsequent contract calls and the submitting account.
        FHE.allowThis(updated);
        FHE.allowSender(updated);

        emit BadgeSubmitted(msg.sender, badgeId, euint64.unwrap(weight), euint64.unwrap(updated));
    }

    /// @notice Return the ciphertext pointer representing the stored score.
    /// @dev Used by tests and off-chain services to reference the encrypted value.
    function scorePointer(address account) external view returns (uint256) {
        return euint64.unwrap(_scores[account]);
    }

    /// @notice Allow the registry to share an account's score with an authorised reader.
    /// @param account The subject whose score is requested.
    /// @param reader Address that should receive read permissions for the ciphertext.
    /// @return pointer The ciphertext pointer representing the subject's score.
    function shareScore(address account, address reader) external onlyRegistry returns (uint256 pointer) {
        euint64 score = _scores[account];
        pointer = euint64.unwrap(score);

        if (pointer != 0 && reader != address(0)) {
            FHE.allow(score, reader);
        }
    }

    /// @notice Evaluate whether a user meets an encrypted capability threshold.
    /// @param account Subject whose reputation should be compared.
    /// @param encryptedThreshold Encrypted threshold provided by the verifier.
    /// @param reader Address that should receive read permissions for the comparison result.
    /// @return scorePointer Ciphertext pointer for the subject's score.
    /// @return attestationPointer Ciphertext pointer for the boolean comparison (1 if >= threshold).
    function evaluateCapability(address account, InEuint64 memory encryptedThreshold, address reader)
        external
        onlyRegistry
        returns (uint256 scorePointer, uint256 attestationPointer)
    {
        euint64 score = _scores[account];
        euint64 threshold = FHE.asEuint64(encryptedThreshold);
        ebool passes = FHE.gte(score, threshold);

        // Allow follow-up programmatic use.
        FHE.allowThis(score);
        FHE.allowThis(threshold);

        if (reader != address(0)) {
            uint256 scoreHash = euint64.unwrap(score);
            if (scoreHash != 0) {
                FHE.allow(score, reader);
            }
            FHE.allow(passes, reader);
        }

        scorePointer = euint64.unwrap(score);
        attestationPointer = ebool.unwrap(passes);

        emit CapabilityEvaluated(reader, account, euint64.unwrap(threshold), attestationPointer);
    }
}

