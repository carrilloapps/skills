# [SEV<n>] <Failure>: <system> — Incident Postmortem — EN

> 🌐 Also available in: `<YYYY-MM-DD>_SEV<n>_<SLUG>_ES.md`

Blameless: this document describes systems, signals, and decisions. No individual is a cause.

## Table of contents

1. Executive summary
2. Incident record
3. Timeline
4. Severity
5. Contributing factors
6. Triggering change
7. Detection gap
8. What went well
9. Action items
10. Incident metrics
11. Out of scope & limitations
12. Lessons
13. Registry snapshot
14. Gate

## Executive summary

<Five lines at most. Impact first, cause second, state third. No jargon. A reader who stops here must know what happened, who was affected, whether it is over, and what happens next.>

## Incident record

| Field | Value |
|-------|-------|
| Incident ID | `INC-<nnn>` |
| Detected | `<YYYY-MM-DD HH:MM UTC>` / `<HH:MM LOCAL>` — source: `<alert / person role / report>` |
| Stabilized | `<HH:MM UTC>` — source: `<evidence>` |
| Resolved | `<YYYY-MM-DD HH:MM UTC>` or `pending` — source: `<evidence>` |
| Severity | `SEV<n>` (rubric line in § Severity) |
| Systems affected | `<service>`, `<service>` |
| **Systems NOT affected** | `<service>` — verified: `<evidence>` |
| Responders (roles) | `<role>`, `<role>` |
| Report author | Agent, reviewed by `<role>` |

## Timeline

All times UTC and `<LOCAL ZONE>`. Every row names its source. `[unknown]` means the evidence does not reach; a `— gap —` row means no evidence exists for that period.

| UTC | Local | Event | Source | Confidence |
|-----|-------|-------|--------|------------|
| `<HH:MM:SS>` | `<HH:MM>` | `<what happened>` | `<log / alert ID / commit / role>` | Confirmed |
| `<HH:MM>` | `<HH:MM>` | — gap: no evidence between `<HH:MM>` and `<HH:MM>` — | `<why: retention, no logging>` | — |

## Severity

```text
SEV<n> ← D1 users: <evidence> (SEV<n>) · D2 data: <evidence> (SEV<n>)
       · D3 duration: <evidence> (SEV<n>) · D4 radius: <evidence> (SEV<n>)
       · D5 regulatory: <evidence> (SEV<n>) → max = SEV<n>
```

<For a near miss, add the counterfactual: what the severity would have been had the control not held.>

## Contributing factors

### CF-1 — <condition in one line> (Confirmed | Probable | Possible)

**Condition**: <what was true>
**Evidence**: <file:line, log, config, metric>
**If removed**: <what would have changed>

### CF-2 — <condition> (Confirmed | Probable | Possible)

**Condition**: <…>
**Evidence**: <…>
**If removed**: <…>

## Triggering change

<The deploy, config change, traffic shift, or dependency failure that made the latent conditions matter — with its identifier and time. Separate from the factors above: the trigger is not the cause.>

## Detection gap

<Onset versus detection, quantified from the timeline when possible. What signal existed but was not alerted on, and how much earlier it would have fired. If the gap cannot be measured, say `not measured` and make it an action.>

## What went well

1. <Control, alert, or decision that limited the damage> — evidence: `<…>`
2. <…>

## Action items

| ID | Type | Action | Traces to | Owner (role) | Due | Verification | State |
|----|------|--------|-----------|--------------|-----|--------------|-------|
| A-01 | prevent | `<imperative change>` | CF-1 | `<role>` | `<YYYY-MM-DD>` | `<observable check>` | Open |
| A-02 | detect | `<imperative change>` | detection gap | `<role>` | `<YYYY-MM-DD>` | `<observable check>` | Open |
| A-03 | mitigate | `<imperative change>` | CF-2 | `<role>` | `<YYYY-MM-DD>` | `<observable check>` | Open |

## Incident metrics

| Metric | Value | From → to | Evidence |
|--------|-------|-----------|----------|
| Time to detect | `<duration>` or `not measured` | `<HH:MM → HH:MM UTC>` | `<evidence>` |
| Time to mitigate | `<duration>` | `<HH:MM → HH:MM UTC>` | `<evidence>` |
| Time to resolve | `<duration>` or `pending` | `<… → …>` | `<evidence>` |
| Impact duration | `<duration>` | `<onset → mitigation>` | `<evidence>` |
| Users affected | `<count>` or `not measured` | — | `<what the figure actually measures>` |

## Out of scope & limitations

1. <Evidence that was unavailable, and what it cost the analysis.>
2. <What was deliberately not reviewed, and who owns it.>
3. <Any `.memory/` ignore rule the agent could not write, e.g. Subversion.>

## Lessons

| # | Lesson | Triggers on a plan that… | Evidence |
|---|--------|--------------------------|----------|
| L-1 | `<generalized rule>` | `<condition a future plan would meet>` | `INC-<nnn>` CF-1 |

## Registry snapshot

| ID | Date | Sev | Title | Open actions | Status |
|----|------|-----|-------|--------------|--------|
| `INC-<nnn>` | `<YYYY-MM-DD>` | `SEV<n>` | `<title>` | `<n>` | Open |

## Gate

1. ✅/❌ No individual is named as a cause — roles only
2. ✅/❌ Every timeline row has a source, `[unknown]`, or an explicit gap row
3. ✅/❌ Severity shows its rubric line and the maximum dimension
4. ✅/❌ Every causal claim carries Confidence
5. ✅/❌ Every action item has an owner role, a due date, and a verification step
6. ✅/❌ Metrics are measured or marked `not measured`
7. ✅/❌ Out of scope & limitations lists the evidence that was unavailable
8. ✅/❌ What went well is not empty
