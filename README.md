# CipherCommons – Private Reputation & Prediction Playground

**Track:** Creative Privacy Applications ($3,000)  
**Hackathon:** Zypherpunk – Zcash Privacy Hackathon  
**Stack:** Fhenix CoFHE, Zcash shielded pools, Sismo badges, Next.js + wagmi

---

## Concept

CipherCommons experiments with composable privacy by blending encrypted reputation, prediction markets, and sybil resistance. Participants stake privately, vote on encrypted outcomes, and build on-chain reputations without revealing addresses or wager sizes.

---

## Modules

1. **Encrypted Reputation Scores**
   - Users mint zk badges (Sismo) proving domain expertise.
   - CoFHE aggregates badge weights into private reputation vectors.
   - Dapps request “capability attestations” instead of raw scores.

2. **Private Prediction Pools**
   - Markets accept shielded ZEC stakes bridged through Fhenix.
   - Outcome votes submitted as encrypted ballots.
   - Settlement decrypts final tallies only; per-user stakes remain hidden.
   - ReputationGatekeeper contracts enforce that only cleared accounts can stake in a given market scope.

3. **Sybil-Resistant Identity**
   - Uses Proof-of-Personhood ceremonies (Gitcoin Passport, BrightID).
   - Attestations converted into FHE verifiers to limit multiple entries.

4. **Composable APIs**
   - `CipherCommonsRegistry.sol` exposes attestations for other apps (e.g., learning platforms, DAO governance).
   - Consumer SDK simplifies verifying encrypted reputations on the client.

---

## Architecture Overview

```
User Wallet (Zcash Shielded)
  ├─ zk badge claims (Sismo, Gitcoin Passport)
  ├─ Encrypts stakes & votes with Fhenix SDK
  └─ Interacts via Next.js interface

CipherCommons Contracts (Fhenix)
  ├─ ReputationEngine.sol – maintains encrypted reputation vectors
  ├─ PredictionPool.sol – handles shielded staking & payouts
  ├─ IdentityGate.sol – enforces sybil limits via FHE attestations
  └─ ReputationGatekeeper.sol – off-chain attestors flip capability scopes for eligible accounts

Off-chain Services
  ├─ Snapshot adapter converts DAO proposals into encrypted ballots
  └─ Oracle relays final real-world outcomes (Chainlink, UMA)
```

---

## Smart Contract Highlights

```solidity
// Register reputation proof
function submitBadge(
    bytes32 badgeId,
    inEuint256 calldata encryptedWeight
) external;

// Create encrypted prediction market
function createMarket(
    bytes32 topic,
    uint256 deadline,
    inEuint256 calldata encryptedMinStake,
    uint16 minParticipants,
    uint8 rangeBucketPercent
) external;

// Place encrypted stake
function stake(
    bytes32 marketId,
    inEuint256 calldata encryptedAmount,
    bytes calldata encryptedVote
) external;

// Settle market (decrypt aggregate only)
function settle(bytes32 marketId, bytes calldata outcomeProof) external;
```

Privacy controls:

- Minimum participant thresholds before any market reveals aggregate amounts.
- Optional “range reveal” mode that discloses only buckets (e.g., 60–70% YES).
- Sybil gating ensures each verified human can place at most one encrypted stake per market.

---

## Example Use Cases

- **DAO Reputation** – allocate voting power based on encrypted activity scores.
- **Research Pools** – run private bounty forecasts where panelists stay anonymous.
- **Content Moderation** – gate community features based on trust scores without exposing them publicly.

---

## Build & Run

```bash
# Contracts
cd contracts
forge install              # only required once to pull deps
forge build
forge test

# Web dapp
cd apps/ciphercommons
pnpm install
pnpm build                 # optional production bundle
pnpm dev                   # start the Next.js dev server
```

Contracts can also be compiled from the repo root now that a top-level `foundry.toml` mirrors the `contracts/` configuration. If you hit missing OpenZeppelin imports, double-check that you are running `forge` from the repo or `contracts/` directory so the remappings resolve correctly.

### Deploy the stack

```
export FHENIX_RPC_URL=<https://rpc.fhenix.example>
export PRIVATE_KEY=<hex-private-key>
cd contracts
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $FHENIX_RPC_URL \
  --broadcast
```

The script deploys IdentityGate, PredictionPool, ReputationEngine, and CipherCommonsRegistry, wires the dependencies (coordinator + registry permissions), and logs the resulting addresses.

`.env` template:

```
FHENIX_RPC_URL=
CHAIN_ID=8008135
ZCASH_BRIDGE_URL=
SISMO_APP_ID=
UMA_API_KEY=
```

---

## Roadmap

1. **Hackathon Prototype**
   - Encrypted YES/NO market with 100-user cap.
   - Reputation-based market access control.
2. **Beta Q1 2026**
   - Multi-outcome markets, bonding curves, encrypted LP shares.
   - Partnerships with DAO tools (Snapshot, Tally).
3. **Full Launch Q2 2026**
   - Mobile-friendly interface.
   - Plugin architecture for third-party reputation sources.

---

**Goal:** Showcase how FHE unlocks playful, privacy-respecting social coordination primitives that Zcash alone could not deliver.***
