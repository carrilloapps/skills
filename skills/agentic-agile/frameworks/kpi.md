# KPIs — Definition, Interpretation, and Sprint Close

The KPIs themselves are the team's: `plans/agile/kpi-directives.md`. This file defines how the agent measures, interprets, and publishes them. No KPI is invented, renamed, or re-thresholded by the agent.

---

## 1. Gate zero — before any number

A KPI may be computed only when **both** are true:

1. **Definition** — formula, unit, window, and inclusion/exclusion rules are written in `kpi-directives.md` and confirmed (`Confirmed by:`).
2. **Data source verified** — the capability that owns the data responded in this session ([`integrations.md`](integrations.md#availability-rule)) and the query matches the definition.

Gate zero failed → the row is `not measurable — <reason>`. Never a number, never an estimate, never "approximately".

---

## 2. State tree

```text
defined ──► measurable ──► measured ──► interpreted ──► published
   │             │
   │             └──► not measurable — <reason>   (source down, data incomplete, definition ambiguous)
   └──► not defined — propose a definition (Proposed, needs Confirmed by:)
```

- A measure with no valid value has **no state** (no ✅/⚠️/❌) — only the reason.
- *Interpreted* means compared with the threshold **and** the context (scope changes, holidays, incidents) with the source cited.
- *Published* means written to an external tool after exact-payload approval (N3).

---

## 3. Mandatory row schema

Every KPI table — report, quarterly, executive summary — uses:

| KPI | Value | Threshold | State | Notes / source |
|-----|-------|-----------|-------|----------------|
| Cycle time p50 | 3.2 d | ≤ 4 d | ✅ | tracker, items closed 2026-09-22 → 2026-10-03 |
| Escaped defects | not measurable — tracker label missing on 4 items | ≤ 2 | — | open question to QA lead |

`Notes / source` is never empty.

---

## 4. "A drop that is success"

Some KPIs move the "wrong" way for good reasons: velocity drops while the team pays down a planned migration; open defects rise right after a test suite is added. Before assigning ❌:

1. Check decisions (`plans/decisions/`) and the sprint goal for an intended trade-off.
2. If found, state it with the decision link; the state is ⚠️ with the reason, not ❌.
3. If not found, ❌ stands — the agent does not invent a justification.

---

## 5. Sprint close — seven phases (vendor-neutral)

| # | Phase | What the agent does | Output |
|---|-------|---------------------|--------|
| 1 | Context | Load `plans/agile/`, sprint planning, decisions with review dates in the window | List of active definitions |
| 2 | Version control | Collect commits, merged/open PRs, branches in the window ([`delivery.md`](delivery.md#4-sprint-data-collection)) | Change set by initiative |
| 3 | Observability | Incidents, alerts, error budgets in the window (if the slot is filled) | Production facts with sources |
| 4 | Chat | Blockers and decisions announced in team channels (if the slot is filled), attributed | Facts with attribution |
| 5 | Interpretation | Apply gate zero, the state tree, and §4 to every KPI | KPI table (§3) |
| 6 | Publication | Draft `plans/sprints/<…>/report.md`; external publication only after exact-payload approval | Report + payload |
| 7 | Memory & decisions | Propose updates to `plans/agile/` and new decision records for what the team changed | Proposed changes (team confirms) |

### Close checklist (all ✅ before the report is final)

1. ✅/❌ Every KPI row passes gate zero or says `not measurable — <reason>`.
2. ✅/❌ Every row has notes/source.
3. ✅/❌ No per-person metric appears anywhere.
4. ✅/❌ Work is classified by initiative.
5. ✅/❌ Every ❌ was checked against §4.
6. ✅/❌ Agentic indicators computed from `events.jsonl` ([`agentic-agility.md`](agentic-agility.md)).
7. ✅/❌ "Nothing was written to the tracker/docs." until approval.

---

## 6. Calibration

Thresholds are not judged until **two full baseline cycles** exist. Then, at a quarterly review:

1. Show each KPI's distribution over the baseline.
2. Propose (Proposed) threshold changes with the evidence.
3. The team decides; the change is a decision record and an edit to `kpi-directives.md` with `Confirmed by:`.
