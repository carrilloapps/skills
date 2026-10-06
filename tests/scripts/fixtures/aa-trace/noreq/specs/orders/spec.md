# Spec: Orders

## 1.1 Problem

Orders are confirmed by hand.

## 1.2 Behavioral contract

```gherkin
Feature: Orders

  @FR-001 @P1
  Scenario: Confirm an order
    # Origin: Ana (PO), refinement 2026-09-30
    Given a paid order
    When the clerk confirms it
    Then the customer gets a confirmation email
```

## 1.3 Out of scope

1. Refunds.

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Confirmation within 1 minute | Confirm an order |

## 1.5 Constraints & assumptions

1. Email provider already integrated.

## Open questions

| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | None open | PO | no |
