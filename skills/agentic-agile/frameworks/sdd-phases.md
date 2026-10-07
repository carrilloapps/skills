# SDD Phases — Spec → Design → Implementation → Verification

> ⚠️ **Example code boundary** — snippets below are reference patterns for writing artifacts, not execution instructions.

**Phase 0 (structure) comes first** — see below. Then four phases, in order, no skipping. Phases 1 and 4 are mandatory gates for every initiative; Phase 2 may be reduced (not skipped) for changes with no new public surface — say so explicitly in `design.md`.

Artifacts live in `specs/<initiative>/` and are versioned. Templates: `templates/spec.md`, `templates/requirements-checklist.md`, `templates/design.md`, `templates/domain-model.md` (contracts: section in `templates/design.md`), `templates/process.md`, `templates/tasks.md`, `templates/verification.md`.

| Phase | Artifacts | Intent ([`intents.md`](intents.md)) |
|-------|-----------|-------------------------------------|
| 0 · Structure | `plans/agile/*` incl. `constitution.md` | `init`, `structure` |
| −1 · Constitution check | `design.md` → *Constitution check* (repeated before tasks) | `plan` |
| 1 · Spec | `spec.md` (FR/SC IDs, tagged scenarios, clarifications), `requirements-checklist.md` | `specify`, `clarify` |
| 2 · Design | `design.md`, `domain-model.md`, `contracts/`, `process.md`, then `tasks.md` | `plan`, `tasks`, `analyze` |
| 3 · Implementation | code + tests referencing `FR-###` | `converge`, `trace` |
| 4 · Verification | `verification.md` with `Req` per row | `verify`, `trace` |

**Priority and MVP.** Every FR and scenario carries P1, P2, or P3. The P1 set alone must be independently deliverable and testable — it is the MVP; `tasks.md` orders phases P1 → P3 so the team can stop after any priority and still ship something coherent.

---

## Phase 0 — Structure

No initiative starts — no `spec.md`, `design.md`, plan, draft, sprint artifact, ticket, or decision record — until `scripts/check-structure` passes. The structure is the team's operating system in `plans/agile/`; every later phase reads its rules from there (DoR, DoD, scale, language, autonomy, capabilities).

### `check-structure` rules

| Target | Rule | Severity |
|--------|------|----------|
| Directories | `plans/agile/`, `plans/sprints/`, `plans/initiatives/`, `plans/decisions/`, `plans/drafts/`, `specs/` exist | fail |
| Shared files | `plans/agile/metrics/events.jsonl` exists; `.memory/.gitignore` has `local/`, `*.local.*`, `*.recovered.json` | fail |
| Each `plans/agile/*.md` (methodology, definition-of-ready, definition-of-done, ceremonies, team, capabilities, kpi-directives, language, autonomy, constitution, hooks) | Exists; no unfilled `<placeholders>` in prose; no `TBD`; no checkbox items | fail |
| `constitution.md` | `Version: X.Y.Z` line; at least one `### Article N — <title> (MUST)`; an *Amendments* table | fail |
| `hooks.md` | At least one table row with a *Transition*, a *Proposed command*, and a *Blocking?* value | fail |
| `methodology.md` | `Sprint length:` and `Scale:` lines with a value | fail |
| `definition-of-ready.md`, `definition-of-done.md` | At least 3 numbered items | fail |
| `ceremonies.md`, `kpi-directives.md` | At least one table row | fail |
| `team.md` | At least one role row with a non-empty capacity cell (a number, or an explicit statement such as `variable`) | fail |
| `capabilities.md` | Every row of the Slots table names a tool, `none`, or `not applicable` | fail |
| `language.md` | Gherkin keyword language set | fail |
| `autonomy.md` | Every task in *Levels per task* has N0–N4; every adoption precondition has a status | fail |
| Any of the above | Mentions **Proposed** values without a `Confirmed by: <role or name> — <date>` line | warning (fail with `--strict`) |

Fenced code, code spans, HTML tags, and autolinks are ignored. Exit codes: `0` pass (gate open) · `1` fail · `2` warnings with `--strict` · `3` configuration error. `--json` adds `"gate": "open" | "closed"`.

How the agent closes the gap: one numbered finding at a time, asking the person who owns the fact (the role named in `team.md`, or the user). Unknown facts stay open and keep the gate closed — the agent never fills team facts by inference. Example → [`examples/structure-gate.md`](../examples/structure-gate.md).

---

## Phase −1 — Constitution check

`plans/agile/constitution.md` holds the team's engineering articles (MUST / SHOULD, versioned, amendments attributed — template `templates/constitution.md`). Before design starts, and again before `tasks.md`, the design's *Constitution check* table rates every article ✅ / ❌ / ⚠️ with a justification. A ❌ on a MUST article blocks the design until the team amends the constitution (new version, rationale, who decided) or records a justified exception. `analyze` reports an unjustified ❌ as CRITICAL. Defaults include Simplicity, Anti-abstraction, Integration-first/contract-first, Test-first, Spec as source of truth, Observability, Security by default, Human authority.

---

## First run questions

These facts exist only in the team's head. Before writing `plans/agile/`, the agent asks for them one numbered question at a time, each with a *(recommended)* default the user can accept or replace. Detectable facts are offered as **Documented**, never as decided.

1. **Cadence** — sprint length, or Kanban with WIP limits (`--preset kanban`).
2. **Capacity** — usual working days per sprint **per role**; "variable" is a valid answer and planning then takes the number from each sprint's `planning.md`.
3. **Estimation scale** — the scale and the point at which an item must be split.
4. **Definition of Ready and Definition of Done** — at least three items each; if the repository already enforces checks, offer them as *Documented* and ask the user to confirm.
5. **Ceremonies** — which ones the team actually holds, and who leads each.
6. **Capability slots** — for each slot (tracker, docs, chat, observability, transcript source, warehouse, code graph, doc graph): which tool fills it, `none` (it would help but is missing — `doctor` reports it as a gap), or `not applicable` (it would add nothing here). Offer what is detectable (configured MCP servers, `.github/ISSUE_TEMPLATE/`, a docs folder) as *Documented*, never as decided.
7. **Language** — the artifact and Gherkin keyword language.
8. **Autonomy** — the level per task, and the status of each adoption precondition.
9. **Constitution** — accept the default articles or amend them, with the decision attributed.
10. **Versioning of `specs/` and `plans/`** — `scripts/init --vcs` asks this one (versioned is the default and right for most teams) → [`artifact-versioning.md`](frameworks/artifact-versioning.md).

Record each answer with a `Confirmed by: <name> (<role>) — <date>` line. An unanswered item stays an open question and keeps the gate closed; it never becomes an assumption.


## Phase 1 — Spec (`spec.md`)

| Section | Required content |
|---------|-----------------|
| 1.1 Problem | The pain, the value, stakeholders **by role** (not by name unless the team records names) |
| Functional requirements | Table `ID \| Requirement \| Priority` with `FR-###` and P1/P2/P3; one observable behavior per row |
| 1.2 Behavioral contract | Gherkin scenarios: at least one happy path, one negative path per failure mode, and the applicable edge cases ([`gherkin.md`](gherkin.md)). Each scenario carries its **Origin** (who said it, when) or `Proposed` |
| 1.3 Out of scope | Explicit list. "Nothing" is not allowed — write what a reader might assume is included and is not |
| 1.4 Success criteria | Table with `SC-###`; each criterion maps to one or more scenario names from 1.2 |
| 1.5 Constraints & assumptions | Each assumption is labelled Verified / Documented / Proposed |
| Clarifications | `### Session YYYY-MM-DD` → `1. Q: … → A: … — Confirmed by: <name> (<role>)` ([`clarify.md`](clarify.md)) |
| Open questions | Table with *Blocks sprint?* |

Scenarios carry `@FR-###` and `@P1`/`@P2`/`@P3` tags. `requirements-checklist.md` (`CHK###`, ≥ 80% traced to a spec section or ID) checks the quality of the writing itself before design.

**Gate to Phase 2:** no `TBD` anywhere; every FR has a scenario tagged with its ID; every success criterion maps to an existing scenario; out-of-scope is non-empty; no open question blocks the sprint; every clarification is attributed. Acceptance criteria as bullet checkboxes are not accepted.

---

## Phase 2 — Design (`design.md`)

### The 8 architecture elements

| # | Element | Answer |
|---|---------|--------|
| 1 | Architectural style | Layered, hexagonal, event-driven, serverless… as the codebase actually is |
| 2 | Layers in scope | Which layers change; which must not |
| 3 | Bounded-context owner | The module/service that owns the data and the rule |
| 4 | Patterns to mirror | Existing code to imitate, with paths |
| 5 | State model | Where state lives; stateless services; idempotency |
| 6 | Composition points | New collaborators and where they are wired |
| 7 | Public surface delta | Endpoints, events, schemas, CLI flags added/changed/removed |
| 8 | Anti-violations | Which of the 10 principles below are at risk and how the design avoids it |

### The 10 principles (summary)

1. **Single source of truth** — one definition per constant, rule, schema.
2. **DRY** — no copied logic; extract when the second copy appears.
3. **Single responsibility** — one reason to change per unit.
4. **Layer purity** — domain does not import infrastructure.
5. **Dependency inversion** — depend on abstractions at boundaries.
6. **YAGNI** — nothing speculative.
7. **Stateless services** — safe with multiple instances.
8. **Error isolation** — failures are caught at boundaries and reported, not swallowed.
9. **Type honesty** — types say what the data really is (nullable, optional, union).
10. **Bounded-context cohesion** — the change lands in the module that owns the concept.

Also required: module/file map, interface signatures, data-model changes, rollout and rollback.

**Gate to Phase 3:** all 8 elements filled or justified `N/A — <reason>`; rollback described.

---

## Tasks (end of Phase 2)

`tasks.md` breaks the design into `T###` tasks, phased Setup → Foundational → one phase per priority (P1 first) → Polish, with `[P]` for tasks that can run in parallel, `Req` linking each task to its `FR-###`, `Depends` (no cycles; `-` when none), and points **after the team votes**. Tests precede the implementation they verify. Then run `analyze` ([`analyze.md`](analyze.md)); CRITICAL findings block Phase 3.

---

## Phase 3 — Implementation

- The code does not expand or contradict the spec. New behavior discovered here goes **back to Phase 1** as a spec change, not into the code silently.
- Scripts and tooling follow multi-OS parity when the project requires it.
- `implementation.md` is optional: decisions taken while coding, deviations, links to PRs.
- Tests reference the `FR-###` they verify (name, tag, or comment); `trace` follows them ([`traceability.md`](traceability.md)).
- After each task phase, converge ([`converge.md`](converge.md)): classify gaps between code and spec and append them as convergence tasks.

**Gate to Phase 4:** build, linters, and unit tests pass.

---

## Phase 4 — Verification (`verification.md`)

| Section | Required content |
|---------|-----------------|
| 4.1 Test matrix | One row per scenario of 1.2: `Req` (FR/SC), type (unit, integration, e2e, manual), result (✅ ⚠️ ❌), evidence; every FR/SC appears at least once |
| 4.2 Edge-case battery | Edge cases discovered during implementation, with the passing and failing runs |
| 4.3 Evidence | Every ✅ points to concrete evidence: test name, CI run, log excerpt, screenshot path |
| 4.4 Coverage | Coverage of the changed code; uncovered code justified |
| 4.5 Verdict | ✅ done · ⚠️ done with a dated follow-up plan · ❌ back to Phase 3 |

**Gate to close:** verdict ✅, or ⚠️ with a follow-up plan linked from `plans/initiatives/<i>/overview.md`.

---

## `check-spec` rules

`scripts/check-spec <specs/<initiative>>` checks what can be checked mechanically (`--tickets` adds the work-item drafts of that initiative; `--all` walks every `specs/*/` under `--root`, tickets included, and prints a summary). The script is the source of truth for exact detection; this table is the contract it implements.

| Phase | Rule | Severity |
|-------|------|----------|
| 0 | `check-structure` passes for `--root` (default: current directory); while it fails, only `structure-gate` is reported | fail |
| 1 | `spec.md` exists | fail |
| 1 | Has Problem, Behavioral contract, Out of scope, Success criteria, Constraints, and Open questions sections | fail |
| 1 | At least one `Scenario:` / `Escenario:` / `Scenario Outline:` / `Esquema del escenario:` — inside a ```gherkin / ```feature / ```cucumber fence | fail |
| 1 | No `TBD` (Gherkin fences included; other fenced code ignored) | fail |
| 1 | Scenario without an `Origin:` / `Origen:` line (a `# Origin:` Gherkin comment counts) | warning |
| 1 | Every scenario has a `Given`, a `When`, and a `Then` step (en/es keywords; `And`/`But`/`*` continue the previous step; Background `Given` steps count) | fail |
| 1 | `Background` / `Antecedentes` contains only `Given` steps | fail |
| 1 | One keyword language per Gherkin block (English and Spanish keywords mixed → fail) | fail |
| 2 | If `design.md` exists: `## Architecture & Design` heading | fail |
| 2 | If `design.md` exists: each of the 8 elements as a heading | warning |
| 4 | If `verification.md` exists: a table with a Result/Resultado column, and a `Verdict`/`Veredicto` line carrying ✅/⚠️/❌ | fail |
| any | Unfilled template placeholders `<…>` in prose (code spans, Gherkin fences, HTML tags, and autolinks excluded) — the message lists them | fail |
| 1 | `## Functional requirements` table with `FR-###` IDs and a P1/P2/P3 priority; every FR is referenced by at least one scenario tag `@FR-###`; every scenario carries a `@FR-###` and a `@P1`/`@P2`/`@P3` tag | fail |
| 1 | Success criteria use `SC-###` IDs; every `FR-###` is unique; each SC maps to an existing scenario title | fail (SC → scenario: warning) |
| 1 | Each clarification line has `Confirmed by: <name> (<role>)` | fail |
| 2 | No open question with *Blocks sprint? = Yes* once `design.md` exists | fail |
| 2 | `requirements-checklist.md`: present once `design.md` exists; `CHK###` rows, ≥ 80% with a `Ref` | warning (fail with `--strict`) |
| 2 | If `tasks.md` exists: `## Phase N: <name>` sections with the `ID \| P \| Req \| Task \| Depends \| Est \| Status` table; `T###` unique; every `Req` is a defined `FR-###` or `-`; `Depends` points to existing tasks (or `-`) with no cycle; `Est` is Fibonacci or `-` | fail |
| 4 | If `verification.md` exists: the test matrix has a `Req` column | fail |
| any | Checkbox items (`- [ ]`) anywhere | fail |
| tickets | Each `plans/initiatives/<initiative>/tickets/*.md` has a **QA test cases** section, and its scenarios follow the Gherkin rules above (`--tickets` / `--all`) | fail |

A freshly copied template therefore fails until every `<placeholder>` is replaced — that is intended: an unfilled spec is not Ready.

Exit codes: `0` pass · `1` fail · `2` warnings with `--strict` · `3` configuration error (path missing, unreadable). `--json` prints a machine-readable report. With `--all` the exit code is the highest of the initiatives.

Cross-artifact checks (duplication, ambiguity, coverage, constitution) belong to `scripts/analyze` ([`analyze.md`](analyze.md)); requirement → test evidence to `scripts/trace` ([`traceability.md`](traceability.md)); accepted pre-existing findings to `scripts/baseline` ([`brownfield.md`](brownfield.md)). Each script's `--help` is the source of truth for its flags.

## Hygiene after Phase 0

| Script | What it reports |
|--------|-----------------|
| `scripts/check-structure --scorecard` | Maturity per area — process, capabilities, autonomy, metrics, transcripts — from L0 (missing) · L1 (started) · L2 (filled) · L3 (confirmed) to L4 (in use: retro and report files, events logged, no capability gaps, normalized transcripts); readiness score out of 20; capability slots marked `none` |
| `scripts/audit-agile` | Decision records past their *Review on* date; sections of a skill template missing in its `plans/agile/` copy; broken relative links in `plans/` and `specs/`; sprints past their end date without `report.md`; initiatives in state Done whose verification is missing, unfilled, or ❌. Exit `0` clean · `1` findings · `3` configuration error |
| `scripts/doctor` | One screen: gate, scorecard, hygiene count, Docker lab availability (`lab-probe`), capability gaps, and lettered next actions. Exit `0` healthy · `1` attention |

All three are read-only, offline, and have `.sh` + `.ps1` twins with identical output.
