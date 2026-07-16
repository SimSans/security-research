# Original Security Research

Vulnerability *classes* I've invented or weaponized, not findings against a single protocol, but primitives that generalize across the ecosystem. Each ships with a runnable proof-of-concept.

This is the work I'm proudest of: it's the difference between running a checklist and inventing the thing the checklist will one day contain.

| Research | Class | Status | Proof |
|---|---|---|---|
| [**The Mirage**](the-mirage.md) | Transient-storage (EIP-1153) simulation divergence, defeats wallet previews, "is-this-safe" scanners, DEX-aggregator quotes, and ERC-4337 per-userOp validation | Under coordinated disclosure; targets = simulation vendors + 4337 infra | 6 passing Foundry tests (**gated**: on request under NDA) |
| [**GOLEM**](golem-agent-hijack.md) | On-chain data as indirect prompt injection against fund-moving AI agents, an attacker-named token drains a real wallet through an unmodified agent SDK | Reported (defensive research; sanitized here) | End-to-end PoC (drainer redacted) |

## Why this section exists

Most audit portfolios are a list of "found bug X in protocol Y." That proves you can read code. It doesn't prove you can find the bug *no one has written a detector for yet*, which is exactly what a protocol needs before it ships something novel.

Both pieces below were **forward-invented**: I started from a capability the ecosystem assumes is inert (transient storage is "just cheap scratch space"; on-chain text is "just data the EVM parses") and asked *what breaks if that assumption is false*. Then I built the exploit and proved it runs.
