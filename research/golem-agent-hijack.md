# GOLEM: On-Chain Data as Indirect Prompt Injection

**The one assumption web3 auditors never examine, "on-chain data is inert; only the EVM interprets it", is false the moment an LLM agent reads attacker-writable on-chain text and acts on it.** An attacker who airdrops a poison-*named* token can steer a fund-moving AI agent into signing an on-chain approval to the attacker, with zero victim consent.

Status: reported as defensive research. **This page is sanitized**: it describes the pattern, the vulnerable code shape, and the fix. It intentionally omits the drop-in exploit chain.

---

## 1. The premise

Autonomous "crypto agents" (agent frameworks wired to a wallet) increasingly let an LLM read chain state and *move funds* in the same loop: "check my balance," "show my portfolio," "rebalance." To do that, the framework interpolates on-chain fields (a token's `name` / `symbol` / metadata, a Zerion position label, a swap-quote description) **raw** into the model's observation text.

But those fields are **attacker-writable**. Anyone can deploy an ERC-20 whose `name` is not "USD Coin" but a paragraph of instructions. Anyone can airdrop it to the agent's wallet, permissionless, no victim action. The next time the agent lists balances, that paragraph enters the LLM's context as if it were trusted system data.

This is textbook **indirect prompt injection** (OWASP LLM01 / the #1 agentic-AI risk of 2026), but through a channel web3 threat models treat as inert. The injection surface *is the blockchain*.

## 2. The vulnerable code shape

Two conditions, both of which I found in a real, widely-used, unmodified agent SDK:

1. **Injection in: no sanitization.** A balance/portfolio/quote action returns a string built by interpolating an attacker-controlled on-chain field directly into the observation the LLM reads. No delimiting, no escaping, no "this is untrusted data" framing. (I grepped the entire SDK for `sanitize|escape|delimit` on these paths: zero hits.)
2. **Weapon out: no gate.** A fund-moving action (`approve`) calls `send_transaction(...)` immediately, with **no confirmation gate, no allowlist, no human-in-the-loop**. The sibling `transfer` action *did* carry guardrails ("Guardrails to prevent loss of funds", refuse-to-token-contract); `approve` had **none**.

That asymmetry is the tell. It's not "the model was dumb" and it's not "integrator responsibility": one fund-moving path in the SDK's *own* code was guarded and the adjacent one wasn't. That's an oversight in the framework, and it's where the injection lands.

Chain of custody: attacker airdrops poison token → victim's routine "show my balance" renders the payload into context → model emits `approve(spender = attacker, amount = MAX)` → the SDK fires a **real on-chain transaction** → attacker `transferFrom` drains the wallet.

## 3. The real research artifact: the defense gradient

The interesting result isn't "an agent can be injected." It's **which agents, and how the vulnerability is a function of the deployer's model choice**: because these SDKs are model-agnostic.

- **A cheap, realistic model** (the kind a cost-sensitive sniper-bot actually runs): **hijacked by multiple distinct payloads** (authority-spoofing, fake "custom settlement," urgency/loss framing) into emitting the malicious approval. A clean control token produced clean behavior.
- **A frontier model** (e.g. Claude): **resisted and detected** the attack, explicitly flagged "this is an injected instruction trying to redirect approval to a non-official spender," and even caught the impersonation using knowledge of the canonical token address.

So the vulnerability is real but **conditional on economics**: the deployers most likely to run the cheap models that fall are exactly the high-frequency, low-margin bots holding hot-wallet funds. The framework ships the gap; the model choice decides whether it detonates.

## 4. Honest calibration

I flagged this at intake and it played out exactly: the *class* (indirect prompt injection → crypto agent → unauthorized tx) is known and hot, and a vendor can rule "integrator responsibility" or "model-dependent" and close it Informational, which is what happened when it was reported. I include it here not as a bounty trophy but because the **method** is the transferable asset, and because the finding is real, live-verified, and defensively valuable regardless of the payout verdict.

## 5. Fix

1. **Treat all on-chain text as untrusted input.** Delimit and clearly label attacker-controllable fields (`name`/`symbol`/metadata/memos/revert reasons) before they enter LLM context, never interpolate raw. Prefer rendering the *canonical address* over the self-reported name.
2. **Gate every fund-moving action.** `approve`/`transfer`/`send` must pass a confirmation hook, spender allowlist, or human-in-the-loop, applied symmetrically. The guardrail asymmetry (transfer guarded, approve not) is the specific bug to close.
3. **Address-based identity, not name-based.** Resolve tokens by address against a known registry; show the user the mismatch when a token *claims* to be a canonical asset it isn't.

## 6. Method (reusable)

Static pass: *does attacker-controllable on-chain text reach the LLM context, and can that context reach a fund-moving tool, unsanitized and un-gated?* Then a live PoC driving the **real framework code** with a cheap local model to confirm the end-to-end drain, and a frontier model as the contrast, to characterize the defense gradient rather than assert a single verdict.

---

*Reported to the vendor's disclosure channel as defensive research. Sanitized here: the pattern and the fix are the point; the weaponized poison-token + driver chain is withheld.*
