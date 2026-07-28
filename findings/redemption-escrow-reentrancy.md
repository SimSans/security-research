# Redemption-Escrow Reentrancy (CEI Violation, Commingled Singleton)

**Class:** reentrancy / checks-effects-interactions · **Protocol type:** alt-VM L1 CDP + StableSwap platform (~$16M TVL) · **Impact:** theft from a shared, commingled redemption escrow · **Proof:** code + interpreter-source verified (drain-magnitude PoC pending the platform runtime) · **Status:** disclosed to the team's security contact; live. Class-level; named privately on request.

---

## The setup

A CDP and StableSwap platform running a Solidity *dialect* on a non-EVM interpreter. Its redemption `Escrow` holds redeemable assets in a single, **commingled per-token balance** shared across all depositors. The `redeem()` path performs the external asset transfer **before** it finalizes state: it decrements the recipient record and the deposit quantity only *after* the transfer returns.

## The bug

A textbook checks-effects-interactions violation, with three aggravators that turn it from a code-smell into a fund-theft path:

1. **No reentrancy guard** on `redeem()` (or on `cancelDeposit()`, which shares the flaw).
2. The token address is **caller-supplied**, so the "transfer" is an attacker-controlled callback, a clean reentry point.
3. The escrow is a **commingled singleton**, one shared per-token balance for everyone, so a reentrant redeem draws down *all* depositors' funds, not just the attacker's own record.

## Why the usual backstop isn't there

The natural assumption is that the state decrement (`d.quantity--`) would underflow-revert and stop a double-spend. It does not. The platform's VM inserts its underflow bounds-check **only when the assignment target is a plain variable, not a struct-member access.** I verified this in the interpreter's own source: the optimizer emits the check for a `Variable` left-hand side and falls through with no check for a `MemberAccess`. So the field wraps silently instead of reverting, and the one invariant the CEI ordering would have leaned on simply isn't enforced on this host.

## Disclosure & honest scope

Reported to the team with the full code trace and the interpreter-source proof, framed as an urgent reentrancy/CEI defect (add a guard, and finalize state before the external transfer). Honest boundary: I verified the reentrancy and the silent-no-revert behavior at the code and interpreter-source level; pinning the exact profit magnitude needs the platform's runtime, which I flagged rather than over-claimed. One of five findings I reported on this platform.

## The lesson that generalizes

Host-VM semantics come *before* you trust a Solidity invariant. "The subtraction reverts on underflow" is an EVM assumption; on an alternative VM you confirm it in the interpreter, not the contract, and here the interpreter said otherwise.
