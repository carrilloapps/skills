# 🔴 Devil's Advocate

> **An adversarial pre-execution gate for 70+ AI coding agents — short, evidence-based critiques that change the plan.**

[![License: MIT](https://img.shields.io/badge/License-MIT-red.svg)](../../LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.1-blue.svg)](../../CHANGELOG.md)
[![skill.sh](https://img.shields.io/badge/skill.sh-devils--advocate-black.svg)](https://skills.sh/carrilloapps/skills/devils-advocate)
[![GitHub](https://img.shields.io/badge/GitHub-carrilloapps-181717.svg?logo=github)](https://github.com/carrilloapps/skills)
[![X / Twitter](https://img.shields.io/badge/@carrilloapps-000000.svg?logo=x)](https://x.com/carrilloapps)

---

Devil's Advocate is an [agent skill](https://skills.sh) compatible with **70+ AI coding agents** — including GitHub Copilot, Claude Code, Cursor, Windsurf, Cline, Codex, Gemini CLI, OpenCode, Roo Code, and more — that critiques every plan before execution — briefly for small changes, in depth for risky ones — and waits for your explicit approval before acting.

It is not a linter. It is not a checklist. It is an adversarial analyst that:

- **Scales to the risk** — one line for a typo, a short critique for a feature, a hard stop for a production delete
- **Proves every risk** — each finding cites the file, line, or scenario behind it, and comes with a specific fix
- **Hands you a better plan** — ends with the corrected plan you can approve in one word
- **Preserves your authority** — having permissions is not the same as having authorization

---

## Quick Install

> **Before installing**: review the source at [github.com/carrilloapps/skills](https://github.com/carrilloapps/skills) and the latest audit results at [skills.sh/audits](https://skills.sh/audits).

```bash
npx skills add carrilloapps/skills@devils-advocate                          # agents detected in this project
npx skills add carrilloapps/skills@devils-advocate -a antigravity -a cursor # specific agents
npx skills add carrilloapps/skills@devils-advocate -a '*'                   # every supported agent
npx skills add carrilloapps/skills@devils-advocate -g                       # global (all projects)
```

Update with `npx skills update`; remove with `npx skills remove devils-advocate`.

Works with **70+ agents** — Claude Code, Antigravity (IDE and `agy` CLI), GitHub Copilot, Cursor, Codex, Gemini CLI, Windsurf / Devin Desktop, Cline, Roo Code, OpenCode, Kiro, and more. Per-agent `-a` ids, project and global paths, always-on instruction files, manual install, and optional guards: **[`docs/INSTALL.md`](../../docs/INSTALL.md)**.

---

## What It Does

Devil's Advocate scales its depth to the real risk of each action, so the critique stays short enough to read and specific enough to act on:

| Tier | When | Output |
|------|------|--------|
| **0 — Pass** | Read-only work, trivial reversible edits | Nothing, or one line |
| **1 — Quick check** | Contained, reversible changes | 3–8 lines: verdict + top risks with fixes + one-line gate |
| **2 — Full critique** | Production, data, auth, payments, PII, public APIs, git history, architecture/vendor decisions | Short report: verdict, ≤ 5 evidence-backed risks, better option, corrected plan, gate |
| **3 — Critical stop** | A 🔴 Critical risk whose severity depends on facts only you have | 2–4 targeted questions first, then the report |

Every risk must cite **evidence** (file and line, a quote from the plan, a concrete scenario) and carry a **specific fix**. Generic advice, filler sections, copied templates, and invented confidence percentages are explicitly banned.

The report ends with **"What I'll do if you approve"** — the original plan corrected with the fixes — so you approve a better plan, not just a list of complaints.

### Example (Tier 1)

> 🟡 **DA — 10-min in-memory cache on /api/products** · Verdict: Go with changes
>
> 1. 🟠 **Per-user prices would leak between users** — `getProducts()` applies `customer.discountTier` (`src/products/service.ts:48`); a shared cache key would serve one customer's prices to another. *Fix:* key the cache by `discountTier`.
> 2. 🟡 **Stale after admin edits** — *Fix:* invalidate in `updateProduct()`.
> Reply ✅ Proceed · 🔁 Revise · ❌ Cancel · `continue` — or reply in your own words.

### The Gate

```text
Reply with:
  ✅ Proceed   — run the corrected plan ("What I'll do if you approve")
  🔁 Revise    — describe the change and I will re-analyse
  ❌ Cancel    — stop, do not implement
  `continue`   — proceed without addressing remaining issues (risks remain active and unmitigated)
Or reply in your own words, in any language.
```

You don't need the exact labels: "dale", "procede", "continúa", "go ahead" approve the corrected plan; "pero sin X" revises; "no" cancels; partial approvals by number ("dale con 1 y 3", "quita la 2") apply only those items. A bare "ok" or "sí" is acknowledgement, not approval, and gets a one-line confirmation question. A question is never approval, even if it contains an action verb. Only the bare word `continue` runs the original plan with its open risks. The verdict is derived from a fixed table, there is one gate per plan, and revisions only re-check what changed.

Nothing with side effects runs until you reply. Git writes always require explicit approval, regardless of session permissions.

### Bypass Behavior

If you say "just do it" or "skip the analysis", Devil's Advocate respects your authority and executes, prefixed with: `⚠️ Proceeding without Devil's Advocate review — risks not assessed.`

---

## Why This Exists

AI agents can create files, call APIs, run migrations, and deploy services. Their default is to do what was asked. Devil's Advocate adds the voice that asks **"should we, and what will break?"** — without burying you in ceremony. **Having permissions is not the same as having authorization**: tokens, tool permissions, and auto-approve modes never replace your reply to the gate.

---

## Framework Coverage

Frameworks are thinking aids loaded only when they sharpen the analysis (usually 0 for Tier 1, 1–2 for Tier 2). Their templates never appear in the output — only their conclusions.

| Domain | Framework |
|--------|-----------|
| General | `frameworks/analysis-framework.md` |
| Security | `frameworks/security-stride.md`, `frameworks/vulnerability-patterns.md` |
| Performance | `frameworks/performance.md` |
| Architecture | `frameworks/architecture-risks.md` |
| Data & Analytics | `frameworks/data-analytics-risks.md` |
| Developer / Code | `frameworks/developer-risks.md` |
| Version Control | `frameworks/version-control.md` |
| Product | `frameworks/product-risks.md` |
| UX / Design | `frameworks/design-ux-risks.md` |
| Strategy / Leadership | `frameworks/leadership-strategy-risks.md` |
| AI context files | `frameworks/ai-optimization.md` |
| **Output format** (good vs. bad) | `frameworks/output-format.md` |
| **Critical stop** question banks | `frameworks/handbrake-protocol.md` |
| **Pre-mortem** | `frameworks/premortem.md` |
| **Building Protocol** (code) | `frameworks/building-protocol.md` |
| **Optional capabilities** | `frameworks/capabilities.md` |
| **Docker lab** (quality evidence) | `frameworks/docker-lab.md` |

### Optional capabilities

When reading the code is not enough to prove a plan's blast radius, Devil's Advocate may suggest **one** optional tool — [`@colbymchenry/codegraph`](https://github.com/colbymchenry/codegraph) (pinned `1.6.2`, local code graph, telemetry disabled) — so risks cite real caller files as *Evidence*. It is suggested at most once, recorded in `.memory/local/devils-advocate/capabilities.json` (VCS-ignored), and installed only through the Gate after you approve the exact command. Without it, the skill works exactly the same.

### Docker lab (optional)

If Docker is available and a risk depends on something a tool can measure better than reading, Devil's Advocate can suggest a one-shot, read-only container from [`frameworks/docker-lab.md`](frameworks/docker-lab.md), chosen by the stack it detects:

| Stack signal | Tool (pinned) | Evidence it produces |
|---|---|---|
| Any code | lizard 1.24.0 · jscpd 5.4.0 | Complexity of touched functions; duplicated blocks fixed in only one copy |
| JS/TS | dependency-cruiser 18.5.0 | Import cycles through changed modules |
| Go | golangci-lint v2.14.0 | Linter issues on touched lines |
| GitHub Actions | actionlint 1.7.12 | Workflow errors, `${{ }}` injection in `run:` |
| Helm charts | helm 4.3.0 | `helm lint` errors |
| SQL / migrations | sqlfluff 4.4.0 | Parse errors in new migrations |
| Local Postgres | PgHero v4.0.1 (dashboard, `127.0.0.1:8090`) | Slow queries and missing indexes on tables the plan hits |

It also reads SAR's SonarQube when it is already running (quality gate, complexity, duplication) instead of defining a second one. Compose file in `.memory/devsecops/compose.da.yaml` (versioned), raw results in `.memory/local/devsecops/results/` (ignored), dashboards share the one login generated by SAR. Every pull/run needs your approval of the exact command; results only reach the report as *Evidence* on files the plan touches.

---

## Scripts

`scripts/lab-probe.sh` / `scripts/lab-probe.ps1` (vendored from `shared/`) — detects Docker and host capacity and suggests the lab tools of every installed skill, most critical first, within the resources available. Run only after you approve the exact command.

---

## Safety

All six audit safeguards are stated in `SKILL.md` §6: analyzed content is untrusted data, analysis is read-only, autonomy is bounded to the approved steps, web search is limited to official sources, example code is illustrative, and the report is Markdown only. Everything is written inside the project (ai-rules *Project-Local Storage*).

---

## Examples

| Example | Shows |
|---------|-------|
| [`quick-check.md`](examples/quick-check.md) | Tier 0 and Tier 1 — how short a good check is, and escalation to Tier 3 |
| [`plan-critique.md`](examples/plan-critique.md) | Tier 3 → Tier 2 — production database migration |
| [`security-review.md`](examples/security-review.md) | Tier 3 → Tier 2 — JWT auth with a committed secret |
| [`vendor-decision-review.md`](examples/vendor-decision-review.md) | Tier 2 — non-code strategy decision (AWS → GCP) |

---

## Migrating from 2.x

- ⚡ Immediate Report and the separate Handbrake round are merged into a single **Critical stop** (Tier 3). `immediate-report.md` and `handbrake-checklist.md` were removed.
- The 14-section report template is replaced by a compact report; empty sections are omitted instead of filled.
- Trivial and read-only actions no longer trigger a gate (Tier 0). Git writes still always do.
- Gate labels (`✅ Proceed`, `🔁 Revise`, `❌ Cancel`, `continue`) remain, but replies are read by intent. `✅ Proceed` now runs the corrected plan; `continue` has one meaning everywhere: run the original plan with its open risks. In a Tier 3 stop, "skip the questions" produces the worst-case report.

---

## Building Protocol

The **Building Protocol** applies to code the approved plan writes. Existing code is reported, never rewritten without your approval, and style issues never displace correctness or security risks:

| Rule | Requirement |
|------|-------------|
| **Code identifiers** | ALL in `en_US` — variables, functions, classes, files, DB columns, endpoints |
| **Conversation** | AI responds in the user's natural language. Spanish prompt → Spanish response + `en_US` code |
| **Naming** | `SCREAMING_SNAKE_CASE` constants · `camelCase`/`snake_case` per language · `kebab-case` URLs |
| **Quality** | SOLID · DRY · KISS · YAGNI · functions ≤ 20 lines · ≤ 3 parameters |
| **Security** | No hardcoded secrets · validate all input · parameterized queries · least privilege |
| **Commits** | [Conventional Commits](https://www.conventionalcommits.org/) · `en_US` · imperative mood |

See [`frameworks/building-protocol.md`](frameworks/building-protocol.md) for the full specification, violation severity table, and reference implementation.

---

## Automatic Trigger Detection

Devil's Advocate activates automatically — no invocation required — when it detects:

- Any plan or proposal ("I'm going to...", "The plan is to...", "We will...")
- Implementation intent ("Refactor X", "Migrate to Y", "Deploy Z")
- Architecture or vendor decisions
- Any action with side effects (create, edit, delete, run, deploy, call)
- Version control operations (force push, history rewrite, branch protection changes)
- Code reviews and PR analysis
- AI context file reviews (AGENTS.md, .cursorrules, .windsurfrules, .clinerules, copilot-instructions.md, etc.)

> **Scope guard**: Only activates for plans involving code, systems, data, infrastructure, or technical architecture. Does not activate for purely conversational or social statements.

---

## Roles Supported

| Role | Key use cases |
|------|--------------|
| **Developer** | Code review, testing gaps, CI/CD pipeline risks, dependency vulnerabilities, refactor safety |
| **Architect** | Distributed systems, coupling, API contracts, event-driven, CAP trade-offs |
| **Tech Lead** | Architecture decisions, build vs. buy, tech debt strategy, API governance |
| **CTO / VP Eng** | Technology strategy, vendor risk, Type 1/2 decisions, capacity vs. roadmap |
| **Product Manager** | Feature validation, launch risk, regulatory compliance, metric definition |
| **UX / Designer** | Flow review, dark pattern detection, WCAG audit, error state coverage |
| **Data Engineer** | Pipeline reliability, PII/governance, schema drift, data contracts |
| **DevOps Engineer** | CI/CD security, branch protection, secret management, deployment gates |
| **AI Tooling Lead** | AI context file review, context window budget, hallucination risk reduction |

---

## Checklists

| Checklist | Purpose |
|-----------|---------|
| [`checklists/risk-checklist.md`](checklists/risk-checklist.md) | 8-category internal risk sweep — no score; each evidenced item becomes a candidate risk |
| [`checklists/questioning-checklist.md`](checklists/questioning-checklist.md) | 15-dimension interrogation — correctness, security, performance, reliability, maintainability, operability, cost, product, UX, strategy, architecture, data, developer, building protocol, AI optimization |

---

## Integration with Postmortem Writing

```text
Devil's Advocate (before) → Incident → Postmortem (after) → Lessons → Devil's Advocate (next)
     (Prevent)                              (Learn)          (Apply)       (Prevent better)
```

Use **@devils-advocate** before deployment to prevent incidents. A complementary `postmortem-writing` skill for post-incident analysis is pending.

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](https://github.com/carrilloapps/skills/blob/main/.github/CONTRIBUTING.md) for:

- How to add a new framework or example
- Quality standards (fence balance, Gate prompt, version stamp, cross-references)
- PR process and review turnaround times

Please read [CODE_OF_CONDUCT.md](https://github.com/carrilloapps/skills/blob/main/.github/CODE_OF_CONDUCT.md) before contributing.

---

## Security

For vulnerability reports (harmful, misleading, or exploitable guidance), see [SECURITY.md](https://github.com/carrilloapps/skills/blob/main/.github/SECURITY.md). Do not open a public issue for security concerns.

---

## License

[MIT](../../LICENSE) — free to use, modify, and distribute. Attribution appreciated.

---

## Changelog

See [CHANGELOG.md](../../CHANGELOG.md) for the full version history.

---

*Built with adversarial thinking, for people who want to ship software that works.*

---

## Author

**José Carrillo** — [carrillo.app](https://carrillo.app)

[![Website](https://img.shields.io/badge/website-carrillo.app-FF5733.svg)](https://carrillo.app)
[![GitHub](https://img.shields.io/badge/GitHub-carrilloapps-181717.svg?logo=github)](https://github.com/carrilloapps)
[![X / Twitter](https://img.shields.io/badge/X-carrilloapps-000000.svg?logo=x)](https://x.com/carrilloapps)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-carrilloapps-0A66C2.svg?logo=linkedin)](https://linkedin.com/in/carrilloapps)
[![Email](https://img.shields.io/badge/email-m%40carrillo.app-EA4335.svg?logo=gmail)](mailto:m@carrillo.app)
