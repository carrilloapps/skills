# Example: A Spec That Passes `check-spec`, and One That Fails

> ⚠️ **Example only** — fictional initiative. Commands are illustrative.

**Skill version**: 1.0.0

## Passing spec (`specs/order-history-csv/spec.md`, abridged)

```markdown
## 1.1 Problem
Customers cannot get their order history out of the product; support handles ~30 requests a week (Documented — support channel, 2026-09).

## Functional requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | A customer can export their full order history as CSV | P1 |
| FR-002 | A suspended account cannot export | P1 |

## 1.2 Behavioral contract
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

## 1.3 Out of scope
1. Refunds (finance decision, 2026-10-05)
2. Scheduled or emailed exports

## 1.4 Success criteria
| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Support export requests drop below 5 a week | Export order history as CSV |
| SC-002 | Zero exports from suspended accounts | Reject export for a suspended account |
```

```text
$ bash skills/agentic-agile/scripts/check-spec.sh specs/order-history-csv
PASS  phase 1  spec.md: problem, FR-001–FR-002 tagged, contract (2 scenarios), out of scope, SC-001–SC-002 mapped
WARN  phase 1  1 scenario marked Proposed
SKIP  phase 2  design.md not present yet
exit 0
```

With `--strict`, the warning makes it exit `2`.

## Failing spec

```markdown
## 1.2 Behavioral contract
☑ User can export
☑ Export is fast
## 1.4 Success criteria
TBD
```

```text
FAIL  phase 1  no Functional requirements table (FR-###)
FAIL  phase 1  no Scenario/Escenario found
FAIL  phase 1  "TBD" found (line 5)
FAIL  phase 1  missing section: Out of scope
exit 1
```

The agent reports the failures as a numbered list and proposes the fixes; it does not mark the spec Ready. Output above is abridged — the real script prints numbered findings with rule IDs (see `scripts/check-spec --help`). A complete passing initiative, with design, tasks, and verification, is in [`end-to-end.md`](end-to-end.md).
