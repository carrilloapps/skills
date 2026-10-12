# Pre-Launch Gate — 20 Controls

> *Protocol file — load when the user asks whether something is safe to launch, ship, publish, or open to users, and for any assessment of a target about to reach production.*
>
> A full assessment answers *what is wrong with this system*. This gate answers one narrower question: **is this safe to expose?** It is a fixed list of twenty controls, each with a pass condition that can be verified against the code and configuration present in the target, so two runs on the same commit give the same verdict.

> ⚠️ **Reference patterns only** — the detection hints below point at files and configuration shapes to read. They are not execution instructions; the gate is a static review plus the outputs of tools the user has already approved. The agent never attacks, probes, or sends traffic to a live system to decide a verdict.

---

## How the gate runs

1. **Scope it first** — a control that does not apply to this target is `N/A` with the reason (a CLI with no HTTP surface has no security headers). `N/A` is a verdict, not a skip.
2. **Evidence or it is not a pass** — every `Pass` cites a file, a configuration key, or an approved tool output present in the target. A control that cannot be verified is `Unknown`, never `Pass`.
3. **Each `Fail` becomes a finding** — scored with [scoring-system.md](scoring-system.md), written in the report block of [output-format.md](output-format.md), and recorded in the findings registry. The gate never invents a severity of its own.
4. **The verdict is derived, not chosen** — `Not ready` if any control is `Fail` or `Unknown`; `Ready with accepted exceptions` if every `Fail` carries a written exception with an owner role and a date; `Ready` otherwise.
5. **An exception is a decision, not a note** — it names what is accepted, who accepted it, when it expires, and the compensating control. An exception without an expiry date is not accepted.
6. **The gate reports; it does not fix.** Remediation is proposed as a diff and applied only after the user approves it, like every other finding in this skill.

---

## The 20 controls

| # | Control | Passes when | Detected in |
|---|---|---|---|
| 1 | **Hide API keys** | No key, token, or secret appears in source, client bundle, mobile binary, repository history, or CI logs. Every secret is read at runtime from a secret store or an untracked environment file, and the client only ever holds values meant to be public | [storage-exfiltration.md](storage-exfiltration.md) → *Secrets and Environment Variables* |
| 2 | **Purge secrets from version control** | No credential is reachable in any commit of the published history. Every secret that was ever committed has been **rotated**, and the rotation date is recorded | [storage-exfiltration.md](storage-exfiltration.md) → *Secrets already committed* |
| 3 | **Public database key is the public one** | The key shipped to clients is the anonymous/publishable key with no privileged grants; service-role, admin, or master keys exist only server-side. A client-side privileged key is Critical regardless of other controls | [database-access-protocol.md](database-access-protocol.md) → *Client-exposed database keys* |
| 4 | **Row-level security** | Every table reachable by a client key has RLS (or the platform equivalent) enabled **and** a policy per operation. Enabled with no policy, or a policy of `true`, is a failure | [database-access-protocol.md](database-access-protocol.md) |
| 5 | **Encrypt sensitive data** | Personal, financial, and health data is encrypted at rest and in transit; the key lives in a managed key service, not next to the data. Deterministic or reversible encoding is not encryption | [storage-exfiltration.md](storage-exfiltration.md) |
| 6 | **Authentication enforced** | Every non-public route, job, webhook, and administrative surface requires authentication server-side. A route protected only by an unguessable path, or only by client-side routing, is unauthenticated | [edge-session-controls.md](edge-session-controls.md) §3 |
| 7 | **Record-level authorization** | Every read and write checks that the caller owns or may act on that specific record — not only that the caller is logged in. Object identifiers from the request are never trusted as proof of ownership | [database-access-protocol.md](database-access-protocol.md), [injection-patterns.md](injection-patterns.md) |
| 8 | **Field manipulation blocked** | Writes bind only to an explicit allowlist of fields. `role`, `isAdmin`, `balance`, `status`, `ownerId`, and price or quantity fields are never settable from a request body | [injection-patterns.md](injection-patterns.md) → *Mass Assignment* |
| 9 | **Session cookies protected** | Session cookies carry `HttpOnly`, `Secure`, and an explicit `SameSite`; the identifier rotates on login and on privilege change; logout invalidates server-side; state-changing requests carry CSRF protection | [edge-session-controls.md](edge-session-controls.md) §3 |
| 10 | **Passwords hashed** | Passwords are stored with a memory-hard algorithm (`argon2id`, or `bcrypt` cost ≥ 12) with a per-record salt and constant-time verification. Recovery codes and TOTP seeds are hashed or encrypted too | [edge-session-controls.md](edge-session-controls.md) §4 |
| 11 | **Rate limiting** | Authentication, password reset, OTP, token, and expensive endpoints are limited server-side, keyed by account **and** network identity, returning `429` with `Retry-After` | [edge-session-controls.md](edge-session-controls.md) §5 |
| 12 | **Automation and bot control** | Public write, signup, and messaging paths carry an automation control (CAPTCHA, proof of work, device or domain check, or approval step), and webhooks verify a signature within a timestamp window | [edge-session-controls.md](edge-session-controls.md) §5 |
| 13 | **Parameterized queries** | Every query uses parameter binding or a safe query builder. Concatenated or interpolated user input in SQL, NoSQL filters, raw ORM fragments, or shell arguments is a failure even where the input "looks" numeric | [injection-patterns.md](injection-patterns.md) |
| 14 | **Inputs validated** | Every external input is validated at its boundary against an explicit schema — type, range, length, format, and allowlist — and rejected when invalid. Validation lives server-side; client validation does not count | [injection-patterns.md](injection-patterns.md) |
| 15 | **Content sanitized** | User-generated content is encoded for its output context, and rich text is sanitized with a vetted library against an allowlist. No `innerHTML`, `dangerouslySetInnerHTML`, or raw template interpolation of user content | [injection-patterns.md](injection-patterns.md) |
| 16 | **File handling restricted** | Uploads are limited by type (verified by content, not extension), by size, and by count; stored outside the web root or in a private bucket with generated names; served through signed URLs; never executed. Path traversal is blocked on every file read | [storage-exfiltration.md](storage-exfiltration.md) → *File Upload* |
| 17 | **Return only necessary data** | Each endpoint serializes an explicit output schema per audience; persistence models are never returned directly; included relations are authorized; errors return a code and a request identifier instead of a stack trace | [edge-session-controls.md](edge-session-controls.md) §6 |
| 18 | **Security headers** | `Content-Security-Policy` without `unsafe-inline` in `script-src`, `X-Content-Type-Options: nosniff`, `frame-ancestors` (or `X-Frame-Options`), a strict `Referrer-Policy`, and CORS restricted to an explicit origin allowlist whenever credentials are allowed | [edge-session-controls.md](edge-session-controls.md) §2 |
| 19 | **HTTPS enforced** | TLS 1.2+ everywhere, `:80` redirects to `:443`, HSTS with `max-age` ≥ 180 days and `includeSubDomains`, certificate verification never disabled in client code, no mixed content | [edge-session-controls.md](edge-session-controls.md) §1 |
| 20 | **Dependencies scanned** | A lockfile is committed, an advisory scan ran this session or in CI on this commit, no known-exploited or Critical/High advisory is unresolved, and no unmaintained or typosquatted package is present | [dependency-supply-chain.md](dependency-supply-chain.md) |

---

## Verdicts

| Verdict | Meaning |
|---------|---------|
| **Pass** | Verified against evidence in the target, cited |
| **Fail** | Verified absent or incorrectly configured — becomes a scored finding |
| **N/A** | The control does not apply to this target, with the reason |
| **Unknown** | Could not be verified with the access available — states what is missing and blocks readiness exactly like a `Fail` |
| **Accepted exception** | A `Fail` the team accepted in writing, with owner role, expiry date, and compensating control |

`Unknown` exists so the gate never guesses. A control nobody could check is reported as unchecked, in line with the *Honest limits* constraint of this skill.

---

## Output block

The gate appends this block to the report produced by [output-format.md](output-format.md); it never replaces it. Options and actions are numbered, never checkboxes.

```markdown
## Pre-Launch Gate

**Verdict:** Ready · Ready with accepted exceptions · Not ready
**Checked:** <YYYY-MM-DD> · **Commit:** <short sha> · **Scope:** <what was in scope>

| # | Control | Verdict | Evidence / Finding |
|---|---------|---------|--------------------|
| 1 | Hide API keys | Pass | `config/runtime.ts:14` reads from the secret store; no key in the client bundle |
| 4 | Row-level security | Fail | `db/schema.sql:88` — `invoices` has RLS enabled with no policy → F03 (score 85) |
| 12 | Automation and bot control | N/A | No public write path in this release |
| 18 | Security headers | Unknown | Edge configuration is managed outside this repository |

**Blocking (must be resolved or accepted before release)**

1. F03 — `invoices` readable by any authenticated tenant. Fix: policy `tenant_id = auth.tenant_id()` on select, update, delete.
2. Control 18 — request the edge configuration, or accept with a compensating control.

**Accepted exceptions**

1. Control 11 on `/api/export` — accepted by <role> until <YYYY-MM-DD>; compensating control: per-account daily quota in the gateway.
```

---

## Cross-reference

| Need | File |
|---|---|
| Score and Confidence for each `Fail` | [scoring-system.md](scoring-system.md) |
| Report structure, registry, snapshot | [output-format.md](output-format.md) |
| CWE / OWASP / ATT&CK identifiers | [compliance-standards.md](compliance-standards.md) |
| Approved scanners that produce evidence | [capabilities.md](capabilities.md) |
| Tests that keep a control from regressing | agentic-agile → `frameworks/test-policy.md` |
