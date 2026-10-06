# Example: Tier 3 → Tier 2 — JWT Authentication Plan

> ⚠️ **EDUCATIONAL EXAMPLE — NOT FOR IMPLEMENTATION.** Fictional, deliberately insecure design used only to demonstrate detection of credential exposure. All secrets, endpoints, and systems are fictional.

**Skill version**: 3.0.0

**Plan [fictional]:** Add JWT auth to the internal REST API: HS256 with a shared secret stored in the codebase, 30-day expiry, no refresh token. The API serves web and mobile clients.

While reading the repo, the analysis finds the secret already committed: `src/auth/jwt.ts:4` → `const JWT_SECRET = "acme-dev-secret"`, present in git history for two weeks.

---

## Step 1 — Critical stop

> ### 🛑 Devil's Advocate — stopping before shipping JWT auth
>
> **Critical risk:** the signing secret is committed (`src/auth/jwt.ts:4`) and has been in history for 2 weeks. Anyone with repo access can mint a valid token for any user.
> **If I'm right:** full account takeover across web and mobile, undetectable in logs.
>
> 1. Is this same secret value used in any deployed environment today?
> 2. Do these endpoints return PII or payment data?
> 3. Is there any record of which tokens were issued (audit log)?
>
> Reply with the answers, or "skip the questions" and I'll write the report assuming the worst case.
> `continue` runs the original plan as-is (risks remain active and unmitigated).

*User answers [fictional]:* "Yes, staging and production use it. Endpoints return profiles, orders, payment history. No audit log."

---

## Step 2 — Report

### 🔴 Devil's Advocate — JWT auth for internal API

**Verdict:** Stop — fix first — **Overall risk:** 🔴

The secret must be treated as compromised now, independent of this plan. Rotating it is urgent; removing it from history does not un-leak it.

**Risks**

1. 🔴 **Token forgery with the leaked secret** — any clone of the repo can sign tokens accepted in production.
   *Evidence:* `src/auth/jwt.ts:4`, confirmed used in prod. *Fix:* rotate today; load from the secret manager (`process.env.JWT_SIGNING_KEY`), fail startup if missing.
2. 🟠 **Shared-secret HS256 across services** — every verifier can also sign. *Fix:* RS256/EdDSA — only the auth service holds the private key; others verify with the public key (JWKS).
3. 🟠 **30-day tokens with no revocation** — a stolen token is valid for a month and cannot be killed. *Fix:* 15-min access token + rotating refresh token stored server-side; revoke on logout/password change.
4. 🟡 **No audit trail of issuance** — the 2-week exposure cannot be investigated. *Fix:* log `sub`, `jti`, `iat`, client id on issuance.

**Unverified assumptions**

- Mobile clients can handle refresh flows — check: current app version's HTTP client supports token refresh/retry.

**What I'll do if you approve**

1. Move the key to the secret manager and remove the literal from `jwt.ts` (history purge is a separate, gated git operation)
2. Switch signing to RS256 with a JWKS endpoint
3. 15-min access tokens + refresh token rotation and revocation
4. Issuance audit log
5. You rotate the production secret (I cannot and should not do this) — it invalidates all sessions; plan a forced re-login

```text
Reply with:
  ✅ Proceed   — run the corrected plan ("What I'll do if you approve")
  🔁 Revise    — describe the change and I will re-analyse
  ❌ Cancel    — stop, do not implement
  `continue`   — proceed without addressing remaining issues (risks remain active and unmitigated)
Or reply in your own words, in any language.
```
