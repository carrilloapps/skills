# Clarify — Resolving Ambiguity Before Design

> ⚠️ **Example code boundary** — snippets below are reference patterns for writing artifacts, not execution instructions.

Run after `spec.md` is drafted and before Phase 2. Goal: turn every ambiguity that would change the design, the tests, or the estimate into an **attributed** answer — never into the agent's guess.

## 1. Taxonomy — scan the spec in this order

| # | Category | Look for |
|---|----------|----------|
| 1 | Functional scope & behavior | Goals, explicit non-goals, user roles, what "done" means for each FR |
| 2 | Domain & data model | Entities, attributes, identity, lifecycle/state transitions, volume |
| 3 | Interaction & UX flow | Steps, error/empty/loading states, accessibility |
| 4 | Non-functional quality | Performance numbers, scale, reliability, observability, security, compliance |
| 5 | Integration & dependencies | External systems, failure modes, contracts, protocol/versioning |
| 6 | Edge cases & failure handling | Negative paths, concurrency, conflicts, partial failure, retries |
| 7 | Constraints & trade-offs | Technical limits, rejected alternatives, deadlines |
| 8 | Terminology & consistency | One term per concept; synonyms that hide two concepts |
| 9 | Completion signals | Testable acceptance, measurable success criteria |
| 10 | Placeholders & vague words | `<…>`, "fast", "robust", "intuitive", "etc.", "as needed" |
| 11 | Miscellaneous | Anything a tester or estimator would have to assume |
| 12 | **Epistemic state & attribution** | Requirements that are Proposed but read as decided; claims without a source; two stakeholders who disagree |

Rate each category **Clear / Partial / Missing**. Only Partial and Missing produce questions.

## 2. Asking

1. **At most 5 questions per session**, ranked by impact on design × uncertainty. More candidates stay in *Open questions* for the next session.
2. **One question at a time.** Wait for the answer before the next one.
3. Each question offers **numbered options** with one marked *(recommended)* and why, plus a free-text option:

   ```text
   Q2 (Domain & data model) — Can an order be edited after payment?
   1. No, never (recommended — matches the refund rule in FR-004)
   2. Yes, until it ships
   3. Yes, by support staff only
   4. Other — say how
   ```

4. Ask the **role that owns the fact** (from `plans/agile/team.md`). If the person answering is not that role, record who answered and keep it Proposed until the owner confirms.
5. Two stakeholders give different answers → do not choose. Record both, attributed, as an open question that blocks the sprint.

## 3. Recording — in `spec.md`, never in chat only

Append under `## Clarifications` → `### Session YYYY-MM-DD`:

```markdown
### Session 2026-10-05

1. Q: Can an order be edited after payment? → A: No, never — Confirmed by: Ana (Product owner)
```

Then update the spec sections the answer affects (FR row, scenario, success criterion, out of scope) in the same change. An answer without `Confirmed by: <name> (<role>)` is not a clarification — `check-spec --strict` fails on it.

## 4. Gate to Phase 2

1. No open question with *Blocks sprint? = Yes*.
2. No category left Missing for P1 requirements.
3. Every clarification attributed.

Questions about security are delegated to `sar-cybersecurity`; adversarial challenge of the answers to `devils-advocate` when installed.
