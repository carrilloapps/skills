# <Work item title — outcome, not task>

**Type**: Story | Defect | Improvement · **Initiative**: `<initiative-kebab>` · **Epic**: <epic or none>
**Requirements**: <FR-###, FR-### from `specs/<initiative-kebab>/spec.md`> · **Priority**: P1 | P2 | P3 · **Tasks**: <T### from `tasks.md`, or none yet>
**Origin**: <transcript file + date | thread link | notes> · **Drafted by**: agent (N2) · **Date**: <YYYY-MM-DD>

## Description

<What and why, each claim attributed: "<claim>" — <speaker> @ <time> | no attribution available.>

## Scope

1. <in scope>

## Out of scope

1. <explicitly excluded>

## Acceptance criteria

```gherkin
# language: <en | es>
@<initiative-kebab> @FR-<###> @P<1|2|3>
Scenario: <outcome>
  # Origin: <speaker> @ <time> | Proposed
  Given <state>
    | <column> | <column> |
    | <value>  | <value>  |
  When <action>
  Then <observable outcome>
```

## QA test cases

```gherkin
# language: <en | es>
@qa @negative @FR-<###>
Scenario: <negative / edge case>
  # Origin: Proposed
  Given <state>
  When <action>
  Then <observable outcome>
```

Minimum: one happy path, one negative per failure mode, and the applicable edge cases. Edge categories not applicable: <category — reason>

## Metrics

<How success will be observed after release — or "none stated".>

## Dependencies & risks

| # | Item | Owner (role) | State |
|---|------|--------------|-------|

## Tasks

| # | Task | Points (after the vote) |
|---|------|-------------------------|

## Estimate

Withheld until the team votes. Sealed suggestion: <stored, revealed after the vote>.

## Readiness (from `plans/agile/definition-of-ready.md`)

1. ❌ / ✅ / ⚠️ <item> — <evidence, only if explicit in the source>

## Open questions

| # | Question | For | Blocks sprint |
|---|----------|-----|---------------|

## Adversarial pass

1. Assumptions treated as settled: <…>
2. Contradictions with the current system: <…>
3. Ambiguous scope words: <…>
4. Missing roles or areas: <…>
5. What is recorded if the flow fails: <…>
6. Other: <…>

---
**Epistemic state**: <Verified / Documented / Proposed per section>
**Nothing was written to the tracker.**
