# Output Format — Good vs. Bad

> ⚠️ **Example only** — fictional content illustrating format.

## Rules

1. First line: the result — what was written (path) or the verdict. While the Phase 0 gate is closed, the first line says so: `Phase 0 gate closed — <N> structure item(s) open; nothing else will be created until they are done.`
2. Options are **numbered or lettered**. Never checkbox lists: nobody can tick them in a chat, and they invite the agent to "tick" by inference.
3. Gate items in artifacts: `1. ✅ / ❌ / ⚠️ <item> — <evidence>`.
4. Every draft closes with open questions (or "Open questions: none"), the epistemic state, and "Nothing was written to the tracker."
5. Short. Details live in the files; the chat says where they are.
6. Script results are quoted verbatim (finding IDs, severities, exit code) before any interpretation; the agent's own reading is labelled **Proposed**.
7. Requirements are cited by ID (`FR-003`, `SC-001`, `T012`) so every statement can be traced ([`traceability.md`](traceability.md)).
8. Clarifying questions: one at a time, numbered options, one marked *(recommended)* with the reason ([`clarify.md`](clarify.md)).

## ❌ Bad

> Here is the user story! ✅ Ready for sprint.
> ☑ Acceptance criteria defined
> ☑ Dependencies identified
> ☐ Estimated
> Estimate: 5 points. The export should be fast and work for all users.

Why it fails: readiness ticked by inference, an estimate before the vote, vague words ("fast", "all users") with no open question, no attribution, no statement about the tracker.

## ✅ Good

> Draft written: `plans/drafts/2026-10-05-csv-export.md`
>
> Readiness (from `plans/agile/definition-of-ready.md`):
>
> 1. ✅ Problem stated — Speaker 2 @ 00:03:10
> 2. ❌ Acceptance criteria agreed — 3 scenarios are **Proposed**, none confirmed
> 3. ⚠️ Dependencies — export service named, owner unknown
>
> Open questions:
>
> 1. "Fast" — what latency for 50k rows? → product owner · blocks sprint: yes
> 2. "All users" includes read-only roles? → product owner · blocks sprint: no
>
> Estimate: withheld until the team votes.
> State: Documented (transcript) + Proposed (criteria 2–4). Nothing was written to the tracker.
>
> Next — reply in your own words or with numbers:
>
> 1. Run the adversarial pass now
> 2. Create the initiative and spec skeleton in `specs/csv-export/`
> 3. Stop here
