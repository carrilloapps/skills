# Tasks: Invoice CSV export

## Phase 1: Setup
| ID | P | Req | Task | Depends | Est | Status |
|----|---|-----|------|---------|-----|--------|
| T001 | - | - | Create the export module skeleton | - | 1 | ✅ |

## Phase 2: Scenarios
| ID | P | Req | Task | Depends | Est | Status |
|----|---|-----|------|---------|-----|--------|
| T002 | [P] | FR-001 | Write the failing export test | T001 | 2 | - |
| T003 | [P] | FR-002 | Write the failing refusal test | T001 | 1 | - |
| T004 | - | FR-001, FR-002 | Implement export and validation | T002, T003 | 5 | - |
