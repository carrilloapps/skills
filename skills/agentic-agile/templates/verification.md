# Verification: <Initiative title>

**Initiative**: `<initiative-kebab>` · **Phase**: 4 — Verification · **Spec**: [`spec.md`](spec.md)

## 4.1 Test matrix

| # | Scenario (from spec 1.2) | Req | Type | Result | Evidence |
|---|--------------------------|-----|------|--------|----------|
| 1 | <scenario name> | <FR-### / SC-###> | unit / integration / e2e / manual | ✅ / ⚠️ / ❌ / skipped — reason | <test name, CI run, log path> |

One row per scenario; every `FR-###` and `SC-###` of the spec appears in `Req` at least once (`trace` checks it). A ✅ without evidence is **not verified**; a ❌ blocks closing the item. Evidence = timestamp · artifact (test name, CI run, log or screenshot path) · commit.

## 4.2 Edge-case battery

| # | Case | Found during | Result | Evidence |
|---|------|--------------|--------|----------|

## 4.3 Evidence notes

<Anything the matrix links need to be reproducible: commands, data sets, environment.>

Per-scenario evidence block (when a row needs more than one line):

```text
RESULT: ✅ | ⚠️ | ❌
EVIDENCE: <YYYY-MM-DDTHH:MMZ> · <artifact: test name, CI run, log or screenshot path> · commit <sha>
```

## 4.4 Coverage

<Coverage of the changed code; uncovered lines and why. Requirement coverage comes from `trace` — paste its summary line.>

## 4.5 Verdict

**Verdict**: ✅ Done | ⚠️ Done with follow-up | ❌ Back to Phase 3

Follow-up plan (required for ⚠️): <link and date>
