# The Mirage: Transient-Storage Simulation Divergence

**A malicious contract can render a benign, "fair," SAFE result to every isolated transaction simulator (wallet preview, Blockaid-class security scanner, DEX-aggregator quote, ERC-4337 per-userOp validation), then behave differently when a cheap, innocuous sibling call runs earlier in the same atomic execution context (transaction / 4337 bundle / multicall).**

> **Disclosure status: this page is gated.** The full mechanism, the weaponized contract, and the runnable proof-of-concept (**6 passing Foundry tests**) are held under **coordinated disclosure** with the affected simulation vendors and ERC-4337 infrastructure teams. This page establishes the concept, the honest scope, and the fix. Full technical detail and the PoC are available **on request** to vendors and prospective clients under NDA, not published here, because releasing the technique before those vendors ship detection would create exactly the harm the research exists to prevent.

---

## 1. TL;DR

Every transaction-security product rests on one unstated axiom:

> *Simulating a call in isolation predicts its on-chain effect.*

EIP-1153 transient storage (`TSTORE`/`TLOAD`, live on Ethereum, Base, Arbitrum, Optimism, Polygon, and every post-Cancun chain) breaks that axiom. Transient storage is **tx-scoped**: it persists across separate calls **within one transaction/bundle** but is **empty in any fresh isolated call**. A contract can therefore make its behavior, *including a `view` quote a wallet reads to preview a trade*, depend on whether a cheap innocuous "prime" call ran earlier in the same atomic context. Every isolated simulator sees the benign branch; the primed on-chain execution takes the malicious branch.

This is **stronger than every known sim-evasion / honeypot technique**, which keys off the *environment* (block number, timestamp, `tx.origin`, gas, coinbase, chainid) or *persistent storage*, both of which a stateful **fork-simulator** (Tenderly, a wallet preview that forks current state) faithfully reproduces and defeats. The Mirage defeats even a *perfect* fork-simulator, because the trigger is **a sibling call inside the same atomic bundle the simulator never includes**: not any property of the chain it forks.

## 2. Why it works (concept)

The security-relevant fact about transient storage is narrow and load-bearing: a value written with `TSTORE` is visible to later calls **in the same transaction** and is guaranteed **empty** at the start of any independent one. So a contract can branch on "has a sibling call in *this* atomic context touched my transient slot?", a question an isolated simulator, by construction, always answers "no."

That turns the standard honeypot inside-out. Classic honeypots try to look *malicious to defenders and benign to victims* by keying on the environment, which stateful simulators reproduce. The Mirage looks *benign to defenders* (the isolated preview) and *malicious in execution* (the primed bundle), and no amount of faithful state-forking closes the gap, because the trigger isn't in the forked state at all, it's a co-located sibling call the simulator never bundles in.

*(The exact contract construction and the primed/unprimed divergence are withheld, see the disclosure banner above.)*

## 3. Faithful threat model: the honest scope

This is what makes the primitive *real* instead of over-claimed. The divergence fires **iff a sibling "prime" call executes in the victim action's atomic context.** That gate is the whole ballgame.

**Where it bites** (defensive isolated-simulation + shared-execution context):

- **ERC-4337 bundles.** A `handleOps` transaction executes many userOps **sequentially in one tx** → shared transient storage. Bundlers, SDKs, and wallets validate/preview each userOp **in isolation** (`eth_call` / `debug_traceCall` / `eth_estimateUserOperationGas` of a single op). An attacker co-bundles a cheap innocuous userOp ahead of the victim's. Per-op simulation is **structurally blind** to it. *(The 4337 spec restricts the VALIDATION phase's cross-op storage access; it does NOT restrict the EXECUTION phase, this lives in execution.)*
- **Multicall / batch routers / intent-solver settlements** that place attacker-influenced calls and the victim's action in one transaction, while the safety preview evaluates the victim's leg alone.
- **Any product whose safety guarantee = "we simulated this action and it's fine"**: wallet transaction previews, Blockaid / Wallet-Guard / Pocket-Universe-class scanners, aggregator/solver quotes, automated "safe-to-sign" gates.

**Where it does NOT bite** (stated plainly, so the boundary is trusted):

- **A plain single EOA transaction** the victim composes alone: no sibling prime in it → preview == execution → **safe**. This is *not* a generic "any wallet, any tx" break.
- **Slippage / min-output / post-condition-checked actions**: a swap with `minOut` **reverts** on the primed dust. On-chain user-side validation is a complete backstop.
- Actions where the acted-upon contract is **not** attacker-controlled and reads no attacker-settable transient slot.

**Lethal target class** = preview-trusting, *un-validated* actions (deposits without `minShares`, migrations, "claim", batched authorizations, permit-style flows) executed in a shared-transient context (4337 / multicall / solver batch), where the isolated preview is the *only* protection.

## 4. Proof of concept (gated)

A self-contained Foundry PoC (**6 passing tests**, verified via `forge test` on a Prague-EVM toolchain) demonstrates:

1. An isolated preview of the action returns a fair result, what every simulator sees.
2. The identical call, primed by a sibling in the same tx, diverges catastrophically.
3. A faithful two-userOp ERC-4337 bundle defeats per-userOp simulation.
4. The honest limit, a slippage-checked trade is **safe** (the primed rug reverts at `minOut`).
5. A preview-trusting action with no backstop is drained.
6. A disclosure-grade model of a **defensive simulator** (`snapshotState`/`revertToState` = `eth_call`/`debug_traceCall`) that flags the action SAFE, then a `MiniEntryPoint` bundle that rugs the identical op, a 10⁶× preview-vs-execution divergence.

The PoC targets **no live protocol**, names no victim, and contains no deployment or targeting logic, it's a demonstration model. It's held for coordinated disclosure and shared on request; see the banner above.

## 5. Impact & severity

- **Primitive class:** a general defeat of isolated-simulation safety guarantees for a specific, common, high-value action class (preview-trusting deposits/migrations/claims in shared-transient contexts). It converts "our simulation says this is safe" from a guarantee into an assumption an attacker chooses to violate.
- **User impact where applicable:** full loss of the deposited/migrated/claimed amount, with the victim having been shown an explicit "safe/fair" preview, i.e., it defeats the exact control users are told to rely on.
- **Likelihood:** gated by the co-location requirement (needs 4337/multicall/solver context), which is why the honest framing targets simulation *vendors* and 4337 infra, not a blanket "all wallets" claim.

## 6. Detection & mitigations

1. **Flag transient opcodes in simulated code paths.** If a previewed action's executed bytecode contains `TLOAD`/`TSTORE` (or calls a contract that does), the isolated simulation is **unsound**: surface a "simulation may not reflect execution" warning instead of a green "SAFE."
2. **Simulate in the real pending context, not in isolation.** For 4337, simulate the victim userOp **appended to the actual pending bundle** (including other senders' ops), not alone.
3. **Differential simulation:** run the action twice, once cold, once after a probe that sets an arbitrary transient slot the target reads, and diff the results; divergence ⇒ Mirage-class.
4. **Protocol-side (defense in depth):** require on-chain `minShares`/`minOut`/post-conditions on deposit/migrate/claim so the preview is never the sole backstop. (Fully neutralizes it.)

## 7. Responsible disclosure

Targets, by blast radius: **Blockaid** (powers MetaMask / Coinbase Wallet malicious-tx detection), **MetaMask / ConsenSys** tx simulation, **Rabby (DeBank)** pre-tx simulation, and **ERC-4337 bundler/SDK teams** (Pimlico, Alchemy, Biconomy, ZeroDev, Candide, Etherspot, Safe4337), the per-userOp-simulation-vs-shared-execution gap is squarely theirs. Posture: **private, coordinated; no public release of the mechanism or PoC before vendor remediation**: which is why this page is gated.

---

*This is defensive research. The goal is to get soundness-aware simulation shipped before the class is weaponized in the wild, not to hand anyone a recipe. Full detail available to vendors and clients on request.*
