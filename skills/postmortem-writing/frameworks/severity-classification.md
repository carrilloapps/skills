# Severity Classification

Severity is **deterministic**: five dimensions, each scored independently, and the incident's severity is the **highest** dimension that matches. Never an average, never a feeling, never negotiated downward because the fix was quick.

## The five dimensions

| Dimension | SEV1 | SEV2 | SEV3 | SEV4 |
|-----------|------|------|------|------|
| **D1 User impact** | Core function unusable for all or most users | Core function degraded, or unusable for a subset | Non-core function affected, workaround exists | No user-visible impact (internal or near miss) |
| **D2 Data** | Loss, corruption, or unauthorized disclosure of data | Data incorrect or stale in a user-visible way, recoverable | Data incorrect in an internal system only | No data affected |
| **D3 Duration** | > 4 h, or any duration with D1/D2 at SEV1 | 30 min – 4 h | < 30 min | No impact window |
| **D4 Blast radius** | Multiple systems or tenants, or a dependency others rely on | One system, many users | One system, few users or one tenant | Contained to a non-production or single-instance surface |
| **D5 Regulatory / financial** | Reportable event, money moved incorrectly, or contractual breach | Financial exposure without loss, or an SLA breach | Internal policy deviation | None |

## The rubric line — mandatory

Every report states its classification as one line, so a reader can re-derive it:

```text
SEV2 ← D1 users: checkout degraded for ~18% of sessions (SEV2) · D2 data: none (SEV4)
     · D3 duration: 95 min (SEV2) · D4 radius: one service, one region (SEV2)
     · D5 regulatory: none (SEV4) → max = SEV2
```

Rules:

1. Each dimension names the **evidence**, not an adjective. "18% of sessions" is evidence; "significant" is not.
2. A dimension with no evidence is `[unknown]` and is **excluded** from the maximum, and the exclusion is stated. It never silently lowers severity.
3. The final value is the maximum of the scored dimensions. Write `→ max = SEVn`.
4. D3 alone never raises severity above D1 and D2: a four-hour incident with no user impact and no data effect is SEV4 by D1/D2 and the duration is noted as context. The exception is written into D3 itself (`or any duration with D1/D2 at SEV1`).

## Near misses

An incident with no user impact is still a postmortem when a control nearly failed. Classify it SEV4 and add the counterfactual explicitly:

```text
SEV4 ← all dimensions SEV4 → max = SEV4
Counterfactual: had the expiry not been caught, D1 would have been SEV1 (all API clients
rejected) and D3 SEV1 (> 4 h to reissue). Recorded as a near miss.
```

Near misses are the cheapest lessons a team ever gets. Treating them as "nothing happened" is how the same gap produces a SEV1 later.

## Reclassification

Severity may change when evidence does — never because the conversation got uncomfortable. When it changes:

1. Keep the original line and add the new one.
2. State the evidence that moved it.
3. Record both values in the registry (`severity`, `severityInitial`).

```text
Initial: SEV3 ← D1 users: assumed internal only (SEV3) …
Revised: SEV2 ← D1 users: 240 external API consumers affected, confirmed in the gateway log
         (SEV2) … → max = SEV2
Reason: the gateway access log was not available during the first pass.
```
