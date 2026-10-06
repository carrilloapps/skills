# Delivery — Tickets, PR Conformance, Changelog, Sprint Data

From an approved spec to shipped work. Every procedure here runs only with the Phase 0 gate open ([`sdd-phases.md`](sdd-phases.md#phase-0--structure)).

---

## 1. Plan → tickets

1. **Source** — the refined work item (`plans/initiatives/<i>/tickets/<NN>-<slug>.md`) whose readiness gate is all ✅ against `plans/agile/definition-of-ready.md`. A Not Ready item never becomes a tracker ticket.
2. **Split** — one ticket per independently verifiable slice; each maps to one or more scenarios of `specs/<i>/spec.md`. Above the team's split threshold (`plans/agile/methodology.md`) → split before writing.
3. **Shape** — follow `templates/ticket-conventions.md` (title pattern, type, labels, links to the spec scenario and the DoR).
4. **Quality check** (numbered, all must be ✅):
   1. Title follows the convention and states the outcome, not the task.
   2. Acceptance criteria are the Gherkin scenarios, copied or linked — never rewritten as bullets.
   3. Out of scope is stated.
   4. Dependencies and blockers are linked.
   5. No `TBD`, no unfilled `<placeholder>`, no invented estimate (estimates come from the team's vote).
5. **Exact payload** — show the full payload per ticket (fields and values) exactly as it will be sent.
6. **Approval (N3)** — write only after the user approves the payload. One approval covers exactly the payloads shown; a changed payload needs a new approval.
7. **Record** — append `{"event":"tickets_written",…}` to `plans/agile/metrics/events.jsonl` and link the created IDs in the work item.

Until step 6 the draft closes as [`output-format.md`](output-format.md) rule 4 prescribes (nothing written to the tracker).

---

## 2. PR conformance against the spec

The code must not expand or contradict the spec (Phase 3 rule). For a PR or diff:

1. **Map every change** (file + hunk) to the scenario it implements: `specs/<i>/spec.md#<scenario>` and its `FR-###`. `scripts/trace` gives the requirement → test evidence for the whole initiative ([`traceability.md`](traceability.md)).
2. **Unmapped change** → **scope expansion**. It is not "probably fine": list it, and the behavior goes back to Phase 1 (new or amended scenario, approved by the team) before merge. Pure refactors with no behavior change are labelled `refactor — no behavior change` with the evidence (tests unchanged and green).
3. **Contradiction** (the code does something a scenario forbids) → blocking finding.
4. **Missing scenario coverage** — a scenario with no implementing change and no test → finding.
5. **Delegate** what is not conformance: failure-mode and design critique → `devils-advocate`; security review → `sar-cybersecurity`. Without them installed, list those concerns as open questions; do not score them.

Reply in chat with a numbered table (no file is created):

| # | Change | Scenario | Verdict |
|---|--------|----------|---------|
| 1 | `src/export/csv.ts` L12–40 | `spec.md#export-orders-only` | ✅ mapped |
| 2 | `src/export/csv.ts` L41–55 | — | ❌ scope expansion → Phase 1 |

Worked example → [`../examples/pr-conformance.md`](../examples/pr-conformance.md).

**Living spec.** The spec outlives the PR (constitution Article 5). A merged behavior change without its spec change is a contradiction that `converge` will report ([`converge.md`](converge.md)); after release, the next change to the same behavior starts in `spec.md`, not in the code.

---

## 3. Changelog

- Group by **initiative**, then by type (added · changed · fixed · removed). Never by commit prefix alone.
- Write for the user of the product, in the team's language (`plans/agile/language.md`). One line per change, outcome first.
- Link each line to its spec (`specs/<i>/`) or ticket.
- Breaking changes go first, with the migration note.
- N3: draft it; publishing it anywhere external needs the exact-payload approval.

---

## 4. Sprint data collection

For the sprint report and close ([`kpi.md`](kpi.md)):

1. **Window** — sprint start and end dates from `plans/sprints/<YYYY>-S<NN>/planning.md`.
2. **Version control** — commits and merged PRs in the window, open PRs at close, active branches. Read-only queries, through the code-host capability or local history.
3. **Tracker** — items done, carried over, added mid-sprint (scope change), reopened.
4. **Classify** each change by initiative using the specs and tickets it links — not by author or commit prefix.
5. **No per-person metrics.** Throughput, commits, or points per person are never computed or published (assessing people is N0).
6. A source that is unavailable → "not measurable — <reason>" for the measures that depend on it.
