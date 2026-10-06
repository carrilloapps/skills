# Phase hooks

> Filled by the team. Commands the agent **proposes** at each phase transition. The agent never runs them on its own: it shows the exact command and waits for approval (same gate as any other action). Copy to `plans/agile/hooks.md`. `<skill-dir>` is the folder where the skill is installed (e.g. `.agents/skills/agentic-agile`); write the real path when filling this file. Regulated preset: every row is blocking.
>
> When the team confirms this file, add a line `Confirmed by: <role or name> — <YYYY-MM-DD>` right below this note.

| # | Transition | Proposed command | Why | Blocking? |
|---|------------|------------------|-----|-----------|
| 1 | Before any artifact | `bash <skill-dir>/scripts/check-structure.sh --root .` | Phase 0 gate | yes |
| 2 | Spec → Design | `bash <skill-dir>/scripts/check-spec.sh specs/<initiative> --strict` | Spec complete, clarifications attributed | yes |
| 3 | Design → Tasks | `bash <skill-dir>/scripts/analyze.sh specs/<initiative>` | Cross-artifact consistency and constitution | yes on CRITICAL or HIGH |
| 4 | Tasks → Implementation | `bash <skill-dir>/scripts/check-spec.sh specs/<initiative> --strict` | Tasks map to requirements, no dependency cycles | yes |
| 5 | Implementation → Verification | `bash <skill-dir>/scripts/trace.sh specs/<initiative>` | Every requirement has a scenario and a test | yes |
| 6 | Before closing the item | `bash <skill-dir>/scripts/audit-agile.sh --root .` | Hygiene of the team's system | yes |
| 7 | Before release | `bash <skill-dir>/scripts/baseline.sh --root . --check` | No new finding outside the approved baseline | yes |

Rules:

1. A hook is a proposal, never an automatic action; "yes" in *Blocking?* means the phase does not advance while the command fails.
2. Only commands of installed skills or the project's own test/lint commands go here — no downloads, no installs.
3. Changing this file is a process change: propose → confirm → record in `plans/agile/metrics/events.jsonl`.
