# QA Regression: <release or scope>

**Sprint**: <YYYY>-S<NN> · **Environment**: <name, version, data set> · **Date**: <YYYY-MM-DD>

## 1. Suite scope

<Which features and specs are covered, and what is deliberately excluded.>

## 2. Scenarios by risk

| # | Scenario (link to spec) | Risk | Why in this run |
|---|-------------------------|------|-----------------|

Scenarios come from `specs/<initiative>/spec.md` — never rewritten as bullets.

## 3. Results

| # | Scenario | Result (✅ / ❌ / ⚠️ / N/A) | Evidence (run ID, log, screenshot, commit) |
|---|----------|------------------------------|---------------------------------------------|

A pass without evidence is not verified. N/A needs a reason.

## 4. Defects found

| # | Defect | Scenario | Severity | Ticket |
|---|--------|----------|----------|--------|

## Gate

1. ✅/❌ Every high-risk scenario was run.
2. ✅/❌ Every result has evidence.
3. ✅/❌ Every ❌ has a defect ticket (written after approval).
