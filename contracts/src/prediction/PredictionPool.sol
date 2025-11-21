// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FHE, euint128, ebool, InEuint128, InEbool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {IdentityGate} from "../identity/IdentityGate.sol";

/// @title PredictionPool
/// @notice Privacy-preserving prediction markets that only expose encrypted aggregates.
contract PredictionPool {
    struct Market {
        address creator;
        bytes32 topic;
        uint256 deadline;
        euint128 minStake;
        euint128 totalStake;
        euint128 yesStake;
        euint128 noStake;
        uint16 participantCount;
        uint16 minParticipants;
        uint8 rangeBucketPercent;
        bool settled;
    }

    struct MarketView {
        address creator;
        bytes32 topic;
        uint256 deadline;
        uint256 minStake;
        uint256 totalStake;
        uint256 yesStake;
        uint256 noStake;
        uint16 participantCount;
        uint16 minParticipants;
        uint8 rangeBucketPercent;
        bool settled;
    }

    event MarketCreated(
        bytes32 indexed marketId, address indexed creator, bytes32 indexed topic, uint256 deadline, uint256 minStakeHash
    );
    event StakePlaced(bytes32 indexed marketId, address indexed account, uint256 amountHash, uint256 voteHash);
    event MarketSettled(
        bytes32 indexed marketId,
        bytes outcomeProof,
        uint256 totalStakeHash,
        uint256 yesStakeHash,
        uint256 noStakeHash,
        uint256 bucketPointer,
        bool rangeMode
    );

    IdentityGate public immutable IDENTITY_GATE;

    mapping(bytes32 => Market) private _markets;
    mapping(bytes32 => bool) private _marketExists;
    mapping(bytes32 => mapping(address => bool)) public hasStaked;

    uint16 public constant MAX_PARTICIPANTS = 100;

    constructor(IdentityGate identityGate_) {
        IDENTITY_GATE = identityGate_;
    }

    /// @notice Create a new encrypted prediction market.
    function createMarket(
        bytes32 topic,
        uint256 deadline,
        InEuint128 memory encryptedMinStake,
        uint16 minParticipants,
        uint8 rangeBucketPercent
    )
        external
        returns (bytes32 marketId)
    {
        require(deadline > block.timestamp, "PredictionPool:deadline");
        require(minParticipants <= MAX_PARTICIPANTS, "PredictionPool:threshold-high");
        if (rangeBucketPercent != 0) {
            require(rangeBucketPercent <= 50, "PredictionPool:bucket-large");
            require(100 % rangeBucketPercent == 0, "PredictionPool:bucket-mismatch");
        }

        marketId = keccak256(abi.encodePacked(msg.sender, topic, block.timestamp));
        require(!_marketExists[marketId], "PredictionPool:duplicate");

        euint128 minStake = FHE.asEuint128(encryptedMinStake);
        FHE.allowThis(minStake);

        _markets[marketId] = Market({
            creator: msg.sender,
            topic: topic,
            deadline: deadline,
            minStake: minStake,
            totalStake: FHE.asEuint128(0),
            yesStake: FHE.asEuint128(0),
            noStake: FHE.asEuint128(0),
            participantCount: 0,
            minParticipants: minParticipants,
            rangeBucketPercent: rangeBucketPercent,
            settled: false
        });
        _marketExists[marketId] = true;

        emit MarketCreated(marketId, msg.sender, topic, deadline, euint128.unwrap(minStake));
    }

    /// @notice Place an encrypted stake and vote on a market once per verified identity.
    function stake(bytes32 marketId, InEuint128 memory encryptedAmount, InEbool memory encryptedVote) external {
        Market storage market = _markets[marketId];
        require(_marketExists[marketId], "PredictionPool:missing");
        require(block.timestamp < market.deadline, "PredictionPool:closed");
        require(!market.settled, "PredictionPool:settled");
        require(!hasStaked[marketId][msg.sender], "PredictionPool:repeat");
        require(market.participantCount < MAX_PARTICIPANTS, "PredictionPool:cap");

        IDENTITY_GATE.consumeScope(msg.sender, _scopeKey(marketId));
        hasStaked[marketId][msg.sender] = true;
        market.participantCount += 1;

        euint128 amount = FHE.asEuint128(encryptedAmount);
        ebool vote = FHE.asEbool(encryptedVote);

        euint128 zero = FHE.asEuint128(0);
        euint128 yesContribution = FHE.select(vote, amount, zero);
        euint128 noContribution = FHE.select(vote, zero, amount);

        market.totalStake = FHE.add(market.totalStake, amount);
        market.yesStake = FHE.add(market.yesStake, yesContribution);
        market.noStake = FHE.add(market.noStake, noContribution);

        FHE.allowThis(market.totalStake);
        FHE.allowThis(market.yesStake);
        FHE.allowThis(market.noStake);
        FHE.allowSender(amount);

        emit StakePlaced(marketId, msg.sender, euint128.unwrap(amount), ebool.unwrap(vote));
    }

    /// @notice Trigger settlement by decrypting the encrypted aggregates.
    function settle(bytes32 marketId, bytes calldata outcomeProof) external {
        Market storage market = _markets[marketId];
        require(_marketExists[marketId], "PredictionPool:missing");
        require(block.timestamp >= market.deadline, "PredictionPool:open");
        require(!market.settled, "PredictionPool:settled");
        require(market.participantCount >= market.minParticipants, "PredictionPool:threshold");

        market.settled = true;

        FHE.allowSender(market.totalStake);
        FHE.allowSender(market.yesStake);
        FHE.allowSender(market.noStake);

        FHE.allow(market.totalStake, market.creator);
        FHE.allow(market.yesStake, market.creator);
        FHE.allow(market.noStake, market.creator);

        uint256 bucketPointer;
        if (market.rangeBucketPercent == 0) {
            FHE.decrypt(market.yesStake);
            FHE.decrypt(market.noStake);
        } else {
            bucketPointer = _rangePointer(market);
        }

        emit MarketSettled(
            marketId,
            outcomeProof,
            euint128.unwrap(market.totalStake),
            euint128.unwrap(market.yesStake),
            euint128.unwrap(market.noStake),
            bucketPointer,
            market.rangeBucketPercent != 0
        );
    }

    /// @notice Lightweight market view returning ciphertext pointers for encrypted values.
    function marketView(bytes32 marketId) external view returns (MarketView memory) {
        Market storage market = _markets[marketId];
        require(_marketExists[marketId], "PredictionPool:missing");

        return MarketView({
            creator: market.creator,
            topic: market.topic,
            deadline: market.deadline,
            minStake: euint128.unwrap(market.minStake),
            totalStake: euint128.unwrap(market.totalStake),
            yesStake: euint128.unwrap(market.yesStake),
            noStake: euint128.unwrap(market.noStake),
            participantCount: market.participantCount,
            minParticipants: market.minParticipants,
            rangeBucketPercent: market.rangeBucketPercent,
            settled: market.settled
        });
    }

    function _scopeKey(bytes32 marketId) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("ciphercommons:market", marketId));
    }

    /// @dev Returns the ciphertext pointer describing the ratio bucket when range reveal is enabled.
    function _rangePointer(Market storage market) private returns (uint256 pointer) {
        uint8 bucketSize = market.rangeBucketPercent;
        uint8 bucketCount = uint8(100 / bucketSize);

        euint128 hundred = FHE.asEuint128(100);
        euint128 scaledYes = FHE.mul(market.yesStake, hundred);
        euint128 bucketIndex = FHE.asEuint128(0);
        euint128 one = FHE.asEuint128(1);
        euint128 zero = FHE.asEuint128(0);

        for (uint8 i = 1; i <= bucketCount; i++) {
            uint8 boundary = bucketSize * i;
            euint128 rhs = FHE.mul(market.totalStake, FHE.asEuint128(boundary));
            ebool passed = FHE.gte(scaledYes, rhs);
            euint128 increment = FHE.select(passed, one, zero);
            bucketIndex = FHE.add(bucketIndex, increment);
        }

        FHE.allowThis(bucketIndex);
        FHE.decrypt(bucketIndex);
        pointer = euint128.unwrap(bucketIndex);
    }
}
