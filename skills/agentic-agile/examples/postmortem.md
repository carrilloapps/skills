# Example: Blameless Postmortem

> ⚠️ **Example only** — fictional incident, systems, and times.

**Skill version**: 1.0.2

User: "Draft the postmortem for yesterday's export outage. Here is the alert history and the incident channel export."

`plans/decisions/2026-10-04-postmortem-export-timeouts.md` (draft):

```markdown
# Postmortem: Order export timed out for large accounts

**Date of incident**: 2026-10-03 · **Severity**: SEV-3 (team scale) · **Status**: Draft

Blameless: this document describes systems, signals, and decisions — never a person as the cause.

## 1. Summary
For 47 minutes, CSV exports for accounts with more than 50,000 orders timed out. Smaller accounts were unaffected.

## 2. Impact
312 failed export requests (source: API gateway logs, 14:05–14:52 UTC). No data loss; users retried after the fix.

## 3. Timeline
| Time (UTC) | Event | Source | Attribution |
|------------|-------|--------|-------------|
| 13:58 | Release 4.12 deployed | deploy log | pipeline |
| 14:05 | Timeout alert fires | alerting | automated |
| 14:19 | "Large accounts only" observed | incident channel | on-call engineer |
| 14:41 | Rollback started | deploy log | pipeline |
| 14:52 | Error rate back to baseline | dashboard | automated |

## 4. Root cause
Release 4.12 removed pagination from the export query, so the query loaded every order into memory before streaming. Nothing in the test suite exercised a large history.

## 5. Contributing factors
1. The load-test data set has at most 2,000 orders per account.
2. The spec scenario for large histories was marked out of scope in an earlier initiative and never revisited.

## 6. What went well
1. The alert fired within 7 minutes of the deploy.
2. Rollback took 11 minutes, inside the documented window.

## 7. Actions
| # | Action | Type | Owner | Due date | Tracking |
|---|--------|------|-------|----------|----------|
| 1 | Restore pagination and add a 100k-order scenario to the spec | prevent | export maintainer | 2026-10-10 | after approval |
| 2 | Add a large-account data set to load tests | detect | QA lead | 2026-10-17 | after approval |

## 8. Lessons for future plans
Any change to query shape on export paths must state its memory behavior for the largest account (fed to devils-advocate).

## Gate
1. ✅ No person is named as a cause.
2. ✅ Every timeline line has a source.
3. ✅ Every action has an owner and a date.
4. ✅ Root cause and contributing factors are separated.
```

Open questions: 1. Is SEV-3 the right severity on the team's scale? — for the incident commander.
Epistemic state: timeline Verified from the alert history and channel export; root cause Verified from the release diff; actions Proposed until the owners accept them. Nothing was written to the tracker.
