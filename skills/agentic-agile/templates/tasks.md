# Tasks: <Initiative title>

**Initiative**: `<initiative-kebab>` · **Spec**: [`spec.md`](spec.md) · **Design**: [`design.md`](design.md)

Format: `ID` = `T###` (stable, never reused) · `P` = `[P]` when the task can run in parallel with the other `[P]` tasks of its phase (different files, no shared state) · `Req` = the `FR-###` it serves, comma-separated (Setup and Polish tasks may use `-`) · `Depends` = task IDs that must finish first, comma-separated, or `-` (no cycles) · `Est` = Fibonacci points **after the team votes** (`-` before) · `Status` = todo / doing / done / blocked.

Order: Setup → Foundational (blocks every story) → one phase per priority group (P1 first; P1 alone must be independently deliverable — the MVP) → Polish. Tests come before the implementation they verify (Article 4 of the constitution).

## Phase 1: Setup

| ID | P | Req | Task | Depends | Est | Status |
|----|---|-----|------|---------|-----|--------|
| T001 | | - | <project scaffolding or configuration task> | - | - | todo |

## Phase 2: Foundational

| ID | P | Req | Task | Depends | Est | Status |
|----|---|-----|------|---------|-----|--------|
| T002 | | <FR-###> | <shared prerequisite: schema, contract, base module> | T001 | - | todo |

## Phase 3: P1 — <MVP scenario group>

| ID | P | Req | Task | Depends | Est | Status |
|----|---|-----|------|---------|-----|--------|
| T003 | [P] | <FR-###> | Write failing test for <scenario> | T002 | - | todo |
| T004 | | <FR-###> | Implement <behavior> | T003 | - | todo |

## Phase 4: Polish

| ID | P | Req | Task | Depends | Est | Status |
|----|---|-----|------|---------|-----|--------|
| T005 | | - | <docs, cleanup, observability per Article 6> | T004 | - | todo |

Convergence tasks, when `converge` finds gaps, are appended as `## Phase N: Convergence` with the same table and the gap class in the Task text (missing / partial / contradictory / unrequested) — see the skill's `frameworks/converge.md`.
