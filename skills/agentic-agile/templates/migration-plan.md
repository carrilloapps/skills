# Migration Plan: <what is migrated>

**Initiative**: `<initiative-kebab>` · **Owner**: <role> · **Window**: <date and time range, timezone>

## 1. Scope

<What moves from where to where; what explicitly does not move.>

## 2. Phases

| # | Phase | Action | Success signal | Duration |
|---|-------|--------|----------------|----------|
| 1 | Prepare | <backups, dry run on a production-sized copy> | <signal> | <time> |
| 2 | Migrate | <steps> | <signal> | <time> |
| 3 | Verify | <data checks> | <signal> | <time> |
| 4 | Cut over | <switch traffic> | <signal> | <time> |
| 5 | Clean up | <retire the old path after the observation period> | <signal> | <time> |

## 3. Data verification

<Row counts, checksums, sample comparisons, invariants — each with the query or tool that proves it.>

## 4. Rollback

<Exact steps, who can trigger it, how long it takes, how data written after cut-over is reconciled.>

## 5. Abort criteria

1. <measurable condition that stops the migration>
2. <measurable condition that stops the migration>

## 6. Communication

| When | Audience | Channel | Message owner |
|------|----------|---------|---------------|

## Gate

1. ✅/❌ Dry run done on a production-sized copy, with measured duration.
2. ✅/❌ Rollback tested; its duration fits the window.
3. ✅/❌ Abort criteria are measurable.
4. ✅/❌ Consumers and on-call informed before the window.

## Open questions

| # | Question | For | Blocks? |
|---|----------|-----|---------|
