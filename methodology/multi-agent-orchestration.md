# Multi-Agent Orchestration

Auditing a large protocol has a fundamental tension: **breadth** (cover every surface) fights **depth** (understand one surface well enough to break it). A single reviewer reading top-to-bottom gets depth but runs out of time before breadth; a shallow sweep gets breadth but misses the deep bugs.

I resolve it by orchestrating parallel analysis: **fan out for breadth, converge with adversarial verification for correctness.**

## The shape

```
                 ┌─ surface 1 (AMM / swap math) ─────┐
   recon &       ├─ surface 2 (oracle / pricing) ────┤     dedup +      adversarial      synthesize
   scope-lock ──▶├─ surface 3 (liquidation / risk) ──┤──▶ collect  ──▶  verification ──▶ + PoC the
   (one pass)    ├─ surface 4 (governance) ──────────┤    findings     (refute each)     survivors
                 └─ surface N (bridge / accounting) ─┘
```

1. **Recon once.** Establish scope, lineage, the core promise, and the surface decomposition, the natural module boundaries an attacker would treat separately.
2. **Fan out.** One focused analysis per surface, in parallel. Each is a deep read of *its* module against the attacker wishlist, not a shallow skim. Breadth comes from running many of these at once; depth comes from each one being narrow.
3. **Collect and dedup.** Pool the candidate findings across surfaces. Many collapse into each other or into known issues here.
4. **Verify adversarially.** This is the critical stage (see below).
5. **Synthesize + PoC** the survivors into fork-proven findings.

## Adversarial verification is the point

The failure mode of any fan-out, human team or automated, is **plausible-but-wrong findings** surviving to the report. A confident write-up of a bug that isn't real is worse than no finding: it burns credibility and the client's time.

So every candidate that survives collection is **actively attacked, not confirmed**. Instead of asking "is this real?" (which invites motivated confirmation), I ask "*refute this*": spawn independent skeptics, each prompted to find the reason it *doesn't* work, defaulting to "refuted" under uncertainty. A finding survives only if the refutation attempts fail. Where a finding can fail in more than one way, the skeptics get *distinct lenses* (correctness, does-it-actually-reproduce, is-it-known/by-design, is-it-in-scope), because diversity catches failure modes that redundancy can't.

This killed more findings than it kept, which is exactly right. Examples of what adversarial verification caught before it reached a report:

- A "critical missing access control" that the **project's own test suite asserted was intentional**.
- A false-positive "critical" that a cross-check against the real dependency's behavior disproved.
- A "novel" consensus bug that an upstream diff showed was **already known upstream**.

## Why this beats one-pass review

- **Coverage without shallowness.** Ten parallel deep reads cover a protocol the way ten specialists would, in the wall-clock time of the slowest one, not the sum.
- **Independence.** Surfaces are analyzed blind to each other, so a wrong assumption in one doesn't contaminate the others. Verifiers are independent of finders, so the person who *wants* the bug to be real isn't the one who signs off.
- **A stronger clean verdict.** When this process returns *nothing*, that's a well-founded "no critical issues", many independent deep reads plus adversarial verification all came up empty. That's a deliverable a team can ship on. (See [Verification Discipline](verification-discipline.md) on why an *empty shallow* pass is **not** the same thing, and why I follow it with a deep second pass.)

## Honest note on tooling

I use LLM-driven agents to run the fan-out and the adversarial verification at a scale a solo researcher couldn't match by hand. That's a force multiplier for *breadth* and for *generating* candidate attacks, but every claimed finding is verified by a runnable PoC I execute myself, and every "empirical result" is one I've reproduced. Tools find candidates; I own the verdict. The discipline that makes this safe rather than a fabrication risk is the whole subject of the [next page](verification-discipline.md).
