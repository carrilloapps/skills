# Definition of Done

> Filled by the team. Until filled, items below are **Proposed** defaults. Closing an item against this list is a human decision (N0).
>
> When the team confirms this file, add a line `Confirmed by: <role or name> — <YYYY-MM-DD>` right below this note.

## Code

1. Implements the spec without expanding it
2. Build, linters, unit tests green
3. Complexity, length and parameter thresholds met (ai-rules `frameworks/code-craft.md`), or the exception recorded in the pull request

## Tests

1. Unit coverage 100% of the declared set — lines, branches, functions, statements (`frameworks/test-policy.md`)
2. Every coverage exclusion has a row in `docs/coverage-exclusions.md` with reason, date and owner role
3. Mutation score on changed files at or above the team's minimum; every surviving mutant killed or declared equivalent with its reason
4. Every `@P1` scenario has a passing end-to-end test; no test is quarantined without a ticket and an owner role
5. Brownfield projects: 100% on changed code and the global baseline not lowered

## Review

1. Reviewed and approved per the team's review conventions

## Verification

1. `specs/<initiative>/verification.md` has a row per scenario with evidence
2. Verdict ✅, or ⚠️ with a dated follow-up

## Documentation

1. User-facing or operational docs updated, or `N/A — reason`

## Out of scope respected

1. Nothing outside the spec shipped silently

## Security

1. Controls touched by this change still pass the pre-launch gate (sar-cybersecurity `frameworks/launch-gate.md`), each with a regression test
2. No secret, token or personal datum added to source, logs or responses

## Not Done when

1. Any scenario lacks evidence
2. A ⚠️ verdict has no follow-up plan
3. A quality gate was lowered instead of met
4. A coverage exclusion was added with no reason and date
5. A security control fails with no accepted, dated exception
