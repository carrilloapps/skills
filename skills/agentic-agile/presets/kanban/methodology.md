# Methodology

> Filled by the team. Until filled, values below are **Proposed** defaults (kanban preset).
>
> When the team confirms this file, add a line `Confirmed by: <role or name> — <YYYY-MM-DD>` right below this note.

## Cadence

1. Sprint length: not applicable — continuous flow
2. Report period: monthly, folder `plans/sprints/<YYYY>-M<NN>/`
3. Replenishment: <e.g. weekly, Monday>

## Flow

| Column | WIP limit | Exit policy |
|--------|-----------|-------------|
| Ready | <limit> | Meets `definition-of-ready.md` |
| In progress | <limit> | Code and tests per `tasks.md` |
| Review | <limit> | Approved per review conventions |
| Done | — | Meets `definition-of-done.md` |

Exceeding a WIP limit is a blocker alert (N3, inform only).

## Estimation

1. Scale: none — forecasting from cycle time (85th percentile) and weekly throughput
2. Split at: items expected to exceed the 85th-percentile cycle time
3. Agent forecasts: from `plans/agile/metrics/events.jsonl`, only after two full months of data

## Working agreements

1. <agreement>

## Transcripts

1. Recording consent announced at the start of every session: <yes/no>
2. Retention of raw transcripts: <e.g. deleted after the draft is refined>
3. Classification: production-sensitive

## Language

See `language.md`.
