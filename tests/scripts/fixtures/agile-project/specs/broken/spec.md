# Spec: Broken

## Problem
Broken on purpose. See [the overview](../../plans/initiatives/broken/overview.md).

## Behavioral contract

```gherkin
Feature: Broken rules

  Background:
    Given a user
    When the user logs in

  Scenario: Missing when
    # Origin: QA
    Given a cart
    Then nothing happens

  Escenario: Mezcla de idiomas
    # Origen: QA
    Dado un carrito
    Cuando el usuario paga
    Entonces el pago queda registrado
```

## Out of scope
1. Nothing.

## Success criteria
1. None.

## Constraints
1. None.

## Open questions
1. None.
