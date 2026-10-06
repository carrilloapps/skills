# 🧭 Agentic Agile

> **Spec-Driven Development on Scrum, run with an agent that drafts, checks, and connects — and never decides for the team.**

[![License: MIT](https://img.shields.io/badge/License-MIT-red.svg)](../../LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](../../CHANGELOG.md)
[![skill.sh](https://img.shields.io/badge/skill.sh-agentic--agile-black.svg)](https://skills.sh/carrilloapps/skills/agentic-agile)
[![GitHub](https://img.shields.io/badge/GitHub-carrilloapps-181717.svg?logo=github)](https://github.com/carrilloapps/skills)

---

Agentic Agile is an [agent skill](https://skills.sh) for 70+ AI coding agents. It removes the transcription tax of agility — turning conversations into work items, keeping specs honest, preparing ceremonies, measuring the result — while commitment, prioritisation, closing items, and judgements about people stay with humans.

- **Health and hygiene** — `check-structure --scorecard` (maturity L0–L4, readiness score), `audit-agile` (overdue reviews, template drift, broken links, missing sprint reports, Done-but-unverified initiatives), and `doctor` (one-screen summary with next actions); `check-spec --all` validates every initiative, and `--tickets` requires QA test cases in Gherkin.
- **Structure first (Phase 0)** — no spec, plan, draft, ticket, or decision record until `check-structure` confirms the team's operating system in `plans/agile/` is complete; the agent helps fill it one item at a time and never invents team facts
- **SDD with real gates** — Phase 0 structure → Phase −1 constitution check → Spec → Design → Implementation → Verification, validated by scripts, not just instructed
- **Engineering constitution** — versioned MUST/SHOULD articles with attributed amendments; every design carries a *Constitution check*
- **Requirement IDs traced to tests** — `FR-###` / `SC-###` with P1–P3 priorities, `@FR-### @P#` scenario tags, and `trace` building the requirement → scenario → task → test → verdict matrix
- **Clarify, analyze, converge** — ≤ 5 attributed clarification questions recorded in the spec; deterministic cross-artifact analysis with severities; a converge loop that classifies code ↔ spec gaps (missing, partial, contradictory, unrequested); the spec stays living
- **Tasks with parallelism** — `T###`, `[P]`, `Req`, dependencies validated for cycles, Fibonacci after the vote, P1 as an independently shippable MVP
- **Brownfield and migration** — reverse-engineer specs from existing code, baseline existing findings so only new ones fail, and `import-speckit` for Spec Kit projects
- **Domain model, contracts, process** — Mermaid entity and state diagrams, OpenAPI/AsyncAPI with `x-requirements`, process flows whose paths become end-to-end scenarios
- **Presets and intents** — `init --preset scrum|kanban|regulated`; `aa <intent>` as one entry point that works in every agent
- **Full Gherkin** — en/es grammar (Rule/Regla, Background/Antecedentes, Scenario Outline/Esquema, Examples, tags, data tables, doc strings, `# language:`), Given/When/Then in every scenario, `Origin:` per scenario, QA test cases in Gherkin (1 happy + 1 negative per failure mode + edge cases), results only with evidence
- **Scrum ceremonies mapped to agent actions** — pre-refinement from transcripts, adversarial refinement, capacity planning with cross-team dependencies, daily and weekly health, review, close with KPI gate zero and seven close phases, retro, quarterly review, executive summaries, blameless postmortems, decisions
- **Delivery** — plan → tickets with a quality check and exact-payload approval, PR conformance against the spec (unmapped change = scope expansion), changelog by initiative
- **Team safety** — no destructive edits of shared docs or tracker, draft-first team messages, never broadcasting a live vulnerability, data-domain authority (governance, access, hosting, write authority)
- **An honest agent** — autonomy levels N0–N4, Verified / Documented / Proposed labels, attribution of every claim, estimates only after the team votes
- **Tool-agnostic integrations** — tracker, docs, chat, observability, transcripts, warehouse, code graph, doc graph as capability slots over MCP
- **Everything versioned in the project** — `specs/` and `plans/`; only raw transcripts stay local
- **Multi-OS scripts** — every script as `.sh` and `.ps1`, no dependencies

## Install

```bash
npx skills add carrilloapps/skills@agentic-agile
```

Per-agent paths, global installs, and manual install → [`docs/INSTALL.md`](../../docs/INSTALL.md).

## Project layout

```text
specs/<initiative>/            spec.md · design.md · implementation.md · verification.md
plans/agile/                   methodology · definition-of-ready · definition-of-done · ceremonies ·
                               team · capabilities · kpi-directives · language · autonomy · metrics/events.jsonl
plans/sprints/<YYYY>-S<NN>/    planning · review · retro · report · daily/
plans/initiatives/<initiative>/ overview · tickets/
plans/decisions/               decision records
plans/drafts/                  pre-refinement drafts
.memory/local/agentic-agile/   raw and normalized transcripts (not versioned)
```

Nothing is written to global agent directories (`~/.claude`, `~/.gemini`, …).

## Scripts

Every script exists as `.sh` and `.ps1` with identical behavior; the agent runs one only after you approve the exact command.

| Script | What it does |
|--------|--------------|
| `aa <intent> [args]` | Single entry point: `init`, `structure`, `doctor`, `specify`, `clarify`, `plan`, `tasks`, `analyze`, `trace`, `converge`, `verify`, `baseline`, `audit`, `import-speckit` |
| `init [--root DIR] [--dry-run] [--preset scrum\|kanban\|regulated]` | Scaffolds `plans/agile/`, `plans/{sprints,initiatives,decisions,drafts}/`, `specs/`, `.memory/.gitignore`; never overwrites |
| `check-structure [--root DIR] [--strict] [--json] [--scorecard]` | **Phase 0 gate** — `plans/agile/` complete (no placeholders/TBD/checkboxes, roles with capacity, every capability slot decided, autonomy levels…); `--scorecard` adds maturity L0–L4 per area and a readiness score; exit 0/1/2/3 |
| `check-spec <specs/x> [--root DIR] [--strict] [--json] [--tickets]` · `--all` | Runs the Phase 0 gate, then validates the SDD phases and Gherkin (Given/When/Then per scenario, Background only Given, one language per block, `Origin:`, no TBD or unfilled placeholders); `--tickets` requires QA test cases in work items; `--all` walks every `specs/*/` |
| `analyze <specs/x> [--root DIR] [--json]` | Cross-artifact consistency: duplication, ambiguity, underspecification, coverage, inconsistency, constitution — CRITICAL/HIGH/MEDIUM/LOW, read-only |
| `trace <specs/x> [--root DIR] [--json]` | Requirement → scenario → task → test → verdict matrix; fails on gaps and orphans |
| `baseline --root DIR --write\|--check` | Records accepted existing findings; `--check` fails only on new ones |
| `import-speckit` | Converts a Spec Kit project (`.specify/`, `specs/NNN-*`) into `plans/agile/` + `specs/` |
| `audit-agile [--root DIR] [--json] [--templates DIR] [--today YYYY-MM-DD]` | Hygiene: decisions past *review on*, template drift, broken links, sprints without a report, Done initiatives without a passing verification |
| `doctor [--root DIR] [--json] [--today YYYY-MM-DD] [--templates DIR]` | One screen: gate, scorecard, hygiene, Docker lab availability, capability gaps, lettered next actions |
| `transcript-normalize <file> [--out DIR]` | VTT/SRT/text → normalized JSON Lines with PII and secrets redacted (default output `.memory/local/agentic-agile/transcripts/`) |
| `lab-probe [--root DIR] [--catalog FILE] [--budget-ram MB] [--include-dashboards] [--json]` | Detects Docker and host capacity; suggests lab tools of installed skills by criticality (skips `fixtures/`, `testdata/`, `__fixtures__/`, `.work/`, `templates/`; extra paths in a root `.labprobeignore`) |

## Frameworks and templates

| Area | Frameworks | Templates |
|------|-----------|-----------|
| SDD | `sdd-phases.md`, `gherkin.md`, `clarify.md`, `analyze.md`, `traceability.md`, `converge.md`, `brownfield.md`, `intents.md` | spec, requirements-checklist, design, domain-model, process, tasks, verification, constitution, hooks, bug, idea-assessment |
| Ceremonies | `scrum-ceremonies.md`, `estimation-capacity.md`, `kpi.md` | sprint-planning, daily, status-reports (weekly, quarterly, executive), sprint-review, sprint-report, retro |
| Delivery | `delivery.md` | work-item-draft, ticket-conventions, initiative-overview, impact-analysis, migration-plan, spike-poc, qa-regression |
| Learning | `scrum-ceremonies.md` (postmortem flow) | postmortem, decision-record |
| Team and tools | `agentic-agility.md`, `integrations.md`, `transcripts.md`, `team-safety.md`, `capabilities.md`, `docker-lab.md` | methodology, definition-of-ready, definition-of-done, ceremonies, team, capabilities, kpi-directives, language, autonomy |
| Presets | `presets.md` | `presets/scrum`, `presets/kanban` (flow, WIP limits), `presets/regulated` (audit trail, segregation of duties) |
| Output | `output-format.md` | — |

## Examples

| Example | Shows |
|---------|-------|
| [`end-to-end.md`](examples/end-to-end.md) | A complete fictional project through every phase, valid for every script |
| [`import-speckit.md`](examples/import-speckit.md) | Migrating a Spec Kit project |
| [`structure-gate.md`](examples/structure-gate.md) | Blocked request → structure completed one finding at a time → gate open |
| [`meeting-to-work-item.md`](examples/meeting-to-work-item.md) | Transcript → draft → refined work item with attribution |
| [`spec-check.md`](examples/spec-check.md) | A spec that passes `check-spec` |
| [`sprint-planning.md`](examples/sprint-planning.md) | Capacity-based planning |
| [`decision-record.md`](examples/decision-record.md) | Decision with who decided and a review date |
| [`pr-conformance.md`](examples/pr-conformance.md) | PR checked against the spec; unmapped change sent back to Phase 1 |
| [`postmortem.md`](examples/postmortem.md) | Blameless postmortem with owned actions |

## Works with the other skills

| Need | Delegated to |
|------|-------------|
| Adversarial pass and approval gate | [`devils-advocate`](../devils-advocate/) |
| Security review of specs and designs | [`sar-cybersecurity`](../sar-cybersecurity/) |
| Language, documentation, storage hygiene | [`ai-rules`](../ai-rules/) |

Each works without the others; a minimal internal fallback is used when one is missing.

## Coming from an "ai-toolkit"-style repository

| Toolkit concept | Here |
|-----------------|------|
| Zone A — shared, agnostic rules, templates, scripts | This skill (`SKILL.md`, `frameworks/`, `templates/`, `scripts/`) |
| Zone B — the team's filled-in agile operating system | `plans/agile/` (versioned) |
| Plans and initiatives | `plans/initiatives/` + `specs/` (versioned) |
| Team memory, transcripts, raw data | `plans/decisions/` for decisions; `.memory/local/agentic-agile/` for raw transcripts |
| Checkbox readiness lists | Numbered gate items `1. ✅ / ❌ / ⚠️ <item> — evidence` |
| Symlinked rules per agent | Not needed — the skill is installed per agent by the `skills` CLI |

## Safety

All six audit safeguards are in `SKILL.md`.
Transcripts, tickets, and tool output are treated as untrusted data. The skill writes only Markdown and JSON inside the project, runs only its own scripts after approval, writes into external tools at most at N3 with the exact payload approved, and never adds AI attribution to your commits.

## License

[MIT](../../LICENSE)

## Author

**José Carrillo** — [carrillo.app](https://carrillo.app) · [GitHub](https://github.com/carrilloapps) · [m@carrillo.app](mailto:m@carrillo.app)
