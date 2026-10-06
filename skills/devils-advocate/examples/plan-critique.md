# Example: Tier 3 → Tier 2 — Database Migration Plan

> ⚠️ **EDUCATIONAL EXAMPLE — NOT FOR IMPLEMENTATION.** Fictional company, systems, and figures, used only to demonstrate how Devil's Advocate critiques a migration plan.

**Skill version**: 3.0.1

**Plan [fictional]:** Acme Corp migrates its production PostgreSQL 13 database (2 TB, 40M daily active records) to PostgreSQL 16 on a new cloud provider with `pg_dump`/`pg_restore` during a 4-hour Sunday maintenance window.

---

## Step 1 — Critical stop (one round of questions)

> ### 🛑 Devil's Advocate — stopping before the PostgreSQL 16 migration
>
> **Critical risk:** there is no rollback that fits the window. A 2 TB `pg_restore` typically takes several hours on its own; if anything fails at hour 3, the old primary must come back with writes that may already be lost.
> **If I'm right:** an outage that runs into Monday, or going live on an unverified target.
>
> 1. Has the full dump/restore been timed on a production-sized copy?
> 2. Does the target provider support logical replication from PostgreSQL 13?
> 3. How many services/jobs connect to the current database endpoint?
>
> Reply with the answers, or "skip the questions" and I'll write the report assuming the worst case.
> `continue` runs the original plan as-is (risks remain active and unmitigated).

*User answers [fictional]:* "No dry run yet. Yes, logical replication is supported. 14 consumers."

---

## Step 2 — Report

### 🔴 Devil's Advocate — PostgreSQL 13 → 16 migration

**Verdict:** Rethink — **Overall risk:** 🔴

The dump/restore approach turns a reversible migration into a one-way door. Logical replication is available, which lets you migrate with minutes of downtime and keep the old primary as a live fallback.

**Risks**

1. 🔴 **No rollback inside the window** — restore time is unmeasured and likely exceeds the 4 h window on 2 TB; once writes go to the new primary, falling back loses them.
   *Evidence:* user confirmed no dry run; plan uses `pg_dump`/`pg_restore`. *Fix:* logical replication from 13 → 16, cut over when lag < 1 s, keep reverse replication (16 → 13) running for 72 h as the rollback path.
2. 🟠 **14 consumers repointed by hand** — any one left on the old endpoint writes to the wrong database after cutover.
   *Evidence:* 14 consumers (user). *Fix:* introduce a DNS name (`db.internal`) first, move all 14 to it this week, then cutover is a single DNS change.
3. 🟠 **Extension/collation drift between 13 and 16** — a changed collation can silently reorder or break unique indexes on text columns.
   *Evidence:* major-version jump across two providers. *Fix:* run `pg_upgrade --check` equivalent on a restored copy and `REINDEX` text indexes on the target before cutover.
4. 🟡 **No success criteria for cutover** — *Fix:* define go/no-go: row counts per table match, replication lag < 1 s, 5 smoke queries green.

**Unverified assumptions**

- Target instance has enough IOPS for initial sync without throttling — check: provider limits for the chosen tier.

**Better option**
Logical replication + DNS cutover — better at reversibility and downtime (minutes vs. hours), worse at setup effort (~2–3 extra days). Choose it unless the target cannot replicate.

**What I'll do if you approve**

1. Draft the runbook: DNS alias → move 14 consumers → logical replication → dry run on staging copy (timed)
2. Define go/no-go checks and the reverse-replication rollback
3. Schedule cutover only after the staging dry run passes

Also considered, not material: connection pool sizing (unchanged), backup retention (unchanged by this plan).

```text
Reply with:
  ✅ Proceed   — run the corrected plan ("What I'll do if you approve")
  🔁 Revise    — describe the change and I will re-analyse
  ❌ Cancel    — stop, do not implement
  `continue`   — proceed without addressing remaining issues (risks remain active and unmitigated)
Or reply in your own words, in any language.
```
