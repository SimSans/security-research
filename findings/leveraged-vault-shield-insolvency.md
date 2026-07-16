# Leveraged-Vault Collateral Double-Spend → Insolvency

**Class:** accounting desync / synthetic-vs-real collateral · **Protocol type:** leveraged LST staking vault (3-sided: lenders / leveraged borrowers / collateral-lenders shielding drawdowns), with a Chainlink-automation integration · **Impact:** real collateral leaves the system while the synthetic shield stays committed → liquidations can't be honored → insolvency · **Status:** verified by hand against the real code paths; disclosed to the team. Class-level.

---

## Context: where the bug lives

This was a **fresh feature-branch** (`feat-integrate-chainlink-cre`) on a public repo — genuinely in-development, pre-final-audit code. That's the highest-yield place to look: not the audited `main`, but the branch where new integration logic is still settling. Two verified findings came out of it; this is the more severe.

## The double-spend

The vault runs a "shield": collateral-lenders' funds absorb borrower drawdowns. When the automation path commits a collateral-lender's (CL) capital to the live shield, it:

- mints a **synthetic** collateral token,
- moves the CL's balance from `unutilized` → `utilized`,
- **but never pulls the CL's real underlying** out of the external lending market (Aave).

So the shield is now backed by a synthetic IOU, while the CL's *real* underlying still sits in Aave under the CL's control. Then `withdrawCLOrder` — `external`, no epoch guard — lets the CL **withdraw that real underlying**, and instead of reverting, it **clamps `totalCLDepositsUnutilized` to 0** rather than decrementing the `utilized` side.

Net effect: the real collateral walks out the door while the synthetic shield stays committed on the books. When a liquidation later fires, the auction's `transferForProxy` has nothing real to draw on — **the liquidation can't be honored → the vault is insolvent.**

## The sibling finding (same class, same target)

The second verified bug is the same *shape* — a real-vs-recorded desync — at epoch close: the upkeeper credited only accrued interest back to the CL principal accumulator (`totalCollateralLenderCT += totalInterest`) while restoring the order to `principal + interest`. The lender-side sibling did it correctly (added the full amount); the CL side dropped the principal. A later `withdrawCLOrder -= principal` then **underflow-reverts**, permanently locking CL funds and corrupting the backing/payout math. A third finding (a passing PoC) showed untimed proportional withdrawal letting a same-block flash-loan deposit skim honest lenders' accrued interest.

## How I avoided a false positive

An earlier candidate on this same target — "the automation `performTask()` / `onReport()` has no forwarder auth, anyone can call it" — *looked* like a critical access-control bug. It wasn't: the project's **own test suite** (`PublicPerformTaskMainnetTest`) asserts that public callability is intentional. I caught it before filing by reading the tests for design intent. **The rule that came out of this: always read the project's test suite for intent before filing an access-control finding.** An agent flagged it; the test suite killed it; the two real accounting bugs survived.

## The lesson that generalizes

The win pattern here — proven across an audited-shelf losing streak — is **fresh public feature-branch code on a smaller platform**, not the picked-over audited `main`. New integration logic (here, an automation callback wiring a synthetic shield to a real external market) is where real-vs-synthetic accounting desyncs hide, because the two sides of the ledger are written in different places by different code paths.
