<!-- Work-item templates in one file. Copy ONLY the part you need, never the whole file:
     A -> plans/drafts/<YYYY-MM-DD>-<slug>.md          pre-refinement draft from a conversation
     B -> plans/drafts/<YYYY-MM-DD>-<slug>.md          defect record, until it becomes a ticket
     C -> plans/decisions/<YYYY-MM-DD>-<slug>.md       idea assessment (five stages)
     D -> the team's QA run record, e.g. plans/sprints/<YYYY>-S<NN>/qa-regression-<YYYY-MM-DD>.md -->

---

<!-- A. Work item draft -->

# <Work item title — outcome, not task>

**Type**: Story | Defect | Improvement · **Initiative**: `<initiative-kebab>` · **Epic**: <epic or none>
**Requirements**: <FR-###, FR-### from `specs/<initiative-kebab>/spec.md`> · **Priority**: P1 | P2 | P3 · **Tasks**: <T### from `tasks.md`, or none yet>
**Origin**: <transcript file + date | thread link | notes> · **Drafted by**: agent (N2) · **Date**: <YYYY-MM-DD>

## Description

<What and why, each claim attributed: "<claim>" — <speaker> @ <time> | no attribution available.>

## Scope

1. <in scope>

## Out of scope

1. <explicitly excluded>

## Acceptance criteria

```gherkin
# language: <en | es>
@<initiative-kebab> @FR-<###> @P<1|2|3>
Scenario: <outcome>
  # Origin: <speaker> @ <time> | Proposed
  Given <state>
    | <column> | <column> |
    | <value>  | <value>  |
  When <action>
  Then <observable outcome>
```

## QA test cases

```gherkin
# language: <en | es>
@qa @negative @FR-<###>
Scenario: <negative / edge case>
  # Origin: Proposed
  Given <state>
  When <action>
  Then <observable outcome>
```

Minimum: one happy path, one negative per failure mode, and the applicable edge cases. Edge categories not applicable: <category — reason>

## Metrics

<How success will be observed after release — or "none stated".>

## Dependencies & risks

| # | Item | Owner (role) | State |
|---|------|--------------|-------|

## Tasks

| # | Task | Points (after the vote) |
|---|------|-------------------------|

## Estimate

Withheld until the team votes. Sealed suggestion: <stored, revealed after the vote>.

## Readiness (from `plans/agile/definition-of-ready.md`)

1. ❌ / ✅ / ⚠️ <item> — <evidence, only if explicit in the source>

## Open questions

| # | Question | For | Blocks sprint |
|---|----------|-----|---------------|

## Adversarial pass

1. Assumptions treated as settled: <…>
2. Contradictions with the current system: <…>
3. Ambiguous scope words: <…>
4. Missing roles or areas: <…>
5. What is recorded if the flow fails: <…>
6. Other: <…>

---
**Epistemic state**: <Verified / Documented / Proposed per section>
**Nothing was written to the tracker.**

---

<!-- B. Bug -->

# Bug: <observable symptom, not the guessed cause>

**Initiative**: `<initiative-kebab>` · **Reported by**: <role or name> @ <date> | no attribution available · **Severity**: <critical / high / medium / low> · **Req affected**: <FR-### or none>

## 1. Assess

| Item | Value | State |
|------|-------|-------|
| Expected behavior | <from spec scenario or FR> | Verified / Documented / Proposed |
| Actual behavior | <what happens> | Verified (<evidence>) |
| Reproduction | <steps, data, environment> | Verified / not reproduced |
| Scope | <users, data, versions affected> | |
| Spec status | <the spec covers this case: yes (scenario) / no (spec gap → Phase 1 change)> | |

## 2. Root cause

<Cause with the evidence that proves it (file:line, log, commit). Blameless. If not yet proven, say so and keep the bug open.>

## 3. Fix

<What changes and why it is the smallest fix at the root, not a symptom patch.>

## 4. Test — regression scenario (mandatory)

```gherkin
# language: <en | es>
@regression @FR-<###> @<initiative-kebab>
Scenario: <the bug can no longer happen>
  # Origin: bug report <date>
  Given <state that triggered the bug>
  When <action>
  Then <correct observable outcome>
```

The regression test fails before the fix and passes after it; both runs are recorded as evidence.

## 5. Evidence

```text
RESULT: ✅ | ⚠️ | ❌
EVIDENCE: <YYYY-MM-DDTHH:MMZ> · <failing run before fix> · <passing run after fix> · commit <sha>
```

## Open questions

| # | Question | For | Blocks fix? |
|---|----------|-----|-------------|
| 1 | <question or "none"> | <role> | Yes / No |

---

<!-- C. Idea assessment -->

# Idea assessment: <idea in one line>

**Proposed by**: <role or name> @ <date> | no attribution available · **Assessed by**: agent (N2) with <role> · **Date**: <YYYY-MM-DD>

Five stages, in order. Each stage labels its claims Verified / Documented / Proposed. The decision (stage 5) is human (N0); the agent prepares it.

## 1. Intake

<The idea as stated, verbatim and attributed. The problem it claims to solve and for whom.>

## 2. Research

| # | Question | Finding | Source | State |
|---|----------|---------|--------|-------|
| 1 | Does the problem exist and how often? | <finding> | <data, tracker, transcript> | Verified / Documented / Proposed |
| 2 | What exists today (in the system or the market)? | <finding> | <source> | |
| 3 | What does it conflict with (constitution, roadmap, other initiatives)? | <finding> | <source> | |

## 3. Define

1. Outcome if it works: <measurable outcome>
2. Who benefits: <roles>
3. Smallest test of value: <spike, prototype, or experiment — see `templates/spike-poc.md`>

## 4. Shape

| Option | Scope | Rough size (points or t-shirt) | Risks |
|--------|-------|--------------------------------|-------|
| a | <minimal version> | <size> | <risks> |
| b | <fuller version> | <size> | <risks> |

## 5. Decide

**Decision**: go | needs-clarification | kill — **Decided by**: <role or name> — **Date**: <YYYY-MM-DD>

1. go → create `specs/<initiative>/spec.md` (after the Phase 0 gate) and record the decision.
2. needs-clarification → the open questions below, each with an owner and a date.
3. kill → the reason, recorded so the idea is not re-litigated without new facts.

Every decision is also written as a decision record in `plans/decisions/<YYYY-MM-DD>-<slug>.md` (template `decision-record.md`).

## Open questions

| # | Question | For | Blocks decision? |
|---|----------|-----|------------------|
| 1 | <question or "none"> | <role> | Yes / No |

---

<!-- D. QA regression run -->

# QA Regression: <release or scope>

**Sprint**: <YYYY>-S<NN> · **Environment**: <name, version, data set> · **Date**: <YYYY-MM-DD>

## 1. Suite scope

<Which features and specs are covered, and what is deliberately excluded.>

## 2. Scenarios by risk

| # | Scenario (link to spec) | Risk | Why in this run |
|---|-------------------------|------|-----------------|

Scenarios come from `specs/<initiative>/spec.md` — never rewritten as bullets.

## 3. Results

| # | Scenario | Result (✅ / ❌ / ⚠️ / N/A) | Evidence (run ID, log, screenshot, commit) |
|---|----------|------------------------------|---------------------------------------------|

A pass without evidence is not verified. N/A needs a reason.

## 4. Defects found

| # | Defect | Scenario | Severity | Ticket |
|---|--------|----------|----------|--------|

## Gate

1. ✅/❌ Every high-risk scenario was run.
2. ✅/❌ Every result has evidence.
3. ✅/❌ Every ❌ has a defect ticket (written after approval).
