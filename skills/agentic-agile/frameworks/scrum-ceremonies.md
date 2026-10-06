# Scrum Ceremonies — Agent Actions

The team's actual cadence and durations live in `plans/agile/ceremonies.md` and `methodology.md`. The defaults below are the **Proposed** starting values the team confirms during Phase 0.

**Phase 0 first.** No ceremony output below is written while `scripts/check-structure` fails ([`sdd-phases.md`](sdd-phases.md#phase-0--structure)). If a ceremony is requested before the gate opens, the agent says so in one line and offers to complete the structure with the team — it does not draft a partial artifact "for later".

| Ceremony | Default duration | Inputs | Agent output | Autonomy |
|----------|-----------------|--------|--------------|----------|
| Pre-refinement | async | Transcript, thread, or notes | `plans/drafts/<date>-<slug>.md` | N2 |
| Refinement | 60 min | Draft | `plans/initiatives/<i>/tickets/<NN>-<slug>.md` + open questions | N2 |
| Planning | 90 min | Ready items, capacity | `plans/sprints/<YYYY>-S<NN>/planning.md` | N2 (commitment N0) |
| Daily | 15 min | Tracker, PRs | `plans/sprints/<…>/daily/<date>.md` | N3, inform only |
| Review | 30–60 min | Done items, verification files | `plans/sprints/<…>/review.md` | N2 |
| Sprint close | — | Tracker, git, KPI directives | `plans/sprints/<…>/report.md` | N2 / N3 |
| Retro | 60 min | Report, events | `plans/sprints/<…>/retro.md` (facts and themes) | N2 |
| Decision | any time | The conversation | `plans/decisions/<date>-<slug>.md` | N2 |
| Weekly status | weekly | Sprint data, decisions | `plans/sprints/<…>/weekly-<YYYY-MM-DD>.md` | N2 |
| Quarterly review | quarterly | Sprint reports, events | `plans/sprints/<YYYY>-Q<N>-report.md` | N2 |
| Executive summary | on request | Any report | Draft in chat or `plans/sprints/<…>/executive-summary.md` | N2 |
| Postmortem | after an incident | Timeline sources | `plans/decisions/<date>-postmortem-<slug>.md` | N2 |

---

## Context refresh — before every ceremony

1. Re-read `plans/agile/` (methodology, DoR, DoD, ceremonies, team, kpi-directives, autonomy).
2. Re-read the decision records relevant to the items on the agenda, and any whose *review on* date has passed.
3. State in one line what changed since the last ceremony (new decisions, structure edits). Never rely on memory of a previous session.

## Capture — a new fact about the process

When a conversation reveals a fact that changes the team's operating system (a new ceremony time, a DoD item, a capacity change):

1. **Propose** the exact edit to the `plans/agile/` file, attributed.
2. **Confirm** with the person who owns that decision.
3. **Apply** with `Confirmed by: <name, date>`.
4. **Log** `{"event":"structure_updated",…}` in `plans/agile/metrics/events.jsonl`.

Unconfirmed facts stay **Proposed** and never change the file.

## Pre-refinement — from conversation to draft

1. **Ingest** the source (see [`transcripts.md`](transcripts.md)). Refuse a "summary of a summary": ask for the transcript, the thread, or the person's own notes.
2. **Contrast with the system** (SKILL.md §1.5) before writing a single criterion.
3. **Draft** with `templates/work-item-draft.md`: attribution per claim, Gherkin with Origin per scenario, out of scope, dependencies, risks.
4. **Readiness gate** from `plans/agile/definition-of-ready.md`: mark ✅ only what is explicit in the source; everything else ❌ or ⚠️ with the reason.
5. **Adversarial pass** (delegated to `devils-advocate` when installed): assumptions, contradictions with the system, ambiguous words ("all", "automatic", "fast"), missing roles, what is recorded on failure. Each finding → open question with an addressee. **An empty category is declared empty** ("Missing roles: none found") — never silently omitted.
6. **Estimate**: withheld until the team votes.
7. Close as [`output-format.md`](output-format.md) rule 4 prescribes.

## Refinement

- Walk the draft's open questions first; record answers with attribution — for initiatives with a spec, run the clarify protocol ([`clarify.md`](clarify.md)): ≤ 5 questions, one at a time, answers written to `spec.md` → *Clarifications* with `Confirmed by:`.
- Every refined item names its `FR-###` and priority; items that change behavior link to `specs/<i>/spec.md`. Bugs use `templates/bug.md` (mandatory regression scenario); new ideas use `templates/idea-assessment.md` before they become backlog items.
- Unanswered questions that block the sprint keep the item **Not Ready**.
- Items above the team's split threshold (`plans/agile/methodology.md`) are split before leaving refinement.

## Planning

1. Load `plans/agile/team.md`, `methodology.md`, the calendar, and last sprint's report.
2. State the sprint's position in the quarter and the sprint goal **as proposed by the product owner**.
3. **Cross-team dependencies** — list every candidate item that needs another team's work, API, review, or environment; for each, the owner, the date it is needed, and whether it is confirmed. An unconfirmed dependency keeps the item out of the commitment proposal.
4. Compute capacity ([`estimation-capacity.md`](estimation-capacity.md)).
5. Team votes; then the agent reveals its sealed estimate and the historical comparison. Estimates go into the `Est` column of `tasks.md` and the work item.
6. Before committing an initiative's tasks, `analyze` has no CRITICAL finding ([`analyze.md`](analyze.md)); the P1 phase alone must be shippable (MVP).
7. Suggest an assignment and an order by impact (N2), respecting `[P]` and `Depends` in `tasks.md`. The team commits (N0).

## Daily and sprint health

Report only facts with sources: items without movement for N days, PRs waiting for review over N hours, WIP per person, blockers raised. Never assess a person's performance. Notify, do not act.

## Review and close

Before review, run `trace` per initiative in the sprint ([`traceability.md`](traceability.md)) and converge any gap ([`converge.md`](converge.md)); the review shows requirement coverage, not just finished tickets.

- Review lists what was done against the sprint goal, with links to each `verification.md` verdict.
- The report computes the KPIs defined in `plans/agile/kpi-directives.md` only, following gate zero, the state tree, and the seven close phases in [`kpi.md`](kpi.md). If a measure is invalid or incomplete, write "not measurable — <reason>" instead of a number (no state assigned to an invalid measure).
- Classify work by initiative, not by commit prefix; data collection → [`delivery.md`](delivery.md#4-sprint-data-collection).

## Retro

The agent brings facts (cycle time outliers, reopened scope, escaped defects, open questions that arrived late) and themes. It does not choose the actions; it records the ones the team chooses, with an owner and a date.

## Weekly status

`templates/status-reports.md` (part A): sprint goal progress, done/in progress/blocked with sources, risks with owner, decisions needed. Facts only, no per-person ranking.

## Quarterly

`templates/status-reports.md` (part B): aggregate sprint reports; KPI trends with the row schema ([`kpi.md`](kpi.md#3-mandatory-row-schema)); trend the six agentic indicators ([`agentic-agility.md`](agentic-agility.md)); review decisions whose *review on* date passed; calibration proposals after two baseline cycles.

## Executive summary

`templates/status-reports.md` (part C): the decision asked of the reader first; at most five lines of context; options with consequences; risks; what is needed from the reader and by when. No jargon, no internal codenames without explanation, every number with its source.

## Postmortem

After an incident, `templates/postmortem.md`:

1. **Blameless** — describe systems, decisions, and signals; never name a person as the cause.
2. **Timeline** from sources (alerts, deploys, chat), each line attributed or marked `no attribution available`.
3. **Root cause and contributing factors** separated; "human error" is never a root cause — ask what made the error possible.
4. **Actions** each with an owner and a date, recorded as decision records or tickets after approval.
5. **Lessons** feed `devils-advocate` (when installed) as risks to check in future plans.
