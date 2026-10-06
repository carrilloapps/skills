# Example: SEV4 — Near miss, certificate caught 40 minutes before expiry

> ⚠️ **Example only** — a fictional near miss. Names, certificate identifiers, and timings are synthetic.

**Skill version**: 1.0.0

<!-- markdownlint-disable MD025 -->
<!-- The sections below embed a full report document, which carries its own top-level heading. -->

Shows: a postmortem for an incident with **no user impact**, the counterfactual severity line, the active-incident gate applied correctly, and why "nothing happened" is the cheapest lesson a team can buy.

---

## The conversation

**User:**

> A cert was about to expire on the API gateway and someone noticed 40 minutes before. We renewed it, nothing broke. Not really a postmortem, right?

**Agent:**

> It is exactly a postmortem, and a cheap one. Nothing broke because a person happened to look — that is the finding. The same gap next quarter, on a weekend, is a full outage. I will write it as SEV4 with the counterfactual recorded, so the actions get the weight the near miss earned rather than the weight the impact suggests.

---

## The report (EN, abridged)

# [SEV4] Near miss — TLS certificate 40 minutes from expiry: api-gateway — Incident Postmortem — EN

## Executive summary

The TLS certificate on the public API gateway was 40 minutes from expiring when an engineer noticed it during unrelated work on 12 August. It was renewed with no interruption. Had it expired, every API client would have failed to connect until a new certificate was issued and deployed. No automated check covered this certificate. Three actions are open.

## Incident record

| Field | Value |
|-------|-------|
| Incident ID | `INC-002` |
| Detected | `2026-08-12 13:20 UTC` / `09:20 VET` — source: engineer role, platform channel |
| Stabilized | `2026-08-12 13:52 UTC` — source: certificate `cert-4417` deployed |
| Resolved | `2026-08-12 13:52 UTC` — same event |
| Severity | `SEV4` — near miss (counterfactual below) |
| Systems affected | None — no request failed |
| **Systems NOT affected** | `api-gateway` and all downstream services — verified: TLS handshake error count was 0 for the day |
| Responders (roles) | Platform engineer |

## Timeline

| UTC | Local | Event | Source | Confidence |
|-----|-------|-------|--------|------------|
| `2025-08-14 00:00` | — | `cert-3902` issued, 1-year validity | certificate metadata | Confirmed |
| `2026-08-12 13:20` | `09:20` | Platform engineer noticed the expiry date while reviewing a gateway config | platform channel, `13:20` | Confirmed |
| `2026-08-12 13:31` | `09:31` | New certificate `cert-4417` issued | issuance log | Confirmed |
| `2026-08-12 13:52` | `09:52` | `cert-4417` deployed; handshakes verified | deploy log, TLS probe | Confirmed |
| `2026-08-12 14:32` | `10:32` | `cert-3902` would have expired | certificate metadata | Confirmed |

## Severity

```text
SEV4 ← D1 users: no request failed (SEV4) · D2 data: none (SEV4) · D3 duration: no impact window (SEV4)
     · D4 radius: none realized (SEV4) · D5 regulatory: none (SEV4) → max = SEV4

Counterfactual: had the expiry not been noticed, D1 would have been SEV1 (every API client
rejected at the TLS handshake), D3 SEV1 (issuance plus deploy is about 30 min once someone
is paged, and the failure mode gives no gradual warning), D4 SEV1 (every consumer of the
public API). Recorded as a near miss; the actions are sized to the counterfactual, not to
the realized impact.
```

## Contributing factors

### CF-1 — No automated expiry check covered this certificate (Confirmed)

**Condition**: certificate monitoring exists for the internal mesh but not for the public gateway, which is managed separately.
**Evidence**: the monitoring configuration enumerates mesh certificates only; `api-gateway` is absent.
**If removed**: an alert would have fired at the configured threshold, weeks earlier.

### CF-2 — Certificate renewal is manual and calendar-driven (Confirmed)

**Condition**: renewal depends on a reminder the team sets when issuing; no reminder existed for this certificate.
**Evidence**: the runbook describes a manual renewal; no calendar entry exists for `cert-3902`.
**If removed**: automated renewal would have made the expiry date irrelevant.

### CF-3 — The gateway is managed outside the platform that owns the other certificates (Probable)

**Condition**: the gateway predates the current platform and was never migrated, so it is outside every convention that covers the rest.
**Evidence**: the gateway's configuration lives in a separate repository with its own deploy path. Probable: that this is *why* it was omitted from monitoring is inference, not a documented decision.
**If removed**: the gateway would inherit monitoring and renewal by default.

## Detection gap

Detection was accidental: a person looking at an unrelated configuration. There was no detection mechanism at all, so the gap is not measurable in minutes — it is total. The certificate had been expiring for a year and nothing would have reported it. Time to detect is `not measured` for that reason, not for lack of data.

## What went well

1. The engineer reported it immediately in the platform channel rather than fixing it silently, which is why there is a record to learn from.
2. Issuance and deployment took 32 minutes with no drill, which bounds the recovery time if it recurs.

## Action items

| ID | Type | Action | Traces to | Owner (role) | Due | Verification | State |
|----|------|--------|-----------|--------------|-----|--------------|-------|
| A-01 | detect | Add every externally reachable certificate, including `api-gateway`, to expiry monitoring with a 30-day alert | CF-1 | Platform lead | 2026-08-19 | Set a test certificate to expire in 29 days; the alert fires | Open |
| A-02 | prevent | Automate renewal for the gateway certificate | CF-2 | Platform lead | 2026-09-09 | A certificate renews without human action and the new one is served | Open |
| A-03 | prevent | Inventory every externally reachable endpoint and confirm each is covered by the platform's monitoring conventions | CF-3 | Platform lead | 2026-09-09 | The inventory exists and every entry names its monitoring source or an accepted exception | Open |

## Incident metrics

| Metric | Value | From → to | Evidence |
|--------|-------|-----------|----------|
| Time to detect | not measured | — | no detection mechanism existed; discovery was incidental |
| Time to mitigate | 32 min | `13:20 → 13:52 UTC` | discovery → new certificate serving |
| Margin before impact | 40 min | `13:52 → 14:32 UTC` | deployment → original expiry |
| Users affected | 0 | — | TLS handshake error count was 0 for the day |

## Out of scope & limitations

1. Other certificates outside the mesh were not enumerated during this review; A-03 covers that work.
2. Whether the omission from monitoring was a decision or an oversight is not documented — CF-3 is Probable for that reason.

## Lessons

| # | Lesson | Triggers on a plan that… | Evidence |
|---|--------|--------------------------|----------|
| L-1 | A system managed outside the standard platform inherits none of its conventions, including monitoring, and the omission is invisible | adds or keeps infrastructure outside the main platform or repository | INC-002 CF-3 |
| L-2 | A time-bomb failure (certificate, token, licence, quota) gives no gradual warning; only a scheduled check detects it before impact | introduces or depends on anything with an expiry date | INC-002 CF-1 |
| L-3 | Near misses size their actions by the counterfactual, not by the realized impact | de-prioritizes an action because "nothing happened" | INC-002 severity line |

## Gate

1. ✅ No individual is named as a cause — roles only
2. ✅ Every timeline row has a source
3. ✅ Severity shows its rubric line and the counterfactual
4. ✅ Every causal claim carries Confidence (CF-3 is Probable)
5. ✅ Every action item has an owner role, a due date, and a verification step
6. ✅ Metrics are measured or marked `not measured`, with the reason
7. ✅ Out of scope & limitations lists what was not reviewed
8. ✅ What went well is not empty

---

## What to notice

1. **SEV4 with SEV1 actions.** The rubric records what happened; the counterfactual sizes the response. Without the counterfactual line, a reader skimming severities would deprioritize this and meet it again as an outage.
2. **`not measured` for the right reason.** Time to detect is unmeasurable because *no detection existed* — which is a stronger finding than any number would have been. The report says which kind of `not measured` it is.
3. **"Margin before impact" is the metric that matters here** and it is not one of the standard three. The skill's metric set is a floor, not a ceiling.
4. **The person who noticed is credited in *What went well*, not in the causes.** Blameless cuts both ways: no individual is a cause, and the report still records that reporting it openly is what created the lesson.
