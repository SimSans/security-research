# Methodology

A finding is an outcome. A *method* is what makes outcomes repeatable, and it's what you're actually hiring when you hire a security researcher. This section documents how I work, because the process is the product.

Four pieces:

1. **[The Audit Workflow](the-audit-workflow.md)**: the end-to-end sequence I run on every target, from scope-lock to PoC.
2. **[Hunt the Diff](hunt-the-diff.md)**: the single highest-EV thesis I have: bugs live in the *modifications* a fork makes, not in the battle-tested code it inherits. Nearly every finding I've landed is a fork-regression.
3. **[Multi-Agent Orchestration](multi-agent-orchestration.md)**: how I get breadth *and* depth by fanning out parallel analysis across a protocol's surfaces, then verifying adversarially before anything is claimed.
4. **[Verification Discipline](verification-discipline.md)**: the rules that keep me honest: PoC-or-it-didn't-happen, the two-pass rule, dedup-before-you-claim, and reading the test suite for design intent.

## The one-line version

> Name the promise the protocol exists to keep. Model the attacker's wishlist. Enumerate the real levers (flash loans, the actual deployed dependencies, MEV/ordering, weird states). Hunt the *sequence* that turns levers into profit. Then prove it on a fork wired to the real world, positive attacker P&L or it doesn't ship.

Everything below is that loop, made concrete.
