# Spec: Broken traceability

## 1.1 Problem
Something hurts.

## Functional requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | First | P1 |
| FR-001 | Duplicate | P2 |

## 1.2 Behavioral contract
@FR-009 @P1
Scenario: Tagged with an unknown requirement
  Origin: PO
  Given a
  When b
  Then c

Scenario: No tags at all
  Origin: PO
  Given a
  When b
  Then c

## 1.3 Out of scope
1. Nothing.

## 1.4 Success criteria
| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | Fast | Missing scenario name |
| SC-002 | Safe | - |

## 1.5 Constraints
1. None.

## Clarifications
### Session 2026-10-02
1. Q: Who approves? → A: The PO
2. Q: Deadline? → A: Friday — Confirmed by: Luis (TL)

## Open questions
| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | Which bank format? | PO | Yes |
