# Byzantine Proposer Picks the Deleveraging Counterparty

**Class:** consensus / spec-drift (off-chain-derived value not re-validated on-chain) · **Protocol type:** Cosmos-SDK perpetuals DEX with an off-chain order-matching engine · **Impact:** a Byzantine block proposer force-closes a *chosen solvent user's winning position* at the bankruptcy price · **Proof:** passing Go chain-test (victim −$5,000; conservation holds) · **Status:** PoC-proven, submission drafted. Class-level; named privately on request.

---

## The invariant this breaks

When a negative-equity (bankrupt) account is **deleveraged**, its position must be offset against **canonically-selected** opposite-side counterparties, the accounts the protocol's own deterministic rule picks (e.g. most-profitable first). The counterparties don't consent and aren't compensated beyond the bankruptcy price, so *which* accounts get chosen must not be attacker-controllable. That selection is a protocol-critical, must-be-deterministic decision.

## The bug: the selector runs in exactly one place: the proposer's

The canonical counterparty selector is called in **exactly one location**: the proposer's *off-chain* block-building path (the in-memory matching engine). The on-chain delivery that **every validator** runs to apply the deleveraging does **not** re-derive or compare against the canonical set. It loops the proposer-supplied fills and, for each, validates only:

- the counterparty is on the opposite side,
- the magnitude is in range,
- the counterparty stays solvent after.

It **never checks that the named counterparty is the one the canonical rule would have selected.** So a Byzantine proposer can name **any solvent account** with an opposite-side position, force-closing that victim's *winning* position at the bankruptcy price (loss = size × (mark − bankruptcy spread)), while sparing the account the canonical rule *would* have picked (for instance, the proposer's own).

## The smoking gun: the team's own docstring promises the missing check

The docstring on the on-chain handler literally claims it errors "if the generated fills do not match the fills in the Operations object", **but that check is absent**, and an open `TODO(<internal-ticket>)` sits right above it. That's the team's own evidence the gap is **unintended**, not accepted design, which pre-empts the "known / by-design / validator-honesty-assumption" rebuttal that usually kills consensus-level findings.

## Proof of concept

I wrote and **ran** a Go chain-test (`go test`) against the real keeper:

- Canonical rule picks account *Dave* as the counterparty.
- Byzantine proposer instead names *Bob* (solvent, opposite side, winning).
- On-chain delivery **accepts** it: Bob's position is force-closed, Bob $100k → $95k (**−$5,000**), Dave is spared.
- **Conservation holds**: value is *redistributed* onto the victim, not minted, confirming it's a real transfer of loss, not a test artifact.

## Dedup diligence

A sibling finding from a prior public review of the same protocol covered the *liquidated* side and was rebutted on a validator-honesty assumption. This finding is the **counterparty** side, a *solvent victim*, plus the docstring-vs-code spec-drift, which is a materially different vector, not a verbatim duplicate. Checking that boundary *before* claiming novelty is the difference between a credible submission and a wasted one.

## The lesson that generalizes

After ~290 creative attacks proved the flashy, high-value cores of several major protocols architecturally clean, the one fileable bug was in the single place with a **real code gap: a docstring that promised a check the code didn't perform.** Creativity *finds* candidates; a runnable PoC and a dedup pass make one *fileable*. Go where the gap actually is, not where the TVL is biggest. And a `// TODO` referencing an internal ticket next to a docstring promising an absent check is gold: it's the team telling you the gap is a bug.
