# Five Whys worksheet — `INC-<nnn>`, factor `CF-<n>`

One worksheet **per contributing factor**, not per incident. A single chain for a whole incident produces the single-root-cause fiction this skill rejects.

**Starting symptom**: `<the observable failure, as a user or a monitor saw it>`

| # | Why? | Answer | Evidence | Confidence |
|---|------|--------|----------|------------|
| 1 | Why did `<symptom>` happen? | `<answer>` | `<log, metric, config>` | Confirmed / Probable / Possible |
| 2 | Why did `<answer 1>` happen? | `<answer>` | `<…>` | |
| 3 | Why did `<answer 2>` happen? | `<answer>` | `<…>` | |
| 4 | Why did `<answer 3>` happen? | `<answer>` | `<…>` | |
| 5 | Why did `<answer 4>` happen? | `<answer>` | `<…>` | |

## Stop rules

Stop at the first answer that is a **design or process decision the team can change**, even if that is step 3. Five is a maximum, not a quota.

Stop and rewrite the step when an answer:

1. **Names a person or a team as the cause** — rewrite into what made the action possible, easy, or invisible ([root-cause.md](../frameworks/root-cause.md)).
2. **Reaches "human error"** — not a cause. Ask what the system offered: an unvalidated input, a manual copy between systems, a missing guard rail.
3. **Leaves the system** ("the vendor was down") — that is a dependency fact. The next why is about **your** system: why did a dependency failure become user impact?
4. **Has no evidence** — mark it `Possible` and add a `detect` action so the next occurrence is Confirmed. Never build an action on a `Possible` step alone.

## Result

**Condition to carry into the report**: `<the stopping answer, phrased as a condition that was true>`
**Confidence**: `<Confirmed | Probable | Possible>`
**Counterfactual test**: if this condition were removed, would the incident still happen? `<yes → it is not a necessary factor, reconsider | no → it is a real contributing factor>`
**Action it generates**: `<A-nn>`
