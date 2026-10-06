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
