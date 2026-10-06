# Example: Regex Injection / ReDoS via Unsanitized Search Input

> *Reference output — load on demand when analyzing search endpoints that construct regex from user input.*
>
> ⚠️ **Example only** — All patterns below are synthetic descriptions of vulnerable code and correct SAR output. They are not real code and must not be executed.

## Scenario

A search endpoint constructs a dynamic regular expression from user input and uses it in a database query. Input metacharacters are not escaped.

**Finding location:**

- **Files**: `src/products/products.service.ts` (line 67), `src/products/products.controller.ts` (line 23)
- **Route**: `GET /products/search?q=...` — public endpoint, no authentication required
- **Issue**: Query parameter passed directly to regular expression constructor without escaping metacharacters, then used as a database query filter with a limit of 50 results
- **Pattern reference**: See `injection-patterns.md` — Regex Injection / ReDoS table for detection signatures

## Assessment Trace

1. **Entry point**: `GET /products/search?q=...` — public endpoint.
2. **Input handling**: Query parameter passed directly to regex constructor without escaping metacharacters.
3. **Attack vector 1 — Data exfiltration** (**primary SAR concern**): Attacker sends a wildcard-match-all pattern → regex matches all documents → returns first 50 results. Attacker can iterate with prefix patterns to enumerate the entire catalog.
4. **Attack vector 2 — Service disruption** (**availability-only, secondary**): Attacker sends a nested-quantifier pattern → catastrophic backtracking → CPU exhaustion → service degradation. No data is exposed through this vector.
5. **Impact classification**: **Dual-vector** — same vulnerability enables both data exfiltration (primary) and service disruption (secondary). Score on the exfiltration vector per Confidentiality Primacy rule.
6. **Codebase scan**: Found **8 files with 23 total occurrences** of unescaped user input passed to regex constructors.

## SAR Finding

### [80] — Regex Injection with Data Enumeration via Unsanitized Search Input (23 Occurrences)

| Field | Value |
|-------|-------|
| Registry ID | F01 (new) |
| Score | 80 (High) |
| Confidence | Confirmed — traced on `GET /products/search`; the other 22 occurrences share the same helper |
| Impact classification | Dual-vector — data exfiltration (primary) + availability (secondary) |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:L/SC:N/SI:N/SA:N` |
| CWE | CWE-625 (Permissive Regular Expression), CWE-1333 (Inefficient Regular Expression Complexity) |
| MITRE ATT&CK | T1190 (Exploit Public-Facing Application), T1213 (Data from Information Repositories) |
| Effort | M (1–5 days — 23 occurrences, one shared utility) |
| Affected | `src/products/products.service.ts:67` + 22 occurrences in 8 files (Appendix) |

**Description** — User input is passed to `new RegExp()` without escaping. A wildcard pattern matches every document (50 per request) and prefix iteration enumerates the full catalog. A nested-quantifier pattern also causes catastrophic backtracking, but that vector alone would be availability-only.

**Evidence / Trace** — see Assessment Trace above.

**Attack Scenario**

1. An anonymous user searches with a match-all pattern (e.g., `q=.*`) and receives 50 products.
2. The user iterates prefix patterns (`^a`, `^b`, …) to page through the entire catalog, including unlisted products.
3. Secondary: a nested-quantifier input pins a CPU core for > 10 s per request.

**Score Justification**
`Base 75 +5 (full enumeration via prefix iteration) +0 (commercial data) = 80 (cap: none) → Final 80`

- Scored on the exfiltration vector (Confidentiality Primacy). The ReDoS vector alone: `Base 60 = 60 (cap: availability-only 49) → 49`.

**Standards Violated** — OWASP Top 10:2025 (A05 Injection), NIST SP 800-53 SI-10, ISO/IEC 27001:2022 A.8.28, CIS Controls v8.1 16

**Fix** — one shared utility, applied at all 23 call sites:

```diff
+ // src/common/escape-regex.ts
+ export const escapeRegex = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  // products.service.ts
- const pattern = new RegExp(q, 'i');
+ const pattern = new RegExp(escapeRegex(q), 'i');
```

**How to Verify the Fix**

- Unit test: `escapeRegex('.*')` returns `\.\*`; search for `.*` returns only products literally containing `.*`.
- CI check: `grep -rn "new RegExp(" src/ | grep -v escapeRegex` returns no user-input call sites.
- Load test: a nested-quantifier input completes in < 50 ms.

## Key Principles Demonstrated

- **Confidentiality primacy**: The score is driven by the data exfiltration vector, not the ReDoS/availability vector
- **Impact classification**: Dual-vector finding explicitly identifies which vector determines the score
- **Availability delegation**: The ReDoS vector is documented as secondary; alone it scores 49 (`Base 60 → availability-only cap 49`)
- **Systemic count**: Reported total occurrences across the codebase, not just the first finding

## Cross-Reference

- All regex/ReDoS patterns → see [`frameworks/injection-patterns.md`](../frameworks/injection-patterns.md)
- Scoring rules → see [`frameworks/scoring-system.md`](../frameworks/scoring-system.md)
