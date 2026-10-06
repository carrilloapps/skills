# Estimation and Capacity

## Scale

Fibonacci story points: **1 · 2 · 3 · 5 · 8 · 13**. An item at 13 should be split; an item at 20 or more is forbidden in a sprint — split it in refinement. The team may define another scale in `plans/agile/methodology.md`; that file wins.

## Estimation protocol (anti-anchoring)

1. The team votes first (planning poker or the team's method).
2. Only then the agent reveals its suggestion, sealed earlier if it had to be written.
3. The suggestion is a **comparison with closed, similar items** from the tracker or `plans/sprints/*/report.md`, cited by ID or path. No history → say so; never invent a reference velocity.
4. Large divergence between the vote and the comparison becomes an open question, not an override.

### Assistant availability

If most of the team works with AI assistants, history from before adoption overstates effort for boilerplate-heavy work and understates nothing for discovery-heavy work. Note the uplift honestly per area; do not apply a blanket discount.

## Capacity

1. **Pivot position** — where the sprint sits in the quarter (start, middle, end, release week) from the calendar in `plans/agile/`.
2. **Per-person available days** = sprint working days − time off − ceremonies − declared support/on-call load. Data comes from `plans/agile/team.md` and the calendar; missing data is asked for, not assumed.
3. **Capacity in points** = available days × the person's recent points per day (last 2–3 sprints). If no history: state "no baseline" and plan by days.
4. **Assignment suggestion** — match items to people by area of ownership and current WIP. It is a suggestion (N2); the team decides.
5. **Pattern-aware notes** — recurring carry-over, items that always reopen, areas with a single owner (bus factor). Facts with sources only.

## Output shape

```markdown
## Capacity — Sprint <YYYY>-S<NN> (<pivot position>)

| Role | Available days | Recent pts/day | Capacity (pts) | Source |
|------|----------------|----------------|----------------|--------|

Total: <N> pts · Sprint goal (proposed by PO): <goal>
Suggested order and assignment (N2 — the team decides):
1. <item> — <pts> — <suggested owner role> — <reason>
```
