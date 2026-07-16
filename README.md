# Smart Contract Security Research

**Independent Web3 security researcher.** I hunt high-impact vulnerabilities in live DeFi protocols: the kind that lead to fund theft, protocol insolvency, and permanent freezes. I prove them with runnable proof-of-concept exploits, not hand-waving. When code is solid, I prove *that*, too.

**Simeon Petkov** · GitHub [@SimSans](https://github.com/SimSans) · simeon.petkov2110@gmail.com

---

## At a glance

- **[50+ protocols reviewed](coverage/protocols-reviewed.md)** end-to-end across DeFi lending, perps, yield vaults, CDP stablecoins, AMMs, cross-chain bridges, liquid staking, and account abstraction, including flagship scopes securing hundreds of millions to billions in TVL ($15.5M, $10M, $7.5M, $5M+ bounty programs).
- **[Verified findings up to Critical](findings/)**: oracle over-valuation → insolvency, permissionless zero-slippage sandwich, leveraged-vault collateral double-spend, Byzantine-proposer counterparty selection, vault share-price manipulation, EIP-214 STATICCALL violation. Every serious one ships with a passing PoC.
- **[Original vulnerability research](research/)**: two forward-invented attack primitives, each with a proof-of-concept: **[The Mirage](research/the-mirage.md)** (EIP-1153 transient-storage simulation divergence, 6 passing tests, held under coordinated disclosure) and **[GOLEM](research/golem-agent-hijack.md)** (on-chain data as prompt injection against AI agents).
- **Multi-ecosystem / multi-language:** Solidity (EVM + all major L2s), Rust (Solana / reth / Chia), Go (Cosmos / Geth / Injective), Move (Sui / Aptos), Clarity (Stacks), Vyper.
- **If I can't prove it, I don't claim it.** Every finding is backed by a PoC I ran myself.

---

## Navigate

| Section | What's in it |
|---|---|
| 🔬 **[Research](research/)** | Original attack primitives I invented + weaponized, each with a PoC. The Mirage · GOLEM. |
| 🎯 **[Findings](findings/)** | High-impact vulnerabilities in live/pre-launch protocols, by class (responsible-disclosure framing). |
| 🏆 **[Contest Reports](contest-reports/)** | Public, independently-verifiable competition submissions (Code4rena, etc.). |
| 🧭 **[Methodology](methodology/)** | How I work, the audit workflow, the hunt-the-diff thesis, multi-agent orchestration, verification discipline. |
| 📊 **[Coverage](coverage/protocols-reviewed.md)** | The full matrix of 50+ protocols reviewed, by ecosystem. |
| 🤝 **[Work With Me](services.md)** | Engagements, deliverables, and how to start. |

---

## Selected findings

> Presented by vulnerability class and protocol type. Most of these are or were **live**: in a private bounty program, in coordinated disclosure, or affecting funds with no public fix, so specific protocol names are shared privately on request, and published openly once resolved. The one named entry is an already-public duplicate. This is deliberate: publishing a weaponized write-up of a live-unfixed bug endangers users. See [findings/](findings/) for the full set.

| Vulnerability class | Protocol type | Impact | Proof |
|---|---|---|---|
| [Oracle omits `min(market, canonical)` on an LST collateral](findings/lst-oracle-missing-min.md) | Liquity-V2 CDP fork | Over-valuation → over-mint → insolvency / depeg | PoC passing |
| [Permissionless zero-slippage compound → atomic sandwich](findings/autocompounder-zero-slippage-sandwich.md) | ve(3,3) DEX | Theft of 88-96% of managed-veNFT yield | PoC passing (3/3) |
| [Leveraged-vault collateral double-spend](findings/leveraged-vault-shield-insolvency.md) | Leveraged LST vault | Real collateral withdrawn while shield stays committed → insolvency | Verified |
| [Byzantine proposer picks the deleveraging counterparty](findings/proposer-chosen-counterparty.md) | Cosmos perps DEX | Force-close a chosen solvent user at the bankruptcy price | Go chain-test passing (−$5,000) |
| Vault share-price manipulation via stale vesting state | ERC-4626 boring-vault | Theft of unvested yield + DoS | Fork PoC passing |
| [Forgeable migration-completion check](findings/polygon-spol-migration.md) | **Polygon**: sPOL migration | Front-runnable stranding of migrating stake | Disclosed (public / duplicate) |

---

## What I specialize in: the bugs checklists and scanners *miss*

- **Economic-game / attacker-sequence exploits**: flash-loan-funded, multi-step, cross-protocol composition, MEV/ordering.
- **Fork-regressions**: the guard a fork deleted, the collateral it mispriced, the integration it rewired. Nearly every bug I land is in the diff. ([Hunt the Diff](methodology/hunt-the-diff.md).)
- **Oracle valuation gaps** and vault share-price manipulation.
- **Access-control & authorization seams** across module boundaries and lifecycle/migration windows.
- **Cross-chain accounting drift** and reconciliation desync.

## Methodology in one line

> Name the promise the protocol exists to keep. Model the attacker's wishlist. Enumerate the real levers. Hunt the *sequence* that turns levers into profit. Prove it on a fork wired to the real world, positive attacker P&L or it doesn't ship.

Full detail in [methodology/](methodology/).

## Tooling

Foundry (forge / cast / anvil), Halmos (symbolic), fuzzing & invariant suites, mainnet-fork PoCs, Slither, plus hand-written exploit harnesses and multi-agent analysis pipelines. Comfortable reading and writing Solidity, Rust, Go, Clarity, Move, and Vyper.

---

## Work with me

Pre-launch reviews, focused audits, fork-based PoC development, fix verification. Payment in USDC / ETH. → **[services.md](services.md)**

**Early-stage and small teams especially welcome.** I like helping teams find and fix bugs *before* they ship, not just flagship protocols. Tell me what you're building and I'll work with your scope and your budget.

**Contact:** simeon.petkov2110@gmail.com · GitHub [@SimSans](https://github.com/SimSans)
