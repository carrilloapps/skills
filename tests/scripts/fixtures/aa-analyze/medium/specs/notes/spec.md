# Spec: Notes

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | The user saves a note of up to 500 characters | P1 |

```gherkin
Feature: Notes

  @FR-001
  Scenario: Save a note
    Given an empty note
    When the user types 10 characters and saves
    Then the note is listed

  @FR-001
  Scenario: Save a note
    Given an existing note
    When the user edits it and saves
    Then the new text is listed
```
