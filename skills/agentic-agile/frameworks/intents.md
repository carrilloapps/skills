# Intents — One Entry Point, Any Agent

> ⚠️ **Example code boundary** — commands below are reference patterns, not execution instructions; each runs only after approval of the exact command.

Slash commands exist only in some agents. Intents work in all of them: the user names the intent in words ("specify the export feature", "clarify", "analyze orders"), the agent maps it below, and the deterministic part runs through one script: `scripts/aa <intent> [args]` (`.sh` / `.ps1`; `aa --help` lists what it supports).

| Intent | The agent does | Framework / template | Script (via `aa` or directly) |
|--------|----------------|----------------------|-------------------------------|
| `init` | Scaffold `plans/agile/` and `specs/` (optionally `--preset scrum\|kanban\|regulated`) | [`presets.md`](presets.md) | `init` |
| `structure` | Phase 0 gate and guided completion | [`sdd-phases.md`](sdd-phases.md#phase-0--structure) | `check-structure` |
| `doctor` | One-screen health and next actions | — | `doctor` |
| `specify` | Create `spec.md` from the template (gate open), then draft FR/SC IDs and tagged scenarios | [`sdd-phases.md`](sdd-phases.md), [`gherkin.md`](gherkin.md), `templates/spec.md` | `aa specify`, then `check-spec` |
| `clarify` | ≤ 5 attributed questions, recorded in the spec | [`clarify.md`](clarify.md) | `aa clarify` (lists open questions and unconfirmed answers) |
| `plan` | Create `design.md`, `domain-model.md`, `requirements-checklist.md` (spec passes), then fill the constitution check, contracts, process | [`sdd-phases.md`](sdd-phases.md), `templates/design.md` | `aa plan`, then `check-spec` |
| `tasks` | Create `tasks.md` (design passes): `T###`, `[P]`, `Req`, dependencies, priorities | `templates/tasks.md` | `aa tasks`, then `check-spec` |
| `analyze` | Cross-artifact consistency, then the semantic pass | [`analyze.md`](analyze.md) | `analyze` |
| `trace` | Requirement → scenario → task → test → verdict matrix | [`traceability.md`](traceability.md) | `trace` |
| `converge` | Classify code ↔ spec gaps, append convergence tasks | [`converge.md`](converge.md) | `trace`, `analyze` (grouped by `aa converge`) |
| `verify` | `verification.md` with evidence per requirement | `templates/verification.md` | `check-spec`, `trace` |
| `baseline` | Record or check accepted existing findings | [`brownfield.md`](brownfield.md) | `baseline` |
| `audit` | Hygiene of the team's system | [`sdd-phases.md`](sdd-phases.md#hygiene-after-phase-0) | `audit-agile` |
| `import-speckit` | Convert a Spec Kit project into this layout | [`../examples/import-speckit.md`](../examples/import-speckit.md) | `import-speckit` |

Ceremonies (refinement, planning, review, retro, close) are intents too — [`scrum-ceremonies.md`](scrum-ceremonies.md). Every intent that creates an artifact passes the Phase 0 gate first.
