# Public Contest Reports

Findings submitted to **public** audit competitions become attributable once the contest closes, so unlike the private-bounty work in [findings/](../findings/), these can be shown by name, with links to the public contest repo.

I include them for one reason: **verifiability**. An outside reader can follow the links to the public Code4rena / CodeHawks repository and confirm the code, the lines, and the report are real. A portfolio is worth more when parts of it can be checked independently.

---

## Monetrix (Code4rena, 2026-04): QA report

Repo: [`code-423n4/2026-04-monetrix`](https://github.com/code-423n4/2026-04-monetrix), a USDM/sUSDM yield-stablecoin protocol.

A quality-assurance report of five issues. The two substantive ones are **invariant violations the protocol claims to enforce but doesn't**:

**L-01: `Vault.distributeYield` mints USDM past `maxTVL` (supply-cap bypass).**
`Vault.deposit` guards supply growth with `require(usdm.totalSupply() + amount <= maxTVL)`. The *other* minting path, `distributeYield`, has **no equivalent check**: so protocol-driven yield distribution can push total USDM supply past the configured `maxTVL`, breaking the sizing assumption the cap exists to guarantee.
[`MonetrixVault.sol#L395-L399`](https://github.com/code-423n4/2026-04-monetrix/blob/main/src/core/MonetrixVault.sol#L395-L399)

**L-02: `sUSDM.injectYield` is not gated by `whenNotPaused` (Guardian pause bypass).**
The Guardian's emergency pause is supposed to be able to halt state-changing flows. `injectYield` omits the `whenNotPaused` modifier its siblings carry, so **yield injection continues even while the protocol is paused**: a defense-in-depth gap that defeats part of the pause's purpose during an incident.

Plus L-03 (a README invariant that's factually wrong about cooldown behavior), L-04 (`O(N)` iteration in the redeem/unstake removal loops = a self-grief / DoS surface), and L-05 (dead write-only state).

*Takeaway pattern:* when a protocol enforces an invariant (`maxTVL`, `whenNotPaused`) on the **obvious** path, check **every other path that touches the same state**: the guard is almost always missing on the second-most-obvious one.

---

## Other public-contest participation

Deep reviews submitted to public competitions on Code4rena, Cantina, and CodeHawks, including several flagship multi-million-dollar scopes, where my verdict was a well-argued *clean* (no critical issues) after multi-module analysis, custom fuzzing, and fork-based testing. Those protocols are listed in the [coverage matrix](../coverage/protocols-reviewed.md); a clean verdict on code this size is a deliverable in its own right.
