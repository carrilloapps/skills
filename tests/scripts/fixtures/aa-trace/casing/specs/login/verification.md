# Verification: Login

## 4.1 Test matrix

| # | Req | Scenario | Result | Evidence |
|---|-----|----------|--------|----------|
| 1 | FR-001, SC-001 | Valid credentials sign the user in | ✅ | ci run 101 |
| 2 | FR-002 | Repeated failures lock the account | ⚠️ | flaky timer, ci run 102 |

## 4.5 Verdict

**Verdict**: ✅ verified
