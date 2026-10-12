# Test Policy — 100% Coverage That Means Something, and the Tooling That Enforces It

> *Domain framework — load in phase 4 (verification), when writing or reviewing tests, and when a team sets or changes its coverage gate.*
>
> `sdd-phases.md` §4 asks for a test matrix and for coverage of the changed code. This file sets the policy those rows are measured against: what 100% means, what may be excluded from it and how, and which signal shows the tests actually verify behaviour.

> ⚠️ **Example code boundary** — configuration keys, thresholds, and file names below are documentation examples and recognition templates. They are not execution instructions; the agent proposes them and the team runs its own commands.

---

## 1. The gate

**Unit coverage is 100% — lines, branches, functions, and statements — over the declared set.**

The declared set is all production code **minus** the entries in the exclusion register. There is no 99%, no "90% is fine for now", and no per-module exception that is not written down. A number below 100 fails the build.

Why the exclusion register exists: a bare 100% target over everything is met by writing tests for generated clients, framework glue, and data holders. That inflates the number and leaves the real branches untested. Declaring what is **not** measured, with a reason, keeps the number honest and keeps the attention on code that can be wrong.

**Coverage is a floor, not evidence of correctness.** Full coverage proves every line ran during the suite, nothing more. A test that executes a function and asserts nothing counts the same as a real one, which is why §4 exists.

---

## 2. The exclusion register

One versioned file, `docs/coverage-exclusions.md`, is the only place an exclusion may be declared. The coverage tool's ignore configuration must match it exactly; an ignore comment or config entry with no row in the register is a finding.

| Column | Required content |
|---|---|
| Path or pattern | The narrowest form that works — a file, not a folder, whenever possible |
| Reason | Which category below, in one line, specific to this entry |
| Added | `YYYY-MM-DD` |
| Owner | Role, not a person |
| Review | Date when the entry is re-examined, or `permanent` with the reason it cannot change |

**Categories that may be excluded**

1. Generated code — API clients, ORM artifacts, protobuf or GraphQL types, migrations produced by a tool.
2. Framework entry points with no logic — bootstrap files, module declarations, dependency wiring.
3. Pure type declarations and interfaces with no runtime behaviour.
4. Third-party or vendored code kept in the repository.
5. Platform code that cannot run in the unit environment (native bindings, OS-specific branches), **only** when it is covered by an integration or e2e test, and that test is cited in the Reason.
6. Defensive branches that are unreachable by construction (an exhaustive switch default), **only** where the language cannot express the exhaustiveness.

**Never excludable**: business rules, authorization and ownership checks, input validation, money or quantity arithmetic, error and retry paths, state machines, parsers and serializers, anything in the pre-launch gate of `sar-cybersecurity`.

Excluding a file to make the build pass is a change of scope, not a fix: it goes through the same approval as any other decision, and a decision record when it covers more than one file.

---

## 3. What a unit test must prove

A test that cannot fail is not a test. Each test:

1. **Asserts an observable outcome** — a returned value, a raised error, a state change, or a recorded interaction that the contract actually promises. Executing a function and asserting nothing is a coverage artifact, and is removed.
2. **Fails for one reason.** Prefer several focused tests over one that walks through a workflow.
3. **Names behaviour, not implementation** — `rejects an invoice whose due date has passed`, not `test method 3`.
4. **Covers the boundaries**: empty, one, many, maximum, malformed, duplicated, out of order, and the failure of every dependency it talks to.
5. **Is deterministic** — time, randomness, locale, time zone, and identifiers are injected or frozen. A test that depends on the current date is a scheduled failure.
6. **Is independent** — runs alone, in any order, in parallel, with no shared mutable state and no dependency on a previous test.
7. **Mocks only what it owns or what crosses a boundary.** Mocking the unit under test proves nothing; mocking a value object makes the test lie.
8. **Verifies errors by type and message contract**, not by asserting that *something* threw.

**Assertion-free test detection**: any test body with no assertion, no expected exception, and no verified interaction is reported in review, regardless of the coverage number.

---

## 4. Mutation score — the signal coverage cannot give

Coverage says the line ran. Mutation testing changes the code (flips a comparison, removes a call, alters a boundary) and checks whether the suite notices. A surviving mutant is a line that is covered and unverified.

| Scope | Minimum mutation score | When it runs |
|---|---|---|
| Changed files in the pull request | 80% | Every pull request that touches production code |
| Core domain — money, authorization, state machines, parsers | 90% | Every pull request touching them, and nightly |
| Whole project | Record the trend, no hard gate | Nightly or weekly |

Rules:

1. The number is set once by the team and recorded in `AGENTS.md`; raising it is a decision, lowering it is a decision record.
2. A surviving mutant is either killed with a new assertion or declared equivalent in the pull request, with the reason — never ignored silently.
3. Mutation runs on changed files in the pull request, so the cost stays proportional to the change. A full run belongs to a scheduled job.
4. When the stack has no mutation tool (§10 below), say so once and compensate with property-based tests on the same core paths, plus review attention on assertion quality.

---

## 5. Beyond unit tests

| Level | Covers | Gate |
|---|---|---|
| **Unit** | One behaviour, no I/O, milliseconds | 100% of the declared set |
| **Integration** | Real adapters against a real engine in a container — repositories, migrations, queues, external clients | Every adapter has at least one; every migration applies and rolls back |
| **Contract** | The promise between two services or between client and API | Every published endpoint or event has a contract test, versioned with the schema |
| **End-to-end** | A user-visible path through the running system | Every `@P1` scenario in the spec; `@P2` on the critical business flows (§10 below) |
| **Non-functional** | Load, accessibility, resilience | Only where a requirement states a number to meet |

**End-to-end stays small on purpose.** It is the slowest and most fragile level: cover the paths whose failure would be visible to a user or to money, and push everything else down to units. An e2e suite that mirrors the unit suite is a maintenance cost with no added signal.

Security controls get tests at the level where they live: an authorization rule is a unit test on the guard **and** an e2e test proving a foreign record is refused. A control from the pre-launch gate without a regression test is a finding in review, not a passing control.

---

## 6. Brownfield — reaching the gate without stopping delivery

A project that starts at 42% does not get to 100% in one sprint, and a long-lived branch doing it is worse than the problem.

1. **Ratchet on changed code.** From day one, every pull request meets 100% on the lines it adds or modifies. Coverage can only go up.
2. **Record the baseline.** The starting number per module goes in `plans/` with its date; the build fails if the global number drops below the recorded baseline.
3. **Pay down by risk, not by file size.** Order the debt by what breaks worst: money, authorization, data integrity, then the rest.
4. **Untestable legacy is a refactor task**, listed in `tasks.md` with the seam that will make it testable — never an exclusion-register entry.
5. **Declare the state honestly.** Until the ratchet reaches 100% globally, the Definition of Done says "100% on changed code, global baseline `<n>%`", and `verification.md` §4.4 shows both numbers.

---

## 7. Flaky tests

A test that fails intermittently destroys the value of the whole suite, because the team learns to re-run instead of to read.

1. A flake is a defect with the same priority as the bug it hides. Fix the cause — shared state, real time, real network, order dependence, unawaited work.
2. Quarantine is allowed for at most one sprint, with a ticket and an owner role. A quarantined test does not count toward the gate.
3. Retries at the runner level are never the fix: they hide the cause and keep the test useless.
4. Three flakes on the same path mean the design is untestable there; the fix is the seam, not the test.

---

## 8. In the ceremonies

| Artifact | What this policy adds |
|---|---|
| `plans/agile/definition-of-done.md` | The coverage, exclusion, mutation, and e2e lines |
| `specs/<initiative>/verification.md` §4.1 | A row per scenario with its test type and evidence |
| `specs/<initiative>/verification.md` §4.4 | Coverage of changed code, global number, mutation score, surviving mutants and their decision |
| Review | A lowered threshold, a new exclusion, or a quarantined test is raised explicitly — never merged quietly |
| Retro | Flake count and escaped defects by level: where the suite should have caught it and did not |

---

## 9. Choosing the tooling

1. **Use what the project already has.** A second test runner for the same language is a cost with no signal. Replace a runner only when it cannot express the gate.
2. **Pin every tool version** in the lockfile or manifest; a test suite that changes behaviour on its own is not evidence.
3. **One command per level**, named the same in every project: unit, integration, e2e. `AGENTS.md` lists them; CI calls exactly those.
4. **The gate lives in configuration, not in CI**, so a local run and the pipeline give the same verdict.
5. **No tool for a level means the level is declared missing**, not assumed covered.

---

## 10. Stack matrix

| Stack | Unit runner | Coverage + 100% gate | Mutation | End-to-end |
|---|---|---|---|---|
| **TypeScript / JavaScript** (Node, React, Next.js, Vue, Svelte) | Vitest, or Jest where the project already uses it | `@vitest/coverage-v8` or Istanbul — `coverage.thresholds` all at `100`, `all: true` so untested files count | Stryker Mutator | Playwright (browser and API) |
| **Node backend** (Express, Nest, Fastify, Hono) | Vitest / Jest | Same, plus `coverage.exclude` mirroring the exclusion register | Stryker Mutator | Playwright request fixtures, or Supertest for in-process HTTP |
| **Python** (FastAPI, Django, Flask) | pytest | `coverage.py` — `fail_under = 100` and `branch = true` in `[tool.coverage]` | mutmut, or Cosmic Ray | Playwright for Python; Schemathesis for contract fuzzing from OpenAPI |
| **Go** | `go test` with testify where helpful | `go test -covermode=atomic -coverprofile` plus a threshold check in CI; `//go:build` tags keep platform code out of the set | go-mutesting, or Gremlins | Playwright via a driver, or `httptest` plus a container-based suite |
| **Java / Kotlin** (Spring Boot, Micronaut, Quarkus) | JUnit 5 with AssertJ | JaCoCo — `LINE`, `BRANCH`, `METHOD` limits at `1.0` in `jacocoTestCoverageVerification` | PIT (`pitest`) | Playwright for Java, or Selenium where it is already in place; REST Assured for APIs |
| **C# / .NET** | xUnit (or NUnit) | Coverlet — `/p:Threshold=100 /p:ThresholdType=line,branch,method` | Stryker.NET | Playwright for .NET |
| **Dart / Flutter** | `flutter test` | `flutter test --coverage` with an `lcov` threshold check; generated `*.g.dart` goes in the exclusion register | mutation-test (Dart) where available, otherwise property tests on the core | `integration_test` for in-app flows; Patrol for native dialogs and permissions; Maestro for black-box flows |
| **Swift / iOS** | XCTest, or Swift Testing | Xcode code coverage with a threshold check in CI (`xccov`) | Muter | XCUITest; Maestro for cross-platform flows |
| **Kotlin / Android** | JUnit 5 with Robolectric for framework classes | JaCoCo with the same limits; generated bindings excluded | PIT | Espresso, or Maestro |
| **PHP** (Laravel, Symfony) | PHPUnit, or Pest | PHPUnit coverage with `--coverage-text` and a CI threshold; Infection reports coverage too | Infection | Playwright, or Laravel Dusk where it is already used |
| **Ruby** (Rails) | RSpec, or Minitest | SimpleCov — `minimum_coverage line: 100, branch: 100` | mutant | Playwright, or Capybara with a real driver |
| **Rust** | built-in `#[test]` | `cargo llvm-cov` with a threshold check (`--fail-under-lines 100`) | cargo-mutants | Playwright via a driver for web surfaces; integration tests in `tests/` for CLIs |

**No row for this stack**: apply the same four columns — a runner, a coverage tool whose threshold can fail a build, a mutation tool or property-based testing as a substitute, and one black-box tool that drives the real system. Record the choice in `AGENTS.md` so the next contributor does not re-decide it.

---

## 11. Making the gate fail (shapes, not recipes)

The point of each example is the key that turns a report into a gate.

```jsonc
// Vitest — coverage.thresholds, with `all` so an untested file cannot hide
{ "test": { "coverage": {
  "provider": "v8",
  "all": true,
  "thresholds": { "lines": 100, "branches": 100, "functions": 100, "statements": 100 },
  "exclude": ["src/generated/**"]   // every entry also appears in docs/coverage-exclusions.md
}}}
```

```toml
# coverage.py — branch coverage on, build fails under 100
[tool.coverage.run]
branch = true
omit = ["src/generated/*"]          # mirrors the exclusion register
[tool.coverage.report]
fail_under = 100
show_missing = true
```

```xml
<!-- JaCoCo — a ratio of 1.0 is the gate; COVEREDRATIO below it fails the build -->
<rule><element>BUNDLE</element>
  <limit><counter>LINE</counter><value>COVEREDRATIO</value><minimum>1.0</minimum></limit>
  <limit><counter>BRANCH</counter><value>COVEREDRATIO</value><minimum>1.0</minimum></limit>
</rule>
```

Three properties make these equivalent across stacks: branch coverage is on, untested files are counted, and the exclusion list is the same list that lives in `docs/coverage-exclusions.md`.

---

## 12. End-to-end scope

| Rule | Why |
|---|---|
| One suite drives the real system through its real interface — no internal function calls | Anything else is an integration test wearing an e2e name |
| Every `@P1` scenario of the spec has one e2e test, tagged with its `@FR-###` | Keeps `trace` able to close the requirement-to-evidence loop ([`traceability.md`](traceability.md)) |
| Data is created by the test and removed after it; no shared fixture database | Order independence and parallel runs |
| Selectors are roles or test identifiers, never CSS paths or copy text | Copy changes must not break the suite |
| Authentication is set up once per role and reused as stored state | Logging in through the UI in every test is the main source of slowness and flakes |
| Network to third parties is stubbed at the boundary, except in one scheduled smoke run | A vendor outage must not fail the pull request |
| The suite runs against a build, not a development server | What is tested is what ships |
| Budget: the pull-request e2e suite stays under ten minutes | Beyond that it gets skipped, and a skipped suite protects nothing |

**Mobile**: in-app flows go to the framework's own harness (`integration_test`, XCUITest, Espresso); flows crossing native dialogs, permissions, deep links, or payment sheets go to a black-box driver (Patrol, Maestro). A device matrix is declared in `AGENTS.md`: one current and one oldest supported version per platform, minimum.

**APIs without a UI**: the e2e level is the public contract exercised over the network against a deployed build, including authentication, error codes, and pagination — plus a schema-driven fuzzer where an OpenAPI document exists.

---

## Cross-reference

| Need | File |
|---|---|
| Scenario format and tags | [`gherkin.md`](gherkin.md) |
| Requirement-to-test traceability | [`traceability.md`](traceability.md) |
| Phase 4 structure | [`sdd-phases.md`](sdd-phases.md) |
| Code-level quality that makes code testable | ai-rules → `frameworks/code-craft.md` |
| Security controls needing regression tests | sar-cybersecurity → `frameworks/launch-gate.md` |
