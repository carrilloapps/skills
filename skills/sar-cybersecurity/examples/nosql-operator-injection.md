# Example: NoSQL Operator Injection via Direct Body Passthrough

> *Reference output — load on demand when analyzing MongoDB/NoSQL query patterns with user input.*
>
> ⚠️ **Example only** — All patterns below are synthetic descriptions of vulnerable code and correct SAR output. They are not real code and must not be executed.

## Scenario

An authentication endpoint passes unvalidated user input directly to a database query. An attacker sends a query operator object instead of the expected string value to extract unauthorized records.

**Finding location:**

- **Files**: `src/auth/auth.service.ts` (line 34), `src/auth/auth.controller.ts` (line 12)
- **Route**: `POST /login` — public endpoint, no authentication required
- **Issue**: Request body field forwarded to database query method without type validation or sanitization — the field accepts arbitrary objects where only a string is expected
- **Missing controls**: No input sanitization middleware, no DTO or schema validation
- **Pattern reference**: See `injection-patterns.md` — NoSQL Injection table for detection signatures

## Assessment Trace

1. **Entry point**: `POST /login` — public endpoint, no auth required.
2. **Input handling**: Request body field forwarded to database query function without type validation — accepts arbitrary objects where a string is expected.
3. **Schema check**: Database schema defines the field as String type, but strict mode only applies to document creation, not query filters.
4. **Middleware check**: No input sanitization middleware in the application chain.
5. **Impact**: Attacker sends a query operator object instead of a string → the database filter matches unintended documents → returns the **first document in the collection** (typically an admin created early). Combined with password-less flows or password reset, this enables full account takeover.
6. **Scale**: Searched codebase for similar patterns — found **14 additional endpoints** forwarding request body fields directly to database query methods without validation.

## SAR Finding

### [95] — NoSQL Operator Injection via Direct Body Passthrough (15 Endpoints)

| Field | Value |
|-------|-------|
| Registry ID | F01 (new) |
| Score | 95 (Critical) |
| Confidence | Confirmed — traced `POST /login` body → service → `findOne` filter; no sanitizer or DTO at any layer |
| Impact classification | Data exfiltration + integrity (account takeover) |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N` |
| CWE | CWE-943 (Improper Neutralization of Special Elements in Data Query Logic), CWE-20 |
| MITRE ATT&CK | T1190 (Exploit Public-Facing Application), T1078 (Valid Accounts) |
| Effort | M (1–5 days — 15 endpoints) |
| Affected | `src/auth/auth.service.ts:34`, `src/auth/auth.controller.ts:12`, + 14 endpoints (Appendix) |

**Description** — `POST /login` and 14 other endpoints forward request body fields straight into database query filters. A client can send an operator object where a string is expected, bypass the credential check, and read or enumerate records.

**Evidence / Trace** — see Assessment Trace above.

**Attack Scenario**

1. An anonymous user posts to `/login` with the username field set to an operator object (e.g., a "not equal to empty" operator) instead of a string.
2. The filter matches the first document in the collection — typically the earliest-created admin account.
3. The attacker is authenticated as that admin; repeating the technique on list endpoints enumerates the user collection (emails, names, phones).

**Score Justification**
`Base 80 +10 (full enumeration + privilege escalation, D2 capped at +10) +5 (PII) = 95 (cap: none) → Final 95`

- Base 80: injection into a data store — classified by the **sink** (the `findOne` filter), not the consequence. The login bypass is carried by D2 (privilege escalation). *Authentication bypass (90)* applies only when the sink is the authentication logic itself (e.g., a JWT verifier accepting `alg: none`).
- D1 0: public, no barriers.
- D2 +10: collection enumeration (+5) and admin takeover (+5).
- D3 +5: injection exposure rule — operator injection is confined to the collections these endpoints query (no `$where`, `$function`, or `$lookup` in the affected code), and the most sensitive of them, `users`, holds PII. Password hashes live in `credentials`, which no affected endpoint queries.

**Standards Violated** — OWASP Top 10:2025 (A05 Injection, A07 Authentication Failures), NIST SP 800-53 SI-10, CIS Controls v8.1 16, ISO/IEC 27001:2022 A.8.28, GDPR Art. 32, SOC 2 CC6.6

**Fix** — global sanitizer (one line, covers all 15 endpoints) plus a typed DTO on the login path:

```diff
  // main.ts
+ app.use(mongoSanitize()); // strips keys starting with '$' or containing '.'

  // auth.controller.ts
- async login(@Body() body: any) {
+ async login(@Body() body: LoginDto) { // @IsString() username; @IsString() password
```

**How to Verify the Fix**

- Integration test: posting an operator object as `username` returns 400 (DTO) and never 200.
- Integration test per affected endpoint (list in Appendix): operator payload returns 400 or an empty result.

## Key Principles Demonstrated

- **Systemic pattern detection**: Found 14 additional vulnerable endpoints beyond the initial finding
- **Full attack chain**: Traced from public endpoint to database query to data exposure
- **PII impact assessment**: Evaluated which fields are exposed, not just that a query is injectable
- **Layered mitigation**: Immediate → short-term → medium-term remediation path

## Cross-Reference

- All NoSQL injection patterns → see [`frameworks/injection-patterns.md`](../frameworks/injection-patterns.md)
- MongoDB inspection procedures → see [`frameworks/database-access-protocol.md`](../frameworks/database-access-protocol.md)
- Standard mapping guide → see [`frameworks/compliance-standards.md`](../frameworks/compliance-standards.md)
