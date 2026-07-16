# Oracle Feed Omits `min(market, canonical)` on an LST/LRT Collateral

**Class:** oracle valuation gap · **Protocol type:** Liquity-V2 / BOLD CDP fork with liquid-staking-token collateral · **Impact:** collateral over-valuation → over-mint of the stablecoin → branch insolvency → depeg · **Proof:** passing Foundry PoC · **Status:** verified, class-level (live protocol, no public bounty, named privately on request).

---

## The invariant this breaks

A CDP protocol that accepts a liquid-staking or restaking token (an LST/LRT) as collateral must price it defensively. The canonical pattern, which the protocol's *own documentation* specified, is:

> An LST feed must return `min(market_price, exchange_rate_price)`.

The reason is that an attacker must then corrupt **both** the market oracle **and** the canonical exchange rate to inflate the collateral value. Either source alone is insufficient. This is standard for Liquity-V2-family forks; the correctly-built collaterals in the same codebase (the "blue-chip" LSTs) all took the `min(...)`.

## The bug

The two **newest, lowest-liquidity** collaterals the fork *added*, the riskier LRTs, exactly the ones most prone to depeg, derived their USD price from a **single** oracle:

```solidity
// price = ethUsd * lstRate / 1e18    , NO min(market, canonical)
```

They extended the *base* price-feed contract instead of the *composite* one, silently dropping the two-source `min(...)` guard that every sibling collateral used. So the protocol's stated "must manipulate both sources" defense collapsed to "manipulate one", on the collaterals where a depeg is most likely to occur naturally, without any manipulation at all.

## Why it's exploitable

Two independent triggers, either sufficient:

1. **A market depeg** (LRT market price < NAV, a *recurring, historical* event for these assets). The feed keeps reporting the higher canonical value, so open positions stay "healthy" on paper while the real collateral is worth less → the system is under-collateralized without anyone doing anything wrong.
2. **A single-oracle upward manipulation**: since only one source gates the price, the attacker's cost to over-value collateral is halved versus the intended design.

Either way: over-valued collateral → borrower mints more stablecoin than the collateral backs → bad debt → branch insolvency → the exact "catastrophic" outcome the protocol's own README named.

## Proof of concept

A non-fork Foundry PoC (3/3 passing) driving the real feed contracts:

- Identical depeg scenario: the vulnerable LRT feed reported **+15.78% over-valued** vs. the `min()`-protected blue-chip collateral, which correctly clamped down.
- Upward manipulation: the vulnerable feed tracked the manipulated price uncapped; the protected feed capped it.
- Sizing: 100 units of the LRT at a 13.6% depeg produced **~$15k of instant bad debt**: scaling linearly with position size.

On-chain I confirmed both LRT oracles were live, API3-style feeds (empty description, `roundId = 0`, 25h staleness), i.e., a single point of failure with no second source anywhere in the path.

## The lesson that generalizes

This is a **fork-regression**: upstream Liquity was fine; a well-built *sibling* collateral in the same repo was fine; the bug is purely in the two collaterals the fork bolted on and mispriced. The reusable check, now a fixed step in my CDP-fork playbook, is: **grep every price feed for `min(` on every LST/LRT/yield-bearing collateral first.** A single missing `min` on a low-liquidity collateral is a latent insolvency.

I've since verified the *same* class does **not** exist on a sibling fork of the same base (its LST feed correctly took `min(market, canonical)`), which is how you tell a real bug from a family-wide design choice.
