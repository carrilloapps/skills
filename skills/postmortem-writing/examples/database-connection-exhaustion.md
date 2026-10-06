# Example: SEV1 — Checkout outage from connection pool exhaustion

> ⚠️ **Example only** — a fictional incident at a fictional company. Every service name, alert ID, commit, and log line is synthetic. Nothing here describes a real system and no command is meant to be executed.

**Skill version**: 1.0.0

<!-- markdownlint-disable MD025 -->
<!-- The sections below embed a full report document, which carries its own top-level heading. -->

Shows: the active-incident gate, the severity rubric line, blameless rewriting of a person-shaped input, a timeline with a gap, measured metrics, and all three action types.

---

## What the user said

> Checkout was down for an hour and a half last night. One of the engineers pushed a bad config. Write the postmortem.

Two problems with that input: the incident state is unstated, and the cause is attributed to a person. The agent handles both before writing.

> Before I write it: is the incident fully stabilized, or is anything still being watched? And one thing about framing — a postmortem never records a person as the cause. I will describe the change that shipped and the conditions that made it harmful, which is also what produces usable action items. Where should the report go, and is this repository public?

*(User: stabilized at 15:47, private repository, `docs/postmortems/`, both languages. Evidence: `journalctl` for `checkout-api`, the deploy log, the alert history, and the incident channel export.)*

---

## The report (EN)

# [SEV1] Connection pool exhaustion: checkout-api — Incident Postmortem — EN

> 🌐 Also available in: `2026-10-06_SEV1_CHECKOUT-DB-POOL-EXHAUSTION_ES.md`

Blameless: this document describes systems, signals, and decisions. No individual is a cause.

## Executive summary

Checkout was unusable for all users for 95 minutes on 6 October. A deploy raised the per-instance database connection limit so that the six instances together requested more connections than the database allows, so checkout could not get a connection. A rollback restored service. No orders were lost and no payment data was affected. Four actions are open, the first due 13 October.

## Incident record

| Field | Value |
|-------|-------|
| Incident ID | `INC-003` |
| Detected | `2026-10-06 14:12 UTC` / `10:12 VET` — source: alert `A-7781` (`pool-saturation-prod`) |
| Stabilized | `2026-10-06 15:47 UTC` — source: rollback `deploy-8842` |
| Resolved | `2026-10-07 09:20 UTC` — source: PR #412 merged |
| Severity | `SEV1` (rubric line below) |
| Systems affected | `checkout-api`, `orders-db` (connection layer) |
| **Systems NOT affected** | `payments-api`, `billing` — verified: no error-rate change in their dashboards for the window; `payments-api` holds a separate pool |
| Responders (roles) | On-call engineer, platform lead |
| Report author | Agent, reviewed by the platform lead |

## Timeline

All times UTC and VET. Canonical clock: the deploy service.

| UTC | Local | Event | Source | Confidence |
|-----|-------|-------|--------|------------|
| `14:04:11` | `10:04` | `deploy-8841` reached the last of 6 instances; `pool.max` 20 → 40 per instance | deploy log `deploy-8841` | Confirmed |
| `~14:05` | `~10:05` | Pool utilization reached 100% on all instances | `pool.utilization` metric, 1-min resolution | Confirmed |
| `14:12:03` | `10:12` | Alert `A-7781` fired on checkout error rate > 2% | alert history `A-7781` | Confirmed |
| `14:19` | `10:19` | On-call engineer began investigating | on-call role, incident channel `14:19` | Confirmed |
| `14:31` | `10:31` | 412 log lines matching `timeout acquiring connection after 5000ms` | `journalctl -u checkout-api` | Confirmed |
| `14:47` | `10:47` | — gap: no metric data between 14:47 and 15:10 — | `checkout-api` metric retention is 15 min at 1-min resolution | — |
| `15:07` | `11:07` | Cause identified: requested 240 connections against a 200 limit | incident channel, platform lead `15:07` | Confirmed |
| `15:18` | `11:18` | Rollback decision taken | incident channel, platform lead `15:18` | Confirmed |
| `15:47:22` | `11:47` | Rollback `deploy-8842` completed; error rate returned to baseline | deploy log, `error_rate` metric | Confirmed |
| `[unknown]` | `[unknown]` | First user-visible failure | — | — |

Onset is bounded to about 14:05 by the utilization metric, but the first failed user request is not retained — hence `[unknown]` for that row and `not measured` for users affected.

## Severity

```text
SEV1 ← D1 users: checkout unusable for all users (SEV1) · D2 data: none, 0 orders lost (SEV4)
     · D3 duration: 102 min with D1 at SEV1 (SEV1) · D4 radius: one service, all regions (SEV2)
     · D5 regulatory: none (SEV4) → max = SEV1
```

Initial classification was SEV2 on the assumption that a subset was affected; the gateway access log showed every checkout request failing, which moved D1 to SEV1.

## Contributing factors

### CF-1 — A per-instance connection limit was raised without validating the shared database maximum (Confirmed)

**Condition**: `deploy-8841` set `pool.max=40` per instance across 6 instances — 240 connections requested — while `orders-db` allows 200.
**Evidence**: `deploy-8841` diff, `config/pool.yaml:12`; `max_connections = 200` in the database parameter group (`infra/rds/orders.tf:28`).
**If removed**: the deploy would have exhausted no connections. The incident requires this factor.

### CF-2 — No alert covered connection saturation; detection waited for user-visible errors (Confirmed)

**Condition**: alerting read `error_rate`, not `pool.utilization`, although utilization is collected.
**Evidence**: alert `pool-saturation-prod` definition — despite its name, its condition is `error_rate > 2%`.
**If removed**: detection moves from 14:12 to about 14:05.

### CF-3 — The staging database allows 500 connections, so the production limit is unreachable in pre-production (Confirmed)

**Condition**: staging `max_connections = 500`; the 240-connection configuration passes there.
**Evidence**: `infra/rds/orders-staging.tf:28`.
**If removed**: the configuration would have failed in staging first.

### CF-4 — Connection waits queued until the request timeout instead of shedding load (Probable)

**Condition**: the pool blocks for up to 5 s per request under saturation, so saturation became timeouts rather than fast rejections, lengthening diagnosis.
**Evidence**: 412 `timeout acquiring connection after 5000ms` lines; pool configuration has no `maxWait` below the request timeout. Probable: the diagnosis-time effect is inferred from the timeline, not measured.
**If removed**: user requests would have failed fast and the saturation signal would have been unambiguous.

## Triggering change

`deploy-8841`, merged as PR #408 and deployed at 14:04 UTC, raised `pool.max` from 20 to 40 to address a latency complaint. The change is the trigger; CF-1 through CF-4 are why it became an outage.

## Detection gap

Onset was about 14:05; detection was 14:12 — about 7 minutes, and detection came from a downstream symptom. `pool.utilization` was already at 100% at 14:05 and is collected at 1-minute resolution. An alert at 85% utilization would have fired around 14:03, before user impact.

## What went well

1. The unique constraint on `orders.idempotency_key` prevented duplicate orders during client retries — verified: 0 duplicate keys in the window.
2. `payments-api` holds a separate connection pool, so no payment request failed — verified: flat error rate in its dashboard.
3. The rollback path had been exercised in a September drill and completed in 6 minutes once the decision was taken.

## Action items

| ID | Type | Action | Traces to | Owner (role) | Due | Verification | State |
|----|------|--------|-----------|--------------|-----|--------------|-------|
| A-01 | prevent | Fail the deploy pipeline when `pool.max × instance_count > db.max_connections` | CF-1 | Platform lead | 2026-10-13 | A PR setting 40 × 6 against a 200-connection database fails the check | Open |
| A-02 | detect | Alert on `pool.utilization > 85%` for 2 minutes, routed to the paged channel | CF-2, detection gap | On-call rotation owner | 2026-10-13 | Alert fired deliberately in staging reaches the pager | Open |
| A-03 | mitigate | Set the pool wait below the request timeout so saturation sheds load instead of queueing | CF-4 | Checkout service owner | 2026-10-27 | Load test at 2× pool capacity returns 503 within 1 s instead of timing out at 5 s | Open |
| A-04 | prevent | Align the staging database connection limit with production, or document the divergence as accepted | CF-3 | Platform lead | 2026-10-27 | `max_connections` matches in both parameter groups, or an accepted-risk record exists | Open |

## Incident metrics

| Metric | Value | From → to | Evidence |
|--------|-------|-----------|----------|
| Time to detect | 7 min | `~14:05 → 14:12 UTC` | utilization metric → alert `A-7781` |
| Time to mitigate | 95 min | `14:12 → 15:47 UTC` | alert `A-7781` → rollback `deploy-8842` |
| Time to resolve | 19 h 8 min | `14:12 UTC 06 Oct → 09:20 UTC 07 Oct` | alert → PR #412 merged |
| Impact duration | 102 min | `~14:05 → 15:47 UTC` | onset → mitigation |
| Users affected | not measured | — | per-user attribution is not retained; every checkout request in the window failed |

Phase breakdown: detect 7 min · diagnose 48 min (14:19 → 15:07) · decide 11 min · act 29 min. Diagnosis dominates, which is what A-02 and A-03 address.

## Out of scope & limitations

1. Metric data between 14:47 and 15:10 is unavailable (15-minute retention at 1-minute resolution), so the saturation curve in that window is not reconstructable. Not an action: the window is covered by log evidence.
2. The first user-visible failure time is not retained; onset is bounded by the utilization metric, not measured directly.
3. No live database query was run; the connection limit was read from the IaC parameter group.
4. The latency complaint that motivated PR #408 was not investigated here — it remains open and belongs to the checkout service owner.

## Lessons

| # | Lesson | Triggers on a plan that… | Evidence |
|---|--------|--------------------------|----------|
| L-1 | A per-instance resource limit must be validated against the shared backend maximum, because instance count multiplies it | changes a pool size, replica count, or any per-instance limit on a service sharing a backend | INC-003 CF-1 |
| L-2 | An alert on a downstream symptom detects later than one on the saturating resource | adds or changes alerting for a resource-constrained service | INC-003 CF-2, 7-minute gap |
| L-3 | A pre-production environment with looser limits than production cannot reach the production failure mode | relies on staging to validate a capacity or limit change | INC-003 CF-3 |
| L-4 | Blocking under saturation converts a resource signal into a timeout signal and lengthens diagnosis | introduces or tunes a blocking resource pool | INC-003 CF-4, 48-min diagnose phase |

## Registry snapshot

| ID | Date | Sev | Title | Open actions | Status |
|----|------|-----|-------|--------------|--------|
| INC-003 | 2026-10-06 | SEV1 | Checkout unavailable from connection pool exhaustion | 4 | Open |
| INC-002 | 2026-08-19 | SEV3 | Stale cache after a config change | 0 | Closed |
| INC-001 | 2026-06-02 | SEV2 | Partial search outage after an index rebuild | 1 | Open |

## Gate

1. ✅ No individual is named as a cause — roles only
2. ✅ Every timeline row has a source, `[unknown]`, or an explicit gap row
3. ✅ Severity shows its rubric line and the maximum dimension
4. ✅ Every causal claim carries Confidence (CF-4 is Probable, with the gap stated)
5. ✅ Every action item has an owner role, a due date, and a verification step
6. ✅ Metrics are measured or marked `not measured`
7. ✅ Out of scope & limitations lists the evidence that was unavailable
8. ✅ What went well is not empty

---

## What to notice

1. **The person disappeared and the analysis got better.** "An engineer pushed a bad config" produces one action: be careful. The structural rewrite produced four, each verifiable.
2. **The deploy is the trigger, not the cause.** Separating them is what makes CF-2, CF-3, and CF-4 visible — all three existed before the deploy and will outlive it.
3. **`not measured` is load-bearing.** Users affected is unknown, so it is not invented; the phase breakdown that *is* measured points directly at the two best actions.
4. **The gap row is evidence.** It bounds what the report can claim and explains why onset is `~14:05`.
5. **What went well is not decoration.** The separate payments pool and the idempotency key are the reason this was a 95-minute outage and not a financial incident.
