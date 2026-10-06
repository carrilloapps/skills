# Spec: Export invoices as CSV

**Initiative**: `invoice-csv-export` · **Phase**: 1 — Spec · **Status**: In review

## 1.1 Problem

Finance re-types invoice data into spreadsheets every month-end. Stakeholders: finance analyst, team lead.

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Export one month of invoices as CSV | P1 |
| FR-002 | Refuse an invalid month | P2 |

## 1.2 Behavioral contract

```gherkin
# language: en
Feature: Invoice CSV export

  @FR-001 @P1
  Scenario: Analyst exports the invoices of one month
    # Origin: finance analyst, refinement 2026-09-30
    Given 3 invoices exist for September 2026
    When the analyst exports September 2026 as CSV
    Then the file contains a header row and 3 invoice rows

  @FR-002 @P2
  Scenario Outline: Export rejects an invalid month
    # Origin: Proposed
    Given no invoices exist
    When the analyst exports "<month>" as CSV
    Then the export is refused with "invalid month"

    Examples:
      | month   |
      | 2026-13 |
      | abc     |
```

## 1.3 Out of scope

1. PDF export.

## 1.4 Success criteria

| # | Criterion | Scenario(s) |
|---|-----------|-------------|
| 1 | Month-end export takes under 1 minute | Analyst exports the invoices of one month |

## 1.5 Constraints & assumptions

| # | Item | State |
|---|------|-------|
| 1 | Invoices carry an issue date | Verified (schema) |

## Open questions

| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | Is a semicolon separator needed for some locales? | Product owner | No |
