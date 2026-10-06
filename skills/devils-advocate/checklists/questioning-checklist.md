# Questioning Checklist

Load this file to run a rapid structured interrogation of any solution across 15 dimensions. Use before or during the analysis to ensure no dimension is skipped.

---

## For Every Solution, Ask

### Correctness

1. What edge cases are not handled?
2. What assumptions might be wrong?
3. What input could break this?
4. What if the dependency fails?
5. What if there is concurrent access?

### Security

1. How would I exploit this as an attacker?
2. What sensitive data is exposed or logged?
3. Are all inputs validated and sanitized?
4. Is authentication and authorization enforced at every layer?
5. Are third-party dependencies audited for CVEs?

### Performance

1. What is the worst-case time/space complexity?
2. Where are the bottlenecks under realistic load?
3. What happens at 10× current load?
4. Are there N+1 queries or unbounded result sets?
5. What is the memory footprint per request?

### Reliability

1. What are the failure modes of each component?
2. Is there a single point of failure?
3. Can we roll back safely and completely?
4. What happens on partial failure (some steps succeed, some fail)?
5. Are all errors handled and surfaced correctly?

### Maintainability

1. How much complexity does this add to the system?
2. What technical debt is being created?
3. How hard is this to debug in production?
4. Is it documented well enough for someone new to own it?
5. Can this be tested in isolation?

### Operability

1. How is this deployed safely (zero-downtime, canary, feature flag)?
2. What monitoring and alerting is needed?
3. How do we know it is working correctly in production?
4. What is the incident response runbook?
5. Can it be debugged in production without downtime?

### Cost

1. What is the estimated infrastructure cost at current and 10× load?
2. Are there licensing or per-seat costs not yet budgeted?
3. What is the Total Cost of Ownership (TCO) including maintenance?
4. Does this create ongoing cost that grows with scale (e.g., per-API-call pricing)?
5. Is there a cost ceiling or alert if spend exceeds budget?

### Product

1. Is this solving a validated user problem, or an assumed one?
2. What is the success metric, and can it be gamed without producing real value?
3. What is the rollback or kill plan if the feature does not perform?
4. Are there regulatory or compliance requirements that apply (GDPR, WCAG, HIPAA)?
5. What happens to users who are mid-flow if this is rolled back?

### UX / Design

1. Are all states designed: empty, loading, error, offline, partial failure?
2. Does any part of the flow contain dark patterns or manipulative design?
3. Is the flow accessible to users with disabilities (keyboard, screen reader, contrast)?
4. Does the design match the mental model of the target user population?
5. Has this flow been tested with real users, or only internally reviewed?

### Strategy

1. Is this a Type 1 (irreversible) or Type 2 (reversible) decision?
2. If Type 1, has it been analyzed at Tier 2 minimum?
3. Does this decision create vendor lock-in, and is there an exit plan?
4. Is the team structured to own and operate this long-term (Conway's Law)?
5. What is the key-person risk, and is knowledge documented?

### Architecture

1. Are service boundaries clearly defined with no shared databases?
2. Are all synchronous calls protected with timeouts and circuit breakers?
3. Are retries bounded with exponential backoff and idempotent?
4. Is there a schema or API contract version strategy?
5. Can each component fail independently without taking down the system?
6. Is there end-to-end distributed tracing with correlation IDs?

### Data

1. Is the pipeline idempotent (safe to re-run without side effects)?
2. Are data quality checks in place (nulls, duplicates, range, referential integrity)?
3. Is PII identified, masked, and access-controlled appropriately?
4. Is there a schema evolution strategy with backward compatibility?
5. Are success metrics and KPIs defined consistently across teams?
6. Is there a data retention and erasure policy that fulfills compliance obligations?

### Developer

1. Are the critical paths covered by automated tests (unit + integration)?
2. Are all dependencies pinned and scanned for vulnerabilities?
3. Is the CI pipeline enforcing quality gates (lint, test, coverage, SAST)?
4. Are all catch blocks handling errors explicitly (not swallowing them)?
5. Is this safe to re-deploy multiple times (no duplicate side effects)?
6. Does the local environment match production closely enough to prevent surprises?

### Building Protocol

1. Are ALL identifiers (variables, functions, constants, files, DB columns, endpoints) written in `en_US`?
2. Do naming conventions match the target language (camelCase, snake_case, PascalCase, SCREAMING_SNAKE_CASE)?
3. Are there any magic numbers or magic strings that should be named constants?
4. Are there any empty catch blocks, TODO stubs, or commented-out code in deliverable output?
5. Are secrets, tokens, and credentials loaded from environment variables (never hardcoded)?
6. Is all external input validated at the boundary before use?
7. Do functions respect single responsibility (≤ 20 lines, ≤ 3 parameters)?
8. Does each function have at least a happy-path test and one error/edge case test?
9. Do commit messages follow Conventional Commits format in `en_US`?

### AI Optimization

1. Are all always-loaded AI context files within safe token limits (target < 8K tokens; never > 16K)?
2. Is there a single canonical source for each major instruction topic — no ambiguous duplicate rules?
3. Are all cross-references (file links, section anchors, `See also` notes) valid and up to date?
4. Are instructions specific enough to prevent hallucination — with concrete ✅ / ❌ examples, not just rules?
5. Is there a progressive loading strategy — can irrelevant context be avoided for out-of-scope tasks?
6. Are there any instruction conflicts across files that would cause non-deterministic AI behavior?
7. Does each AI context file have a clear, explicit purpose and activation trigger?
8. Are key domain terms, patterns, and constraints defined with at least one ✅ correct and one ❌ wrong example?

---

> 💡 **See also**: [`checklists/risk-checklist.md`](risk-checklist.md) — categorical risk scoring across Technical, Security, Operational, Cost, Organizational, Reversibility, Building Protocol, and AI Optimization. Use the risk checklist for fast pass/fail scoring; use this checklist for deep dimensional interrogation.
