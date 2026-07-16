# The Mirage — Transient-Storage Simulation Divergence

**A malicious contract renders a benign, "fair," SAFE result to every isolated transaction simulator — wallet preview, Blockaid-class security scanner, DEX-aggregator quote, ERC-4337 per-userOp validation — then rugs the user when a cheap, innocuous sibling `prime()` runs earlier in the same atomic execution context (transaction / 4337 bundle / multicall).**

Status: responsible-disclosure draft. Proof: **6 passing Foundry tests** — [`mirage-poc/`](mirage-poc/), runnable with `forge test`.

---

## 1. TL;DR

Every transaction-security product rests on one unstated axiom:

> *Simulating a call in isolation predicts its on-chain effect.*

EIP-1153 transient storage (`TSTORE`/`TLOAD`, live on Ethereum, Base, Arbitrum, Optimism, Polygon, and every post-Cancun chain) breaks that axiom. Transient storage is **tx-scoped**: it persists across separate calls **within one transaction/bundle** but is **empty in any fresh isolated call**. A contract can therefore make its behavior — *including a `view` quote a wallet reads to preview a trade* — depend on whether a cheap innocuous `prime()` ran earlier in the same atomic context. Every isolated simulator sees the benign branch; the primed on-chain execution takes the malicious branch.

This is **stronger than every known sim-evasion / honeypot technique**, which keys off the *environment* (block number, timestamp, `tx.origin`, gas, coinbase, chainid) or *persistent storage* — signals a stateful **fork-simulator** (Tenderly, a wallet preview that forks current state) faithfully reproduces and defeats. The Mirage defeats even a *perfect* fork-simulator, because the trigger is **a sibling call inside the same atomic bundle the simulator never includes** — not any property of the chain it forks.

---

## 2. The mechanism

```solidity
contract Mirage {
    uint256 private constant PRIMED = 0x6d69726167655f7072696d6564; // transient slot

    function prime() external { assembly { tstore(PRIMED, 1) } }      // cheap, "does nothing"
    function _primed() internal view returns (bool p) { assembly { p := tload(PRIMED) } }

    // The VIEW quote a wallet / aggregator / oracle reads to preview the action.
    // Isolated  -> fair (amountIn).   Primed -> dust (amountIn / 1e6).
    function getAmountOut(uint256 amountIn) public view returns (uint256) {
        return _primed() ? amountIn / 1_000_000 : amountIn;
    }

    // A preview-trusting action with NO user-side backstop (deposit / migrate / claim).
    function deposit(uint256 amountIn) external returns (uint256 minted) {
        token.transferFrom(msg.sender, address(this), amountIn);
        minted = getAmountOut(amountIn);          // "fair 1:1" in any isolated preview
        shares[msg.sender] += minted;
        if (_primed()) shares[attacker] += amountIn - minted;  // the silent theft
    }
}
```

A wallet/scanner previews `deposit(AMOUNT)` in isolation → transient empty → `getAmountOut` returns `AMOUNT` → **"you receive 1:1 shares, nothing routed elsewhere: SAFE."** On-chain, the attacker's `prime()` runs first in the same bundle → `deposit` mints the victim dust and credits the attacker the rest. **The preview and the execution are the same bytecode; only the transient context differs, and the simulator's context is structurally wrong.**

---

## 3. Faithful threat model — the honest scope

The rug fires **iff a sibling `prime()` executes in the victim action's atomic context.** That is the whole ballgame. This section is deliberately conservative — the boundary is what makes the primitive *real* instead of over-claimed.

**Where it bites** (defensive isolated-simulation + shared-execution context):

- **ERC-4337 bundles.** A `handleOps` transaction executes many userOps **sequentially in one tx** → shared transient storage. Bundlers, SDKs, and wallets validate/preview each userOp **in isolation** (`eth_call` / `debug_traceCall` / `eth_estimateUserOperationGas` of a single op). An attacker submits a cheap `prime()` userOp co-bundled ahead of the victim's userOp. Per-op simulation is **structurally blind** to it. *(The 4337 spec restricts the VALIDATION phase's cross-op storage access; it does NOT restrict the EXECUTION phase — this attack lives in execution.)*
- **Multicall / batch routers / intent-solver settlements** that place attacker-influenced calls and the victim's action in one transaction, while the safety preview evaluates the victim's leg alone.
- **Any product whose safety guarantee = "we simulated this action and it's fine"**: wallet transaction previews, Blockaid / Wallet-Guard / Pocket-Universe-class scanners, aggregator/solver quotes, automated "safe-to-sign" gates.

**Where it does NOT bite** (stated plainly, so the boundary is trusted):

- **A plain single EOA transaction** the victim composes alone: no sibling `prime()` in it → preview == execution → **safe**. This is *not* a generic "any wallet, any tx" break.
- **Slippage / min-output / post-condition-checked actions**: a swap with `minOut` **reverts** on the primed dust. On-chain user-side validation is a complete backstop. (PoC test 4.)
- Actions where the quoted/acted-upon contract is **not** attacker-controlled and reads no attacker-settable transient slot.

**Lethal target class** = preview-trusting, *un-validated* actions — deposits without `minShares`, migrations, "claim", batched authorizations, permit-style flows — executed in a shared-transient context (4337 / multicall / solver batch), where the isolated preview is the *only* protection.

---

## 4. Proof of concept

[`mirage-poc/`](mirage-poc/) — `forge test` (Prague EVM, EIP-1153). All six tests pass.

`test/Mirage.t.sol` (5 tests):
1. `test_1_everySimulatorSeesAFairSwap` — isolated preview = fair 1:1.
2. `test_2_theSameSwapExecutesAsARug` — the same call, primed, is a catastrophic rug.
3. `test_3_crossUserOpBundleDefeatsPerUserOpSimulation` — two userOps, one tx, shared transient.
4. `test_4_slippageCheckedTradeIsSafe` — the honest limit: `minOut` reverts the primed dust.
5. `test_5_previewTrustingActionIsRugged` — a deposit with no backstop is drained.

`test/Mirage4337.t.sol` (1 test — the disclosure-grade model):
- `test_defensiveSimulationSaysSafe_thenBundleRugsTheUser` — models a **defensive simulator** faithfully: it executes the victim's `deposit` userOp against current state, reads the outcome (fair 1:1, **nothing** routed to any attacker → flagged SAFE), and **discards state** (`snapshotState` / `revertToState`, exactly like `eth_call` / `debug_traceCall`). Then a `MiniEntryPoint`-style bundle `[attacker.prime, victim.deposit]` executes in one tx and the identical op rugs the user. The preview and the execution diverge by 10⁶×.

---

## 5. Impact & severity

- **Primitive class:** a general defeat of isolated-simulation safety guarantees for a specific, common, high-value action class (preview-trusting deposits/migrations/claims in shared-transient contexts). It converts "our simulation says this is safe" from a guarantee into an assumption an attacker chooses to violate.
- **User impact where applicable:** full loss of the deposited/migrated/claimed amount, with the victim having been shown an explicit "safe/fair" preview — i.e., it defeats the exact control users are told to rely on.
- **Likelihood:** gated by the co-location requirement (needs 4337/multicall/solver context) — which is why the honest framing targets simulation *vendors* and 4337 infra, not a blanket "all wallets" claim.

---

## 6. Detection & mitigations

1. **Flag transient opcodes in simulated code paths.** If a previewed action's executed bytecode contains `TLOAD`/`TSTORE` (or calls a contract that does), the isolated simulation is **unsound** — surface a "simulation may not reflect execution" warning instead of a green "SAFE."
2. **Simulate in the real pending context, not in isolation.** For 4337, simulate the victim userOp **appended to the actual pending bundle** (including other senders' ops), not alone.
3. **Differential simulation:** run the action twice — once cold, once after a probe that sets an arbitrary transient slot the target reads — and diff the results; divergence ⇒ Mirage-class.
4. **Protocol-side (defense in depth):** require on-chain `minShares`/`minOut`/post-conditions on deposit/migrate/claim so the preview is never the sole backstop. (Fully neutralizes it — test 4.)

---

## 7. Responsible disclosure

Targets, by blast radius: **Blockaid** (powers MetaMask / Coinbase Wallet malicious-tx detection), **MetaMask / ConsenSys** tx simulation, **Rabby (DeBank)** pre-tx simulation, and **ERC-4337 bundler/SDK teams** (Pimlico, Alchemy, Biconomy, ZeroDev, Candide, Etherspot, Safe4337) — the per-userOp-simulation-vs-shared-execution gap is squarely theirs. Posture: private, coordinated; no public exploitation guidance beyond the self-contained PoC.

---

*This is defensive research. The PoC contracts are a self-contained demonstration model — they target no live protocol, name no victim, and contain no deployment or targeting logic. The point is to get the fix (soundness-aware simulation) shipped before someone weaponizes the class in the wild.*
