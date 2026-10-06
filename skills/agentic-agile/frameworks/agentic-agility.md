# Agentic Agility — Adoption, Defaults, Indicators

The operating rules (autonomy, labels, attribution, anti-anchoring, contrast, availability) are in `SKILL.md` §1. This file covers how a team adopts them and measures the result. The team's instantiation lives in `plans/agile/autonomy.md`.

## Default autonomy per task

| Task | Level | Why |
|------|-------|-----|
| Transcribe and summarise sessions | N1 → N2 | The next step is feeding the draft |
| Draft a work item from a conversation | **N2** | A bad criterion propagates into tests, QA, and the done gate |
| Adversarial refinement | **N2** | It exposes; it does not decide |
| Create a defect from a thread | N3 | Cheap error, defined flow, instantly verifiable |
| Sprint changelog | N3 | Reconstructible from merged PRs and closed items |
| Detect blockers and notify | N3 | Informs; does not act |
| Order the backlog by impact | N2 | Supplies data; priority is the product owner's |
| Estimate | **N2, after the vote** | Avoids anchoring |
| Close or transition items | **N0** | Depends on the team's done criterion |
| Commit the sprint | **N0** | Belongs to the team |

## Preconditions before adoption

| # | Precondition | Hard? |
|---|--------------|-------|
| 1 | Transcription active in recurring ceremonies | — |
| 2 | **Programmatic access** to those transcripts | Required for phase 1 |
| 3 | **Retention and classification policy** for transcripts | Required before touching production data |
| 4 | Recording consent announced in every session | — |
| 5 | Pilot scope agreed | — |
| 6 | Third-party capabilities authorized (four questions below) | — |
| 7 | Metric baseline over at least two full cycles | Required for targets and N4 |

Record status and owner of each in `plans/agile/autonomy.md`.

**Precondition 0 is structural and always hard:** `scripts/check-structure` passes — the team's operating system in `plans/agile/` is complete and its Proposed defaults are confirmed or explicitly accepted. Each of preconditions 1–7 needs a status in `plans/agile/autonomy.md` for that gate to open.

## Adoption phases

| Phase | Horizon | Objective | Level |
|-------|---------|-----------|-------|
| 1 · Capture | ~30 days | Transcribe every requirement-bearing session; summaries feed drafts; capture the baseline | N1 |
| 2 · Draft and question | ~60 days | Drafts with readiness gate and Gherkin; open questions mandatory before planning; Gherkin lands as a test before code | N2 |
| 3 · Write into the tools | ~90 days | Defects from threads, blocker alerts, changelog; the team's own procedures published; honest review of what stays | N3 where errors are cheap |

**Phase 3 success:** a requirement travels from conversation to refined item **without depending on one specific person**.

## Third-party skills and capabilities — four questions

One unanswered question means it does not touch production data:

1. Which data does it reach?
2. Which write permissions does it request?
3. Where is the data processed and how long is it retained?
4. Who answers if it fails (a named internal owner)?

Record: name, provider, version, approval date, approver, data scope, next review date — in `plans/agile/capabilities.md`.

## The six indicators

Computed from `plans/agile/metrics/events.jsonl` (append-only, one JSON object per line). **No numeric targets before two full cycles of baseline.**

### Event schema

```json
{"ts":"2026-10-05T14:03:00Z","event":"draft_created","item":"<initiative>/<NN>","sprint":"2026-S20","actor":"agent|<role>","meta":{}}
```

| `event` | Written when |
|---------|-------------|
| `session_captured` | A transcript is normalized (meta: source type) |
| `draft_created` | A draft is written in `plans/drafts/` or `tickets/` |
| `item_ready` | The team marks an item Ready |
| `question_opened` / `question_resolved` | An open question is raised / answered (meta: id, before_planning true/false) |
| `scope_reopened` | Scope of a committed item changes during the sprint |
| `item_started` / `item_done` | Work starts / meets the DoD |
| `defect_escaped` | A defect is found in production (meta: item) |
| `decision_recorded` | A decision record is written (meta: has_author, has_reason) |
| `structure_updated` | A `plans/agile/` file changes after confirmation (meta: file, confirmed_by) |
| `tickets_written` | Tickets are created in the tracker after N3 approval (meta: ids) |

The agent appends events only for actions it performed or that the user reported; it never back-fills inferred events. This table is the only definition of event names and keys — every other file and example uses exactly these.

| # | Indicator | Formula |
|---|-----------|---------|
| 1 | Time from session to ready item | median(`item_ready.ts` − `session_captured.ts`) per item |
| 2 | Items entering the sprint without scope reopened | committed items without `scope_reopened` ÷ committed items |
| 3 | Open questions resolved before planning | `question_resolved` with `before_planning=true` ÷ `question_opened` |
| 4 | Cycle time per item | median(`item_done.ts` − `item_started.ts`) |
| 5 | Defects escaping per cycle | count(`defect_escaped`) per sprint |
| 6 | Decisions recorded with author and reason | `decision_recorded` with both flags ÷ all `decision_recorded` |

## Capability catalogue — what a team should be able to run

Conversation → work item with readiness gate and Gherkin · adversarial refinement · defect from a thread on the right parent · sprint summary · estimation against history · blocker detection · team state · changelog · blameless postmortem · decision record · warehouse queries · KPI dashboards. The team records which ones it has, and at what maturity, in `plans/agile/capabilities.md`.

## Names used elsewhere

| Practice here | Also called |
|---------------|-------------|
| Team's non-negotiable engineering principles | Engineering constitution |
| Readiness gate before refining | Spec-Driven Development (`spec.md`) |
| Bounded task with a per-item ceiling | Executable decomposition (`tasks.md`) |
| Acceptance criteria in Gherkin | BDD · Given / When / Then |
