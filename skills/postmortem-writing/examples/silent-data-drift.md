# Example: SEV2 — Silent data drift detected 11 days late

> ⚠️ **Example only** — a fictional incident. Service names, job names, counts, and log lines are synthetic. Nothing here describes a real system.

**Skill version**: 1.0.0

<!-- markdownlint-disable MD025 -->
<!-- The sections below embed a full report document, which carries its own top-level heading. -->

Shows: an incident where the **detection gap dominates the severity**, a timeline mostly built from derived evidence, `not measured` on the user-impact dimension, and a security handoff that is correctly declined.

---

## Why this one is different

The outage example has a sharp onset and a clear mitigation. This one has neither: the system kept working, the data was wrong, and nobody knew for 11 days. The analysis therefore spends its effort on *detection*, not on *recovery* — and the severity rubric lands on D2 (data), not D1 (users).

---

## The report (EN, abridged to the sections that differ)

# [SEV2] Partial nightly aggregation: reporting-etl — Incident Postmortem — EN

## Executive summary

Daily usage reports were understated for 11 days, from 18 to 29 September. A schema change added a column that the nightly aggregation job silently skipped, so one of three event types was never counted. The job reported success every night. Totals were corrected by a backfill on 30 September. No customer billing used these figures. Five actions are open, the first due 7 October.

## Incident record

| Field | Value |
|-------|-------|
| Incident ID | `INC-004` |
| Detected | `2026-09-29 11:40 UTC` / `07:40 VET` — source: analyst role, reporting channel (a weekly total looked low) |
| Stabilized | `2026-09-29 18:05 UTC` — source: job patched, `deploy-9103` |
| Resolved | `2026-09-30 04:12 UTC` — source: backfill job `bf-220` completed |
| Severity | `SEV2` (rubric line below) |
| Systems affected | `reporting-etl`, `usage_daily` table |
| **Systems NOT affected** | `billing` — verified: billing reads `usage_events` directly, not `usage_daily`; no invoice referenced the affected table in the window |
| Responders (roles) | Data engineer, analyst |

## Timeline

Most rows here are **derived** from data, not from logs — the job logged success throughout. That is itself the finding.

| UTC | Local | Event | Source | Confidence |
|-----|-------|-------|--------|------------|
| `2026-09-17 16:22` | `12:22` | Migration `0094_add_event_source.sql` added `event_source` and began writing a third event type | migration file, `git log -L` | Confirmed |
| `2026-09-18 02:00` | `2026-09-17 22:00` | First nightly run after the migration; `usage_daily` undercounted by 31% | derived: `usage_events` vs `usage_daily` comparison for that date | Confirmed |
| `2026-09-18 02:04` | `22:04` | Job reported success, exit 0 | `journalctl -u reporting-etl` | Confirmed |
| `—` | `—` | — gap: 11 nightly runs, each reporting success, no alert, no review — | no data-quality check exists for this table | — |
| `2026-09-29 11:40` | `07:40` | Analyst role noticed a weekly total below expectation and asked in the reporting channel | reporting channel, `11:40` | Confirmed |
| `2026-09-29 14:55` | `10:55` | Cause identified: the aggregation filters on a hardcoded list of two event types | `jobs/aggregate_usage.py:41`, incident channel | Confirmed |
| `2026-09-29 18:05` | `14:05` | Patched job deployed (`deploy-9103`) | deploy log | Confirmed |
| `2026-09-30 04:12` | `2026-09-29 00:12` | Backfill `bf-220` recomputed 2026-09-18 → 2026-09-29; totals matched `usage_events` | backfill log, post-backfill comparison | Confirmed |

## Severity

```text
SEV2 ← D1 users: no user-facing function failed; internal reports understated (SEV3)
     · D2 data: user-visible figures incorrect for 11 days, fully recoverable (SEV2)
     · D3 duration: 11 days of incorrect data (SEV1 by duration alone — see note)
     · D4 radius: one table, one downstream report (SEV3)
     · D5 regulatory: none; billing unaffected and verified (SEV4) → max = SEV2
```

**D3 note**: the 11-day duration maps to SEV1 on the duration axis, but D3 does not raise severity above D1 and D2 ([severity-classification.md](../frameworks/severity-classification.md) rule 4). With D1 at SEV3 and D2 at SEV2, the incident is SEV2 and the duration is recorded as the dominant *detection* problem instead.

## Contributing factors

### CF-1 — The aggregation filtered on a hardcoded list of event types (Confirmed)

**Condition**: `jobs/aggregate_usage.py:41` filters `event_type IN ('view', 'export')`; the migration added `'share'`.
**Evidence**: the source line, and the 31% delta matching the `share` volume exactly.
**If removed**: the new type would have been counted from the first run.

### CF-2 — The job's success signal measured completion, not correctness (Confirmed)

**Condition**: exit 0 means "ran without raising"; no row-count, no comparison against the source, no anomaly check.
**Evidence**: the job's only assertion is a non-empty result set.
**If removed**: 11 nights of success would have been 11 nights of a failing check.

### CF-3 — The migration and the consumer of its data are owned separately, with no contract between them (Confirmed)

**Condition**: adding an event type requires a change in a job the migration author does not own, and nothing links them — no schema contract, no test, no checklist.
**Evidence**: the migration touches no file under `jobs/`; no test covers the event-type list.
**If removed**: the coupling would have been visible at review time.

### CF-4 — No one looks at the daily numbers daily (Probable)

**Condition**: the report is reviewed weekly, so a daily error has a floor of about 7 days before a human can see it.
**Evidence**: detection came from a weekly total; the reporting channel has no daily reference to these figures. Probable: review cadence is inferred from the channel history, not from a documented process.
**If removed**: detection latency drops to about a day — still not good, which is why A-02 does not rely on humans.

## Detection gap

Onset was 2026-09-18 02:00; detection was 2026-09-29 11:40 — **11 days, 9 hours**. This is the incident. A row-count comparison between `usage_events` and `usage_daily` after each run would have failed on the first night, 11 days earlier. The data to perform that comparison already existed every night; nothing read it.

## What went well

1. Billing reads `usage_events` directly, so the incorrect aggregate never reached an invoice — verified by tracing the billing query path.
2. The source table `usage_events` was never modified, so the data was fully recoverable by backfill.
3. The backfill was idempotent (`ON CONFLICT DO UPDATE` on the date key), so it could be re-run safely — it was, twice, during validation.

## Action items

| ID | Type | Action | Traces to | Owner (role) | Due | Verification | State |
|----|------|--------|-----------|--------------|-----|--------------|-------|
| A-01 | detect | Compare `usage_daily` totals against `usage_events` after every run and fail the job on a delta above 0.5% | CF-2, detection gap | Data engineer | 2026-10-07 | Seed a deliberate mismatch in staging; the job exits non-zero and alerts | Open |
| A-02 | detect | Alert when any `event_type` present in `usage_events` is absent from the aggregation's filter | CF-1, CF-4 | Data engineer | 2026-10-07 | Add a test event type in staging; the alert fires within one run | Open |
| A-03 | prevent | Derive the event-type list from the schema instead of hardcoding it | CF-1 | Data engineer | 2026-10-14 | Adding an event type requires no change to `aggregate_usage.py`; a test proves it | Open |
| A-04 | prevent | Add a schema-contract check so a migration touching `usage_events` fails review until its consumers are listed | CF-3 | Data platform owner | 2026-10-28 | A PR adding a column without listing consumers fails the check | Open |
| A-05 | mitigate | Document the backfill procedure in the runbook, including the idempotency guarantee | — (recovery speed) | Data engineer | 2026-10-14 | A responder who has not run it executes a dated backfill in the next drill without assistance | Open |

Coverage: 2 detect, 2 prevent, 1 mitigate.

## Incident metrics

| Metric | Value | From → to | Evidence |
|--------|-------|-----------|----------|
| Time to detect | 11 d 9 h 40 min | `2026-09-18 02:00 → 2026-09-29 11:40 UTC` | first undercounted run (derived) → analyst message |
| Time to mitigate | 6 h 25 min | `2026-09-29 11:40 → 18:05 UTC` | detection → patched job |
| Time to resolve | 16 h 32 min | `2026-09-29 11:40 → 2026-09-30 04:12 UTC` | detection → backfill complete |
| Records affected | 11 daily rows, 31% understated on average | — | per-date comparison, post-backfill |
| Users affected | not measured | — | the report's viewers are not logged; no user-facing function failed |

## Out of scope & limitations

1. Who read the understated reports during the 11 days is unknown — report access is not logged. Any decision made on those figures has not been reviewed; the analyst role owns that follow-up.
2. The job's logs older than 7 days were rotated; the 11 success entries are confirmed for the last 7 runs only, and inferred for the first 4 from the data.
3. Other aggregation jobs were not audited for the same hardcoded-filter pattern. That audit is recommended and is not part of this incident — the data engineer role owns it.
4. No security assessment applies: the drift was a correctness defect with no access-control or exposure component. Had the cause been an authorization gap in the data path, it would have been handed to sar-cybersecurity rather than analyzed here.

## Lessons

| # | Lesson | Triggers on a plan that… | Evidence |
|---|--------|--------------------------|----------|
| L-1 | A job's exit code measures completion, not correctness; a data job needs a correctness assertion against its source | adds or changes a batch or aggregation job | INC-004 CF-2 |
| L-2 | A hardcoded enumeration of domain values drifts silently the first time the domain grows | filters on a hardcoded list of types, statuses, or categories | INC-004 CF-1 |
| L-3 | A schema change and the jobs that read it must be linked by a contract or a test, or the coupling is invisible at review | adds or changes a column other systems consume | INC-004 CF-3 |
| L-4 | Detection latency for a daily artifact reviewed weekly has a floor of about a week; automation is the only fix | relies on human review to catch data errors | INC-004 CF-4, 11-day gap |

## Gate

1. ✅ No individual is named as a cause — roles only
2. ✅ Every timeline row has a source, derivation, or an explicit gap row
3. ✅ Severity shows its rubric line, including why D3 did not raise it
4. ✅ Every causal claim carries Confidence (CF-4 is Probable)
5. ✅ Every action item has an owner role, a due date, and a verification step
6. ✅ Metrics are measured or marked `not measured`
7. ✅ Out of scope & limitations lists the evidence that was unavailable
8. ✅ What went well is not empty

---

## What to notice

1. **The severity rubric prevented inflation and deflation.** Eleven days feels like a SEV1; the rubric rule keeps duration from overriding user and data impact, and the duration is recorded where it matters — the detection gap.
2. **Derived evidence is still evidence**, as long as the derivation is named. "31% delta matching the `share` volume exactly" is stronger than any log line the job produced.
3. **The gap row covers 11 nights** and carries the reason: no data-quality check exists. That single row generates two of the five actions.
4. **Four of five actions are automation.** CF-4 (nobody looks daily) is real, but no action asks a human to look harder.
5. **The security handoff is declined explicitly.** Saying "no security assessment applies, and here is the condition under which it would" is what stops the next reader from assuming it was overlooked.
