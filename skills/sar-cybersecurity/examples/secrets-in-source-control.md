# Example: Secrets Committed to Source Control

> *Reference output — load on demand when assessing repositories for leaked credentials, API keys, or hardcoded secrets.*
>
> ⚠️ **Example only** — All patterns, shell output, and credential placeholders below are synthetic descriptions of vulnerable configurations and correct SAR output. They are not real secrets and must not be executed or used.

## Scenario

The git repository contains committed environment files, hardcoded credentials in source code, and secrets exposed in container build configurations.

**Discovery summary:**

- **Committed environment files**: 3 files tracked in git that should be in `.gitignore` (root, production, and Docker-specific environment files)
- **Hardcoded credentials**: Database connection string with plaintext username and password in `src/config/database.ts` (line 8)
- **Container exposure**: Signing key embedded as build-time directive in container image — visible in image layer history
- **Sensitive content in environment files**: 5 categories of secrets found — database connection string, token signing key, cloud provider access credentials (key ID + secret), and payment provider API key
- **Pattern reference**: See `storage-exfiltration.md` — Secrets and Environment Variables table for detection signatures

## Assessment Trace

1. **Tracked file scan**: 3 environment files appear in the repository file listing provided by the read-only repository tools (the agent runs no VCS commands) and are not excluded by `.gitignore`.
2. **Secret pattern scan**: Found 12 secrets across 6 files:
   - 3 environment files: database credentials, token signing key, cloud provider keys, payment API key
   - Source code config file: hardcoded connection string
   - Container build file: signing key set via build-time directive
   - Container orchestration file: plaintext credentials in environment section
3. **History check**: The read-only repository MCP's commit listing shows the first environment file added 14 months ago and the production environment file 8 months ago. Older history beyond what the tool returned is listed in Out of Scope & Limitations.
4. **Ignore file check**: No environment file patterns found in `.gitignore`.
5. **Secrets manager**: No references to any secrets management service across the codebase.
6. **CI/CD check**: Pipeline uses masked secrets in one step but echoes a database URL variable in a debug step (log exposure).

## SAR Finding

### [90] — Secrets Committed to Source Control (12 Secrets, 6 Files, 14 Months Exposure)

| Field | Value |
|-------|-------|
| Registry ID | F01 (new) |
| Score | 90 (Critical) |
| Confidence | Confirmed — secrets present in current HEAD; key formats match live providers. Whether each key is still active was **not** tested (no credential use). |
| Impact classification | Data exfiltration + integrity (lateral access with write capability) |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:N/SC:H/SI:H/SA:N` |
| CWE | CWE-798 (Use of Hard-coded Credentials), CWE-540 (Inclusion of Sensitive Information in Source Code), CWE-532 |
| MITRE ATT&CK | T1552.001 (Credentials in Files), T1552.004 (Private Keys), T1528 (Steal Application Access Token) |
| Effort | M (1–5 days — rotation across 4 providers + pipeline changes) |
| Affected | 3 env files, `src/config/database.ts:8`, container build file, compose file, CI workflow |

**Description** — 12 production secrets (database, token signing key, cloud access keys, payment API key) are in the repository, some for 14 months, plus one echoed into CI logs. Anyone with read access to the repo, any clone, or the CI logs holds production credentials.

**Evidence / Trace** — see Assessment Trace above.

**Attack Scenario**

1. A former contractor (or anyone who obtains a clone) opens the committed env file.
2. With the cloud keys and DB credentials they read and modify production data directly; with the signing key they mint valid session tokens for any user.
3. With the payment key they can issue refunds or read transaction history.

**Score Justification**
`Base 80 −10 (auth) +10 (lateral access + write capability, D2 capped at +10) +10 (credentials) = 90 (cap: none) → Final 90`

- D1 −10 (auth): reading the secrets requires authenticated repository read access — the listed factor "requires valid authentication".

**Standards Violated** — OWASP Top 10:2025 (A02 Security Misconfiguration, A04 Cryptographic Failures, A07 Authentication Failures), ISO/IEC 27001:2022 A.5.17 & A.8.24, NIST SP 800-53 IA-5, CIS Controls v8.1 16, PCI DSS v4.0.1 Req. 3 & 8, SOC 2 CC6.1, GDPR Art. 32

**Fix** — rotation first (purging history does not un-leak a secret), then stop the bleeding:

```diff
  # .gitignore
+ .env
+ .env.*
+ !.env.example

  # src/config/database.ts
- export const DATABASE_URL = 'postgres://app:<redacted>@prod-db:5432/app';
+ export const DATABASE_URL = requireEnv('DATABASE_URL');

  # .github/workflows/deploy.yml
-       - run: echo "DB=$DATABASE_URL"
```

Follow-up (not in Effort): purge history with a history-rewrite tool (coordinated force-push), adopt a secrets manager, add pre-commit and CI secret scanning.

**How to Verify the Fix**

- Each old credential is rejected by its provider (team-run test after rotation).
- A secret scanner run over HEAD and full history reports 0 findings (after purge).
- The CI log of the next deploy contains no connection strings.

## Key Principles Demonstrated

- **Historical analysis**: Used the commit history available through read-only tools, not just current HEAD — and declared what it could not see
- **Comprehensive scan**: Found secrets in source code, environment files, container definitions, and CI/CD pipeline
- **Credential rotation priority**: Emergency rotation before any cleanup — secrets are already exposed
- **Cascading remediation**: Rotate → gitignore → purge history → adopt secrets manager → prevent recurrence

## Cross-Reference

- All secrets/storage patterns → see [`frameworks/storage-exfiltration.md`](../frameworks/storage-exfiltration.md)
- Compliance standards → see [`frameworks/compliance-standards.md`](../frameworks/compliance-standards.md)
- Scoring system → see [`frameworks/scoring-system.md`](../frameworks/scoring-system.md)
