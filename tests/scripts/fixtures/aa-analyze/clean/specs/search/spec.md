# Spec: Search

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Results appear within 2 seconds for a keyword | P1 |
| FR-002 | The result list shows 20 items per page | P2 |

```gherkin
Feature: Search

  @FR-001 @P1
  Scenario: Keyword returns results
    Given an indexed product "lamp"
    When the user searches "lamp"
    Then the product appears in under 2 seconds

  @FR-002 @P2
  Scenario: Results are paginated
    Given 45 matching products
    When the user searches
    Then the first page shows 20 items
```

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | 95% of searches finish in under 2 seconds | Keyword returns results |

## Open questions

| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | Should typos be corrected later? | PO | no |
