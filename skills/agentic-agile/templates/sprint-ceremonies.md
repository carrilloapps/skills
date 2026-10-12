<!-- Sprint ceremony templates in one file. Copy ONLY the part you need, never the whole file:
     A -> plans/sprints/<YYYY>-S<NN>/planning.md
     B -> plans/sprints/<YYYY>-S<NN>/daily/<YYYY-MM-DD>.md
     C -> plans/sprints/<YYYY>-S<NN>/review.md
     D -> plans/sprints/<YYYY>-S<NN>/retro.md
     E -> plans/sprints/<YYYY>-S<NN>/report.md
     F -> plans/sprints/<YYYY>-S<NN>/weekly-<YYYY-MM-DD>.md
     G -> plans/sprints/<YYYY>-Q<N>-report.md
     H -> plans/sprints/<YYYY>-S<NN>/executive-summary.md (or a draft in chat)
     Kanban boards use <YYYY>-M<NN> in place of <YYYY>-S<NN>. -->

---

<!-- A. Sprint planning -->

# Sprint <YYYY>-S<NN> — Planning

**Dates**: <start> → <end> · **Position in quarter**: <start | middle | end | release> · **Date of planning**: <YYYY-MM-DD>

## Sprint goal

<As proposed by the product owner — attributed.>

## Capacity

| Role | Available days | Recent pts/day | Capacity (pts) | Source |
|------|----------------|----------------|----------------|--------|

Total capacity: <N> pts (or "no baseline — planned by days")

## Candidate items (Ready only)

| # | Item | Team vote (pts) | Agent comparison (revealed after vote) | Suggested owner (role) |
|---|------|-----------------|----------------------------------------|------------------------|

## Commitment

Committed by the team (N0): <list of item numbers> — recorded from <speaker @ time>

## Risks and notes

1. <carry-over, single-owner areas, dependencies>

---

<!-- B. Daily -->

# Daily — <YYYY-MM-DD> (Sprint <YYYY>-S<NN>)

## Blockers raised

1. <blocker> — <who> — <since>

## Items without movement (> <N> days)

| Item | Last change | State |
|------|-------------|-------|

## PRs waiting for review (> <N> hours)

| PR | Waiting since |
|----|---------------|

## WIP per role

| Role | Items in progress |
|------|-------------------|

Facts only, with sources. No assessment of people.

---

<!-- C. Sprint review -->

# Sprint <YYYY>-S<NN> — Review

**Goal**: <goal>

## Shown

| # | Item | Verification verdict | Demo notes (attributed feedback) |
|---|------|----------------------|----------------------------------|

## Feedback that becomes work

| # | Feedback | From (role) | Becomes |
|---|----------|-------------|---------|
| 1 | <feedback> | <role> | new draft in `plans/drafts/` / open question / none |

---

<!-- D. Sprint retro -->

# Sprint <YYYY>-S<NN> — Retro

## Facts brought by the agent

1. <fact> — <source>

## Themes raised by the team

1. <theme> — <who raised it>

## Actions (chosen by the team)

| # | Action | Owner | Due | Follow-up in |
|---|--------|-------|-----|--------------|

The agent records actions; it does not choose them.

---

<!-- E. Sprint report -->

# Sprint <YYYY>-S<NN> — Report

**Goal**: <goal> · **Outcome**: Met | Partially met | Not met — <evidence>

## Done

| # | Item | Points | Verification verdict |
|---|------|--------|---------------------|

## Not done

| # | Item | Reason (attributed) | Next |
|---|------|---------------------|------|

## KPIs (as defined in `plans/agile/kpi-directives.md`)

| KPI | Value | Threshold | State | Notes / source |
|-----|-------|-----------|-------|----------------|

Row schema and states: the skill's `frameworks/kpi.md` §3. A KPI that cannot be measured validly is written as "not measurable — <reason>", never as a number.

## Agentic indicators (from `plans/agile/metrics/events.jsonl`)

| # | Indicator | Value | Baseline cycles so far |
|---|-----------|-------|------------------------|

## Changelog

<Merged PRs and resolved items grouped by initiative.>

---

<!-- F. Weekly status -->

# Weekly Status — <YYYY-MM-DD> (Sprint <YYYY>-S<NN>)

**Sprint goal**: <goal> · **Progress**: <on track / at risk / off track> — <evidence>

## Done this week

| # | Item | Initiative | Verification |
|---|------|------------|--------------|

## In progress

| # | Item | Initiative | Since |
|---|------|------------|-------|

## Blocked

| # | Item | Blocker | Owner of the unblock | Since |
|---|------|---------|----------------------|-------|

## Risks

| # | Risk | Owner | Next step |
|---|------|-------|-----------|

## Decisions needed

| # | Decision | From whom | By when |
|---|----------|-----------|---------|

Facts only, with sources. No per-person ranking.

---

<!-- G. Quarterly report -->

# Quarterly Report — <YYYY>-Q<N>

**Sprints covered**: <list> · **Prepared**: <YYYY-MM-DD>

## 1. Outcomes against goals

| # | Goal | Outcome | Evidence |
|---|------|---------|----------|

## 2. KPIs

| KPI | Value | Threshold | State | Notes / source |
|-----|-------|-----------|-------|----------------|

## 3. Agentic indicators (from `plans/agile/metrics/events.jsonl`)

| # | Indicator | Value | Trend | Baseline cycles |
|---|-----------|-------|-------|-----------------|

## 4. Decisions to review

| # | Decision record | Review on | Status |
|---|-----------------|-----------|--------|

## 5. Calibration proposals (only after two baseline cycles)

| # | KPI | Current threshold | Proposed | Evidence |
|---|-----|-------------------|----------|----------|

## 6. Next quarter — proposed focus

<Proposed. The team and the product owner decide.>

---

<!-- H. Executive summary -->

# Executive Summary: <topic>

**Decision asked**: <one sentence — what the reader must decide or approve>
**Needed by**: <date> · **From**: <role>

## Context (five lines at most)

1. <fact with source>
2. <fact with source>
3. <fact with source>

## Options

| # | Option | Consequence | Cost / effort | Risk |
|---|--------|-------------|---------------|------|

## Recommendation

<Proposed option and why, in plain language.>

## What is needed from you

1. <specific ask>

No jargon or internal codenames without a one-line explanation. Every number has a source.
