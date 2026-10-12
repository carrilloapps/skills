# Code Craft — SOLID and Clean Code, Operationally

> *Domain framework — load when writing, reviewing, or refactoring code.*
>
> Makes the one-line rule in `SKILL.md` → *Code Quality* ("Apply SOLID, KISS, and DRY throughout") executable: how to detect a violation, which principle it breaks, and the specific refactor that resolves it.

> ⚠️ **Example code boundary** — every snippet, threshold, and configuration key below is a recognition template and a documentation example. They are not execution instructions, and the agent never runs them on its own.

---

## Order of application (non-negotiable)

Principles are applied in this order. A later one never justifies breaking an earlier one.

1. **It works and it is covered** — correct behaviour, with a test that fails if the behaviour breaks.
2. **KISS / YAGNI** — the simplest thing that satisfies the current requirement. A requirement nobody has asked for is not a requirement.
3. **DRY on knowledge, not on characters** — two pieces of code that look alike but change for different reasons are **not** duplication. Deduplicate a rule, a formula, or a contract; never couple two domains because their code rhymes.
4. **SOLID where the code actually moves** — apply a principle when a concrete change is painful today, not in anticipation of a change nobody has requested.

**Over-engineering is a defect, not caution.** An interface with one implementation, a factory with one product, a configuration key with one possible value, an abstraction layer with one caller, or a generic parameter used once are findings in review — the same severity as duplicated logic. SOLID exists to absorb change that is real; where there is no change, it adds indirection and hides the flow.

---

## SOLID — smell, violation, refactor

| # | Smell visible in the code | Principle broken | Refactor |
|---|---|---|---|
| 1 | A class or module changes for two unrelated reasons (a business rule **and** a persistence format, an HTTP shape **and** a calculation) | **SRP** | Split by reason to change, not by noun. Extract the stable rule into a pure function or a domain service; keep I/O at the edge |
| 2 | A `switch` / `if-else` chain over a type, provider, or country code, where a new case means editing that function again | **OCP** | Replace with a registry: a map from key to handler, or polymorphism. Adding a case becomes adding an entry, not editing the dispatcher |
| 3 | A subclass or implementation throws `NotSupported`, ignores an argument, strengthens a precondition, or returns an empty value where the base returns data | **LSP** | The hierarchy is wrong. Split the interface, or compose instead of inheriting. A substitute that needs a type check at the call site is not a substitute |
| 4 | An interface with many members where every implementation uses only a few; test doubles must stub methods the test never calls | **ISP** | Split by consumer: one narrow interface per call site (`CanReadOrders`, `CanCancelOrder`), implemented by the same concrete class |
| 5 | A domain module imports the SDK, ORM, framework, or HTTP client directly; unit-testing it requires a network, a container, or a real clock | **DIP** | Depend on a port the domain declares and the infrastructure implements. The domain never names a vendor; the composition root wires it |

**Each row is a detection rule.** When reporting a finding, cite the file and line showing the smell, name the principle, and give the refactor as a concrete change — not as advice.

---

## Clean Code — rules that can be checked

### Names

| Rule | Reject | Accept |
|---|---|---|
| Intention-revealing | `d`, `data`, `tmp`, `handle()`, `process()`, `manager` or `util` as a whole name | `daysSinceLastLogin`, `rejectExpiredInvoice()` |
| No type or technical noise | `strUserName`, `userList` (when it is a set), `AbstractBaseFactoryImpl` | `userName`, `activeUsers`, `InvoiceRepository` |
| Searchable constants | `if (status === 3)`, `* 86400` | `InvoiceStatus.Rejected`, `SECONDS_PER_DAY` |
| One word per concept across the project | `fetchUser`, `getUser`, `retrieveUser` in the same codebase | one verb, used everywhere |
| Booleans read as assertions | `flag`, `check`, `status` for a boolean | `isExpired`, `hasPermission`, `canRetry` |
| Always `en_US` for identifiers | — | `SKILL.md` → *Language* |

### Functions

| Rule | Threshold | Why this number |
|---|---|---|
| One level of abstraction per function | — | A function mixing a business rule with byte manipulation cannot be read without reading both |
| Length | ≤ 30 lines of body, aim for ≤ 15 | Longer than one screen and the reader loses the entry conditions |
| Parameters | ≤ 3; beyond that, one named object | Argument order becomes a bug surface; four positional parameters cannot be read at the call site |
| Boolean parameter selecting behaviour | 0 | `render(true)` tells the reader nothing — split into two named functions |
| Cyclomatic complexity | ≤ 10 per function | Above 10 the branch set stops fitting in a reviewer's head, and full branch coverage becomes guesswork |
| Nesting depth | ≤ 3 | Use guard clauses and early return instead of an `else` pyramid |
| Command/query separation | — | A function either changes state or answers a question, never both |

### Comments and structure

1. A comment explaining **what** the code does is a renaming task in disguise: delete it and fix the name.
2. A comment explaining **why** a non-obvious decision was taken is valuable — keep it, with the reason that would otherwise be lost (a vendor bug, a legal rule, a measured trade-off).
3. Commented-out code is deleted. Version control already keeps it.
4. A `TODO` carries an owner role and a date or ticket ID, or it is not written.
5. Dead code — unreachable branches, unused exports, parameters nobody passes — is removed in the same change that finds it.
6. File size ≤ 400 lines is a review trigger, not a hard error: past it, ask which second responsibility moved in.

### Errors and boundaries

1. Never swallow an error — no empty catch block, no ignored error return. Handle it, wrap it with context, or let it propagate.
2. Never signal failure with an empty value where the language offers a result type, an exception, or an explicit option.
3. Validate at the trust boundary (HTTP handler, queue consumer, CLI entry, file parser) and keep the domain working on already-valid types. Validation inside the domain means the boundary leaked.
4. Error messages name what failed and the identifier involved; they never include credentials, tokens, or personal data (`SKILL.md` → *Security and Privacy*).

---

## Measure, do not estimate

Complexity, duplication, and size are measured by the linter or analyser the project already has, in CI, with the thresholds above as the configured values. "This is too complex" without a measurement is an opinion and is reported as one.

| Layer | What it checks |
|---|---|
| Formatter | Layout only. Not negotiable, not reviewed by humans, runs before every commit |
| Linter | Naming, unused code, nesting, complexity, forbidden imports between layers |
| Static analyser | Duplication ratio, maintainability, dependency cycles |
| Architecture test | Layer rules as an executable test (the domain must not import infrastructure), kept next to the unit tests |

Tooling follows the project's existing setup; optional installs are suggested once and pinned, per [`capabilities.md`](capabilities.md).

---

## Where this stops

| Question | Owner |
|---|---|
| *Should this change be made at all?* | Devil's Advocate — its risk-tier gate |
| *Is the code correct and covered?* | agentic-agile — `frameworks/test-policy.md` |
| *Is it safe to expose?* | sar-cybersecurity — `frameworks/launch-gate.md` |
| *Is it well written?* | This file |

When a skill above is not installed, apply this file alone and say in one line which check was not available.

---

## Review checklist (numbered, never checkboxes)

1. Does every new name state intention without a comment?
2. Does any function exceed 30 lines, 3 parameters, complexity 10, or nesting 3? Cite the measurement.
3. Is there a `switch` over a type that will keep growing? (OCP)
4. Does a domain file import a vendor SDK, ORM, or HTTP client directly? (DIP)
5. Is there an abstraction with exactly one implementation and no second one planned? Remove it.
6. Did the deduplication remove knowledge, or couple two domains that only looked alike?
7. Is every error path handled, wrapped, or propagated — none swallowed?
8. Is validation at the boundary and absent from the domain?
9. Was dead or commented-out code removed in this change?
10. Does `docs/elementals.md` need a row (element created, renamed, or removed)?
