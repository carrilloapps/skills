# Spec: Invoice CSV export

## 1.1 Problem
Finance re-types invoices every month-end.

## Functional requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Export one month of invoices as CSV | P1 |
| FR-002 | Refuse an invalid month | P2 |

## 1.2 Behavioral contract

```gherkin
# language: en
@invoices
Feature: Invoice CSV export

  @FR-001 @P1
  Scenario: Analyst exports one month
    # Origin: finance analyst, refinement 2026-09-30
    Given 3 invoices exist for September 2026
    When the analyst exports September 2026
    Then the file contains 3 invoice rows

  Rule: Input validation

    @FR-002 @P2
    Scenario: Invalid month is refused
      # Origin: Proposed
      Given no invoices exist
      When the analyst exports "2026-13"
      Then the export is refused with "invalid month"
```

## 1.3 Out of scope
1. PDF export.

## 1.4 Success criteria
| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Month-end export under 1 minute | Analyst exports one month |
| SC-002 | No invalid file is produced | Invalid month is refused, "Analyst exports one month" |

## 1.5 Constraints & assumptions
1. Invoices carry an issue date.

## Clarifications

### Session 2026-10-01
1. Q: Which separator? → A: Comma — Confirmed by: Ana Ruiz (product owner)
2. Q: Include voided invoices? → A: No — Confirmed by: Ana Ruiz (product owner)

## Open questions
| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | Semicolon for some locales? | Product owner | No |
