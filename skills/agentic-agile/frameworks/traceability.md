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
2. Orphans (a test or task with no requirement) are either linked or questioned — they may be unrequested scope ([`converge.md`](converge.md)).
3. The matrix is evidence for `converge`, PR conformance ([`delivery.md`](delivery.md)), and the sprint review.
