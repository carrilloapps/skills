# Spec: Order totals

## 1.1 Problem
Totals are computed by hand. Origin: PO, refinement 2026-09-30.

## Functional requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Sum every cart line | P1 |
| FR-002 | Refuse an empty cart | P2 |
| FR-003 | Show the total in the chosen currency | P3 |

## 1.2 Behavioral contract

```gherkin
# language: en
@orders
Feature: Order totals

  Background:
    Given the catalogue contains:
      | sku | price |
      | A-1 | 10.00 |
    And the user is signed in

  Rule: Totals include every line

    @smoke @FR-001 @P1
    Scenario: Two lines are summed
      # Origin: PO, refinement 2026-09-30
      Given a cart with 2 "A-1"
      When the user opens the checkout
      Then the total shown is 20.00
      And the response body is:
        """
        {"total": "20.00"}
        """

    @FR-002 @P2
    Example: Empty cart
      # Origin: Proposed
      * the cart is empty
      When the user opens the checkout
      Then the checkout is refused with "empty cart"
```

```gherkin
# language: es
Característica: Totales en otra moneda

  @FR-003 @P3
  Escenario: Total en bolívares
    # Origen: PO, refinamiento 2026-09-30
    Dado un carrito con 1 "A-1"
    Cuando el usuario elige la moneda VES
    Entonces el total se muestra en VES
```

## 1.3 Out of scope
1. Discounts.

## 1.4 Success criteria
1. Totals match the scenarios.

## 1.5 Constraints & assumptions
1. Prices include taxes.

## Open questions
| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | Rounding mode? | PO | No |
