# Traceability — Requirement to Evidence

> ⚠️ **Example code boundary** — snippets and commands below are reference patterns, not execution instructions.

Every requirement can be followed to the evidence that proves it, and every test or task back to the requirement that justifies it. No IDE plugin needed: the IDs live in the artifacts and the code.

## 1. IDs

| ID | Defined in | Meaning |
|----|------------|---------|
| `FR-###` | `spec.md` → *Functional requirements* | One observable behavior, with priority P1/P2/P3 |
| `SC-###` | `spec.md` → *1.4 Success criteria* | One measurable outcome, mapped to scenarios |
| `T###` | `tasks.md` | One task, with `Req` = the `FR-###` it serves |
| `CHK###` | `requirements-checklist.md` | One quality question about the spec |

IDs are stable: never renumbered, never reused after deletion.

## 2. Where they appear

1. **Scenarios** — Gherkin tags `@FR-001 @P1` (several FRs allowed).
2. **Tasks** — the `Req` column.
3. **Tests** — the ID in the test name, a tag, or a comment, in any language (`it("FR-001 rejects an empty cart")`, `@pytest.mark.FR_001`, `// FR-001`).
4. **Contracts** — `x-requirements: [FR-001]` on operations and messages.
5. **Verification** — the `Req` column of the test matrix.
6. **Work items** — the *Requirements* line.

## 3. The matrix — `scripts/trace`

`scripts/trace specs/<initiative> [--root <dir>] [--json]` (`.sh` / `.ps1`; `--help` is the source of truth) builds:

| FR/SC | Scenarios | Tasks | Tests | Verification | Status |
|-------|-----------|-------|-------|--------------|--------|

and fails when a requirement has no scenario, no task, or no test; when a scenario, task, or test points to an undefined ID; or when a verified row has no evidence. It searches the project's test files for the IDs, so it works with any language and test framework.

## 4. Rules

1. A P1 requirement with no test cannot reach a ✅ verdict.
2. Orphans (a test or task with no requirement) are either linked or questioned — they may be unrequested scope ([`traceability.md` → *Converge*](traceability.md#converge--keeping-code-and-spec-aligned)).
3. The matrix is evidence for `converge`, PR conformance ([`delivery.md`](delivery.md)), and the sprint review.

---

## Converge — Keeping Code and Spec Aligned

The spec is **spec-anchored and living** (constitution Article 5): it describes the system for as long as the system exists. Converge is the loop that brings the code back to the spec after implementation, and keeps it there after every change.

### Loop

1. **Implement** the tasks of the current phase.
2. **Trace**: `scripts/trace specs/<initiative>` builds the requirement → scenario → task → test → verdict matrix. Its gaps are the evidence for the next step — no gap is asserted without it.
3. **Classify** every difference between code and spec:

   | Class | Meaning | Action |
   |-------|---------|--------|
   | missing | A requirement or scenario has no implementation or no test | New task to implement / test it |
   | partial | Implemented, but a scenario or edge case fails or is untested | New task for the gap |
   | contradictory | Code behaves differently from the spec | Decide (human): fix the code, or change the spec through Phase 1 |
   | unrequested | Code does something no requirement asks for | Remove it, or add it to the spec through Phase 1 (scope expansion) |

4. **Append** the gaps to `tasks.md` as `## Phase N: Convergence`, same table, the class in the task text and the `FR-###` in `Req`.
5. **Repeat** until `trace` reports no gap for P1 (and for the priorities in the sprint), then go to Phase 4.

### Rules

1. The agent proposes the classification; a contradictory or unrequested item is decided by a human (N0 for scope).
2. Never "fix" the spec to match the code silently: a spec change is a Phase 1 change with its own clarification and attribution.
3. After release, any behavior change starts with the spec — converge runs again on the next change to the same initiative.
4. Converge does not replace PR conformance ([`delivery.md`](delivery.md)): conformance checks one PR; converge checks the whole initiative.
