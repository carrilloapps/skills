# 🛑 Critical Stop (Handbrake) — Question Banks

Load for **Tier 3** (see `SKILL.md` §4): a 🔴 Critical risk exists and its true severity depends on facts only the user has.

There is exactly **one** stop: ask 2–4 questions, wait, then deliver the Tier 2 report and Gate. No flash alerts, no second round of questions.

---

## When to stop (any one is enough)

1. The consequence is **irreversible** (data deleted, history rewritten, money moved, message sent to customers).
2. It could cause **production failure or data loss** within one release.
3. It touches **PII, financial, or regulated data** without a verified compliance path.
4. **3+ 🟠 High** risks in the same area compound each other.
5. The plan rests on an **unverified assumption that cannot safely be assumed** (backups exist, nobody else uses this table, the key is not in production).

Do **not** stop when you could resolve the question yourself by reading code, config, schemas, or docs — read them instead.

---

## Choosing questions

Pick questions whose answer **changes the severity or the fix**. Prefer yes/no or a number. Skip anything that is nice to know.

| Good | Bad |
|------|-----|
| "Is there a backup of `orders` newer than 24h, and has it ever been restored?" | "What is your backup strategy?" |
| "Does any service other than `billing-api` read `users.email`?" | "Tell me about your architecture." |

### Question banks by domain

**Architecture** (→ Software Architect)

- If this service is down, which other services fail with it?
- If step N fails, what undoes steps 1…N-1?
- Who consumes this API/contract, and how do they learn about breaking changes?

**Data / PII** (→ Data Engineer)

- Is the job safe to re-run after a partial failure (idempotent)?
- Which fields are PII, and who can read them today?
- How is a user's data erased from this store on a GDPR/CCPA request?

**Security** (→ Security / AppSec)

- Which inputs on this path are user-controlled?
- Where exactly are authentication and authorization enforced?
- Is this secret/credential used in production, and has it been rotated since exposure?

**Code / CI** (→ Tech Lead)

- Which tests cover this path today?
- Can two requests/workers run this concurrently? What protects shared state?
- What is the rollback, and how long does it take?

**Database / Migration** (→ DBA / Platform)

- Has this run against a production-sized copy? How long did it take?
- Is there a tested restore, and how long does it take?
- Does the change lock tables that serve live traffic?

**Version control** (→ Tech Lead)

- Who else has this branch checked out or based work on it?
- Is the leaked secret already rotated? (History rewrite does not un-leak it.)
- Are branch protections or required reviews in place on the target branch?

**Product / Legal** (→ PM / Legal)

- Which regulation applies (GDPR, FTC Negative Option, PCI DSS, local law)?
- What metric decides success, and what is the kill criterion?
- Has Legal/Compliance seen this flow?

**UX / Accessibility** (→ UX Lead)

- Can the flow be completed with keyboard and screen reader only?
- What does the user see when this fails?

**Strategy / Vendor** (→ CTO)

- Is this reversible within a quarter? What does exit cost?
- What happens if the vendor raises prices 3× or is acquired?

**Finance / Billing** (→ Finance)

- How are rounding, currency, and refunds handled?
- Is each charge idempotent (no double billing on retry)?

**Performance** (→ Tech Lead)

- What are current p95 latency and peak QPS on this path?
- What is the connection-pool / memory limit that breaks first?

**AI context files** (→ AI Tooling Lead)

- Which agents/tools load this file, and in what order?
- Which existing instruction does this one override or contradict?

---

## Role escalation

If the user is not the owner of the risky area, say who should answer: *"This needs the DBA (or whoever owns the `orders` restore procedure) before it runs."* Name the role once; do not produce a separate escalation section.

---

## After the answers

1. Re-score each risk with the new facts (they may go **down** as well as up — say which).
2. For an irreversible decision, run a 2–3 scenario pre-mortem internally (`premortem.md`) and fold any new risk into the report.
3. Deliver the Tier 2 report with the corrected "What I'll do if you approve" plan, then the Gate.

## If the user skips the questions

"Skip the questions", "asume lo peor", "sin preguntas" → write the Tier 2 report assuming the **worst case** for every unanswered question, mark those risks as `(worst case — unconfirmed)`, then the Gate. Nothing runs yet.

## If the user replies `continue`

Same meaning as at the Gate: run the **original** plan, starting the response by naming the open 🔴/🟠 risks (risks remain active and unmitigated). It does not skip to the report.
