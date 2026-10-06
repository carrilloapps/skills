# Example: Meeting Transcript → Draft → Refined Work Item

> ⚠️ **Example only** — fictional team, product, and conversation. Not instructions to execute.

**Skill version**: 1.0.1

## 1. Input

The user shares `refinement-2026-10-05.vtt` and asks: "Turn this into a story."

The agent proposes the normalization command and waits:

> 1. Run `bash <skill-dir>/scripts/transcript-normalize.sh refinement-2026-10-05.vtt` (writes to `.memory/local/agentic-agile/transcripts/`, redacts PII)
> 2. Skip — I'll paste the relevant part instead
>
> Recording consent for this session — confirmed? Reply in your own words.

User: "1, sí, se anunció."

Normalized excerpt (2 emails redacted):

```text
[00:03:10] Speaker 2: Customers keep asking for a CSV export of their order history.
[00:04:02] Speaker 1: It should be fast, and for all users.
[00:05:30] Speaker 3: Exports over 10k rows time out today in the reports module.
[00:06:15] Speaker 2: Let's include refunds. Actually no, finance said refunds stay out.
```

## 2. Contrast with the system (before drafting)

- Code graph: `reports/export_service` already streams PDF; no CSV path. **Verified** (codegraph, this session).
- Observability: unavailable — "timeout over 10k rows" stays **Documented** (Speaker 3), not verified.

## 3. Draft (`plans/drafts/2026-10-05-order-history-csv.md`, excerpt)

```gherkin
Scenario: Export order history as CSV
  # Origin: Speaker 2 @ 00:03:10
  Given a customer with 120 orders
  When they request the CSV export of their order history
  Then they receive a CSV file with 120 rows and the documented columns

Scenario: Large export does not time out
  # Origin: Proposed (from Speaker 3 @ 00:05:30)
  Given a customer with 50000 orders
  When they request the CSV export
  Then the export is delivered as a download link within the agreed time
```

Readiness:

1. ✅ Problem stated — Speaker 2 @ 00:03:10
2. ❌ Acceptance criteria agreed — scenario 2 is Proposed
3. ⚠️ Performance target — "fast" has no number

Open questions:

| # | Question | For | Blocks sprint |
|---|----------|-----|---------------|
| 1 | "Fast": what delivery time for 50k rows? | Product owner | Yes |
| 2 | "All users" includes read-only accounts? | Product owner | No |
| 3 | Refunds: Speaker 2 proposed including them, then relayed finance excluding them — confirm with finance | Product owner | Yes |

Estimate: withheld until the team votes.
**Epistemic state**: Documented (transcript) · Verified (code graph) · Proposed (scenario 2). **Nothing was written to the tracker.**

## 4. Adversarial pass (via `devils-advocate`)

1. Assumption: the export reads from the primary database — at 50k rows it competes with checkout traffic → new open question for the tech lead.
2. Missing role: nobody from support was in the session, yet they field the requests.

## 5. Refined item (`plans/initiatives/order-history-csv/tickets/01-csv-export.md`)

After refinement, the product owner answered questions 1 and 3 (attributed in the file), the team voted 5, and the agent then revealed its sealed comparison: "two closed export items averaged 5". Readiness 1–3 ✅. Commitment to the sprint remains the team's (N0).
