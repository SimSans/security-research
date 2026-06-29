# Smart Contract Security Research — Portfolio

**Independent Web3 security researcher.** I hunt high-impact vulnerabilities in live DeFi protocols — the kind that lead to fund theft, protocol insolvency, and permanent freezes — and I prove them with runnable proof-of-concept exploits, not hand-waving.

**simsans** · [github.com/simsans](https://github.com/simsans) · simeon.petkov2110@gmail.com

---

## At a glance

- **30+ protocols reviewed** end-to-end across DeFi lending, perps, yield vaults, stablecoins, cross-chain bridges, and liquid staking — including flagship protocols securing hundreds of millions to billions in TVL.
- **Multiple verified and submitted findings up to Critical severity** — oracle manipulation, access-control gaps, cross-chain accounting drift, vault share-price manipulation, protocol insolvency.
- **Multi-ecosystem / multi-language:** Solidity (EVM), Rust (Solana / Cosmos / Substrate), Clarity (Stacks), Move, Vyper.
- **Every serious finding ships with a passing Foundry / fork PoC.** If I can't prove it, I don't claim it.

---

## Selected findings

> Presented by vulnerability class and protocol type. Specific protocol names are shared on request and only where responsible-disclosure timelines allow.

| Vulnerability class | Protocol type | Impact | Status |
|---|---|---|---|
| Missing access control on an oracle-report / task handler | Lending protocol (Chainlink CRE integration) | Unauthorized state updates → fund risk | **Verified** |
| Aave-integration interest accounting flaw | Lending protocol | Theft of accrued interest | **Verified** |
| Oracle feed omitting `min(market, canonical)` price | Liquity-V2 fork (LST collateral) | Collateral over-valuation → over-mint of stablecoin → insolvency / depeg | **PoC passing** |
| Migration-completion recognized via a forgeable public flag | Liquid-staking migration (L2) | Front-runnable strand of migrating funds (temporary freeze) | **Submitted** |
| Resume-on-frozen-oracle-price | Lending protocol | Protocol insolvency | **Submitted (2 passing PoCs)** |
| Vault share-price manipulation via stale vesting state | Yield vault (ERC-4626 / boring-vault) | Theft of unvested yield + DoS | **PoC passing** |
| Sandbox-validator bypass → RCE | OSS AI/ML codebase | Remote code execution (CVSS 9.8) | **Submitted** |

_Protocols tied to currently-undisclosed findings are named privately on request, and publicly once the finding is resolved and disclosed._

### Selected protocols reviewed

Independent security reviews / vulnerability assessments of major protocols, including:

**Optimism (OP Stack)** · **GMX** · **Ethena** · **Sky (MakerDAO)** · **Beanstalk** · **Olympus** · **0x** · **The Graph** · **Enzyme Finance** · **Gearbox** · **Kamino** · **Lombard** · **ether.fi** · **Compound** · **Chainlink**

These were deep reviews (multi-module analysis, custom fuzzing, fork-based testing) that confirmed the contracts were sound and documented latent risks. A clear, well-argued "no critical issues" verdict is a deliverable in its own right — it's what lets a team ship with confidence.

---

## Coverage & depth

**Protocol types:** DeFi lending (Compound/Aave forks), perpetuals & RWA perps, ERC-4626 / boring-vault yield vaults, CDP stablecoins, liquid staking, cross-chain bridges & messaging (CCIP / LayerZero / OFT), AMMs, restaking.

**Ecosystems:** Ethereum & L2s (Arbitrum, Optimism, Base, Ink), Solana, Cosmos, Polkadot/Substrate, Stacks (Clarity), Move chains.

**What I specialize in** — the bugs checklists and static tools *miss*:
- Economic-game / attacker-sequence exploits (flash-loan-funded, multi-step, cross-protocol composition).
- Cross-chain accounting drift and reconciliation desync.
- Oracle valuation gaps and share-price manipulation.
- Access-control and authorization seams across module boundaries.
- First-depositor / donation / rounding edge cases with real token-unit impact.

---

## Methodology

1. **Name the protocol's core promise** — the one invariant it exists to guarantee.
2. **Model the attacker's wishlist** — concrete fund-moving goals, not abstract "what-ifs."
3. **Enumerate the full toolset** — flash loans, the real deployed dependencies, MEV/ordering, and weird states (empty pool, first depositor, mid-migration, epoch boundaries).
4. **Hunt the sequence** that links a lever combination to a profitable outcome.
5. **Prove it on a mainnet fork** wired to the real deployed world — positive attacker P&L or it doesn't ship.

Every engagement ends with a clear written report: each finding gets severity, root cause, impact, a runnable PoC, and a concrete fix.

---

## Tooling

Foundry (forge / cast / anvil), Halmos (symbolic), fuzzing & invariant suites, mainnet-fork PoCs, Slither, plus hand-written exploit harnesses. Comfortable reading & writing Solidity, Rust, Clarity, Move, Vyper.

---

## Work with me

Independent audits, pre-launch security reviews, fork-based PoC development, and fix verification. Payment in USDC / ETH.

**Contact:** simeon.petkov2110@gmail.com · GitHub [@simsans](https://github.com/simsans)
