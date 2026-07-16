# Polygon: Forgeable Migration-Completion Check (Front-Runnable)

**Class:** authorization / forgeable state recognition · **Protocol:** Polygon, sPOL staking migration (L2) · **Impact:** an attacker front-runs and strands a user's migrating stake → temporary freeze · **Severity:** High · **Status:** disclosed; independently confirmed as a duplicate (already public, this is the one named entry in the findings set).

---

## Summary

During the sPOL staking migration, the contract recognized a "migration in progress / completion" state via a check that could be **forged by a third party**. Because the recognition of `backMigratingSPOL` state wasn't bound to the legitimate migrating account, an attacker could **front-run** the user's migration step and cause the user's migrating stake to be **stranded**: a temporary freeze of funds rather than a permanent theft, but a denial-of-service on the user's own assets mid-migration.

## Why I'm naming this one

Everything else in [the findings set](README.md) is class-level because it's live/private/pending. This one is different: it was **disclosed and independently confirmed as a duplicate**: another researcher had already reported the same issue, so it's already public and there's no disclosure risk in naming it. I include it precisely *because* it's the honest, verifiable, named data point: a real High on a flagship protocol, reasoned to a concrete front-running sequence and a temporary-freeze impact.

## The lesson that generalizes

Two lessons banked here, both about *rigor over trophy-hunting*:

1. **Migration / lifecycle windows are a rich seam.** "Mid-migration," "half-committed," and "epoch-boundary" states are where authorization checks are weakest, because the code is reasoning about a *transient* condition that's easy to under-specify. Any check that recognizes "this account is in state X" must bind X to *who* is allowed to be in it.
2. **A duplicate is still a data point about calibration, not a failure of the finding.** The bug was real and correctly severity-rated; it simply wasn't first. That's a normal outcome in competitive disclosure, and the useful takeaway is upstream: check the full prior-report history (including past competitions) *before* investing in a write-up.
