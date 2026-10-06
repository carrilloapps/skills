# Timeline Reconstruction

> ⚠️ **Example code boundary** — log excerpts below are synthetic illustrations, not real incident data.

The timeline is the backbone of the report. Nothing in the analysis may contradict it, and anything not in it is not evidence.

## Row format

| UTC | Local | Event | Source | Confidence |
|-----|-------|-------|--------|------------|
| `14:04:11` | `10:04 VET` | Deploy `deploy-8841` reached the last instance | deploy log, `deploy-8841` | Confirmed |
| `14:12:03` | `10:12 VET` | Alert `pool-saturation-prod` fired | alert ID `A-7781` | Confirmed |
| `14:19` | `10:19 VET` | On-call engineer began investigating the checkout error rate | on-call role, incident channel, `14:19` | Confirmed |
| `~14:30` | `~10:30 VET` | Connection waits began exceeding the request timeout | `checkout-api` log, 412 matching lines | Probable — log sampling is 1:10 |
| `[unknown]` | `[unknown]` | First user-visible failure | — | — |

Rules:

1. **Two clocks, always.** UTC is the canonical column; the team's local zone is the one people remember. Name the zone (`VET`, `CET`), never just "local".
2. **Every row has a source.** A log line, alert ID, commit SHA, deploy ID, dashboard panel, ticket, or message reference.
3. **A statement from a person is attributed to a role and a time** — never to a name. "On-call engineer, incident channel, 14:19", not "María said".
4. **`[unknown]` is a valid value.** Writing `~14:00` when the evidence does not support it is fabrication. `~` is allowed only when the evidence gives a bounded range, and the bound is stated in Confidence.
5. **Precision matches the source.** A log line gives seconds; a chat message gives minutes. Do not add digits the source does not have.
6. **Confidence per row** when it is not Confirmed: state the gap (sampling, clock skew, a reconstructed order).

## Gaps are rows

A period with no evidence is written down, not smoothed over:

```markdown
| `14:47` | `10:47 VET` | — gap: no evidence between 14:47 and 15:10 — | metrics retention is 15 min at 1-minute resolution | — |
```

A gap is often the most actionable thing in the report: it is a missing-observability finding, and it belongs in the Detection gap section.

## Clock skew

Sources disagree. When two sources differ for the same event:

1. Keep the **source-reported** times, both of them, in the row's Source column.
2. State the skew (`the gateway is +4 s ahead of the app host, measured on 2026-10-06`).
3. Order by the canonical source, and say which one that is.

Never silently normalize timestamps. An unexplained reordering can invert cause and effect.

## Required anchor events

Every timeline must try to establish these five, and mark `[unknown]` where it cannot:

| Anchor | Why it matters |
|--------|----------------|
| **Change** — the deploy, config, flag, or traffic shift | Separates the trigger from the conditions |
| **Onset** — first failure, user-visible or not | Start of impact; input to time-to-detect |
| **Detection** — alert fired, or a person noticed | The honest detection time, including "a customer told us" |
| **Mitigation** — impact stopped | Input to time-to-mitigate |
| **Resolution** — permanent fix in place | Input to time-to-resolve; often days later |

`Onset` and `Detection` being far apart **is** the detection gap. Record both even when one is `[unknown]`, and say which is which — a timeline that starts at the alert hides the gap.

## Working order

1. Start from the two times you are sure of (usually detection and mitigation).
2. Work outward to the change and to the onset.
3. Fill the middle from logs and the incident channel.
4. Mark gaps.
5. Re-read the result and check that every causal claim you intend to make is supported by a row. If it is not, either find the evidence or lower the claim's Confidence.
