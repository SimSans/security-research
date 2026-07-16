# The Audit Workflow

The sequence I run on every target. It's designed to spend the least time on the parts a checklist can do and the most time on the part only a human attacker can do — finding the *sequence* that turns a design seam into profit.

## 0. Scope-lock (before reading a line)

The most expensive mistake is auditing the wrong code. So first:

- **Pin the exact commit / deployed bytecode that's in scope.** Not `HEAD` — the specific tag, branch, or on-chain address. (I've watched a scope pin to `rc-4/5` while `HEAD` had moved to a completely different `v6`. Auditing `HEAD` there would have been wasted effort.)
- **Read the *real* assets-in-scope**, not the marketing. A "$100k OP-Stack fork" bounty can turn out to have exactly one in-scope contract — a mature, already-audited bridge — with all the fresh, interesting code out of scope. Confirm the scope boundary from the submission form / assets list, not the landing page.
- **Establish lineage.** Is this a fork of something mature (Liquity / Aave / Velodrome / Uniswap / an OP-stack component)? If so, get the *upstream* checked out too — the audit is now a *diff*, not a read. (See [Hunt the Diff](hunt-the-diff.md).)
- **Establish crowd size.** How many people have already looked? A "fresh" chain can be running mature forked code that hundreds of hunters have already combed with fully-public verified source. That changes the target from *thin/be-early* to *crowded/dedup-dead* — worth knowing before you invest.

## 1. Name the core promise

Every protocol exists to guarantee **one invariant**: "the stablecoin stays backed," "shares always redeem for ≥ their fair value," "only the owner can move funds," "the counterparty is deterministic." Write it down. Every finding is a way to make that sentence false.

## 2. Model the attacker's wishlist

Concrete fund-moving goals, not abstract "what-ifs": *mint stablecoin I didn't back · withdraw more than I deposited · get someone else's collateral seized · freeze a competitor's funds · make my liquidation profitable to me.* Each goal becomes a hunt.

## 3. Enumerate the real toolset

The levers an attacker actually has, wired to the **real deployed world**:

- **Flash loans** (capital is free for one transaction).
- **The actual dependencies** — the real oracle, the real AMM, the real lending market this protocol integrates. Read *their* behavior, not the mock's. (More than once the mock was faithful and the bug was in how the protocol used the *real* dependency's edge case.)
- **MEV / ordering** — front-run, back-run, sandwich, sequencer/proposer control where the trust model allows it.
- **Weird states** — empty pool, first depositor, mid-migration, epoch boundary, paused, frozen oracle, post-slash. Bugs cluster at state transitions.

## 4. Hunt the sequence

This is the actual work: find the *ordered combination of levers* that links a starting state to a wishlist outcome with positive P&L. Not "this function looks risky" — "flash-loan → imbalance pool → call this permissionless compound with `minOut=0` → restore → pocket 88%." The sequence is the finding.

## 5. Prove it on a fork

Positive attacker P&L or it doesn't ship. A PoC that calls the **real** functions on a mainnet fork (or a faithful local harness where only unreachable endpoints are mocked and the loss path is entirely real code), and prints the attacker's balance going up. See [Verification Discipline](verification-discipline.md) for why this rule is non-negotiable — and how I keep the PoC itself honest.

## 6. Dedup, then write

Before claiming novelty: check the protocol's known-issues, prior audit reports (`pdftotext` the PDFs and grep them), past competition findings, and the upstream project's wontfix list. *Then* write the report: severity, root cause, impact, runnable PoC, concrete fix.

## What the workflow optimizes for

Steps 0 and 6 (scope + dedup) are where most *wasted* effort goes — auditing the wrong code, or re-finding a known bug. Steps 3–5 (levers → sequence → PoC) are where the *value* is. The workflow front-loads the cheap checks that prevent expensive mistakes, so the expensive time goes into the one thing that's genuinely hard: the attack sequence.
