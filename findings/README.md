# Findings

High-impact vulnerabilities found in live and pre-launch DeFi protocols. Every serious finding ships with a runnable proof-of-concept, a passing Foundry / fork / chain test with positive attacker P&L, not a hand-waved "this looks risky."

## Responsible-disclosure posture

Most of these findings are, or were, **live**: submitted to a private bounty program, in coordinated disclosure with the team, or affecting funds with no public fix yet. Publishing a weaponized write-up of a live-unfixed bug endangers users and can violate program terms. So this section presents each finding **by vulnerability class and protocol type**, with the exploit pattern and the PoC *result*, but without the drop-in exploit against a named live target.

**Specific protocol names, full write-ups, and PoC sources are shared privately on request**, and published openly once the finding is resolved and disclosure timelines allow. The one named entry below is already public (an independently-confirmed duplicate).

## The matrix

| # | Vulnerability class | Protocol type | Impact | Proof | Status |
|---|---|---|---|---|---|
| 1 | [Oracle feed omits `min(market, canonical)` on an LST/LRT collateral](lst-oracle-missing-min.md) | Liquity-V2 CDP fork | Collateral over-valuation → over-mint → branch insolvency → stablecoin depeg | Foundry PoC passing (+15.8% over-valuation, $15k bad debt/100 units) | Verified · class-level |
| 2 | [Permissionless zero-slippage auto-compound → atomic sandwich](autocompounder-zero-slippage-sandwich.md) | ve(3,3) DEX (Velodrome fork) | Theft of 88-96% of managed-veNFT compound yield | Foundry PoC passing (3/3; fair 18,122 → sandwiched 2,142) | Disclosed to team · class-level |
| 3 | [Leveraged-vault collateral double-spend → insolvency](leveraged-vault-shield-insolvency.md) | Leveraged LST staking vault | Real collateral withdrawn while synthetic shield stays committed → unbacked liquidation | Hand-verified against real code paths | Verified · class-level |
| 4 | Untimed proportional withdrawal → accrued-interest theft | Leveraged LST staking vault | Flash-loan deposit→withdraw same block steals honest lenders' interest | Foundry PoC passing (attacker +9.9 = honest lender's full interest) | Verified · class-level |
| 5 | [Byzantine proposer picks the deleveraging counterparty](proposer-chosen-counterparty.md) | Cosmos perpetuals DEX | Force-closes a chosen solvent user's winning position at the bankruptcy price | Go chain-test passing (victim −$5,000, conservation holds) | PoC-proven · class-level |
| 6 | Vault share-price manipulation via stale vesting state | ERC-4626 boring-vault | Theft of unvested yield + DoS | Fork PoC passing (+3,571 USDC captured) | Submitted · class-level |
| 7 | Resume-on-frozen-oracle-price | CDP lending | Protocol insolvency on stale/frozen feed | 2 passing PoCs | Submitted · class-level |
| 8 | `STATICCALL` is not inert, stateful precompile mutates state under EIP-214 read-only context | EVM-compatible Cosmos L1 | Breaks a load-bearing EVM safety invariant (reentrancy guards, view checks) chain-wide | Reproduced on mainnet with two `eth_call`s | Reported · class-level |
| 9 | [Forgeable migration-completion check, front-runnable](polygon-spol-migration.md) | **Polygon**: sPOL staking migration (L2) | Front-runnable strand of a user's migrating stake (temporary freeze) | Reasoned + disclosed | **Public** (disclosed / duplicate) |

## What ties them together

Almost every one of these is a **fork-regression**: a protocol took mature, audited code (Liquity, Velodrome, Aave, an OP-stack precompile bridge) and *modified* it, and the bug lives in the diff. See [Hunt the Diff](../methodology/hunt-the-diff.md) for why that's where I aim, and [the coverage matrix](../coverage/protocols-reviewed.md) for the (larger) set of protocols where the diff held up and I returned a clean verdict.
