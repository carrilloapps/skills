# Example: Sprint Planning with Capacity and Anti-Anchoring

> ⚠️ **Example only** — fictional team and numbers.

**Skill version**: 1.0.1

## Capacity — Sprint 2026-S20 (middle of quarter)

| Role | Available days | Recent pts/day | Capacity (pts) | Source |
|------|----------------|----------------|----------------|--------|
| Developer A | 8 (2 days off) | 1.2 | 9.6 | `plans/agile/team.md`, S18–S19 reports |
| Developer B | 10 | 1.0 | 10 | S18–S19 reports |
| Developer C | 6 (support rotation 4 days) | — | no baseline | joined in S19 |

Total: ~20 pts plus Developer C planned by days. Sprint goal (proposed by the product owner, planning 2026-10-06): "Customers can export their order history."

## Estimation

1. The team votes on "CSV export": 5, 5, 8 → discussion → 5.
2. Only then the agent reveals its sealed suggestion: 5, by comparison with two closed export items (`plans/sprints/2026-S14/report.md`, items 3 and 7).

## Suggested order and assignment (N2 — the team decides)

1. CSV export — 5 — Developer A (owns `reports/`) — highest customer impact
2. Large-export streaming — 8 — Developer B — depends on 1
3. Support macro update — 2 — Developer C — fits a support week

Note: `reports/` has a single owner (Developer A) — bus-factor risk raised as an open question for the retro.

## Commitment

The team committed items 1 and 2 (N0), recorded from the planning transcript at 00:41:20. Item 3 stays in the backlog.

Next — reply with numbers or in your own words:

1. Write `plans/sprints/2026-S20/planning.md`
2. Also log `item_started` events when work begins
3. Stop
