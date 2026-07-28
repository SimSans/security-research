# Recovered-Balance Double-Count → Permanent Share Inflation → Insolvency

**Class:** accounting / vault-invariant break · **Protocol type:** leveraged ERC-4626 loop vault (Morpho MetaMorpho accounting fork) · **Impact:** permanent ~2x share-price inflation → vault insolvency → depositor loss · **Proof:** passing Foundry PoC (`totalAssets` 200 vs 100 real backing) · **Status:** disclosed to the team; live. Class-level; named privately on request.

---

## The setup

An ERC-4626 loop vault forks Morpho MetaMorpho's `lostAssets` accounting, a **monotonic** tracker of value the vault holds but currently can't see through its normal valuation. `totalAssets()` is defined as `protocol collateral + lostAssets`. A novel async-withdrawal path adds a `reinitiateDeposit()` recovery function the base Morpho code never had.

## The bug

`lostAssets` only ever goes **up** (Morpho's invariant). When a stuck raw balance is later **recovered** and re-supplied through `reinitiateDeposit()`, the code adds it to real backing **and** bumps `lastTotalAssets`, but never lowers `lostAssets`. The same tokens are now counted twice, once as real collateral and once as still-lost, so `totalAssets()` reports roughly **2x** the real backing, permanently, because `lostAssets` can't come back down.

## The trigger (attacker-forceable, then owner-detonated)

1. Attacker holds shares and initiates a native withdrawal to an ETH-rejecting receiver.
2. The failed-transfer branch re-mints the shares and restores `lastTotalAssets`, leaving raw wrapped-native the valuation can't see; the next accrual crystallizes it as `lostAssets`. State is still honest here.
3. The owner's intended `reinitiateDeposit()` recovery then supplies that balance, detonating the double-count.

Result: share price inflated with no backing behind it. Later depositors overpay for shares; the last withdrawers can't be paid, a bank-run insolvency, and an attacker who exits after fresh deposits arrive at the inflated price profits at their expense.

## Proof of concept

Passing Foundry PoC deploying the **real** vault behind its proxy against a faithful synchronous spoke mock (no harness artifact): `totalAssets()` reports **200** against **100** of real backing, `lostAssets` sits at a phantom 100, and the attacker's share claim converts to ~200 backed by only 100.

## The fix

`reinitiateDeposit()` is recovering a balance already represented in `lostAssets`, so it must **move** that value from the lost bucket into the real bucket, reduce `lostAssets` by the recovered amount and do **not** bump `lastTotalAssets`, so `totalAssets()` stays constant across the recovery, as it should.

## The lesson that generalizes

The bug lives entirely in the fork's **novel glue**, the async-withdraw plus `reinitiate` path, not the inherited Morpho accounting, which is correct. Every faithfully-ported surface was clean; the regression was in the diff. [Hunt the diff.](../methodology/hunt-the-diff.md)
