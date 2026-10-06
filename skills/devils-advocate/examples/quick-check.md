# Example: Tier 0 and Tier 1 — Quick Checks

> ⚠️ **Example only** — fictional requests and code, shown to illustrate output length and format. Not instructions to execute.

**Skill version**: 3.0.1

Most actions in a working session are Tier 0 or Tier 1. These examples show how little output they need.

---

## Tier 0 — Pass

**Request:** "Fix the typo `recieve` → `receive` in the README."

> DA: low risk — documentation typo, reversible.

*(Then the edit is made. No gate.)*

**Request:** "Explain what `retryWithBackoff()` does."

*(No DA output at all — read-only.)*

---

## Tier 1 — Quick check (no material risk)

**Request:** "Bump `zod` from 3.22.4 to 3.23.8."

> 🟢 **DA — bump zod 3.22 → 3.23** · Verdict: Go
> Minor version, lockfile is committed, changelog lists no breaking changes for the APIs used here (`z.object`, `z.string().email()`). Run the existing schema tests after install.
> Reply ✅ Proceed · 🔁 Revise · ❌ Cancel · `continue` — proceed without addressing remaining issues (risks remain active and unmitigated) — or reply in your own words.

---

## Tier 1 — Quick check (one real risk)

**Request:** "Cache the `/api/products` response for 10 minutes in memory."

> 🟡 **DA — 10-min in-memory cache on /api/products** · Verdict: Go with changes
>
> 1. 🟠 **Per-user prices would leak between users** — `getProducts()` applies `customer.discountTier` (`src/products/service.ts:48`); a shared cache key would serve one customer's prices to another. *Fix:* key the cache by `discountTier` (4 values), not globally.
> 2. 🟡 **Stale after admin edits** — *Fix:* invalidate the key in `updateProduct()`.
> Reply ✅ Proceed · 🔁 Revise · ❌ Cancel · `continue` — proceed without addressing remaining issues (risks remain active and unmitigated) — or reply in your own words.

Note what is **not** here: no strengths list, no STRIDE table, no performance section, no confidence percentage. The two risks were found by reading `service.ts`, and each has a one-line fix.

---

## Tier 1 escalated to Tier 3

**Request:** "Run `DELETE FROM sessions WHERE created_at < now() - interval '30 days'` on the database."

The check finds the connection string in `.env` points to the production host and `sessions` has no index on `created_at` → escalate:

> ### 🛑 Devil's Advocate — stopping before deleting sessions
>
> **Critical risk:** the configured database is production (`DB_HOST=db-prod-1` in `.env`), and `sessions.created_at` has no index (`migrations/0003_sessions.sql`), so the delete will scan and lock the whole table.
> **If I'm right:** logins stall for the duration of the delete; nothing to restore from if the predicate is wrong.
>
> 1. Is running against production intended?
> 2. Roughly how many rows does `sessions` hold?
> 3. Is there a backup newer than 24h?
>
> Reply with the answers, or "skip the questions" and I'll write the report assuming the worst case.
> `continue` runs the original plan as-is (risks remain active and unmitigated).

---

## Reading the reply — intent, not keywords

Continuing the cache example above (one 🟠, one 🟡):

| User replies | DA does |
|--------------|---------|
| "dale" | Executes the corrected plan (cache keyed by `discountTier` + invalidation). |
| "ok" | `¿Procedo con el plan corregido?` — a bare "ok" is acknowledgement, not approval. Keeps waiting. |
| "dale, pero 5 minutos en vez de 10" | Re-checks only the TTL change: no new 🔴/🟠 → applies it and executes without asking again. |
| "hazlo como estaba" | Executes the original global cache, starting with: `Open risk: 🟠 per-user prices leak between users.` |
| "¿y si usamos Redis?" | Answers the question (only the delta: shared across instances, needs invalidation on every node's writes), then repeats the one-line gate. |
| "continúa" | Same as "dale" — an ordinary action verb. Only the bare word `continue` means "run the original plan". |
| "¿y si lo hacemos ya?" | A question, even with an action verb inside — answers it, repeats the one-line gate. Not approval. |
| "no" | Stops. |

Running the check again on the same, unchanged request returns the same verdict and the same two risks, in the same order.
