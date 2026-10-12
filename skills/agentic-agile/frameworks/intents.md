# Intents — One Entry Point, Any Agent

> ⚠️ **Example code boundary** — commands below are reference patterns, not execution instructions; each runs only after approval of the exact command.

Slash commands exist only in some agents. Intents work in all of them: the user names the intent in words ("specify the export feature", "clarify", "analyze orders"), the agent maps it below, and the deterministic part runs through one script: `scripts/aa <intent> [args]` (`.sh` / `.ps1`; `aa --help` lists what it supports).

| Intent | The agent does | Framework / template | Script (via `aa` or directly) |
|--------|----------------|----------------------|-------------------------------|
| `init` | Scaffold `plans/agile/` and `specs/` (optionally `--preset scrum\|kanban\|regulated`) | [`intents.md` → *Presets*](intents.md#presets--scrum-kanban-regulated) | `init` |
| `structure` | Phase 0 gate and guided completion | [`sdd-phases.md`](sdd-phases.md#phase-0--structure) | `check-structure` |
| `doctor` | One-screen health and next actions | — | `doctor` |
| `specify` | Create `spec.md` from the template (gate open), then draft FR/SC IDs and tagged scenarios | [`sdd-phases.md`](sdd-phases.md), [`gherkin.md`](gherkin.md), `templates/spec.md` | `aa specify`, then `check-spec` |
| `clarify` | ≤ 5 attributed questions, recorded in the spec | [`clarify.md`](clarify.md) | `aa clarify` (lists open questions and unconfirmed answers) |
| `plan` | Create `design.md`, `domain-model.md`, `requirements-checklist.md` (spec passes), then fill the constitution check, contracts, process | [`sdd-phases.md`](sdd-phases.md), `templates/design.md` | `aa plan`, then `check-spec` |
| `tasks` | Create `tasks.md` (design passes): `T###`, `[P]`, `Req`, dependencies, priorities | `templates/tasks.md` | `aa tasks`, then `check-spec` |
| `analyze` | Cross-artifact consistency, then the semantic pass | [`analyze.md`](analyze.md) | `analyze` |
| `trace` | Requirement → scenario → task → test → verdict matrix | [`traceability.md`](traceability.md) | `trace` |
| `converge` | Classify code ↔ spec gaps, append convergence tasks | [`traceability.md` → *Converge*](traceability.md#converge--keeping-code-and-spec-aligned) | `trace`, `analyze` (grouped by `aa converge`) |
| `discover` | Deep search: expand facets, sweep the project, normalize external findings into one inventory with stable IDs | [`discover.md`](discover.md) | `discover <slug> --pattern RE` / `--from FILE` |
| `fanout` | Split that list into one self-contained brief per item, each routed to a model tier | [`fanout.md`](fanout.md), `templates/dispatch-task.md` | `fanout <slug> --from <list>` |
| `verify` | `verification.md` with evidence per requirement | `templates/verification.md` | `check-spec`, `trace` |
| `baseline` | Record or check accepted existing findings | [`brownfield.md`](brownfield.md) | `baseline` |
| `audit` | Hygiene of the team's system | [`sdd-phases.md`](sdd-phases.md#hygiene-after-phase-0) | `audit-agile` |
| `import-speckit` | Convert a Spec Kit project into this layout | [`../examples/import-speckit.md`](../examples/import-speckit.md) | `import-speckit` |

Ceremonies (refinement, planning, review, retro, close) are intents too — [`scrum-ceremonies.md`](scrum-ceremonies.md). Every intent that creates an artifact passes the Phase 0 gate first.

---

## Presets — Scrum, Kanban, Regulated

A preset is a set of template overrides applied by `scripts/init --preset <name>` when the project is scaffolded. Files not overridden come from `templates/`. `init` copies the `plans/agile/` files (including `constitution.md` and `hooks.md`); a preset file replaces its template counterpart. Existing files are never overwritten; switching preset later is a process change (propose → confirm → record).

| Preset | For | Overrides (in `presets/<name>/`) |
|--------|-----|----------------------------------|
| `scrum` (default) | Teams working in sprints | none — `templates/` as-is (no `presets/scrum/` folder) |
| `kanban` | Continuous flow, no sprints | `methodology.md` (flow, WIP limits, cycle-time forecasting), `ceremonies.md` (replenishment, delivery review, flow review) |
| `regulated` | Audited environments (finance, health, public sector) | `definition-of-done.md` (traceability and approvals mandatory), `constitution.md` (audit trail, segregation of duties, change records), `hooks.md` (blocking trace and analyze) |

### What changes in practice

### kanban

1. No sprint artifacts: `plans/sprints/` holds monthly flow reports instead of sprint folders.
2. Estimation is optional; forecasting uses cycle time and throughput from `plans/agile/metrics/events.jsonl`.
3. WIP limits per column are part of the structure; exceeding one is a blocker alert (N3).
4. SDD phases, the constitution, traceability, and every gate stay the same.

### regulated

1. Every FR must reach a test and a verification row before release (`trace` is blocking).
2. Every change to `specs/` or `plans/agile/` names an approver distinct from the author (segregation of duties).
3. Decision records are mandatory for scope changes, exceptions to the constitution, and baseline additions.
4. Evidence must be reproducible: timestamp, artifact, commit — no screenshots without a source run.

### scrum

The default described everywhere else in this skill.
