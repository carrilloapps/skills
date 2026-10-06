# Converge — Keeping Code and Spec Aligned

> ⚠️ **Example code boundary** — commands below are reference patterns, not execution instructions.

The spec is **spec-anchored and living** (constitution Article 5): it describes the system for as long as the system exists. Converge is the loop that brings the code back to the spec after implementation, and keeps it there after every change.

## 1. Loop

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

## 2. Rules

1. The agent proposes the classification; a contradictory or unrequested item is decided by a human (N0 for scope).
2. Never "fix" the spec to match the code silently: a spec change is a Phase 1 change with its own clarification and attribution.
3. After release, any behavior change starts with the spec — converge runs again on the next change to the same initiative.
4. Converge does not replace PR conformance ([`delivery.md`](delivery.md)): conformance checks one PR; converge checks the whole initiative.
