# Example: A Spec That Passes `check-spec`, and One That Fails

> ⚠️ **Example only** — fictional initiative. Script output is reproduced in the real format of `check-spec` 1.0.0 (rule ids and messages as printed; line numbers depend on the file).

**Skill version**: 1.0.2

## Passing spec (`specs/order-history-csv/spec.md`, abridged)

````markdown
## 1.1 Problem
Customers cannot get their order history out of the product; support handles ~30 requests a week (Documented — support channel, 2026-09).

## Functional requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | A customer can export their full order history as CSV | P1 |
| FR-002 | A suspended account cannot export | P1 |

## 1.2 Behavioral contract
```gherkin
# language: en
@FR-001 @P1
Scenario: Export order history as CSV
  # Origin: Product owner, refinement 2026-10-05
  Given a customer with 120 orders
  When they request the CSV export
  Then they receive a CSV with 120 rows

@FR-002 @P1
Scenario: Reject export for a suspended account
  # Origin: Proposed
  Given a suspended customer
  When they request the CSV export
  Then the response is 403 and no file is generated
```

## 1.3 Out of scope
1. Refunds (finance decision, 2026-10-05)
2. Scheduled or emailed exports

## 1.4 Success criteria
| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Support export requests drop below 5 a week | Export order history as CSV |
| SC-002 | Zero exports from suspended accounts | Reject export for a suspended account |

## 1.5 Constraints & assumptions
1. Export runs in the existing worker (Verified — `src/jobs/`)

## Open questions
| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | Is there a maximum number of rows per export? | Product owner | No |
````

```text
$ bash <skill-dir>/scripts/check-spec.sh specs/order-history-csv --root .
check-spec — specs/order-history-csv
No findings.
Result: 0 error(s), 0 warning(s) — PASS
```

`# Origin: Proposed` is allowed (the scenario is attributed to the agent); only a *missing* Origin line is a warning. With `--strict` and a `design.md` present, a missing `requirements-checklist.md` would also fail.

## Failing spec

```markdown
## 1.2 Behavioral contract
- [ ] User can export
- [ ] Export is fast
## 1.4 Success criteria
TBD
```

```text
$ bash <skill-dir>/scripts/check-spec.sh specs/order-history-csv --root .
check-spec — specs/order-history-csv
1. error spec.md [missing-section] missing section: Problem
2. error spec.md [missing-section] missing section: Out of scope
3. error spec.md [missing-section] missing section: Constraints
4. error spec.md [missing-section] missing section: Open questions
5. error spec.md [fr-missing] no Functional requirements table with FR-### rows
6. error spec.md [no-scenarios] no Gherkin scenario (Scenario:/Escenario:)
7. error spec.md:5 [tbd] TBD left in the spec
8. error spec.md:2 [checkbox] checkbox list item; use numbered or lettered items with a state
9. error spec.md:3 [checkbox] checkbox list item; use numbered or lettered items with a state
Result: 9 error(s), 0 warning(s) — FAIL
```

The agent quotes the findings verbatim and proposes the fixes; it does not mark the spec Ready. A complete passing initiative, with design, tasks, and verification, is in [`end-to-end.md`](end-to-end.md).
