# Criticality Scoring System

> *Protocol file — free to load, does not count toward context budget.*

Score every finding from **100 (most critical) to 1**. Findings **above 50** are primary content (`F` IDs). Findings scoring **50 or below** are warnings (`W` IDs). These labels are the same in the report, the registry, the priority, and the roadmap.

| Score | Label | Type | Priority | Action Required |
|-------|-------|------|----------|-----------------|
| 90–100 | Critical | Finding | P0 - Immediate | Immediate remediation |
| 70–89  | High | Finding | P1 - Urgent | Urgent remediation |
| 51–69  | Medium | Finding | P2 - Planned | Planned remediation |
| 1–50   | Low | Warning | P3 - Scheduled | Monitor; fix when convenient |

Something with no security impact is not a finding and is not scored.

The 0–100 contextual score is the **authoritative priority** for the SAR, the registry, and the roadmap. The CVSS v4.0 vector (below) is included for interoperability with external tooling only — it never overrides the contextual score.

---

## Scoring Principle: Deterministic, Auditable, Net Effective Risk

Every score reflects **real-world exploitability and actual impact** after tracing the full flow — not theoretical maximum severity. Two auditors applying this file to the same evidence must arrive at the **same number**. To guarantee that:

1. Every adjustment below is a **single fixed value** — no ranges, no judgment-based fine-tuning.
2. Every finding shows its **arithmetic line**, and the arithmetic must add up exactly:

```text
Base 80 +5 (full enumeration) +5 (PII) = 90 (cap: none) → Final 90
Base 80 −10 (auth) −10 (API key) −5 (rate limit) +5 (full enumeration) +5 (blind extraction) −5 (internal data) = 60 (cap: none) → Final 60
Base 80 −10 (auth) +10 (write + escalation, D2 capped at +10) +8 (financial) = 88 (cap: none) → Final 88
Base 65 −10 (auth) −5 (role) −5 (single record) −10 (public data) = 35 (floor: 51) → Final 51
Base 60 = 60 (cap: availability-only 49) → Final 49
```

A score whose arithmetic line does not add up, or that uses a factor not listed in this file, is a scoring failure and must be corrected before the SAR is written.

> Score ranges quoted in domain frameworks and examples (e.g., "typically 55–70") are **typical outcomes**, not inputs. The final score is always computed with the formula below.

---

## Confidentiality Primacy — Data Exfiltration Focus

The SAR's primary domain is **confidentiality and integrity**. Any vulnerability that enables **data exfiltration** — direct or indirect extraction of data beyond the attacker's authorization — is scored normally. A vulnerability whose only impact is service disruption is capped.

| Impact classification | SAR domain | Scoring treatment |
|-----------------------|-----------|-------------------|
| **Data exfiltration** — attacker extracts records, PII, credentials, secrets, or any data beyond their authorization | Primary | Score with the formula |
| **Data modification / integrity** — attacker alters records, escalates privileges, corrupts data | Primary | Score with the formula |
| **Dual-vector** — same vulnerability enables exfiltration AND service disruption | Primary | Score the exfiltration vector; note the DoS vector as secondary |
| **Availability-only** — sole impact is degradation, CPU/memory exhaustion, or downtime with zero data exposure | Secondary | **Cap at 49** and delegate to performance/infrastructure tooling |

---

## The Formula

```text
Y     = Base + D1 (exploitation) + D2 (impact, capped at +10) + D3 (data sensitivity)
Y     = clamp(Y, 0, 100)
Floor = if reachable AND not fully mitigated AND not availability-only AND Confidence ≠ Possible → max(Y, 51)
Final = apply gates and caps last (lowest applicable value wins)
```

### Step 1 — Base severity (pick exactly one class)

**Classify by the sink, not the consequence.** The class is what the vulnerable code *does* (builds a query from input, deserializes input, skips an ownership check). What the attacker *gains* (admin access, full table, credentials) is carried by D2 and D3. Examples:

- NoSQL operator injection on `/login` that logs the attacker in → **injection into a data store (80)**; the login bypass is D2 `privilege escalation (+5)`.
- A JWT verifier that accepts `alg: none` → **authentication bypass (90)**: the sink is the authentication logic itself.
- An `exec()` call fed by a query parameter → **command execution (90)**, even if the trace shows "only" file reads.

If two classes still apply to the same sink, use the **higher base** and name the other in the justification (e.g., `Base 80 (broken access control; also mass assignment)`).

| Vulnerability class | Base |
|---------------------|------|
| Remote code / command execution, unsafe deserialization, authentication bypass | **90** |
| Injection into a data store (SQL, NoSQL operator, LDAP, ORM raw query) | **80** |
| Broken access control (IDOR, mass assignment, missing authorization), SSRF | **80** |
| Publicly readable storage, secrets committed in current HEAD | **80** |
| Regex injection with data exposure, path traversal, stored XSS | **75** |
| Security-control bypass or misclassification (a guard, validator, allowlist, or policy engine that lets a dangerous action through) | **75** |
| Secret exposure to third-party code or containers (secrets readable by code the project does not control: dependencies, scanner images, plugins) | **70** |
| Reflected XSS, CSRF on state-changing action, secrets present only in git history | **65** |
| Missing encryption, weak cryptography, insecure defaults, supply-chain hygiene (no lock file, unpinned versions), over-privileged skill/plugin/MCP, availability-only patterns | **60** |
| Vulnerable dependency with a published CVE | **min(round(CVSS base score × 10), 90)** — source rule below |

A class not listed here uses the closest listed class — name the analogy in the justification (e.g., `Base 75 (analogous to path traversal)`).

**CVE base score source** — use, in this order: (1) the NVD **Primary** CVSS base score, v4.0 if NVD lists one, else v3.1; (2) if NVD has no score, the GitHub Advisory (GHSA) CVSS base score; (3) otherwise the CNA score shown on the CVE record. Name the source and version in the arithmetic line, e.g., `Base 75 (CVE-2024-12345, NVD Primary CVSS 3.1: 7.5)`. Only use a CVE that was verified during this assessment (see [dependency-supply-chain.md](dependency-supply-chain.md)); never a score recalled from memory.

### Step 2 — D1: Exploitation complexity (cumulative, all that apply)

| Factor | Adjustment |
|--------|-----------|
| Requires valid authentication | **−10** |
| Requires a specific role or privilege level | **−5** |
| Requires an API key, token, or shared secret beyond auth | **−10** |
| Requires chaining 2+ vulnerabilities | **−10** |
| Requires an upstream compromise (malicious dependency, image, plugin, or action release) — supply-chain precondition | **−15** |
| Rate limiting, WAF, or throttling in place on the path | **−5** |
| Requires internal network access (not internet-facing) | **−15** |

The upstream-compromise factor replaces chaining for that precondition — never apply both for the same step.

### Step 3 — D2: Impact scope (cumulative, sum capped at +10)

| Factor | Adjustment |
|--------|-----------|
| Single record exposure only | **−5** |
| Paginated or limited collection exposure | **0** |
| Full collection / table enumeration possible | **+5** |
| Blind extraction possible (timing, boolean, out-of-band) | **+5** |
| Cross-system, cross-database, or lateral access | **+5** |
| Write, modify, or delete capability | **+5** |
| Privilege escalation possible | **+5** |

If the sum of the positive factors exceeds +10, use +10 and write `(D2 capped at +10)` in the arithmetic line.

**Injection exposure rule** — when the attacker controls query *structure* (SQL string interpolation, NoSQL operator injection, raw ORM queries), the exposure is **everything the application's database role can read or write**, not just the columns or rows the original query selects (UNION, stacked, and blind techniques reach other tables). Therefore:

- `Single record exposure only (−5)` never applies to such injections.
- `Blind extraction possible (+5)` applies whenever no result is reflected but query structure is controlled.
- D3 is the most sensitive data **reachable by that database role**. If the role's grants are not visible, assume the most sensitive data in the same database and set Confidence to **Probable** with the gap "database role grants not verified".

### Step 4 — D3: Data sensitivity (exactly one — the most sensitive category exposed or reachable)

| Data category | Adjustment |
|---------------|-----------|
| Public or non-sensitive data | **−10** |
| Internal operational data (logs, metrics, non-PII metadata) | **−5** |
| Commercial / proprietary non-personal data (catalog, pricing) | **0** |
| Personal data — PII (names, emails, phones, addresses) | **+5** |
| Financial data or health data (PHI) | **+8** |
| Credentials, secrets, or authentication tokens | **+10** |

### Step 5 — Gates and caps (applied last)

| Condition | Result |
|-----------|--------|
| Unreachable — dead code, zero callers from any entry point | **Final = 35** (fixed) |
| Unreachable — reachable only through a disabled path (feature flag off, config disabled) | **Final = 40** (fixed) |
| Fully mitigated by a formal, centralized control (guard, schema, gateway authorizer, sanitization middleware) | **Final = 30** (fixed) — name the control |
| Fully mitigated by an inline / ad-hoc control (effective but untested, not reusable) | **Final = 40** (fixed) — name the control |
| Availability-only impact | **Final = min(Y, 49)** |
| Confidence = Possible | **Final = min(Y, 49)** until confirmed |

The primary-finding floor (51) never lifts a finding over a gate or cap.

**Gates need evidence.** The unreachable, mitigated, and availability-only gates apply only when the gating condition itself is **Confirmed** or **Probable** (zero callers traced; the control traced on the path; no data path found). If the gating evidence is only **Possible**, the gate does not apply: compute the formula and let the Possible cap (49) apply. When the finding's Confidence differs from the gate's, state both (e.g., `Confidence: Confirmed (sink) · gate evidence: Probable`).

---

## Confidence (mandatory per finding)

| Confidence | Meaning | Effect |
|------------|---------|--------|
| **Confirmed** | Traced end to end from entry point to impact with code/config evidence at every hop | None |
| **Probable** | Trace has one identified gap (e.g., infrastructure config not visible, runtime value unknown) — **state the gap** | None, but the gap goes in Out of Scope & Limitations |
| **Possible** | Pattern match only; reachability or impact not traced | **Cap at 49** until confirmed |

Never report a pattern match as Confirmed.

---

## CVSS v4.0 Vector (mandatory for primary findings)

Every primary finding (score > 50) includes a CVSS v4.0 **base vector string** describing the vulnerability as traced:

```text
CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N
```

- Metrics: `AV` (N/A/L/P), `AC` (L/H), `AT` (N/P), `PR` (N/L/H), `UI` (N/P/A), `VC/VI/VA` and `SC/SI/SA` (H/L/N).
- The vector must agree with the trace (e.g., `PR:N` only if the trace confirms no authentication).
- Do **not** report a numeric CVSS score unless it was computed with the official FIRST calculator — CVSS v4.0 scores come from a lookup table and cannot be estimated reliably. The vector alone is sufficient for interoperability.
- Warnings (≤ 50) may write `CVSS: N/A — unreachable / mitigated` when the gate applies.

---

## Scoring Decision Flow

```text
Finding identified
  → Classify impact (exfiltration / integrity / dual-vector / availability-only)
  → Assign Confidence (Confirmed / Probable / Possible)
  → Gate check: unreachable or fully mitigated? → fixed value, write arithmetic line, stop
  → Base (Step 1) + D1 (Step 2) + D2 (Step 3, cap +10) + D3 (Step 4)
  → Clamp 0–100 → floor 51 if eligible → caps (availability-only, Possible)
  → Write arithmetic line + CVSS v4.0 vector + CWE ID(s)
```

---

## Comparative Scoring Reference

| Scenario | Arithmetic | Final |
|----------|-----------|-------|
| Public SQL injection, no LIMIT, dumps user table with PII | 80 +5 (enumeration) +5 (PII) | **90** |
| SQL injection behind JWT + API key + rate limit, DB role limited to an internal reports table | 80 −10 −10 −5 +10 (enumeration + blind, D2 capped) −5 (internal) | **60** |
| Public NoSQL operator injection on login, returns admin account, full collection (sink = data store) | 80 +10 (enumeration + escalation) +5 (PII) | **95** |
| Public S3 bucket with PII, DB backups, and secrets in logs | 80 +10 (enumeration + lateral) +10 (credentials) | **100** |
| Private bucket, IAM-protected, missing encryption at rest, PII | 60 −10 (authenticated cloud access) +5 (PII) | **55** |
| Public regex injection, wildcard leaks full product catalog | 75 +5 (enumeration) +0 (commercial) | **80** |
| Same regex pattern — only ReDoS vector, `.limit(1)` prevents exposure | 60 → availability-only cap | **49** |
| Admin-only regex injection with catalog enumeration | 75 −10 (auth) −5 (role) +5 (enumeration) | **65** |
| Mass assignment + IDOR on financial fields, authenticated | 80 −10 (auth) +10 (write + escalation) +8 (financial) | **88** |

> **Differentiation rule**: Findings of the same type that differ in prerequisites, scope, or data must produce different arithmetic lines. Identical lines for materially different risk profiles mean a factor was missed.

---

## Score Boundary Rules

| Boundary | Rule |
|----------|------|
| **Maximum**: 100 | Reachable only with zero barriers, mass impact, and credential or PII exposure — re-check every factor when you reach it |
| **Primary threshold**: 51 | Reachable, unmitigated, non-availability, non-Possible findings never score below 51. A score of exactly 50 is a Warning (Low) |
| **Unreachable**: 35 / 40 | Fixed values — never higher regardless of theoretical severity |
| **Availability-only cap**: 49 | Hard cap |
| **Possible cap**: 49 | Hard cap until the trace is completed |
| **Mitigated**: 30 / 40 | Fixed values, the mitigating control must be named |
| **Integer only** | No decimal scores |
