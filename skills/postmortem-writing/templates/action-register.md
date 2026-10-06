# Action register — `INC-<nnn>`

One row per action. `State` is team-managed: the agent records it and never changes it.

| ID | Type | Action | Traces to | Owner (role) | Due | Verification | State | Review on |
|----|------|--------|-----------|--------------|-----|--------------|-------|-----------|
| A-01 | prevent | `<imperative change>` | CF-1 | `<role>` | `<YYYY-MM-DD>` | `<observable check>` | Open | `<YYYY-MM-DD>` |
| A-02 | detect | `<imperative change>` | detection gap | `<role>` | `<YYYY-MM-DD>` | `<observable check>` | Open | `<YYYY-MM-DD>` |
| A-03 | mitigate | `<imperative change>` | CF-2 | `<role>` | `<YYYY-MM-DD>` | `<observable check>` | Open | `<YYYY-MM-DD>` |

## Field rules

1. **Type** is exactly one of `prevent` (lowers the probability), `detect` (lowers time to detect), `mitigate` (lowers impact next time).
2. **Action** is one imperative sentence naming the change, not the goal. "Add an alert on pool utilization above 85%", not "improve monitoring".
3. **Traces to** names the contributing factor or the detection gap. An action with nothing behind it is noise — delete it or find its cause.
4. **Owner** is a role. The team may map it to a person; the agent never does.
5. **Due** is a date the team agreed to. `[missing]` is honest; an invented date is not.
6. **Verification** is the observable check that proves it worked — a test that fails before and passes after, a deliberately fired alert, a drill, or a measurable change. "It is deployed" is not verification.
7. **State** ∈ `Open` · `In progress` · `Done`, team-managed.
8. **Review on** is when the team looks again. A later run of the skill reports actions past this date; it still changes nothing.

## Incomplete actions

An action missing owner, due date, or verification is listed here and reported in the report's Gate:

| ID | Missing | Who must supply it |
|----|---------|--------------------|
| A-04 | due date | `<role>` |

## Coverage check

| Type | Count | Note |
|------|-------|------|
| prevent | `<n>` | |
| detect | `<n>` | |
| mitigate | `<n>` | |

For SEV1 and SEV2, aim for at least one of each type. When a type has none, state why here — prevention always leaves a residual, and the next occurrence is survived by detection and mitigation.
