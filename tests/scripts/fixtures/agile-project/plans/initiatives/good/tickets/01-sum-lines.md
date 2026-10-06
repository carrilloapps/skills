# Work item: Sum the lines

## Acceptance criteria

```gherkin
Scenario: Two lines are summed
  Given a cart with 2 "A-1"
  When the user opens the checkout
  Then the total shown is 20.00
```

## QA test cases

```gherkin
Scenario: Negative quantity is refused
  Given a cart with -1 "A-1"
  When the user opens the checkout
  Then the checkout is refused
```
