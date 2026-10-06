# Gherkin — Acceptance Criteria and QA Cases

> ⚠️ **Example code boundary** — scenarios below are documentation examples, not executable tests.

Acceptance criteria and QA test cases are written as Gherkin scenarios. Bullet-checkbox lists, free prose describing steps, or recordings without text are not accepted. `scripts/check-spec` enforces the rules marked **(checked)**.

## Language

The keyword language comes from `plans/agile/language.md`. Default: the language of the user's messages. Put `# language: es` (or `# language: en`) as the first line of each block so tooling parses it. **One language per block (checked)**: mixing `Given` and `Cuando` in the same fenced block is an error.

| Concept | English | Español |
|---------|---------|---------|
| Feature | `Feature:` | `Característica:` |
| Rule | `Rule:` | `Regla:` |
| Background | `Background:` | `Antecedentes:` |
| Scenario | `Scenario:` (also `Example:`) | `Escenario:` (also `Ejemplo:`) |
| Scenario Outline | `Scenario Outline:` / `Scenario Template:` | `Esquema del escenario:` / `Plantilla del escenario:` |
| Examples | `Examples:` / `Scenarios:` | `Ejemplos:` / `Escenarios:` |
| Given | `Given` | `Dado` / `Dada` / `Dados` / `Dadas` |
| When | `When` | `Cuando` |
| Then | `Then` | `Entonces` |
| And | `And` | `Y` / `E` (before a word starting with *i*/*hi*) |
| But | `But` | `Pero` |
| Any step | `*` | `*` |

`*` continues the previous step type (it reads as "and"); it never satisfies Given, When, or Then on its own.

### Other syntax

| Element | Syntax | Use |
|---------|--------|-----|
| Tags | `@smoke @payments` on the line above `Feature`, `Rule`, `Scenario`, or `Examples` | Filtering, test type (`@e2e`, `@regression`), and **mandatory** traceability: every spec scenario carries `@FR-###` (one or more) and one priority `@P1` / `@P2` / `@P3` ([`traceability.md`](traceability.md)) |
| Comments | `# text` at the start of a line | Notes; `# Origin: …` is accepted as the scenario origin |
| Data table | Rows of `\| cell \|` under a step | Structured input or expected output for one step |
| Doc string | Text between `"""` (or ```` ``` ````) lines under a step | Multi-line payloads: JSON, messages, emails |
| Language header | `# language: es` as the first line | Tooling keyword detection |

```gherkin
# language: en
@orders
Feature: Order totals

  Background:
    Given the catalogue contains:
      | sku | price |
      | A-1 | 10.00 |
      | B-2 |  4.50 |

  Rule: Totals include every line

    @smoke
    Scenario: Two lines are summed
      # Origin: PO, refinement 2026-10-01
      Given a cart with 2 "A-1" and 1 "B-2"
      When the user opens the checkout
      Then the total shown is 24.50
      And the response body is:
        """
        {"total": "24.50", "currency": "USD"}
        """
```

## Structure (checked)

1. Every scenario has **at least one `Given`, one `When`, and one `Then`** (any language keyword). `And`, `But`, and `*` continue the previous type. Steps inherited from `Background` count as `Given`.
2. `Background` contains **only `Given`** steps (`And`/`But`/`*` continuing them are fine). A `When` or `Then` in `Background` is an error.
3. One behavior per scenario. The title states the outcome, not the steps.
4. `Given` sets state, `When` is one action or event, `Then` is an **observable outcome**: a response code, a persisted record, an emitted event, a visible message. "It works" or "it is processed" are not observable.
5. Declarative over imperative: `When the user submits the order`, not `When the user clicks the blue button at the bottom`.
6. Each scenario carries `Origin: <who>, <when>` (or `# Origin:` inside the block) or `Origin: Proposed` (checked as a warning).
7. Concrete data in steps. No "a valid user" when the difference between users matters.

## Minimum coverage per work item

1. One happy path.
2. One negative path per failure mode.
3. Applicable edge cases from the catalogue — or `N/A — <reason>` per category.

Work-item drafts under `plans/initiatives/<initiative>/tickets/` must have a **QA test cases** section (checked with `check-spec --tickets` or `--all`).

## Edge-case catalogue

| Category | Example |
|----------|---------|
| Empty / null input | `Given an empty order list` |
| Maximum input | `Given a payload with 10000 items` |
| Boundary values | Scenario Outline with `0, 1, max-1, max, max+1` |
| Concurrency | `When two reviewers approve the same request at the same time` |
| Partial failure | `Given the downstream service returns 500 for half of the requests` |
| Idempotency / retries | `When the client resends the same request with the same idempotency key` |
| Authorization | `Given a user without the "approve" permission` |
| Time zone / locale | `Given the date 2026-12-31 23:59:59 in zone <tz-id>` |
| Encoding | `Given a name with accents and emoji` |

## Scenario Outline

```gherkin
Scenario Outline: Reject quantities outside the allowed range
  Given a cart with product "<sku>"
  When the user sets the quantity to <qty>
  Then the response is <status>

  Examples:
    | sku  | qty | status |
    | A-1  | 0   | 400    |
    | A-1  | 1   | 200    |
    | A-1  | 100 | 200    |
    | A-1  | 101 | 400    |
```

## Results with evidence (Phase 4)

Each scenario in `verification.md` has a result and **evidence**. A pass without evidence is **not verified**; a ❌ blocks closing the item.

| Result | Meaning |
|--------|---------|
| ✅ | Pass, evidence attached |
| ⚠️ | Pass with a stated caveat and a follow-up (owner + date) |
| ❌ | Fail — back to Phase 3 |
| `skipped — <reason>` | Not run; the reason is a decision, not an omission |

Evidence block per scenario (or one row per scenario in the 4.1 matrix with an Evidence column):

```text
RESULT: ✅
EVIDENCE: 2026-10-05T14:32Z · ci/run/4812 (test "rejects quantity 0") · commit 3f2a9c1
```

Evidence names a timestamp, an artifact (test name, CI run, log path, screenshot path), and the commit it ran against.

## Anti-patterns

| Anti-pattern | Fix |
|--------------|-----|
| UI script (`click`, `scroll`, `type in field 3`) | State the intent: `When the user submits the order` |
| Several `When` steps chaining actions | Split into scenarios or move setup to `Given` |
| `Then` that is not observable ("it works", "it is saved correctly") | Name the response, record, event, or message |
| Scenario titles that restate steps | Title states the outcome |
| Shared mutable state between scenarios | Each scenario sets its own state (`Given`/`Background`) |
| Mixed languages in one block | One `# language:` per block |
| Placeholder data ("a valid user", "some amount") where it matters | Concrete values or a Scenario Outline |
| Acceptance criteria as bullets or checkboxes | Convert (below) |

## Converting legacy bullet acceptance criteria

1. List each bullet as a candidate behavior; merge duplicates, split bullets that describe two behaviors.
2. For each behavior, write the happy path: the state (`Given`), the trigger (`When`), the observable outcome (`Then`).
3. Add one negative scenario per failure mode the bullet implies (invalid input, missing permission, downstream failure).
4. Keep the bullet's author as `Origin:`; if unknown, write `Origin: Proposed` and add an open question for the author.
5. Bullets that are constraints, not behaviors, move to **Constraints & assumptions**; bullets that are out of scope move to **Out of scope**.
6. Run `scripts/check-spec` and fix every finding.

## Pre-publish checklist

Before a spec or work item is marked Ready (state each item ✅ / ❌ / ⚠️ with evidence):

1. Every scenario has `Given`, `When`, `Then`, and an observable `Then`.
2. One language per block, `# language:` header present.
3. Happy path, one negative per failure mode, edge cases or `N/A — <reason>`.
4. Each scenario has an Origin; Proposed ones have an open question.
5. No placeholders, no TBD, no checkbox lists.
6. Data tables and doc strings carry concrete values.
7. `scripts/check-spec` passes (`--strict` before planning).
