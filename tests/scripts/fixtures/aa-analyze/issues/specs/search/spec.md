# Spec: Search

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | The search is fast | P1 |
| FR-002 | the search is  FAST. | P1 |
| FR-003 | Results load in under 2 seconds and scale | P2 |
| FR-004 | Autocomplete is instant | P2 |
| FR-005 | Keep the filter panel simple | P3 |
| FR-006 | La búsqueda es Rápida y robusta | P3 |

The ranking rule is [NEEDS CLARIFICATION: relevance or recency?].

```gherkin
Feature: Search

  @FR-001
  Scenario: Keyword returns results
    Given an indexed product
    When the user searches
    Then results appear

  @FR-003
  Scenario: keyword returns   results
    Given an indexed product
    When the user searches again
    Then results appear
```

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Users find results easily | Keyword returns results |

## Open questions

| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | Which index engine? | Architect | Yes |
| 2 | Do we log queries? | Security | no |
