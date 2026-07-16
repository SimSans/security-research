# Hunt the Diff

The single highest-EV thesis I have, stated bluntly:

> **Battle-tested code is battle-tested. Bugs live in the modifications a fork makes to it. Audit the diff, not the read.**

## The observation that made it a rule

Looking back across my work, the pattern is stark: **nearly every finding I've landed is a fork-regression**: a bug in the code a protocol *added or changed* on top of a mature base. And **nearly every clean verdict is on an original or faithfully-ported protocol**: where the team either wrote something new and careful, or copied a mature protocol *without* meaningfully changing the security-relevant logic.

Concretely, from [the findings set](../findings/):

- A Liquity-V2 fork mispriced the **two LST collaterals it added**: the upstream and the fork's own blue-chip collaterals were fine.
- A Velodrome fork **deleted five slippage/permission guards** from an auto-compounder, the upstream *had* them; the fork's diff removed them.
- A leveraged-vault bug lived entirely in a **fresh feature-branch** integration, not in `main`.
- An EVM-Cosmos L1 bug was in **the fork's diff from canonical go-ethereum** (a hardcoded `false` where upstream propagated `evm.readOnly`).

The clean banks tell the same story in reverse: faithful ports of Aave (on Move), Uniswap-V3 (on Sui/Move), Vertex (on a new L2), Velodrome/Aerodrome (its AMM, reward, and governor surfaces) all came back clean, because the port *didn't change the invariant-bearing logic*. The bug isn't in the copy; it's in the *edit*.

## Why it works

A mature protocol's core has survived audits, bounties, and years of live adversarial pressure. Re-deriving a bug in *that* is low-probability. But when a team forks it, they:

1. **Add collaterals / assets / markets** the original never priced or risk-modeled.
2. **Delete guards** they believe are redundant or don't understand ("we inherited this from upstream", often *false*; see below).
3. **Rewire integrations** (a new oracle, a new automation layer, a new bridge) whose edge cases the original never touched.
4. **Change parameters / configs** in ways that interact badly with untouched code (a production `maxLockTime` that bricks a feature the whole test suite hides by using a different value).

Each of those is in the diff, and each is fresh, un-battle-tested, and *specific to this fork*. That's the seam.

## The "inherited, therefore safe" trap

The most valuable single move in this thesis: when reviewing a forked surface, **do not trust "this is inherited from upstream, so it's safe."** An agent (or a hurried human) will pattern-match a forked function to its upstream and wave it through. But forks *regress*, they delete the exact guard that made the upstream safe.

The auto-compounder finding turned entirely on this. The first pass called the zero-`minOut` swap "inherited from Velodrome, therefore safe." Diffing it against the actual upstream proved the **opposite**: upstream is the thing that *prevents* the attack (it carries a real on-chain-quoted slippage floor and a `revert NoRouteFound()`), and the fork introduced the bug *by deleting those guards*. **When something looks inherited, diff it against upstream yourself**: the regression is often the exact guard the fork thought it kept.

## How to run it

1. Identify the upstream and check it out at the version the fork branched from.
2. `git diff` (or a structural diff of the deployed bytecode vs. the upstream release) to get the exact modification set.
3. For every changed security-relevant line, ask: *what invariant did the upstream rely on here, and does the change preserve it?*
4. Pay special attention to **deletions** (removed guards), **added assets** (unpriced collateral), and **rewired integrations** (new external dependencies).
5. The faithfully-copied 95% you can review fast. The 5% diff is where you spend your time.

## The corollary: fresh chain ≠ fresh code

A trap on the other side of the same coin. "Fresh Nov-2025 orderbook DEX on a brand-new L2" *sounds* like thin, be-early, un-audited territory. But the **code** can be a mature protocol's fork with hundreds of prior submissions and fully-public verified source, i.e. crowded and dedup-dead. Before treating a "fresh" target as thin, check: *is it a fork of something mature? how many people have already submitted? is the source public and verified?* Freshness of the *chain* says nothing about freshness of the *code*.
