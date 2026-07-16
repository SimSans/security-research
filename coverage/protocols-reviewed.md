# Coverage — Protocols Reviewed

Protocols whose public / in-scope code I've **independently reviewed** as part of bug-bounty and audit-contest work — deep, multi-module analysis with custom fuzzing and fork-based testing. For most of these the verdict was a well-argued **clean** ("no critical issues"); a subset produced the findings in [findings/](../findings/).

**How to read this:** the *Program scope* column is the protocol's public maximum bounty — a proxy for the **size and caliber of the codebase I reviewed**, not a payout. "Reviewed — robust" means I ran the full workflow and the code held up; a clear clean verdict on code this size is a deliverable in its own right (it's what lets a team ship with confidence). "Latent risk documented" means clean of *exploitable* Critical/High, with a conditional risk noted for the team.

Honest framing: these are **independent** reviews of public bug-bounty / contest scope — not commissioned engagements. What they demonstrate is **range** (six+ ecosystems, every major DeFi primitive) and **volume of hard code read to a verdict**.

---

## Ethereum & EVM L2s (Solidity)

| Protocol | Type | Program scope | Verdict |
|---|---|---|---|
| Uniswap | AMM / UniswapX | $15.5M | Reviewed — robust (fresh in-scope clean) |
| Sky (ex-MakerDAO) | CDP stablecoin | $10M | Reviewed — robust |
| Stargate (LayerZero) | Cross-chain bridge / OFT | $10M | Reviewed — robust (credit conservation symmetric) |
| Reserve DTF | Index / folio protocol | $10M | Reviewed — robust |
| EulerSwap | AMM on Euler v2 | $7.5M | Reviewed — robust (curve-verify + EVC deferred health) |
| USDT0 (Tether) | OFT stablecoin | $6M | Reviewed — robust; latent migrate() gap noted |
| Spark | ALM / lending | $5M | Reviewed — robust (rate-limit bounded) |
| GMX | Perpetuals (V2) | $5M | Reviewed — robust (Multichain module) |
| Coinbase | On-chain core | $5M | Reviewed — robust (double-clean) |
| Chainlink | CCIP 2.0 cross-chain | $3M | Reviewed — robust (incl. fresh CCV layer) |
| Ethena | USDe synthetic dollar | $3M | Reviewed — robust (C4-hardened V2) |
| Optimism | OP Stack | $2M | Reviewed — robust |
| Lido V3 | Liquid staking (stVaults) | $2M | Reviewed — robust |
| Celer | cBridge messaging | $2M | Reviewed — robust |
| Compound | Lending (Comet III) | $1M | Reviewed — robust (liquidation canonical) |
| Immutable | zkEVM bridge | $1M | Reviewed — robust (dual source-validation) |
| 0x | Settler / swap router | $1M | Reviewed — robust (witness binds full actions) |
| Origin Protocol | Yield / staking | $1M | Reviewed — robust |
| Flying Tulip | DeFi (Sherlock BB) | $1M | Reviewed — robust (3 leads defended) |
| Beanstalk | Credit-based stablecoin | $1.1M | Reviewed — robust |
| Chronicle | Schnorr oracle | $400k | Reviewed — robust (9-workstream + 6.4M fuzz) |
| ether.fi | Cash / TopUp | $300k | Reviewed — robust |
| Alchemix | CDP (V3) | $300k | Reviewed — robust |
| BOB | Bitcoin↔ETH L2 | $250k | Reviewed — robust (2-pass; bridge deep-verified) |
| Tokemak | Auto-finance adapters | $250k | Reviewed — robust |
| Notional | Exponent leverage | $250k | Reviewed — robust; latent read-reentrancy noted |
| Avail | Ethereum bridge | $250k | Reviewed — robust (VectorX root + replay nullifier) |
| Rootstock | Flyover BTC↔RSK | $200k | Reviewed — robust |
| Valantis | STEX AMM | $200k | Reviewed — robust |
| Gearbox | Leverage (V3.1) | $200k | Reviewed — robust |
| Yearn | stYFI (Vyper) | $200k | Reviewed — robust (donation-immune) |
| StakeWise | Liquid staking | $200k | Reviewed — robust |
| Ostium | RWA perps (Gains fork) | $200k | Reviewed — robust |
| Threshold | tBTC v2 | $150k | Reviewed — robust |
| Boba | OP-Stack fork | $100k | Reviewed — robust (scope-trap resolved) |
| Modular Account V2 | ERC-6900 (Alchemy) | $100k | Reviewed — robust (124 attacks / 6 surfaces) |
| Katana | Vault-bridge | $80k | Reviewed — robust |
| Twyne | Euler-v2 credit | $50k | Reviewed; margin-config lead defended |
| TermMax | Fixed-rate lending (V2) | $50k | Reviewed — robust; latent tail-risk noted |
| Celo | Fee-currency / op-geth | $25k | Reviewed — robust (conservation exact) |
| OpenZeppelin | uniswap-hooks | $25k | Reviewed; dedup-risky High logged |
| IPOR | IRS AMM | $20k | Reviewed — robust |
| Arcadia | Margin accounts | HackenProof | Reviewed — robust (post-hack rebuild) |
| PancakeSwap | Infinity CL + Bin | Remedy | Reviewed — robust |

## Move (Sui / Aptos)

| Protocol | Type | Program scope | Verdict |
|---|---|---|---|
| Aave V3 (Aptos) | Lending (faithful port) | $1M | Reviewed — robust |
| Bucket | Liquity CDP (Sui) | $500k | Reviewed — robust (oracle residual closed) |
| Cetus | Uni-V3 AMM (Sui) | $300k | Reviewed — robust (post-hack faithful port) |
| NAVI | Aave-v3 fork (Sui) | $300k | Reviewed — robust (11-audit fortress) |

## Solana (Rust)

| Protocol | Type | Program scope | Verdict |
|---|---|---|---|
| Raydium | CLMM | $505k | Reviewed — robust (fresh #178 + fuzz) |
| Lombard | LBTC | $250k | Reviewed — robust |
| KAST | M0 stablecoin | $50k | Reviewed — robust |
| Kamino | Lending / vaults | (hyper-audited) | Reviewed — robust |
| OnRe | Reinsurance | — | Reviewed — robust; latent Token-2022 gap noted |
| Agave (Anza) | Validator client | direct-core | Reviewed — robust (v4.1/4.2 diff) |

## Cosmos / Go

| Protocol | Type | Program scope | Verdict |
|---|---|---|---|
| dYdX v4 | Perpetuals DEX | $1M | **Finding** — [proposer-chosen counterparty](../findings/proposer-chosen-counterparty.md) |
| Injective | EVM-Cosmos L1 | $500k | **Finding** — EIP-214 STATICCALL / fee-payer replay (class-level) |
| Mezo (mezod) | BTC bridge | $500k | Reviewed — robust (double-supermajority attestation) |
| Mezo MUSD | BTC CDP (Liquity) | $500k | Reviewed — robust (solvency invariant) |
| Sei | Precompiles | $500k | Reviewed — robust (association unforgeable) |
| Cosmos SDK | Core module | direct-core | Reviewed |

## Clarity (Stacks)

| Protocol | Type | Program scope | Verdict |
|---|---|---|---|
| Hermetica | hBTC synthetic | $100k | Reviewed — robust (14M-op fuzz) |
| Granite | Lending | $100k | Reviewed; liquidation-at-zero-price latent (oracle-scoped) |
| Zest | Lending | $100k | Reviewed — robust (dual-valuation disproven by fuzz) |
| StackingDAO | Liquid staking | $100k | Reviewed — robust |

## L1 clients / core infrastructure (Go / Rust / ZK)

| Protocol | Type | Program scope | Verdict |
|---|---|---|---|
| Ethereum (Geth) | Execution client | $1M (EF) | Reviewed — robust (fresh diff) |
| reth | Execution client (Rust) | $1M (EF) | Reviewed — robust (release-vs-release diff) |
| Citrea | Bitcoin ZK-rollup | $250k | Reviewed — robust (system contracts + ZK core) |
| Push Chain | Universal L1 (Cosmos+EVM) | $75–100k | Reviewed — robust (17-agent gauntlet) |
| Chia | Consensus (Rust) | HackerOne | Reviewed (parse edge-case, by-design) |

---

## By the numbers

- **50+ protocols** reviewed end-to-end to a verdict.
- **6+ ecosystems / languages:** Solidity (EVM + all major L2s), Move (Sui / Aptos), Rust (Solana / reth / Chia), Go (Cosmos / Geth / Injective), Clarity (Stacks), Vyper, plus ZK-rollup system code.
- **Every major DeFi primitive:** lending, perps & RWA perps, CDP stablecoins, ERC-4626 / boring vaults, AMMs (CL + stable + ve(3,3)), liquid staking & restaking, cross-chain bridges & messaging (CCIP / LayerZero / OFT / native BTC bridges), account abstraction (ERC-4337 / ERC-6900).
- **Multi-million-dollar scopes** the norm, not the exception — $1M+ programs reviewed to a clean verdict repeatedly.

The point of this table isn't the clean verdicts individually — it's the **range and the volume of hard code read to a defensible conclusion.** That's the muscle an audit engagement actually needs.
