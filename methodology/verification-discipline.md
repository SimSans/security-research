# Verification Discipline

The rules that keep the work honest. Finding candidate bugs is the easy half; the hard, credibility-defining half is being ruthless about which ones are *real*. These are the disciplines I don't break.

## 1. PoC-or-it-didn't-happen

Every Critical/High ships with a **runnable proof-of-concept** that calls the real functions and prints positive attacker P&L. Not pseudocode, not "an attacker could", a test that passes.

And I **run it myself** before claiming it. This isn't a formality. I once had an analysis assert an "empirical run" that had never actually executed, a fabricated result that read as convincing. The rule that came out of it: *I do not report an empirical claim I have not personally reproduced.* Before recommending a client (or myself) act on a finding, I execute the PoC and read the actual output: the balance going up, the revert firing, the conservation holding. A PoC I didn't run is a hypothesis, not a finding.

## 2. The two-pass rule (an empty shallow pass is weak evidence)

A broad, shallow sweep that finds nothing is **not** proof the code is clean, especially on hard, novel code (Bitcoin SPV proofs, ZK circuits, consensus, cryptography). Shallow finders with small budgets *will* come back empty on genuinely difficult code simply because they didn't dig deep enough.

So a clean result from a breadth pass triggers a **deep second pass**: a targeted, line-by-line read of the highest-risk surface, tracing the actual data flow and diffing against upstream byte-for-byte where relevant. Only after the deep pass comes back clean do I bank a "clean" verdict on hard code.

This has paid off both ways: on one Bitcoin-bridge target the shallow pass was empty, the deep pass **confirmed** it genuinely clean (SPV soundness, offramp CEI, relay logic all verified by hand), a *stronger* clean verdict. On the same target the deep pass also surfaced a real bug the shallow pass missed entirely (an unbounded loop → permanent freeze), which I then correctly rated *not economically exploitable* rather than over-claiming (the trigger was privileged and would take centuries at the live rate). Both outcomes required the deep pass.

## 3. Dedup before you claim novelty

"Novel" is a claim, and it's usually wrong until checked. Before I call anything new:

- Read the protocol's **known-issues** and accepted-risks.
- `pdftotext` the **prior audit reports** and grep them for the function and the class.
- Check **past competition findings** on the same or upstream protocol.
- Check the **upstream project's wontfix list** for forks.

The consensus finding in [the findings set](../findings/proposer-chosen-counterparty.md) survived precisely because I did this: a sibling prior-report finding covered the *liquidated* side; mine was the *counterparty* side, genuinely different, and I could say so with the receipts. Skipping this step produces confident duplicates, which are worse than nothing.

## 4. Read the test suite for design intent

Before filing an access-control or "this should be gated" finding, read the project's **own tests**. More than once a "critical missing auth" was contradicted by a test that *asserts the public callability is intentional*. The team's test suite is their executable spec, if it asserts the behavior you're about to call a bug, it's design, not defect. Catching that before filing is the difference between a credible report and an embarrassing one.

## 5. Calibrate severity honestly

A real bug that isn't economically exploitable is a Low/Info, not a Critical, and saying so *builds* credibility. I've written up genuine bugs (an unbounded-loop freeze; a bricked feature) and rated them accurately at Low because the trigger was privileged, the impact was a temporary freeze, or the preconditions were deploy-time-only. Over-claiming severity is the fastest way to get a report (and an auditor) dismissed. The honest rating is the persuasive one.

## 6. A clean verdict is a real deliverable

The corollary to all of this: when the disciplines all pass and there's *no* critical issue, that well-founded "no critical issues found" is a legitimate result, it's what lets a team ship with confidence. The [coverage matrix](../coverage/protocols-reviewed.md) is mostly this: deep reviews of major protocols that came back robust. A clear, well-argued clean verdict is worth paying for, and I deliver it without inventing a finding to justify the engagement.
