# Example: PR Conformance Against the Spec

> ⚠️ **Example only** — fictional initiative, files, and PR.

**Skill version**: 1.0.2

**Context**: initiative `order-history-export`. `specs/order-history-export/spec.md` has three scenarios: `export-orders-only`, `empty-history-message`, `export-limited-to-12-months`. The Phase 0 gate is open.

User: "Check PR 214 against the spec."

---

**PR 214 — conformance: 2 of 4 changes map to a scenario; 1 is scope expansion; 1 scenario has no coverage.**

| # | Change | Scenario | Verdict |
|---|--------|----------|---------|
| 1 | `src/export/csv-writer.ts` L10–48 — writes order rows | `spec.md#export-orders-only` | ✅ mapped, test `csv-writer.test.ts` covers it |
| 2 | `src/export/empty-state.tsx` — message when there are no orders | `spec.md#empty-history-message` | ✅ mapped, test present |
| 3 | `src/export/csv-writer.ts` L49–70 — adds a `refunds` section | — | ❌ **scope expansion**: refunds are listed under *Out of scope* (decision record 2026-10-05). Back to Phase 1 if wanted |
| 4 | `src/export/date-filter.ts` — renamed variables, no logic change | — | ✅ `refactor — no behavior change`; tests unchanged and green |

**Missing coverage**

1. `spec.md#export-limited-to-12-months` — no change and no test implements the 12-month limit. Either the PR is incomplete or the scenario moved to another ticket; open question to the author.

**Delegated, not assessed here**

1. Failure modes of the CSV generation under large histories → `devils-advocate`.
2. Whether the export endpoint checks ownership of the orders → `sar-cybersecurity`.

**Open questions**

| # | Question | For | Blocks merge? |
|---|----------|-----|---------------|
| 1 | Remove the refunds section, or open a Phase 1 change with the product owner? | PR author, product owner | Yes |
| 2 | Where is the 12-month limit implemented? | PR author | Yes |

Epistemic state: changes 1–4 Verified (diff read in this session); coverage gap Verified (no matching test or code found). Nothing was written to the tracker or the PR.
