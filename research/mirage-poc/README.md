# The Mirage — Proof of Concept

Self-contained Foundry PoC for [The Mirage](../the-mirage.md). Six passing tests demonstrating that an isolated transaction simulation can be made to diverge arbitrarily from on-chain execution via EIP-1153 transient storage.

## Run it

```bash
forge test -vvv
```

Requires a Cancun/Prague-EVM Foundry (transient storage). `foundry.toml` pins `evm_version = "prague"`.

## What's here

| File | Purpose |
|---|---|
| `src/Mirage.sol` | The demonstration contract. A `view` quote (`getAmountOut`) and three preview-trusting actions (`swap`, `swapWithMinOut`, `deposit`) whose behavior forks on a transient `prime()` flag. |
| `test/Mirage.t.sol` | 5 tests: isolated preview is fair → primed execution rugs → cross-userOp bundle defeats per-op sim → slippage-checked trade is safe (the honest limit) → preview-trusting deposit is drained. |
| `test/Mirage4337.t.sol` | 1 test modelling a **defensive simulator** faithfully (`snapshotState`/`revertToState` = `eth_call`/`debug_traceCall`) that flags SAFE, then a `MiniEntryPoint` bundle `[attacker.prime, victim.deposit]` that rugs the identical op. |

## Safety note

These contracts are a **demonstration model**, not a weapon: they target no live protocol, contain no address-targeting or deployment logic, and the "attacker" is a constructor parameter in a test harness. The purpose is to prove the simulation-soundness gap so vendors can ship the detection described in the writeup.
