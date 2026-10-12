# Dispatch: {{SLUG}}

**Source**: `{{SOURCE_FILE}}` · **Briefs**: {{COUNT}} · **Model tier**: {{TIER}} (`{{MODEL}}`) · **Autonomy**: {{AUTONOMY}}

One row per brief. Every brief under `dispatch/` carries its own item, requirement, file allow-list, acceptance criteria, and escalation rule, so each one can run in a different agent — or in the cheapest model that can do it — without the rest of the project in context.

| Brief | Title | Item | Req | Tier | Model | Autonomy | Status | Result |
|-------|-------|------|-----|------|-------|----------|--------|--------|
{{ROWS}}

Runner template (from `plans/agile/capabilities.md` → Slots → `Agent runner`; the model and the brief path are substituted per brief, and each brief carries its own resolved command):

```text
{{RUNNER}}
```

Rules:

1. **Parallel only where the allow-lists are disjoint.** Two briefs that write the same file run in sequence; the dependency goes in the Result column of the one that waits.
2. **A brief is executed, never edited by its executor.** Changes to a brief go through the agent or the human who dispatched it.
3. **Results come back as numbered proposals** for `{{TASKS_PATH}}` and `verification.md`. Nothing merges itself, and no executor closes a work item.
4. **An unmapped `Req` is mapped before implementation**, not during it — an item with no requirement is either a spec change (Phase 1) or not work at all.
5. **`scripts/trace specs/{{SLUG}}` closes the loop**: the dispatch is finished when the trace matrix shows no gap for the priorities in scope, not when every row says done.
