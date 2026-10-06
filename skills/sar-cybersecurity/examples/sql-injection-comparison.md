# Example: Same Vulnerability Type, Different Scores — SQL Injection Comparison

> *Reference output — load on demand to understand how the multi-factor scoring system produces different scores for the same vulnerability type based on exploitation complexity, impact scope, and data sensitivity.*
>
> ⚠️ **Example only** — All patterns below are synthetic descriptions of vulnerable code and correct SAR output. They are not real code and must not be executed.

## Purpose

This example demonstrates **why honest scoring matters**. Two SQL injection vulnerabilities exist in the same codebase. Both are real, confirmed, and exploitable. But they are **not equal** — treating them as equivalent would misrepresent the actual risk profile, generate unnecessary alarm for one and dangerous complacency for the other.

---

## Scenario A — Public Endpoint, Full Table Enumeration, PII Exposure

```text
Vulnerable pattern (pseudocode):

  File: src/search/search.controller.ts — line 18
  Route: GET /api/search/users?q=...
  Guards: None — public endpoint, no authentication required
    → query parameter 'q' passed directly to searchService.findUsers(q)

  File: src/search/search.service.ts — line 42
  Function: findUsers(query)
    → constructs: SELECT id, email, full_name, phone, address FROM users WHERE full_name LIKE '%${query}%'
    → string interpolation, no parameterization
    → no LIMIT clause — returns all matching rows
    → fields returned: id, email, full_name, phone, address (all PII)
```

### Assessment Trace — Scenario A

1. **Entry point**: `GET /api/search/users?q=...` — public, no authentication.
2. **Input handling**: Query parameter `q` interpolated directly into SQL string. No sanitization, no parameterization.
3. **Middleware check**: No WAF, no rate limiting, no input validation middleware.
4. **Attack payload**: `q=' OR '1'='1' --` → returns entire `users` table.
5. **Result set**: No `LIMIT` clause — all rows returned. Table contains 50,000+ records.
6. **Data exposed**: `email`, `full_name`, `phone`, `address` — all PII fields, subject to GDPR/CCPA.
7. **Monitoring**: No query logging, no anomaly detection on this endpoint.

### SAR Finding — Scenario A

#### [90] — SQL Injection on Public Search Endpoint with Full PII Enumeration

| Field | Value |
|-------|-------|
| Registry ID | F01 (new) |
| Score | 90 (Critical) |
| Confidence | Confirmed — traced controller → service → query, no intermediate control |
| Impact classification | Data exfiltration |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N` |
| CWE | CWE-89 |
| MITRE ATT&CK | T1190 (Exploit Public-Facing Application) |
| Effort | S (< 1 day) |
| Affected | `src/search/search.controller.ts:18`, `src/search/search.service.ts:42` |

**Description** — `GET /api/search/users` interpolates the `q` parameter into a SQL string. No authentication, no validation, no `LIMIT`. The full `users` table (50,000+ rows with email, phone, address) is extractable.

**Evidence / Trace** — see Assessment Trace above (7 hops, no control found).

**Attack Scenario**

1. An anonymous visitor calls the search endpoint with a tautology input such as `q=' OR '1'='1' --`.
2. The `WHERE` clause becomes always-true; with no `LIMIT`, every row is returned.
3. The attacker obtains names, emails, phones, and addresses for all users in one request — no trace in logs.

**Score Justification**
`Base 80 +5 (full enumeration) +5 (PII) = 90 (cap: none) → Final 90`

- Base 80: injection into a data store.
- D1 0: public, no auth, no rate limit, internet-facing.
- D2 +5: full table enumeration (no `LIMIT`).
- D3 +5: PII (email, phone, address).

**Standards Violated** — OWASP Top 10:2025 (A05 Injection), GDPR Art. 32, NIST SP 800-53 SI-10, CIS Controls v8.1 16, ISO/IEC 27001:2022 A.8.28, SOC 2 CC6.6

**Fix**

```diff
- const sql = `SELECT id, email, full_name, phone, address FROM users WHERE full_name LIKE '%${query}%'`;
- return this.db.query(sql);
+ return this.db.query(
+   'SELECT id, full_name FROM users WHERE full_name LIKE $1 LIMIT 50',
+   [`%${query}%`],
+ );
```

Follow-up hardening (not in Effort): require authentication for user search; return only `id` and `full_name`.

**How to Verify the Fix**

- Integration test: `GET /api/search/users?q=' OR '1'='1' --` returns HTTP 200 with **0** rows.
- Integration test: a normal query returns at most 50 rows and no `email`/`phone`/`address` fields.

---

## Scenario B — Authenticated Endpoint + API Key, Single Record, Non-Sensitive Data

```text
Vulnerable pattern (pseudocode):

  File: src/reports/reports.controller.ts — line 56
  Route: GET /api/internal/reports/:id
  Guards: JwtAuthGuard + ApiKeyGuard (requires both valid JWT and valid API key header)
  Rate limit: 10 requests/minute per user
    → path parameter 'id' passed to reportsService.getById(id)

  File: src/reports/reports.service.ts — line 73
  Function: getById(id)
    → constructs: SELECT report_name, created_at, status FROM reports WHERE id = '${id}'
    → string interpolation, no parameterization
    → returns single row (id is unique primary key)
    → fields returned: report_name, created_at, status (operational data, no PII)

  File: migrations/0004_reports_role.sql — line 3
    → GRANT SELECT ON reports TO reports_reader;   (the service connects as reports_reader)
    → reports_reader has no grants on any other table
```

### Assessment Trace — Scenario B

1. **Entry point**: `GET /api/internal/reports/:id` — requires JWT authentication + API key header.
2. **Guards**: `JwtAuthGuard` validates JWT token; `ApiKeyGuard` validates `x-api-key` header against a rotatable key stored in Secrets Manager.
3. **Rate limiting**: 10 requests/minute per authenticated user — limits enumeration speed.
4. **Input handling**: Path parameter `id` interpolated into SQL. Vulnerable to injection, but attacker must first have valid JWT + API key.
5. **Attack payload**: `id=1' OR '1'='1' --` returns one row — but the attacker controls query **structure**, so the single-result method does not bound the exposure. Boolean-based blind techniques can read any table the connection role can reach, one bit at a time.
6. **Database role reach**: the service connects as `reports_reader`, which `migrations/0004_reports_role.sql:3` grants `SELECT` on `reports` only. Reachable data = the whole `reports` table (internal operational data — no PII, no financial data, no credentials).
7. **Monitoring**: Request logging with user identification enabled on all authenticated endpoints.

### SAR Finding — Scenario B

#### [60] — SQL Injection on Authenticated Internal Reports Endpoint

| Field | Value |
|-------|-------|
| Registry ID | F02 (new) |
| Score | 60 (Medium) |
| Confidence | Confirmed — traced through both guards to the query; role grants read from migrations |
| Impact classification | Data exfiltration (limited) |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:H/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N` |
| CWE | CWE-89 |
| MITRE ATT&CK | T1190 (Exploit Public-Facing Application) |
| Effort | S (< 1 day) |
| Affected | `src/reports/reports.controller.ts:56`, `src/reports/reports.service.ts:73` |

**Description** — `GET /api/internal/reports/:id` interpolates the path parameter into SQL. Exploitation requires a valid JWT **and** API key and is rate-limited to 10 req/min. Through blind extraction the attacker can read the entire `reports` table — the only table the database role can reach — which holds internal operational metadata.

**Evidence / Trace** — see Assessment Trace above.

**Attack Scenario**

1. An insider (or an attacker holding stolen JWT + API key) calls the endpoint with `id=1' OR '1'='1' --`.
2. The single-result ORM call returns one row; switching to true/false conditions on the response, the attacker extracts the rest of `reports` bit by bit.
3. At 10 requests/minute this is slow, and every request is logged with the user ID — but the whole table is reachable. No other table is, because of the role's grants.

**Score Justification**
`Base 80 −10 (auth) −10 (API key) −5 (rate limit) +5 (full enumeration) +5 (blind extraction) −5 (internal data) = 60 (cap: none) → Final 60`

- D1 −25: JWT required (−10), API key beyond auth (−10), rate limiting (−5).
- D2 +10: injection exposure rule — query structure is controlled, so "single record" does not apply; the whole reachable table can be enumerated (+5) through blind extraction (+5).
- D3 −5: the most sensitive data reachable by `reports_reader` is internal operational metadata.
- Had the role grants not been visible, D3 would assume the most sensitive table in the database and Confidence would be Probable.

**Standards Violated** — OWASP Top 10:2025 (A05 Injection), CIS Controls v8.1 16, ISO/IEC 27001:2022 A.8.28

**Fix**

```diff
- const sql = `SELECT report_name, created_at, status FROM reports WHERE id = '${id}'`;
- return this.db.queryOne(sql);
+ return this.db.queryOne(
+   'SELECT report_name, created_at, status FROM reports WHERE id = $1',
+   [id],
+ );
```

**How to Verify the Fix**

- Integration test: `id=1' OR '1'='1' --` returns HTTP 404 (no row), not report data.
- Add a CI lint rule that fails on template literals passed to `db.query`/`db.queryOne`.

---

## Side-by-Side Comparison

| Factor | Scenario A (Score: 90) | Scenario B (Score: 60) |
|--------|----------------------|----------------------|
| **Vulnerability type** | SQL Injection | SQL Injection |
| **Authentication** | None (public) | JWT + API Key |
| **Rate limiting** | None | 10 req/min |
| **Data reachable** | 50,000+ PII records | One table of operational metadata (role-limited) |
| **PII exposure** | Yes (email, phone, address) | No |
| **Enumeration possible** | Yes (no LIMIT) | Yes, slowly (blind, 10 req/min) |
| **Monitoring** | None | Request logging with user ID |
| **Remediation urgency** | Emergency | Planned (short-term) |
| **Arithmetic** | `80 +5 +5 = 90` | `80 −10 −10 −5 +5 +5 −5 = 60` |
| **Score** | **90 — Critical** | **60 — Medium** |

> Both findings are **real SQL injections** that must be fixed. The difference is **when and how urgently**. Scenario A is an emergency that could result in a data breach within hours. Scenario B is a legitimate finding that should be fixed in the next sprint, but it does not represent an imminent threat to user data.

---

## Key Principles Demonstrated

- **Same type, different scores**: Both are SQL injection — but real-world risk is not determined by vulnerability type alone
- **Auditable arithmetic**: Every score shows its arithmetic line; anyone can recompute it from scoring-system.md and get the same number
- **Proportional urgency**: Remediation timelines match actual risk — emergency vs. planned
- **Professional honesty**: Neither finding is omitted or inflated — both are documented with evidence, but scored proportional to their real impact

## Cross-Reference

- Multi-factor scoring system → see [`frameworks/scoring-system.md`](../frameworks/scoring-system.md)
- SQL injection patterns → see [`frameworks/injection-patterns.md`](../frameworks/injection-patterns.md)
- Compliance standards → see [`frameworks/compliance-standards.md`](../frameworks/compliance-standards.md)
