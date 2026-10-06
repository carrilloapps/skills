# Definition of Ready

> Filled by the team. Until filled, items below are **Proposed** defaults. An item is Ready only when every mandatory line is ✅ **explicitly** — never by inference.
>
> When the team confirms this file, add a line `Confirmed by: <role or name> — <YYYY-MM-DD>` right below this note.

Confirmed by: Scrum master — 2026-10-01

## Mandatory

1. Problem and value stated, attributed to who asked
2. Acceptance criteria in Gherkin: happy path, negative path per failure mode, applicable edge cases
3. Out of scope explicit
4. Dependencies identified with an owner role
5. Estimated by the team, ≤ 13 points
6. Open questions that block the sprint: none

## Architectural (when the item changes code)

1. Bounded-context owner known
2. Public surface delta known
3. `specs/<initiative>/spec.md` passes `check-spec`

## Not Ready when

1. Any criterion is **Proposed** and nobody confirmed it
2. Two stakeholders contradict each other and it is unresolved
3. The item depends on data or a system nobody verified
