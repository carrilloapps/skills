# Spec: <Initiative title>

**Initiative**: `<initiative-kebab>` · **Phase**: 1 — Spec · **Status**: Draft | In review | Approved
**Plan**: [`plans/initiatives/<initiative-kebab>/overview.md`](../../plans/initiatives/<initiative-kebab>/overview.md)

This spec is the living source of truth for the behavior it describes (constitution Article 5): behavior changes start here, and the code is reconciled with it.

## 1.1 Problem

<The pain and the value. Stakeholders by role.>

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | <The system shall … — observable, one behavior per row> | P1 |
| FR-002 | <…> | P2 |

IDs are stable and never reused. P1 = the MVP: the P1 requirements alone must be independently deliverable and testable. Every FR is covered by at least one scenario tagged `@FR-###`.

## 1.2 Behavioral contract

```gherkin
# language: <en | es — from plans/agile/language.md; one language per block>
@<initiative-kebab>
Feature: <capability>

  Background:
    Given <shared state, Given steps only>
      | <column> | <column> |
      | <value>  | <value>  |

  @happy @FR-001 @P1
  Scenario: <happy path outcome>
    # Origin: <who>, <when> | Proposed
    Given <state>
    When <action>
    Then <observable outcome>

  @negative @FR-001 @P1
  Scenario: <negative path outcome>
    # Origin: <who>, <when> | Proposed
    Given <state>
    When <action>
    Then <observable outcome>
```

Every scenario needs `Given`, `When`, and an observable `Then` (Background `Given` steps count), a requirement tag `@FR-###`, and a priority tag `@P1`/`@P2`/`@P3`; see the skill's `frameworks/gherkin.md` for Rule, Scenario Outline, data tables, and doc strings. End-to-end paths come from `process.md` when the initiative has one.

Edge cases (category → scenario name or `N/A — reason`):

1. Empty / null input — <…>
2. Maximum input — <…>
3. Boundary values — <…>
4. Concurrency — <…>
5. Partial failure — <…>
6. Idempotency / retries — <…>
7. Authorization — <…>
8. Time zone / locale — <…>

## 1.3 Out of scope

1. <What a reader might assume is included and is not>

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | <measurable criterion with a number or observable threshold> | <scenario name> |

## 1.5 Constraints & assumptions

| # | Item | State |
|---|------|-------|
| 1 | <constraint or assumption> | Verified (<source>) / Documented (<where>) / Proposed |

## Clarifications

Answers recorded by the clarify protocol (the skill's `frameworks/clarify.md`). Every answer names who confirmed it.

### Session <YYYY-MM-DD>

1. Q: <question> → A: <answer> — Confirmed by: <name> (<role>)

## Open questions

| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | <question the spec cannot answer yet> | <role> | Yes / No |

## Gate to Phase 2

1. ⚠️ No to-be-defined placeholders left — <evidence>
2. ⚠️ Every FR has a scenario tagged `@FR-###`; every SC maps to a scenario — <evidence>
3. ⚠️ Out of scope is explicit — <evidence>
4. ⚠️ No open question that blocks the sprint; every clarification is attributed — <evidence>
5. ⚠️ `requirements-checklist.md` at least 80% traced, no ❌ left (`--strict`) — <evidence>
