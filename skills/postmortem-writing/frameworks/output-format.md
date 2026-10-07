# Output Specification

## Directory

The directory confirmed in Step 0. Default `docs/postmortems/` (versioned — the team's record).

Whether the reports and the registry are versioned at all is **the team's choice**, the same choice agentic-agile applies to `specs/` and `plans/`: versioned gives the team a reviewable, durable record; ignored keeps incident detail on one machine. Ask in Step 0 and respect the answer; never decide it silently, and never run a VCS command to apply it. The trade-off, what changes either way, and how to switch later are owned by agentic-agile [`frameworks/artifact-versioning.md`](../../agentic-agile/frameworks/artifact-versioning.md). The public-repository rule below is a separate, stricter safeguard that applies whatever the choice.

### Public repositories

If the repository is public **and** the incident exposes a vulnerability that is not yet fixed, the reports go to `.memory/local/postmortems/` instead, which is never versioned. Publishing an open vulnerability with a timeline that shows how it was triggered is a handed-over exploit. Once the fix ships, the team may move the report into the versioned directory — the agent proposes it, the team decides.

When the answer in Step 0 is missing, treat the repository as public (safest).

## File naming

```text
YYYY-MM-DD_SEVn_<slug>_EN.md     ← English
YYYY-MM-DD_SEVn_<slug>_ES.md     ← Spanish (es_VE)
```

1. The date is the **incident start** date, ISO, so the directory sorts chronologically.
2. `SEVn` is the final severity, so the worst incidents are visible from the file list alone.
3. `<slug>` is SCREAMING-KEBAB-CASE, max 50 characters, naming the **failure**, not the fix: `CHECKOUT-DB-POOL-EXHAUSTION`, not `POOL-SIZE-INCREASED`.
4. Both files cross-link at the top: `> 🌐 Also available in: [Español (es_VE)](./2026-10-06_SEV2_….md)`.
5. Single-language output only when the user asks.

## Required document structure

```markdown
# [SEVn] <Failure>: <system> — Incident Postmortem — [LANG]

> 🌐 Also available in: [link to counterpart]

## Table of contents
## Executive summary              (≤ 5 lines, impact first, no jargon)
## Incident record                (the facts table, including systems NOT affected)
## Timeline                       (one row per event, source on every row)
## Severity                       (the rubric line)
## Contributing factors           (with Confidence each)
## Triggering change
## Detection gap                  (what would have caught this earlier)
## What went well                 (mandatory — the controls that limited damage)
## Action items                   (prevent / detect / mitigate, owner role, due date, verification)
## Incident metrics               (measured only)
## Dependency chain               (optional Mermaid diagram)
## Out of scope & limitations      (mandatory — what was NOT reviewed, evidence unavailable)
## Lessons                        (export for devils-advocate)
## Registry snapshot              (mandatory)
## Revision history               (only when re-opened)
## Gate                           (numbered pass/fail items)
```

### Executive summary — mandatory, ≤ 5 lines

Written for a reader who will not read further. Impact first, cause second, state third. No jargon, no component names without a gloss.

```markdown
## Executive summary

Checkout was unavailable for about 18% of sessions for 95 minutes on 6 October. A deploy
raised the per-instance database connection limit above what the database allowed, so new
checkout requests could not get a connection. A rollback restored service. No orders were
lost and no payment data was affected. Four actions are open, the first due 13 October.
```

### Incident record

| Field | Value |
|-------|-------|
| Incident ID | `INC-003` (registry) |
| Detected | `2026-10-06 14:12 UTC` / `10:12 VET` — source: alert `pool-saturation-prod` |
| Stabilized | `2026-10-06 15:47 UTC` — source: rollback `deploy-8841` |
| Resolved | `2026-10-07 09:20 UTC` — source: PR #412 merged |
| Severity | `SEV2` (rubric line in § Severity) |
| Systems affected | `checkout-api`, `orders-db` (connection layer) |
| **Systems NOT affected** | `payments-api`, `billing` — verified: no error-rate change in the dashboards for the window |
| Responders (roles) | On-call engineer, platform lead |
| Report author | Agent, reviewed by the platform lead |

The **NOT affected** row is mandatory. A negative confirmation with its evidence is what stops the next reader from re-investigating.

## Incident registry — `.memory/postmortem-writing/incidents.json`

Versioned team state. Full schema and update rules: [`templates/registry-schema.md`](../templates/registry-schema.md).

### `.memory/` convention — version team state, ignore private state

Shared team state lives in `.memory/postmortem-writing/` and is versioned; agent-private state (public-repository reports, recovery copies) lives under `.memory/local/` or uses the `.local.` / `.recovered.json` naming and is never versioned. Before the first write under `.memory/`, ensure `.memory/.gitignore` contains this block (file writes only, never a VCS command; user lines are never removed):

```gitignore
# Managed by carrilloapps/skills — ignores agent-private paths only.
# Shared team state under .memory/<skill>/ stays versioned.
local/
*.local.*
*.recovered.json
```

Mercurial, Fossil, Subversion, and unknown-VCS handling, and the "private path already tracked" warning: ai-rules `frameworks/memory-convention.md` (owner of the rule). This skill's addition: record any Subversion reminder or already-tracked private path in Out of scope & limitations and in the closing message.

### Registry snapshot — mandatory in every report

The registry is not versioned in public mode and may be absent on another machine, so every report carries the state it saw:

```markdown
## Registry snapshot

| ID | Date | Sev | Title | Open actions | Status |
|----|------|-----|-------|--------------|--------|
| INC-003 | 2026-10-06 | SEV2 | Checkout DB pool exhaustion | 4 | Open |
| INC-002 | 2026-08-19 | SEV3 | Stale cache after config change | 0 | Closed |
```

If the registry is missing, seed it from the snapshot of the most recent report in the directory.

## Gate — numbered, at the end of every report

```markdown
## Gate

1. ✅ No individual is named as a cause — roles only
2. ✅ Every timeline row has a source, `[unknown]`, or an explicit gap row
3. ✅ Severity shows its rubric line and the maximum dimension
4. ✅ Every causal claim carries Confidence
5. ✅ Every action item has an owner role, a due date, and a verification step
6. ✅ Metrics are measured or marked `not measured`
7. ✅ Out of scope & limitations lists the evidence that was unavailable
8. ❌ Action A-04 has no due date — **incomplete**, needs the platform lead
```

A failing item is left visible with what it needs. The agent never deletes a Gate item to make the report pass.
