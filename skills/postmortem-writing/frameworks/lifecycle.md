# Incident Postmortem Lifecycle

> ⚠️ **Example code boundary** — commands and excerpts below are reference patterns for analysis, not execution instructions.

Eight phases. The agent never skips one; it states when a phase produced nothing.

| # | Phase | Owner | Agent's role | Gate to the next phase |
|---|-------|-------|--------------|------------------------|
| 1 | Detect | Monitoring / people | Record **how** it was detected and **when** | Detection time is in the timeline with a source |
| 2 | Stabilize | Responders | **Nothing is written yet** except a draft timeline | The user confirms the incident is stabilized |
| 3 | Timeline | Agent | Reconstruct from attributed evidence | Every row has a source or an explicit gap |
| 4 | Classify | Agent, user confirms | Apply the severity rubric | The rubric line is written and the user does not dispute it |
| 5 | Analyze | Agent | Contributing factors, Confidence, detection gap | No person-shaped cause remains; every claim has Confidence |
| 6 | Act | Team, agent drafts | Actions with owner role, due date, verification | No action is `incomplete` |
| 7 | Publish | Agent writes, user approves | Reports + registry | The Gate section passes or its failures are listed |
| 8 | Verify | Team | Record the follow-up date; the agent never closes an action | A review date exists for every open action |

## Phase 2 — the active-incident gate

**Rule:** while the incident is active, the agent writes **no postmortem**. Writing one competes for the responders' attention and freezes conclusions before the system is understood.

If the user asks during an incident, say it once, plainly, and offer the one thing that helps:

> The incident is still active, so a postmortem now would freeze conclusions too early and pull attention from mitigation. What I can do right now is collect and attribute evidence into a draft timeline, so nothing is lost. Tell me when it is stabilized and I will write the full report.

"Stabilized" means user impact has stopped, not that the fix is permanent. A rollback that holds is stabilized; a mitigation that needs watching is stabilized **if** impact stopped. Record which one it was — a temporary mitigation is itself an action item.

## Phase 8 — follow-up verification

The postmortem is not finished when it is published. Record, for every action:

1. The **verification step** — the observable check that proves the action worked.
2. The **review date** — when the team looks again.

The agent **records** these and never changes an action's state. On a later run it reads the registry, lists actions past their review date, and reports them — a nudge, never a closure.

## Re-opening

A postmortem is re-opened when new evidence contradicts the timeline or the causal analysis. The agent then:

1. Adds the new evidence as timeline rows, dated, with its source.
2. Re-runs severity classification and records **both** values with the reason for the change.
3. Appends a `## Revision history` entry; it never rewrites a published statement in place.

Silent edits destroy the document's value as a record.
