# Example: Tier 2 — Strategy Decision (AWS → GCP)

> ⚠️ **EDUCATIONAL EXAMPLE — NOT FOR IMPLEMENTATION.** Fictional company, vendor terms, and figures, used only to demonstrate critique of an irreversible strategic decision. No code is involved.

**Skill version**: 3.0.1

**Proposal [fictional], from the CTO:** Move all infrastructure from AWS to GCP in 12 weeks. Motivation: BigQuery pricing for analytics, plus a 40% credit for 12 months offered by the GCP sales team. All 23 AWS services migrate in parallel; no rollback plan; engineers learn GCP on the job.

No stop is needed here: the facts that drive severity are already in the proposal.

---

### 🔴 Devil's Advocate — full AWS → GCP migration in 12 weeks

**Verdict:** Rethink — **Overall risk:** 🔴

The goal is cheaper analytics. Only one of the 23 services is analytics. Moving the other 22 adds most of the risk and almost none of the benefit.

**Risks**

1. 🔴 **Irreversible, all-at-once move with no rollback** — 23 services in parallel means any failure in IAM, DNS, or data replication hits everything at once, and there is no path back once data is moved.
   *Evidence:* "no rollback plan", "all 23 in parallel" (proposal). *Fix:* migrate only analytics first; keep AWS as the system of record.
2. 🟠 **Credit deadline drives the schedule** — a 12-month credit rewards moving fast; the cost of a botched migration is not capped at 12 months.
   *Evidence:* motivation section. *Fix:* compare 3-year TCO with and without credits, including egress and re-training; decide on that number.
3. 🟠 **Team learning GCP during production migration** — IAM and networking misconfigurations are the most common source of cloud data exposure.
   *Evidence:* "learn on the job". *Fix:* two engineers certified/trained on GCP IAM before the first production workload moves.
4. 🟡 **Egress costs not modeled** — moving data out of AWS and syncing across clouds is billed per GB. *Fix:* estimate monthly egress for the hybrid period from current S3/RDS volumes.

**Unverified assumptions**

- BigQuery is cheaper for *this* workload — check: run last month's top 20 queries on a BigQuery trial with real data volume.

**Better option**
Hybrid: export analytics data to BigQuery (scheduled S3 → GCS transfer) and keep everything else on AWS — better at risk, speed (weeks, not a quarter), and reversibility; worse at the single-vendor story and maybe a smaller credit. Choose full migration only if the 3-year TCO still favors it after the hybrid runs for a quarter.

**What I'll do if you approve**

1. Draft the 3-year TCO comparison (full move vs. hybrid), including egress and training
2. Draft a 4-week BigQuery pilot plan for the analytics workload only
3. List the decision criteria that would justify moving the remaining 22 services later

Also considered, not material now: vendor lock-in on BigQuery SQL dialect (pilot will reveal it), support contract tiers.

```text
Reply with:
  ✅ Proceed   — run the corrected plan ("What I'll do if you approve")
  🔁 Revise    — describe the change and I will re-analyse
  ❌ Cancel    — stop, do not implement
  `continue`   — proceed without addressing remaining issues (risks remain active and unmitigated)
Or reply in your own words, in any language.
```
