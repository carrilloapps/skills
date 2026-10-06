# Phase hooks

> Commands the agent **proposes** at each phase transition. The agent never runs them on its own.

Confirmed by: Tech lead — 2026-10-01

| # | Transition | Proposed command | Why | Blocking? |
|---|------------|------------------|-----|-----------|
| 1 | Before any artifact | `scripts/check-structure --root .` | Phase 0 gate | yes |
| 2 | Spec → Design | `scripts/check-spec specs/INITIATIVE --strict` | Spec complete, clarifications attributed | yes |
| 3 | Implementation → Verification | `scripts/trace specs/INITIATIVE` | Every requirement has a scenario and a test | yes |
