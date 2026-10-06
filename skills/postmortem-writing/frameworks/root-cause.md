# Causal Analysis

A postmortem that names one root cause is usually describing the last thing that changed. Real incidents need several conditions to be true at once; removing any one of them would have prevented the outcome. That set is the analysis.

## Contributing factors — the method

For each factor, state the condition, its evidence, and what removing it would have changed.

```markdown
### CF-1 — The connection limit was raised without checking the database maximum (Confirmed)

**Condition**: the deploy set `pool.max=40` per instance across 6 instances (240 requested),
while `orders-db` allows 200 connections.
**Evidence**: `deploy-8841` diff, `config/pool.yaml:12`; `max_connections = 200` in the
database parameter group.
**If removed**: the deploy would have exhausted no connections; the incident needs this factor.

### CF-2 — No alert covered connection saturation before timeouts appeared (Confirmed)

**Condition**: the alert fired on request error rate, not on pool utilization.
**Evidence**: alert `pool-saturation-prod` definition, threshold `error_rate > 2%`.
**If removed**: detection would have moved from 14:12 to about 14:05 (first saturation sample).
```

Rules:

1. **Minimum two factors** for anything above SEV4. If the analysis truly finds one, say why explicitly — a single-factor incident means every other layer worked, which is itself worth recording.
2. **Each factor is independently removable.** If two "factors" always occur together, they are one.
3. **Each factor carries Confidence.**
4. **The triggering change is not a factor** — it is recorded separately. The deploy is what made the latent conditions matter; the conditions are what made the deploy harmful.

## Confidence

| Level | Means | Required |
|-------|-------|----------|
| **Confirmed** | The evidence shows it directly | Cite the evidence in the factor |
| **Probable** | The evidence is consistent and no alternative explains it as well | State the gap and what would confirm it |
| **Possible** | A hypothesis that fits | Label it; never present it as the cause, never base an action on it alone |

A `Possible` factor that matters gets an action item of type `detect` — instrument it so the next occurrence is Confirmed.

## Blameless rewriting — mandatory

A person is never a cause. When the input names someone, rewrite it into the condition that made the outcome possible and reachable.

| Input says | The report says |
|------------|-----------------|
| "An engineer pushed the wrong config" | The config change was applied to production without a check against the database limit; the pipeline has no such validation (CF-1) |
| "Human error in the runbook step" | The runbook step required a value to be copied by hand between two systems with no verification; a mismatch is undetectable until traffic arrives (CF-3) |
| "On-call missed the alert" | The alert routed to a channel that is not paged outside business hours; routing was never updated after the rotation changed (CF-2) |
| "QA did not catch it" | The staging database allows 500 connections, so the production limit is not reachable in any pre-production test (CF-4) |

"Human error" is never a root cause. The question is always: **what made that action possible, easy, or invisible?**

Roles may appear in the timeline and in action ownership. They never appear as a cause.

## Five Whys — one tool, not the method

Useful to walk from symptom to condition; dangerous when it produces a single chain and stops. Use it per factor, not per incident, and record Confidence at each step ([`templates/five-whys.md`](../templates/five-whys.md)). Stop when the answer becomes a design or process decision, not a person.

Other tools worth reaching for:

| Tool | Use when |
|------|----------|
| **Counterfactual test** | Checking whether a factor is really necessary: "remove it — does the incident still happen?" |
| **Change analysis** | The incident follows a deploy, config, or traffic change: diff what changed against what the system assumed |
| **Barrier analysis** | Several controls existed: list each barrier and why it did not stop the event (this feeds *What went well* too) |
| **Timeline dwell** | Long incidents: look at where time was spent (detect, diagnose, decide, act) — the longest phase is usually the best action |

## Detection gap — mandatory section

Answer in one short section: **what would have caught this earlier, and by how much?**

```markdown
## Detection gap

Onset was about 14:05 (first connection-wait samples); detection was 14:12 via the request
error-rate alert — a gap of about 7 minutes. Pool utilization was already at 100% at 14:05
and is collected, but no alert reads it. An alert at 85% utilization would have fired at
14:03, before user impact.
```

Quantify the gap when the timeline supports it. If it does not, say `not measured` and make the measurement an action.

## What went well — mandatory section

List the controls, alerts, and decisions that limited the damage, each with its evidence. This is not morale decoration: a team that documents only failures eventually deletes the safety net that saved it.

```markdown
## What went well

1. The unique constraint on `orders.idempotency_key` prevented duplicate orders during retries
   — verified: 0 duplicates in the window (`SELECT count(*) … GROUP BY … HAVING count(*) > 1`).
2. The rollback path was exercised in a drill in September and completed in 6 minutes.
3. Payments were isolated by a separate connection pool — no payment request failed.
```
