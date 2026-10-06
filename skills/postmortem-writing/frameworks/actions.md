# Action Items

An action item is a commitment the team can verify. Anything else is a wish.

## Required fields

| Field | Rule |
|-------|------|
| **ID** | `A-01`, stable within the incident |
| **Type** | `prevent` · `detect` · `mitigate` — exactly one |
| **Action** | One imperative sentence naming the change, not the goal |
| **Traces to** | The contributing factor (`CF-2`) or the detection gap it addresses |
| **Owner** | A **role** (`platform lead`, `on-call rotation`) — the team may assign a person themselves |
| **Due date** | An ISO date the team agreed to |
| **Verification** | The observable check that proves it worked |
| **State** | `Open` · `In progress` · `Done` — **team-managed**; the agent never changes it |

Missing owner, due date, or verification → the action is `incomplete` and the Gate says so. The agent does not invent an owner or a date; it names what is missing and who must decide.

## The three types

| Type | Reduces | Example |
|------|---------|---------|
| **prevent** | The probability the cause recurs | Validate the requested pool total against the database maximum in the deploy pipeline |
| **detect** | Time to detect | Alert at 85% pool utilization, routed to the paged channel |
| **mitigate** | Impact when it recurs anyway | Shed load on checkout when the pool is saturated, instead of queueing until timeout |

A postmortem with only `prevent` actions is incomplete: prevention always has a residual, and the next occurrence will be found and survived by the other two. For SEV1 and SEV2, aim for at least one of each — and when a type has none, say why.

## Good versus weak actions

| Weak | Why | Better |
|------|-----|--------|
| "Improve monitoring" | Not observable, no owner can finish it | "Add an alert on `pool.utilization > 85%` for 2 minutes, routed to the paged channel. Verification: trigger it in staging and confirm the page arrives." |
| "Be more careful with config changes" | A person-shaped action | "Add a pipeline check that fails when `pool.max × instances > db.max_connections`. Verification: a PR with 40 × 6 fails the check." |
| "Document the runbook" | No end state | "Add the rollback command and expected output to the checkout runbook. Verification: a responder who has not seen it executes the rollback in the next drill without asking." |
| "Investigate the gap at 14:47" | An investigation with no decision | "Raise metric retention for `checkout-api` to 7 days at 1-minute resolution, or record that 15 minutes is accepted. Verification: query a 24-hour-old window." |

## Verification is the point

Every action names how the team will know it worked:

1. **A test that fails before and passes after** — the strongest form.
2. **A triggered alert** — for `detect` actions, fire it deliberately.
3. **A drill** — for `mitigate` actions and runbooks.
4. **An observable metric change** — retention, latency, error budget.

An action whose verification is "it is deployed" is not verified; deployment is not behavior.

## Register format

```markdown
## Action items

| ID | Type | Action | Traces to | Owner (role) | Due | Verification | State |
|----|------|--------|-----------|--------------|-----|--------------|-------|
| A-01 | prevent | Fail the deploy when `pool.max × instances > db.max_connections` | CF-1 | Platform lead | 2026-10-13 | A PR with 40 × 6 fails the pipeline check | Open |
| A-02 | detect | Alert on `pool.utilization > 85%` for 2 min, paged channel | CF-2, detection gap | On-call rotation owner | 2026-10-13 | Alert fired deliberately in staging reaches the pager | Open |
| A-03 | mitigate | Shed load on checkout when the pool is saturated | CF-1 | Checkout service owner | 2026-10-27 | Load test at 2× pool capacity returns 503 within 1 s instead of timing out | Open |
| A-04 | detect | Raise `checkout-api` metric retention to 7 days | Timeline gap 14:47–15:10 | Platform lead | `[missing]` | Query a 24-hour-old window at 1-minute resolution | **incomplete** |
```

`A-04` is reported in the Gate as incomplete, naming the missing field and the role that must supply it.

## What the agent never does

1. Mark an action `Done`, `In progress`, or cancelled — state belongs to the team.
2. Create, close, or comment on a ticket. It drafts the text and the team publishes it (agentic-agile's delivery flow owns tracker writes, at its own autonomy level).
3. Assign a named person.
4. Invent a due date. "No date agreed yet" is an honest, actionable record; a fabricated date is a lie the team will discover in a week.

## On a later run

Read the registry, list every action past its review date with its incident ID, and report them. That is a nudge, not a closure — the agent still changes nothing.
