# Example: Recurring Assessment with Mitigated Findings

> *Reference example — load on demand to see correct handling of mitigated findings, recurring entries, and the findings registry (`.memory/sar/findings.json`) across multiple SARs — including the one-time migration from a 1.x `vulnerabilities.csv`.*
>
> ⚠️ **Example only** — All findings, registry entries, and names below are synthetic illustrations of correct SAR output. They are not real data.

## Scenario

Second SAR on the same project. The first SAR (January 15) found 3 findings. Between then and now (March 12):

- F01 (SQL Injection, score 92) was **mitigated** by the team (parameterized queries deployed Feb 20)
- W01 (Missing rate limiting, score 45) is **still present** but the team marked it `In Development`
- F02 (NoSQL operator injection, score 85) is **still present** with no status change

The current assessment also discovers 1 new finding: Regex injection (score 75).

The project uses Git (a `.git/` directory at the root) and has no `.memory/` directory yet. In Step 0 the user answered that the repository is **private** and kept the default output directory `docs/security/` — so the registry is `.memory/sar/findings.json` and it is versioned with the reports.

The first SAR was produced with skill 1.x, so the registry is still `docs/security/vulnerabilities.csv` and `.memory/sar/findings.json` does not exist yet. This SAR migrates the CSV once and uses the 2.0.0 deterministic formula, so every **open** finding is re-scored and its arithmetic line shown; mitigated findings are not re-scored.

---

## Input: Existing `docs/security/vulnerabilities.csv` (1.x registry)

```csv
ID,Type,Score,Label,Title,Detection Date,Mitigation Date,Status,Assignee,Priority,Existing Mitigation
F01,Finding,92,Critical,SQL Injection in /api/users endpoint,2026-01-15,2026-02-20,Mitigated,@carlos,P0 - Immediate,No
F02,Finding,85,High,NoSQL operator injection on /api/products,2026-01-15,,Pending,,P1 - Urgent,No
W01,Warning,45,Low,Missing rate limiting on public API,2026-01-15,,In Development,@maria,P3 - Scheduled,No
```

---

## Step 6 — Read Findings Registry (before writing)

`.memory/sar/findings.json` does not exist and `vulnerabilities.csv` does → one-time migration. All 3 rows parse. CSV rows carry no CWE/component, so recurrence is matched this once by title (same vulnerability type + same endpoint):

1. **Mitigated**: F01 (SQL Injection) — must appear in `## Mitigated Findings`. Not in the current assessment → `cwe: []`, `component: null`, `lastSeenSar: null`.
2. **Recurring**: F02 (NoSQL injection on `/api/products`) — keep `id`, `detectionDate` 2026-01-15, `status` `Pending`; `cwe`/`component` filled from the current finding.
3. **Recurring**: W01 (Rate limiting on public API) — keep `id`, `detectionDate`, `status` `In Development`, `assignee` `@maria`.

The CSV is left untouched.

---

## Step 7 — Write Output Files

### SAR Title

Worst finding is F02 (NoSQL operator injection, score 85). Title:

```text
docs/security/2026-03-12_NOSQL-INJECTION-API-PRODUCTS_EN.md
docs/security/2026-03-12_NOSQL-INJECTION-API-PRODUCTS_ES.md
```

### Mitigated Findings section (in the SAR)

```markdown
## Mitigated Findings

> 1 previously reported finding has been mitigated since its initial detection.

### [MITIGATED] — F01 SQL Injection in /api/users endpoint (was: 92 Critical)
- **Detection Date**: 2026-01-15
- **Mitigation Date**: 2026-02-20
- **Original SAR**: [15-01-2026_SQLI-API-USERS_EN.md](./15-01-2026_SQLI-API-USERS_EN.md)
```

The January report was written by 1.x with a `DD-MM-YYYY` filename; the link uses the name as it exists on disk. New reports use ISO dates.

### Findings section (active findings only)

```markdown
## Findings

### 85 — NoSQL operator injection on /api/products
| Field | Value |
|-------|-------|
| Registry ID | F02 (recurring from 2026-01-15) |
| Confidence | Confirmed |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N` |
| CWE | CWE-943 |
| Effort | S |

**Score Justification**: `Base 80 +5 (full enumeration) +0 (commercial catalog data) = 85 (cap: none) → Final 85`
- (Description, trace, attack scenario, fix diff, verification...)

### 75 — Regex injection with data enumeration in /api/search
| Field | Value |
|-------|-------|
| Registry ID | F03 (new) |
| Confidence | Confirmed |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:L/SC:N/SI:N/SA:N` |
| CWE | CWE-625 |
| Effort | S |

**Score Justification**: `Base 75 −5 (rate limit) +5 (full enumeration via prefix iteration) +0 (commercial data) = 75 (cap: none) → Final 75`
- (Description, trace, attack scenario, fix diff, verification...)

---

### Warnings

### 49 — Missing rate limiting on public API
- **Registry ID**: W01 (recurring from 2026-01-15, Status: In Development)
- **Confidence**: Confirmed
- **Score Justification**: `Base 60 = 60 (cap: availability-only 49) → Final 49` — re-scored from 45 (1.x) under the 2.0.0 formula
- (Warning documentation...)
```

### Registry Snapshot section (in the SAR)

```markdown
## Registry Snapshot

> Snapshot of `.memory/sar/findings.json` at 2026-03-12. `status`, `assignee`, and `mitigationDate` are team-managed and copied as-is.

| ID | Title | Score | Status | Assignee | Mitigation Date |
|----|-------|-------|--------|----------|-----------------|
| F02 | NoSQL operator injection on /api/products | 85 | Pending | — | — |
| F03 | Regex injection with data enumeration in /api/search | 75 | Pending | — | — |
| W01 | Missing rate limiting on public API | 49 | In Development | @maria | — |
| F01 | SQL Injection in /api/users endpoint | 92 | Mitigated | @carlos | 2026-02-20 |
```

The registry (`.memory/sar/findings.json`) is versioned in this private repository; the snapshot makes the same state readable inside the report.

---

## Step 8 — Update Findings Registry (after writing)

### Before the first write: the `.memory/` ignore entries

`.git/` exists at the project root and `.memory/` does not → the agent first creates `.memory/.gitignore` with the shared block:

```gitignore
# Managed by carrilloapps/skills — ignores agent-private paths only.
# Shared team state under .memory/<skill>/ stays versioned.
local/
*.local.*
*.recovered.json
```

This file is versioned, so every clone ignores the same private paths. `.memory/sar/findings.json` does not match any line, so it is committed with the reports. The user's root `.gitignore` is not touched. No `.hg/`, `.svn/`, or Fossil markers exist, so no other ignore file is needed.

> **Public-repository variant** — had the user answered "public" (or had nobody answered in an automated run), the registry would be `.memory/local/sar/findings.json` and the reports would go to `.memory/local/sar/reports/`: both ignored by `local/`, so no open vulnerability is published.

### Output: `.memory/sar/findings.json` (created by the migration)

```json
{
  "schemaVersion": 1,
  "findings": [
    {
      "id": "F02", "type": "Finding", "score": 85, "label": "High",
      "title": "NoSQL operator injection on /api/products",
      "cwe": ["CWE-943"], "component": "src/products/products.service.ts",
      "detectionDate": "2026-01-15", "mitigationDate": null,
      "status": "Pending", "assignee": null,
      "priority": "P1 - Urgent", "existingMitigation": "No",
      "lastSeenSar": "2026-03-12_NOSQL-INJECTION-API-PRODUCTS"
    },
    {
      "id": "F03", "type": "Finding", "score": 75, "label": "High",
      "title": "Regex injection with data enumeration in /api/search",
      "cwe": ["CWE-625"], "component": "src/search/search.service.ts",
      "detectionDate": "2026-03-12", "mitigationDate": null,
      "status": "Pending", "assignee": null,
      "priority": "P1 - Urgent", "existingMitigation": "Rate limiting on gateway",
      "lastSeenSar": "2026-03-12_NOSQL-INJECTION-API-PRODUCTS"
    },
    {
      "id": "W01", "type": "Warning", "score": 49, "label": "Low",
      "title": "Missing rate limiting on public API",
      "cwe": ["CWE-770"], "component": "src/app.module.ts",
      "detectionDate": "2026-01-15", "mitigationDate": null,
      "status": "In Development", "assignee": "@maria",
      "priority": "P3 - Scheduled", "existingMitigation": "No",
      "lastSeenSar": "2026-03-12_NOSQL-INJECTION-API-PRODUCTS"
    },
    {
      "id": "F01", "type": "Finding", "score": 92, "label": "Critical",
      "title": "SQL Injection in /api/users endpoint",
      "cwe": [], "component": null,
      "detectionDate": "2026-01-15", "mitigationDate": "2026-02-20",
      "status": "Mitigated", "assignee": "@carlos",
      "priority": "P0 - Immediate", "existingMitigation": "No",
      "lastSeenSar": null
    }
  ]
}
```

### Appendix note written in the SAR

> **Registry migration** — `docs/security/vulnerabilities.csv` (3 rows, 0 unparseable) was imported into `.memory/sar/findings.json`, which is now the versioned findings registry. `.memory/.gitignore` ignores only agent-private paths (`local/`, `*.local.*`, `*.recovered.json`). The CSV was left unchanged and is no longer updated.

### What changed

| ID | Action | Details |
|----|--------|---------|
| F01 | **Migrated as-is** | `status` `Mitigated`, `mitigationDate`, `assignee` — team-managed fields untouched; `cwe`/`component` unknown (not in this assessment) |
| F02 | **Preserved `id` and `detectionDate`** | Score unchanged (85), `status` still `Pending`; `cwe`/`component` filled from the current finding |
| F03 | **New entry** | Next available F-number (F03), `detectionDate` today, `status: "Pending"` |
| W01 | **Preserved `id`, `detectionDate`, `status`, `assignee`; score updated 45 → 49** | `score` is agent-controlled (re-scored with the 2.0.0 formula); `status: In Development` and `assignee: @maria` are team-managed — agent does not overwrite |

### Sorting applied

1. Open findings by Score descending: F02 (85), F03 (75)
2. Open warnings by Score descending: W01 (49)
3. Mitigated by Score descending: F01 (92)

---

## Key Lessons from This Example

1. **Step 6 (read registry) happens BEFORE Step 7 (write report)** — the agent needs the mitigated findings list before generating the SAR.
2. **Mitigated findings appear in the SAR** under `## Mitigated Findings` with the `[MITIGATED]` label — they are not re-analyzed or re-scored.
3. **Team-managed fields are sacred** — `status: In Development`, `assignee: @maria`, `mitigationDate: 2026-02-20` are never overwritten by the agent, including during migration.
4. **New IDs continue the sequence** — F03 follows F02, not F01 (mitigated IDs are never reused).
5. **The registry is sorted by status groups** — open findings, then open warnings, then mitigated (score descending within each).
6. **Re-scoring is allowed, re-labeling team fields is not** — a recurring finding's `score`/`label`/`priority` follow the current formula; its `status`/`assignee`/`mitigationDate` never change.
7. **Migration is one-time and non-destructive** — the CSV is read once and never modified; from now on only `.memory/sar/findings.json` is updated.
8. **Team state is versioned, private state is not** — the ignore block is written before the first registry write and ignores only `local/` and private file patterns; in a private repository the registry is committed with the reports, in a public one it moves to `.memory/local/sar/`.
