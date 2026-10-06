# Spec: Checkout

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | The cart shows the total with taxes | P1 |
| FR-002 | The user pays with a saved card | P1 |
| FR-003 | The user receives a receipt by email | P2 |

## 1.2 Behavioral contract

```gherkin
@FR-001
Feature: Checkout

  @P1
  Scenario: Total includes taxes
    Given a cart with 2 items
    When the user opens the cart
    Then the total includes taxes

  @FR-009 @P1
  Scenario: Pay with a saved card
    Given a saved card
    When the user pays
    Then the order is confirmed
```

```gherkin
Feature: Receipt

  Scenario: Receipt email
    Given a confirmed order
    When the payment settles
    Then the user receives a receipt
```

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Checkout completes in 3 steps | Total includes taxes |
| SC-002 | 99% of receipts arrive in 1 minute | - |
