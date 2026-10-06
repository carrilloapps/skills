# Incident Metrics

Three durations, each computed from timeline rows that have evidence. A metric whose inputs are not both in the timeline is `not measured`. Never estimated, never inferred from a feeling about how long it felt.

## The three durations

| Metric | From | To | Reads as |
|--------|------|----|----------|
| **Time to detect (TTD)** | Onset | Detection | How long the system was failing unnoticed |
| **Time to mitigate (TTM)** | Detection | Mitigation | How long impact continued after someone knew |
| **Time to resolve (TTR)** | Detection | Resolution | How long until the permanent fix, often days |

```markdown
## Incident metrics

| Metric | Value | From → to | Evidence |
|--------|-------|-----------|----------|
| Time to detect | 7 min | 14:05 → 14:12 UTC | first pool-wait samples → alert `A-7781` |
| Time to mitigate | 95 min | 14:12 → 15:47 UTC | alert `A-7781` → rollback `deploy-8841` |
| Time to resolve | 19 h 8 min | 14:12 UTC 06 Oct → 09:20 UTC 07 Oct | alert → PR #412 merged |
| Impact duration | 102 min | 14:05 → 15:47 UTC | onset → mitigation |
| Users affected | not measured | — | session-level attribution is not retained; the 18% figure is a request-rate ratio, not distinct users |
```

## The measured-only rule

| Situation | Write |
|-----------|-------|
| Both endpoints are timeline rows with sources | The duration |
| Onset is `[unknown]` | `TTD: not measured — onset unknown (metric retention 15 min)` |
| The figure is a ratio, not a count | Name what it actually measures, as above with "18% of requests, not distinct users" |
| A system reports it for you | Cite the system and keep its units |

Never convert a request ratio into a user count, never round a `~` into a precise number, and never fill a metric to make a dashboard look complete. One honest `not measured` is worth more than five invented figures: it is the input to a `detect` action.

## Phase breakdown — for long incidents

When TTM is large, split it. The longest phase is usually the best action item.

```markdown
| Phase | Duration | From → to |
|-------|----------|-----------|
| Detect | 7 min | onset → alert |
| Diagnose | 48 min | alert → cause identified in the incident channel |
| Decide | 11 min | cause identified → rollback decision |
| Act | 36 min | decision → impact stopped |
```

A 48-minute diagnose phase points at observability; a 36-minute act phase points at the rollback path. Both are more useful than the single 95-minute number.

## Across incidents

The registry carries each incident's metrics, so a later run can report a trend — only when there are at least **three** closed incidents with the same metric measured. Below that, say so: a trend drawn from two points is noise, and a "trend" built from `not measured` entries is fiction.

```markdown
Trend: TTD across the last 4 incidents with a measured onset: 7, 23, 4, 11 min (median 9).
Two further incidents had an unknown onset and are excluded.
```

Never compare severities as if they were a scale (SEV1 is not "four times" SEV4), and never aggregate a count of incidents into a quality judgement about a team.
