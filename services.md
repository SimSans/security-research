# Work With Me

Independent smart-contract security reviews. I hunt the high-impact bugs that drain protocols — and prove every one with a runnable exploit — then hand you the fix.

**Most "auditors" are developers who write contracts. I'm a security researcher who breaks them.**

## Engagements

- **Pre-launch security review** — a full manual audit of your protocol before you ship, with a written report and PoCs for every Critical/High.
- **Focused review** — a single contract, module, or a specific concern (a new integration, an oracle wiring, a migration path) reviewed deeply and fast.
- **Fork-based PoC development** — you have a suspected issue; I build the runnable exploit (or prove it isn't one) on a mainnet fork wired to your real dependencies.
- **Fix verification / re-audit** — you've patched a finding; I confirm the fix is complete and doesn't open a new seam.
- **Fresh-diff review for forks** — you forked a mature protocol; I audit the *diff* (where the bugs actually are — see [Hunt the Diff](methodology/hunt-the-diff.md)).

## What you receive

- A **line-by-line manual review** by a real researcher — not a scanner run with a logo on it.
- A **professional report**: every finding with severity (Critical / High / Medium / Low / Info), root cause, concrete impact, and a specific fix.
- **Runnable proof-of-concept exploit code** (Foundry / fork / chain test) for every Critical and High — so you can see the bug is real and confirm your patch closes it.
- Coverage of the bugs that actually move funds: oracle & price manipulation, access-control and authorization seams, accounting & rounding drift, first-depositor / donation edge cases, reentrancy, and **economic / flash-loan / MEV attack sequences** — the multi-step exploits checklists miss.

## Why me

- **Real track record:** verified and PoC-proven findings up to Critical across live and pre-launch protocols — see [findings/](findings/). Original vulnerability research (a novel EIP-1153 simulation-divergence primitive; on-chain prompt-injection against AI agents) — see [research/](research/).
- **Range:** [50+ protocols reviewed](coverage/protocols-reviewed.md) across Solidity, Move, Rust, Go, Clarity, and Vyper — lending, perps, CDP stablecoins, vaults, AMMs, bridges, restaking, account abstraction.
- **Honesty as a feature:** I prove what I claim and I calibrate severity straight. A clean report is a real result — if your code is solid, I'll show you *why* it's solid so you can ship with confidence, instead of inventing a finding to justify the invoice.

## Working details

- **Confidentiality:** your code and findings stay private unless you explicitly authorize disclosure. Live-bug write-ups in this portfolio are class-level for exactly this reason.
- **Scope first:** message me with your repo/contracts, the in-scope files, the target chain, deployment status, and any known concerns, and I'll scope the engagement and timeline before you commit.
- **Payment:** USDC / ETH (fiat negotiable).

**Contact:** simeon.petkov2110@gmail.com · GitHub [@SimSans](https://github.com/SimSans)
