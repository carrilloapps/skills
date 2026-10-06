# Example: Public Cloud Storage Bucket with Sensitive Data

> *Reference output — load on demand when assessing cloud storage configurations (S3, GCS, Azure Blob).*
>
> ⚠️ **Example only** — All patterns, IaC descriptions, and configuration references below are synthetic illustrations of vulnerable configurations and correct SAR output. They are not real infrastructure and must not be executed or deployed.

## Scenario

A cloud storage bucket is configured with public read access and contains user uploads, database backups, and application logs.

**Finding location:**

- **File**: `terraform/s3.tf` — infrastructure-as-code definition for the storage bucket
- **Issue**: Bucket ACL allows public read access, no public-access-block resource defined, no encryption, no versioning, no access logging
- **Bucket policy**: Grants object-read access to any unauthenticated user (wildcard principal) on all objects in the bucket
- **Pattern reference**: See `storage-exfiltration.md` — Cloud Object Storage table for detection signatures

## Assessment Trace

1. **IaC scan**: Infrastructure-as-code definition configures the bucket with public-read ACL and no public-access-block resource.
2. **Policy analysis**: Bucket policy grants object-read access to a wildcard principal on all objects — any unauthenticated user can download any file.
3. **What the code writes to the bucket** (derived from code and IaC — the agent never lists or downloads live objects):
   - `uploads/` — `src/uploads/upload.handler.ts:22` stores user-uploaded documents (IDs, contracts, personal files)
   - `backups/` — `ops/backup-cronjob.yaml:14` runs `pg_dump` of the customer database daily into this prefix
   - `logs/` — `src/common/logger.ts:31` ships error traces to this prefix, and the error handler at `src/common/error.filter.ts:18` logs full request headers (including `Authorization` and `x-api-key`)
4. **Encryption**: No server-side encryption configuration — data stored unencrypted.
5. **Access logging**: No access logging configured — no audit trail of who accessed what.
6. **Frontend exposure**: Bucket name hardcoded in `src/config/storage.ts` and visible in client-side code.

## SAR Finding

### [100] — Public S3 Bucket Containing PII, Database Backups, and Application Secrets

| Field | Value |
|-------|-------|
| Registry ID | F01 (new) |
| Score | 100 (Critical) |
| Confidence | Probable — gap: the deployed bucket's live policy and object contents were not verified (static analysis of IaC and code only; no live requests) |
| Impact classification | Data exfiltration (with lateral access via leaked credentials) |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:H/SI:H/SA:N` |
| CWE | CWE-284 (Improper Access Control), CWE-312 (Cleartext Storage of Sensitive Information), CWE-532 (Sensitive Information in Log File) |
| MITRE ATT&CK | T1530 (Data from Cloud Storage), T1552.001 (Credentials in Files) |
| Effort | S (< 1 day) for access block + rotation; L for the follow-up redesign |
| Affected | `terraform/s3.tf`, bucket policy, `src/config/storage.ts` |

**Description** — The IaC makes the production bucket publicly readable (ACL + wildcard-principal policy). The code writes user ID documents, daily database dumps with customer PII, and logs containing auth tokens and API keys into it. No encryption, no access logging — exposure cannot be ruled out retroactively. If the deployed state matches the IaC, the data is public today.

**Evidence / Trace** — see Assessment Trace above.

**Attack Scenario**

1. Anyone reads the bucket name from the frontend bundle.
2. They list or guess object keys and download the latest database dump without credentials.
3. API keys in `logs/` give them access to other systems (lateral movement). No log records any of it.

**Score Justification**
`Base 80 +10 (full enumeration + lateral access, D2 capped at +10) +10 (credentials) = 100 (cap: none) → Final 100`

- Re-checked per the 100 rule: zero barriers, mass impact, credentials + PII, no detection — every factor is backed by IaC or code evidence.
- Confidence Probable does not cap the score; the gap (live state) is listed in Out of Scope & Limitations and the team confirms it with the first verification step below.

**Standards Violated** — OWASP Top 10:2025 (A01 Broken Access Control, A02 Security Misconfiguration, A04 Cryptographic Failures), GDPR Art. 32 & 33 (breach assessment), PCI DSS v4.0.1 Req. 3 & 7 (if payment data in backups), ISO/IEC 27001:2022 A.8.12, A.5.23 & A.8.24, NIST SP 800-53 AC-3, SC-28, AU-2, SOC 2 CC6.1, CC6.7, CSA STAR CCM DSI-04

**Fix** (IaC, documentation only — the team applies it):

```diff
  resource "aws_s3_bucket" "app" { bucket = "app-prod" }
- resource "aws_s3_bucket_acl" "app" { bucket = aws_s3_bucket.app.id  acl = "public-read" }
+ resource "aws_s3_bucket_public_access_block" "app" {
+   bucket                  = aws_s3_bucket.app.id
+   block_public_acls       = true
+   block_public_policy     = true
+   ignore_public_acls      = true
+   restrict_public_buckets = true
+ }
```

Same day, outside the diff: rotate every key found in `logs/` and the database credentials visible in backups; start a GDPR Art. 33 breach assessment (72-hour clock). Follow-up: SSE-KMS encryption, access logging, backups in a separate private account, pre-signed URLs from the backend.

**How to Verify the Fix** (run by the team, not by the agent)

- Before the fix, the team confirms the live state matches the IaC (this closes the Confidence gap); after the fix, an anonymous `GET` on a known `backups/` object returns 403.
- The cloud provider's public-access-block report shows all four flags `true` for the bucket and account.
- Every rotated key fails authentication when tested by the team.

## Key Principles Demonstrated

- **Data classification**: Distinguished between user uploads, backups, and logs — each with different risk profiles
- **Multiple violation mapping**: Mapped to 7 standards with justification
- **Tiered remediation**: Emergency → immediate → short-term → medium-term timeline
- **Collateral impact**: Identified cascading risks (credential rotation needed from exposed logs)

## Cross-Reference

- All cloud storage patterns → see [`frameworks/storage-exfiltration.md`](../frameworks/storage-exfiltration.md)
- Compliance standards → see [`frameworks/compliance-standards.md`](../frameworks/compliance-standards.md)
- Scoring system → see [`frameworks/scoring-system.md`](../frameworks/scoring-system.md)
