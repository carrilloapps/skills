# Feature Specification: Invoice CSV export

**Feature Branch**: `001-invoice-export`
**Created**: 2026-09-30
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Export one month (Priority: P1)

The analyst exports the invoices of a month.

**Acceptance Scenarios**:

1. **Given** 3 invoices exist for September, **When** the analyst exports September, **Then** the CSV has 3 rows
2. **Given** no invoices exist, **When** the analyst exports September, **Then** the CSV has only the header

### User Story 2 - Reject bad months (Priority: P2)

1. **Given** any data, **When** the analyst exports "2026-13", **Then** the export is refused

### Edge Cases

- What happens when the month is in the future?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST export invoices of one month as CSV
- **FR-002**: System MUST reject invalid months with a message | code
- **FR-003**: System MUST support [NEEDS CLARIFICATION: which separators?]

### Key Entities

- **Invoice**: number, date, total

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Month-end export takes under 1 minute

## Clarifications

### Session 2026-09-30

- Q: Include voided invoices? → A: No

## Assumptions

- Invoices carry an issue date
