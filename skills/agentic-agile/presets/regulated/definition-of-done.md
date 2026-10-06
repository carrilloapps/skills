# Definition of Done

> Filled by the team. Until filled, items below are **Proposed** defaults (regulated preset). Closing an item against this list is a human decision (N0).
>
> When the team confirms this file, add a line `Confirmed by: <role or name> — <YYYY-MM-DD>` right below this note.

## Code

1. Implements the spec without expanding it
2. Build, linters, unit tests green
3. Every test that verifies a requirement references its `FR-###`

## Review

1. Reviewed and approved per the team's review conventions
2. Approver is a different person from the author (segregation of duties)

## Verification

1. `specs/<initiative>/verification.md` has a row per scenario with reproducible evidence (timestamp, artifact, commit)
2. `trace` reports every FR/SC covered by a scenario, a task, and a passing test
3. Verdict ✅; a ⚠️ needs a dated follow-up **and** a decision record naming who accepted the risk

## Documentation

1. User-facing or operational docs updated, or `N/A — reason`
2. Change record written in `plans/decisions/` for every scope change or constitution exception

## Out of scope respected

1. Nothing outside the spec shipped silently
2. `analyze` reports no CRITICAL or HIGH finding outside the baseline

## Not Done when

1. Any scenario lacks reproducible evidence
2. Any requirement is untraced to a passing test
3. The author approved their own change
