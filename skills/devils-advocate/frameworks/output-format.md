# Output Format — Good vs. Bad

Reference for writing Devil's Advocate output. The canonical template lives in `SKILL.md` §3; this file shows what separates a useful report from a skimmed one.

> ⚠️ **Example only** — the scenarios below are fictional and illustrate format, not real systems.

---

## Length budget

| Tier | Target length | Hard ceiling |
|------|---------------|--------------|
| 0 — Pass | 0–1 line | 1 line |
| 1 — Quick check | 3–8 lines | 12 lines |
| 2 — Full critique | 15–40 lines | ~60 lines |
| 3 — Critical stop | 6–12 lines | 15 lines (the report comes after the answers) |

If a report goes over the ceiling, the cause is almost always one of: too many risks (cut to 5), generic risks (delete them), or sections with nothing to say (omit them).

---

## The same plan, two reports

**Plan:** "Add a `DELETE /api/users/:id` endpoint so admins can remove accounts."

### ❌ Bad — looks complete, changes nothing

> ## 📊 Executive Summary
>
> **Overall Risk Rating**: 🟠 High · **Analysis Confidence**: 🟢 High (85%)
>
> ## ✅ Strengths
>
> 1. **RESTful design** — follows REST conventions
>
> ## ❌ Weaknesses
>
> 1. **Security** — Risk: endpoint could be misused. Mitigation: ensure proper authorization.
> 2. **Testing** — Risk: bugs. Mitigation: add comprehensive tests.
> 3. **Performance** — Risk: could be slow at scale. Mitigation: monitor performance.
>
> ## 🔒 STRIDE Summary
>
> - Spoofing: ✅ Mitigated · Tampering: ✅ Mitigated · Repudiation: Risk …
>
> ## ⚡ Performance Concerns
>
> - Bottleneck: N/A
> *(…six more sections…)*

Why it fails: no evidence, no specific fix, invented confidence, filler sections, and nothing the user can act on. Every line would fit any endpoint in any codebase.

### ✅ Good — short, proven, actionable

> ### 🟠 Devil's Advocate — admin user deletion endpoint
>
> **Verdict:** Go with changes — **Overall risk:** 🟠
>
> The endpoint as planned hard-deletes rows that 4 other tables reference, and the only guard checks *logged in*, not *admin*.
>
> **Risks**
>
> 1. 🔴 **Any logged-in user can delete any account** — the route would sit behind `requireAuth` only (`src/routes/users.ts:12`); there is no role check in that router.
>    *Evidence:* `router.use(requireAuth)` with no `requireRole`. *Fix:* add `requireRole('admin')` on the route and a test that a non-admin gets 403.
> 2. 🟠 **Orphaned data / FK failures** — `orders`, `invoices`, `sessions`, `audit_log` reference `users.id` (`migrations/0007_orders.sql:9`, …) with no `ON DELETE` rule; the delete will either fail or, if cascades are added naïvely, erase invoices you are legally required to keep.
>    *Evidence:* schema above. *Fix:* soft delete (`deleted_at`) + anonymize PII fields; keep invoices.
> 3. 🟡 **No audit trail** — admin actions are not logged today. *Fix:* write an `audit_log` row with actor, target, timestamp.
>
> **Unverified assumptions**
>
> - Invoices must be retained — check: your accounting/legal retention policy.
>
> **What I'll do if you approve**
>
> 1. `DELETE /api/users/:id` → soft delete + PII anonymization, admin-only
> 2. 403 test for non-admins, 404 for unknown id
> 3. Audit log entry per deletion
>
> Also considered, not material: rate limiting (admin-only route), bulk delete (not requested).
>
> Reply with: ✅ Proceed · 🔁 Revise · ❌ Cancel · `continue` — proceed without addressing remaining issues (risks remain active and unmitigated) — or reply in your own words.

Why it works: three risks, each pinned to a file, each with a concrete fix, and an adjusted plan the user can approve in one word.

---

## Checklist before sending

1. Depth matches the tier; under the length ceiling.
2. First two lines tell the user the verdict and the one thing that matters most.
3. Overall risk = highest severity found; the verdict follows the verdict table in `SKILL.md` §2.
4. Every risk has *Evidence* and a specific *Fix*.
5. No generic risk survived ("ensure", "consider", "monitor" without a concrete target).
6. No empty sections, no template tables copied from frameworks, no invented percentages.
7. "What I'll do if you approve" lists the corrected plan as concrete steps.
8. Ends with the Gate; nothing was executed before the reply.
9. On a re-run of an unchanged plan, the verdict and risks are identical to the previous run.
