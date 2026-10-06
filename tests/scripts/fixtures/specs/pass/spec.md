# Spec: export invoices

## 1.1 Problem
Finance exports invoices by hand.

## Functional requirements
| ID | Requirement | Priority |
|---|---|---|
| FR-001 | Export approved invoices as CSV | P1 |
| FR-002 | Export an empty file when there are no invoices | P2 |

## 1.2 Behavioral contract
```text
Scenario: not counted inside a non-Gherkin fence
```
@FR-001 @P1
Scenario: export succeeds
  Origin: refinement 2026-10-01, PO
  Given an approved invoice
  When the analyst exports invoices
  Then the CSV contains it

@FR-002 @P2
Escenario: exportación sin facturas
  **Origen:** propuesto
  Dado que no hay facturas
  Cuando el analista exporta
  Entonces el archivo está vacío

## 1.3 Out of scope
1. PDF export

## 1.4 Success criteria
1. ✅ Export under 5 s — maps to "export succeeds"

## 1.5 Constraints
None beyond the existing API.

## Open questions
| Question | For | Blocks sprint |
|---|---|---|
| CSV delimiter? | PO | No |
