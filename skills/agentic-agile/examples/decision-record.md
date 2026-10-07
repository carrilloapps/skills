# Example: Decision Record

> ⚠️ **Example only** — fictional decision.

**Skill version**: 1.0.2

User: "Record that we're keeping refunds out of the export."

`plans/decisions/2026-10-05-refunds-out-of-export.md`:

```markdown
# Decision: Refunds are excluded from the order-history CSV export

**Date**: 2026-10-05 · **State**: Accepted

## What
The CSV export contains orders only; refunds are not included in this initiative.

## Alternatives considered
1. Include refunds as negative rows — finance needs a reconciliation review first.
2. Separate refunds export — out of scope for this sprint.

## Reason
Finance has not validated refund figures for customer-facing exports (relayed by the product owner).

## Who decided
Product owner, after consulting finance. Recorded from: refinement transcript @ 00:06:15 and the product owner's confirmation in the planning session.

## Origin
Refinement 2026-10-05; planning 2026-10-06.

## Review on
2027-01-15, or when finance completes the reconciliation review.

## Consequences
The spec lists refunds under Out of scope; support answers refund-export requests manually until review.
```

Event logged: `{"event":"decision_recorded","meta":{"has_author":true,"has_reason":true}}`.
