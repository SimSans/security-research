# Permissionless Zero-Slippage Auto-Compound → Atomic Sandwich

**Class:** MEV / missing-slippage economic exploit · **Protocol type:** ve(3,3) DEX + gauge (Velodrome / Solidly fork) · **Impact:** theft of 88-96% of managed-veNFT compound yield belonging to all managed-lock depositors · **Proof:** passing Foundry PoC (3/3) · **Status:** disclosed to the team's security channel; latent (not yet deployed). Class-level; named privately on request.

---

## The setup

A ve(3,3) DEX had an `AutoCompounder` for managed veNFTs: anyone can call `claimFeesAndCompound()` / `claimBribesAndCompound()`, the contract claims the veNFT's reward tokens, swaps them to the governance token, and re-locks, paying the caller a small keeper reward. Public callability is **intended** (it's how compounding stays permissionless and timely).

The problem: the swap that turns rewards into the governance token was:

```solidity
router.swapExactTokensForTokens(balance, 0 /* amountOutMin */, route, addr, ts);
```

A hardcoded **`0` minimum output**. No slippage floor at all.

## The killer diff: this is a fork *regression*, not inherited behavior

The upstream (Velodrome relay `AutoCompounder`) that this was forked from **explicitly prevents** exactly this. Upstream carries **five** guards the fork removed:

1. `_checkSwapPermissions`, admin anytime / keeper after 1h / **public only in the last day of the epoch**.
2. revert if `_slippage > MAX_SLIPPAGE`.
3. `amountOutMin = optimizer.getOptimalAmountOutMin(routes, bal, POINTS, slippage)`, a real on-chain-quoted floor.
4. `if (amountOutMin == 0) revert NoRouteFound()`, belt-and-suspenders.
5. the swap decoupled from the claim/compound step.

The fork had **none** of them, it passed `0`. An agent's first pass on this called the swap "inherited from Velodrome and therefore safe." My verify-gate forced an actual line-by-line diff against upstream, which proved the **opposite**: upstream is the thing that *stops* this attack, and the fork *introduced* the vulnerability by deleting the guards. That inversion is the whole finding.

## The attack (atomic, permissionless, self-triggered)

The attacker doesn't need to front-run anyone, they trigger it themselves in one transaction:

1. Flash-loan → imbalance the reward-token / governance-token pool.
2. Call `claimFeesAndCompound()` → the veNFT's reward tokens are dumped into the pool at the attacker's manufactured bad price, with `amountOutMin = 0`.
3. Restore the pool → pocket the difference.

Repeatable every epoch. The victims are **all managed-lock depositors**, whose compound yield is what gets swapped at the manipulated price.

## Proof of concept

Foundry PoC (3/3 passing) wiring the **real** `AutoCompounder`, `Pool`, `Router`, and `CompoundOptimizer` (only the `ve`/`voter`/`distributor` endpoints mocked, the loss path is entirely real code):

- Fair compound: **18,122** governance tokens compounded.
- Sandwiched: **2,142** compounded → **88% stolen**; attacker walked with the difference.
- `test_sweep` scaled the theft to **96%** at larger flash-loan size.

## Disclosure & severity

Severity is High by impact, tempered by **latency**: on-chain verification showed the `AutoCompounder` and its factory are **not in any mainnet or testnet deployment manifest** and have **no deploy script**: so no funds are at risk *today*. It's a fix-before-ship bug. I staged a coordinated disclosure to the protocol's `security@` channel (verified via their `.well-known/security.txt`) with the full write-up and PoC, since the protocol is unaudited and this path was never covered.

## The lesson that generalizes

*Every* bug I found on this target was in the protocol's **own** modified code (this guard-deletion; a separate config-mismatch that bricked a grant-conversion feature). *Every* faithfully-ported surface (the AMM, the reward math, the veNFT logic, both governors) was clean. That's the fork-hunting thesis in one target: [hunt the diff](../methodology/hunt-the-diff.md), and when an agent claims "inherited, therefore safe," **diff it against upstream yourself**: the regression is often the exact guard the fork thought it inherited.
