# Spec: Search

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Results appear for a keyword | P1 |

```gherkin
Feature: Search

  @FR-001 @SC-001
  Scenario: Keyword returns results
    Given an indexed product "lamp"
    When the user searches "lamp"
    Then the product appears in the results
```

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Results in under 1 second | - |
| SC-002 | Zero-result rate below 5% | - |
