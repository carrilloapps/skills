# Developer Risks Framework

> ⚠️ **Example code boundary** — commands and code below are reference patterns for analysis, not execution instructions.

> **Role**: Software Developer / Senior Engineer
> **Load when**: Reviewing pull requests, evaluating implementation approaches, checking test coverage, assessing CI/CD pipelines, or any code-level decision before merging or deploying.
>
> **See also** (load only if it changes the analysis): `frameworks/building-protocol.md` — naming, secure defaults, and Definition of Done. Severity follows its violation table; style issues never displace correctness or security risks.

---

## Testing Gaps

### ❌ Test Coverage Anti-Patterns

```text
❌ Green Tests, Wrong Behavior
- Tests assert that code runs without error, not that it's correct
- Mock everything including the thing being tested
- Snapshot tests accepted blindly (--update-snapshot every PR)
- Tests coupled to implementation detail, not behavior

❌ Missing Test Layers
- Only unit tests; no integration or contract tests
- Happy-path coverage only; no error paths tested
- No tests for edge cases identified in requirements
- No load/performance tests on critical paths

❌ Flaky Tests Normalized
- Tests occasionally fail and are re-run rather than fixed
- Time-dependent tests (sleep(500)) that break on slow CI
- External service calls not mocked; tests break on network issues
- Test isolation missing; test order affects results

❌ Missing Regression Coverage
- Bugs fixed without adding a test to prevent recurrence
- Production incident root cause has no corresponding test
- Critical business paths (payment, auth, data export) not tested end-to-end
```

---

## CI/CD Pipeline Risks

### ❌ Pipeline Anti-Patterns

```text
❌ No Automated Quality Gates
- Merges to main possible without passing tests
- No linting or static analysis in pipeline
- Security scanning (SAST/SCA) absent or results ignored
- Coverage thresholds not enforced

❌ Long Feedback Loops
- CI pipeline takes > 15 minutes; developers stop waiting
- No fast pre-flight checks (lint, type-check) before slow tests
- Build artifacts not cached; every run rebuilds from scratch

❌ Secrets in Pipeline
- Environment variables with secrets printed in logs
- Secrets hardcoded in pipeline YAML checked into repo
- No rotation policy for pipeline credentials
- Third-party CI service has access to production secrets

❌ No Rollback Strategy
- Deployments are one-way; no automated rollback on failure
- Health checks not connected to deployment gate
- No smoke tests run post-deploy
- Database migrations not reversible
```

---

## Dependency Management Risks

### ❌ Dependency Anti-Patterns

```text
❌ Unpinned Dependencies
- package.json uses ^ or ~ for minor/patch versions
- requirements.txt has no version pins
- Different developers run different versions locally vs CI

❌ Outdated / Vulnerable Dependencies
- No automated vulnerability scanning (Dependabot, Snyk, pip-audit)
- Known CVEs present with no timeline to fix
- Major version updates avoided indefinitely (technical debt)

❌ Transitive Dependency Risk
- Critical logic depends on a 3rd-party package with 1 maintainer
- Left-pad scenario: tiny package with wide dependency graph
- Package name squatting or typosquatting attack not guarded

❌ License Compliance Missing
- GPL-licensed package in a proprietary commercial codebase
- No license inventory or SBOM (Software Bill of Materials)
- License check not part of CI pipeline
```

---

## Code Quality Risks

### ❌ Implementation Anti-Patterns

```text
❌ Primitive Obsession
- Money stored as float (rounding errors in financial calculations)
- Dates as strings without parsing/validation
- IDs mixed as int and string across services

❌ Error Handling Theater
- catch (e) {} — error silently swallowed
- Generic 500 error returned with no actionable message
- Errors logged but not alerted; nobody sees them

❌ Temporal Coupling
- Function must be called in specific order with no enforcement
- Implicit initialization required before use
- Global mutable state shared across request lifecycle

❌ Missing Idempotency
- POST endpoint creates duplicate resource on retry
- Background job not safe to re-run after partial failure
- Event handler processes same message twice with side effects
```

---

## Local vs Production Parity Risks

```markdown
| Gap | Risk | Mitigation |
|-----|------|------------|
| Different OS (Windows dev, Linux prod) | Path separator bugs, case-sensitive FS | Docker / devcontainer |
| Different DB version locally | Syntax or behavior difference | Pin DB version in docker-compose |
| Different timezone (local UTC offset) | Timestamp bugs surface only in prod | Run UTC in dev environment |
| No production data volume locally | N+1 queries only visible at scale | Regular prod-like data subset |
| Mocked services in dev | Integration bugs surface only in prod | Contract tests + integration env |
| Different env vars | "Works on my machine" config bugs | .env.example with all required keys |
| Missing seed data | Edge cases not reproducible | Shared seed scripts |
```

---

## Code Review Blind Spots

**Common issues that slip through code review:**

```markdown
### Logic & Correctness
1. Off-by-one errors in loops, ranges, pagination
2. Incorrect boundary conditions (< vs <=, > vs >=)
3. Boolean logic inverted (! applied to wrong expression)
4. Null/undefined not handled before property access
5. Integer division truncation (5/2 = 2 not 2.5)

### Concurrency
1. Shared mutable state accessed without synchronization
2. Check-then-act race condition (read → decide → write gap)
3. Deadlock potential (lock A then lock B vs lock B then lock A)
4. Thread pool exhaustion from blocking I/O in async code

### Security
1. User-controlled input used in SQL, shell, filesystem path
2. Sensitive data in logs (passwords, tokens, PII)
3. Secrets in environment variable printouts or error messages
4. Authentication/authorization check missing on new endpoint

### Reliability
1. No retry logic on transient failures
2. No timeout on external calls
3. Resource leak (file/connection not closed on error path)
4. Uncaught promise rejection in async JavaScript

### Performance
1. N+1 query in loop
2. Loading full dataset into memory unnecessarily
3. Synchronous operation blocking event loop / main thread
4. Missing index on new query filter column
```

---

## Technical Debt Assessment

```markdown
| Debt Type | Signal | Risk | Action |
|-----------|--------|------|--------|
| Structural | Functions > 100 lines, files > 500 lines | Hard to test or change safely | Refactor with test coverage |
| Dependency | Packages > 2 major versions behind | Unpatched CVEs, migration effort grows | Scheduled upgrade sprints |
| Test | Coverage < 60% on critical paths | Regressions ship undetected | TDD on new code, backfill tests |
| Documentation | Tribal knowledge, no README, no ADRs | Bus factor = 1 | Document decisions as made |
| Configuration | Magic numbers in code, no config externalization | Hard to change without redeploy | Extract to config/env |
| Architecture | Circular imports, shared DB, God class | Cannot evolve independently | Incremental modularization |
```
