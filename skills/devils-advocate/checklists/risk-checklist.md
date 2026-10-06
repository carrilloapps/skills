# Risk Identification Checklist for Devil's Advocate Analysis

Use this checklist when applying the devils-advocate skill to any proposal or design.
Work through each category and note any items that apply.

---

## 🏗️ Technical Risks

1. Are there known performance bottlenecks under realistic load?
2. Are there single points of failure (no redundancy)?
3. Does the solution depend on third-party services with no SLA guarantees?
4. Are there unhandled error / edge cases?
5. Does this introduce N+1 queries, unbounded loops, or unbounded memory growth?
6. Is there a risk of race conditions or concurrency issues?
7. Are there implicit assumptions about data consistency (transactions, ordering)?
8. Does this create hard-to-reverse state changes?
9. Are there untested integration points?
10. Does this depend on undocumented or unofficial API behavior?

---

## 🔐 Security Risks

1. Does this expand the attack surface (new endpoints, ports, permissions)?
2. Are secrets, credentials, or PII handled securely?
3. Could an attacker abuse this feature (abuse cases, not just use cases)?
4. Does this introduce new dependencies with unknown CVEs?
5. Are authorization checks enforced at the right layer?
6. Is user input validated and sanitized at all entry points?
7. Are audit logs maintained for sensitive operations?

---

## 📦 Operational Risks

1. Is there a tested rollback plan?
2. Does the team have the operational knowledge to run this in production?
3. Are monitoring, alerting, and dashboards in place before go-live?
4. Is the deployment process automated and repeatable?
5. Is there a runbook for the most likely failure modes?
6. Will this require on-call changes or additional staffing?

---

## 💰 Cost & Sustainability Risks

1. Are infrastructure costs validated with load estimates (not just unit costs)?
2. Does this create ongoing maintenance burden with no owner?
3. Are there licensing costs not captured in the proposal?
4. Does this create vendor lock-in that increases switching costs later?
5. Is the team sized to sustain this long-term?

---

## 🧑‍🤝‍🧑 Organizational & Process Risks

1. Does this require cross-team coordination with no formal agreement?
2. Are stakeholders aligned on the definition of success?
3. Is the timeline based on measured estimates or guesses?
4. Does this change who owns a piece of the system without explicit handoff?
5. Will this increase cognitive load or context switching for the team?
6. Is there a dependency on a person (bus factor = 1)?

---

## 🔄 Reversibility & Future-proofing Risks

1. Is this decision easy to reverse if it turns out to be wrong?
2. Does this foreclose better options in the future?
3. Is this being designed for today's scale or tomorrow's scale (over-engineering risk)?
4. Are there assumptions about future requirements that may not hold?

---

## 🏗️ Building Protocol Risks

> Apply this category whenever code is being generated, reviewed, or modified.

1. Are there any identifiers (variables, functions, constants, files, DB columns, endpoints) NOT in `en_US`?
2. Are there hardcoded secrets, API keys, tokens, or credentials anywhere in the code?
3. Are there empty catch blocks (`catch (e) {}`) that silently swallow errors?
4. Are there magic numbers or magic strings that should be named constants?
5. Is all external input validated at the boundary before use?
6. Are there SQL queries built by string concatenation instead of parameterized queries?
7. Are there functions longer than 20 lines or with more than 3 parameters?
8. Are there TODO stubs, commented-out code blocks, or dead code in deliverable output?

---

## 🤖 AI Optimization Risks

> Apply this category when reviewing or generating AI-facing files (`AGENTS.md`, `.ai-context.md`, `SKILL.md`, `.github/copilot-instructions.md`, `CLAUDE.md`, `.cursorrules`, `README.md`, or any file intended to provide context to an AI agent or LLM).

1. Do any always-loaded AI context files exceed 8K tokens (risk of context window saturation or attention degradation)?
2. Are there duplicate or contradictory instructions across multiple AI context files?
3. Do all cross-references (file links, section anchors, `See also` notes) point to files and sections that actually exist?
4. Are there instructions that use undefined terms or vague directives ("follow best practices") with no concrete examples?
5. Is all context loaded simultaneously regardless of relevance (no progressive loading strategy)?
6. Are there instructions that conflict with each other across files (naming conventions, language rules, output format)?
7. Is the most critical information at the **top** of each AI context file, not buried at the end?
8. Do any always-loaded files contain content only needed for specific tasks (unnecessary context budget waste)?

---

## ✅ Using the results

This checklist is an internal sweep — it has no score and never appears in the output.

- Each checked item **with evidence** becomes a candidate risk; items without evidence become *Unverified assumptions* or are dropped.
- Severity comes from the definitions in `SKILL.md` §2, never from how many items were checked.
- A candidate 🔴 Critical moves the analysis to **Tier 3** only when its true severity depends on facts only the user has; otherwise it is reported directly in the Tier 2 report.

---

> 💡 **See also**: [`checklists/questioning-checklist.md`](questioning-checklist.md) — 15-dimension interrogation (correctness, security, performance, reliability, architecture, data, building protocol, AI optimization, and more). Use the questioning checklist for deeper analysis; use this risk checklist for a fast categorical sweep.
