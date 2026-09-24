# Independent AI-Agent Trust & Reliability Assessments

**Simeon Petkov** · Independent technical researcher · [Research portfolio](https://github.com/SimSans/security-research) · [Email](mailto:simeon.petkov2110@gmail.com)

**Your agent can answer correctly in a demo. Will it behave correctly when real external data, tool errors and unexpected instructions appear?**

I run focused, authorized assessments of AI agents that read untrusted information or operate external tools. I investigate failure cases, design adversarial test scenarios, distinguish actual failures from plausible-but-unproven ones, and deliver reproducible evidence and concrete recommendations. My work uses AI-assisted parallel investigation with independent adversarial review; I take responsibility for reproducing empirical claims before reporting them.

## Problems I can investigate

- **Untrusted-content handling:** indirect prompt injection from retrieved documents, tool results, third-party text or structured metadata.
- **Tool permissions:** actions whose real-world effects need deterministic allowlists, confirmation gates or capability checks outside the model.
- **Task reliability:** tool failures, invalid inputs, unexpected execution paths and regression tests for clearly defined workflows.
- **Independent verification:** reproduce suspected failures, challenge false positives, and re-test mitigations.

## Proof of research

[GOLEM — On-Chain Data as Indirect Prompt Injection](https://github.com/SimSans/security-research/blob/main/research/golem-agent-hijack.md): my public, sanitized investigation documents how attacker-writable token metadata can reach a wallet-connected model through a portfolio/balance observation, and how an insufficiently gated approval operation could turn model redirection into unauthorized financial action. The result was model-dependent, and the vendor closed the submission as Informational; this is a research case study, **not** a claim of a paid bounty or universal impact.

[Multi-agent orchestration](https://github.com/SimSans/security-research/blob/main/methodology/multi-agent-orchestration.md) and [verification discipline](https://github.com/SimSans/security-research/blob/main/methodology/verification-discipline.md) describe how I separate candidate generation from adversarial attempts to refute findings. My portfolio is primarily security research, not a claim of having delivered production agent systems to prior clients.

## First engagement: paid diagnostic

**Suggested introductory price: €490, subject to scope.** One AI-agent workflow in a client-authorized staging/test environment, with one explicitly agreed primary risk surface. Typical initial scope: untrusted input reaching a tool or one critical workflow's error-handling and authorization behavior. Timing and fee are confirmed after a short scoping exchange.

**You receive:** a scoped threat/failure model; a reproducible evaluation set and evidence where access permits; confirmed findings *or* documented tested cases where no failure was reproduced; risk-ranked corrective recommendations; and one round of written follow-up questions. This is a limited diagnostic, **not a comprehensive security certification**.

**Larger engagements:** expanded evaluation, regression-test implementation, fix verification and selected code repairs are quoted separately with funded milestones and objective acceptance criteria.

## How I work

- All testing is limited to agreed and authorized environments. No unapproved live-funds, production, third-party or customer-data testing.
- I document exact test inputs, assumptions and observed outputs. A suspected issue is not presented as a demonstrated issue until reproduced.
- I use AI tools in my workflow and will agree with you *in writing* which providers, data categories and repositories may be shared with those tools. If external AI access is not permitted, we must agree on a compatible execution approach before accepting the work.
- Private code, findings and customer data remain confidential unless you explicitly approve publication.
- Work begins after written scope, acceptance criteria and the agreed deposit or funded milestone.

**To discuss a paid diagnostic:** email **simeon.petkov2110@gmail.com** with a public product link or brief description, the agent's one critical workflow, current failures/concerns, whether you have a staging environment, and your preferred completion window. Never send secrets by email.
