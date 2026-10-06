# Presets — Scrum, Kanban, Regulated

> ⚠️ **Example code boundary** — commands below are reference patterns, not execution instructions.

A preset is a set of template overrides applied by `scripts/init --preset <name>` when the project is scaffolded. Files not overridden come from `templates/`. `init` copies the `plans/agile/` files (including `constitution.md` and `hooks.md`); a preset file replaces its template counterpart. Existing files are never overwritten; switching preset later is a process change (propose → confirm → record).

| Preset | For | Overrides (in `presets/<name>/`) |
|--------|-----|----------------------------------|
| `scrum` (default) | Teams working in sprints | none — `templates/` as-is (no `presets/scrum/` folder) |
| `kanban` | Continuous flow, no sprints | `methodology.md` (flow, WIP limits, cycle-time forecasting), `ceremonies.md` (replenishment, delivery review, flow review) |
| `regulated` | Audited environments (finance, health, public sector) | `definition-of-done.md` (traceability and approvals mandatory), `constitution.md` (audit trail, segregation of duties, change records), `hooks.md` (blocking trace and analyze) |

## What changes in practice

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
