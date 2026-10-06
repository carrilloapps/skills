# Spec: Export

## 1.1 Problem

Finance exports invoices by hand every month.

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | The user exports the month's invoices as CSV | P1 |
| FR-002 | The export is fast | P2 |

## 1.2 Behavioral contract

```gherkin
Feature: Export

  @FR-001 @P1
  Scenario: Monthly CSV export
    # Origin: Ana (PO), refinement 2026-09-30
    Given 3 invoices in September
    When the user exports September
    Then a CSV with 3 rows is downloaded

  @FR-002 @P2
  Scenario: Export finishes
    # Origin: Ana (PO), refinement 2026-09-30
    Given 1000 invoices in September
    When the user exports September
    Then the download starts within 5 seconds
```

## 1.3 Out of scope

1. PDF export.

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Month-end export takes under 1 minute | Monthly CSV export |

## 1.5 Constraints & assumptions

1. Uses the existing invoice table.

## Open questions

| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | None open | PO | no |
