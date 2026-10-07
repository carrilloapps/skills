# Changelog

All notable changes to this repository are documented in this file.
Each skill is versioned independently — Devil's Advocate uses `[X.Y.Z]` headers, additional skills use `skill-name [X.Y.Z]` headers.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and all skills adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Repository

- **Permission policy for this repository** (`.claude/settings.json`) — only operations that
  publish or rewrite shared history ask for confirmation: `git push`, `tag`, `merge`, `rebase`,
  `filter-repo`, `remote`, the `gh` release / pr / issue / workflow / secret / variable / repo
  commands, and `npm publish`. Local work — edits, `git commit`, branches, tests — runs
  unprompted. The Devil's Advocate guard hook is deliberately **not** enabled here: it asks on
  every edit by design, which is the skill's behaviour rather than a permission policy.
- **`specs/` and `plans/` are not versioned in this repository** (root `.gitignore`, with the
  reason in the file and in `AGENTS.md`): it is a public skill catalogue, so its Phase 0
  artifacts are a worked example and a public spec would leak roadmap detail. This is a
  per-project choice, not a default — most teams should version them.
- **Faster quality gate** — `validate.sh` went from over 15 minutes to about 80 seconds: it no
  longer runs the parity suite itself (CI has a dedicated job; `--with-parity` opts in) and it
  prunes scratch trees (`.work/`, `.memory/local/`, `node_modules`, `.git`) from every recursive
  scan. It now checks instead that the suite is internally consistent — every case has a golden
  and every golden has a case.
- **Parity runners clean up and can run one case** — a passing run removes `tests/scripts/.work/`
  (3,033 files were being left behind, slowing every later scan; `PARITY_KEEP=1` keeps them), and
  `--case NAME|PREFIX` (`-Case` in PowerShell) runs or regenerates a single case, which turns a
  golden update from ~15 minutes into seconds.

### Planned

- Nothing planned; open items live in `plans/drafts/` of this repository.

---

## agentic-agile [1.0.2] — 2026-10-07

### Added

- **The first run asks instead of assuming.** Phase 0 now opens with ten numbered questions —
  cadence, capacity in working days per sprint and per role, estimation scale, DoR/DoD,
  ceremonies, each capability slot, language, autonomy, the constitution, and whether `specs/`
  and `plans/` are versioned — each with a *(recommended)* default. Detectable facts (configured
  MCP servers, issue templates, a docs folder) are offered as **Documented**, never as decided;
  every answer is recorded with a `Confirmed by: <name> (<role>) — <date>` line; "variable" is a
  valid capacity; and an unanswered item stays an open question that keeps the gate closed rather
  than becoming an assumption. Questions → `frameworks/sdd-phases.md`.
- **Versioning of `specs/` and `plans/` is an explicit user choice** — `init --vcs
  versioned|ignored|ask` (default `ask`) states the consequence of each option and writes the
  ignore rules only when the user picks `ignored`; `check-structure` reports the current state
  (versioned, ignored, or no VCS detected) in its output and `--json` without ever enforcing it,
  because both answers are legitimate. New `frameworks/artifact-versioning.md` owns the
  trade-off: who should version, what changes if they do not — including that a fresh clone
  starts Phase 0 empty with the gate closed — and how to switch later in either direction.

---

## postmortem-writing [1.0.0] — 2026-10-06

### Added

- **New skill: blameless incident postmortems**, closing the collection's prevent → assess → learn loop. Eight-phase lifecycle with an **active-incident gate**: while an incident is live the agent only collects and attributes evidence into a draft timeline, and writes no report.
- **Deterministic severity** — five dimensions (user impact, data, duration, blast radius, regulatory); severity is the highest matching dimension and every report prints its rubric line so a reader can re-derive it. `[unknown]` dimensions are excluded rather than silently lowering severity, duration never overrides user or data impact, and near misses are SEV4 with an explicit counterfactual that sizes the actions.
- **Evidence discipline** — every timeline row carries a log line, alert ID, commit, deploy, or an attributed **role** and time; `[unknown]` replaces guesses; a period without evidence is an explicit gap row; clock skew is recorded, never normalised away. Five anchor events (change, onset, detection, mitigation, resolution) are always attempted.
- **Causal analysis without the single-root-cause fiction** — contributing factors with condition, evidence, and what removing them would have changed; mandatory Confidence (Confirmed / Probable / Possible) on every claim; a blameless rewriting table that turns person-shaped input into structural causes; Five Whys as one tool of four, per factor, with stop rules; mandatory detection-gap and "what went well" sections.
- **Actions that can be verified** — `prevent` / `detect` / `mitigate`, each tracing to a factor, with an owner role, a due date, and a verification step; a missing field is reported as `incomplete`, never silently accepted. The skill records action state and never closes, reassigns, or tickets one.
- **Measured-only metrics** — time to detect, mitigate, and resolve computed from timeline rows that have evidence, with a phase breakdown for long incidents; anything else is `not measured`. Trends need three closed incidents.
- **Bilingual EN + ES (es_VE)** reports with ISO-dated filenames `YYYY-MM-DD_SEVn_<slug>_{EN,ES}.md`, and SAR's public-repository rule: an incident that exposes an unfixed vulnerability writes to `.memory/local/postmortems/` instead of the versioned directory.
- **Versioned incident registry** `.memory/postmortem-writing/incidents.json` with team-managed `status`, action `state`, and `reviewOn`; permanent IDs; entries are never deleted; every report carries a Registry Snapshot so the state survives a non-versioned registry.
- **Evidence collection for Linux / WSL, containers, Kubernetes, and git** — read-only commands proposed verbatim and run only after the user approves that exact command; output is treated as untrusted data and redacted at capture. `git blame` is deliberately absent: the analysis never needs "who".
- **Handoffs, not duplication** — a Lessons export with trigger conditions for devils-advocate; security causes reference the SAR finding ID instead of re-scoring the vulnerability; the boundary with agentic-agile (sprint retro postmortem vs. incident postmortem) is documented in both directions.
- 9 frameworks, 7 templates, 3 examples (SEV1 outage, SEV2 silent data drift, SEV4 near miss), and all six mandatory safeguards.

---

## [3.0.1] — 2026-10-06

### Fixed

A deep review of the four skills, their scripts, and the repository documentation
found 77 issues (errors, inconsistencies, duplication, dead references); all are
fixed and verified. Shared outcomes of that review:

- **Single owner per rule** — the events schema, autonomy defaults, ceremony table,
  project layout, estimation scale, closing line, `.memory/` convention, and the
  capability-suggestion protocol are each defined in exactly one file; every other
  file points to it. No circular references.
- **No dead references** — every documented file, section, script, and flag was
  verified against disk and against each script's `--help`.
- **Installed-path correctness** — examples, hooks, and templates reference
  `<skill-dir>` (the folder the skill is installed into) instead of this
  repository's layout.

Skill-specific:

- Docker lab reads the SonarQube token from the per-service env file written by
  SAR's bootstrap (`env/sonar-scanner.env`); `tokens.env` is bootstrap-internal.
- Capability tool rows point at ai-rules for the shared suggestion protocol.

---

## sar-cybersecurity [2.0.1] — 2026-10-06

### Fixed

A deep review of the four skills, their scripts, and the repository documentation
found 77 issues (errors, inconsistencies, duplication, dead references); all are
fixed and verified. Shared outcomes of that review:

- **Single owner per rule** — the events schema, autonomy defaults, ceremony table,
  project layout, estimation scale, closing line, `.memory/` convention, and the
  capability-suggestion protocol are each defined in exactly one file; every other
  file points to it. No circular references.
- **No dead references** — every documented file, section, script, and flag was
  verified against disk and against each script's `--help`.
- **Installed-path correctness** — examples, hooks, and templates reference
  `<skill-dir>` (the folder the skill is installed into) instead of this
  repository's layout.

Skill-specific:

- 11 CWE identifiers cited by the skill's own examples (CWE-120, 121, 122, 125,
  416, 476, 540, 561, 625, 787) and MITRE ATT&CK T1548 added to the offline
  lookup tables, with names verified against cwe.mitre.org and attack.mitre.org.
- `compose.sar-dast.yaml` is documented as written only when the user asks for
  dynamic testing, not as part of the default lab.
- The compliance baseline is stated consistently as **21 baseline standards**
  (plus the expanded reference); the recurring-assessment example uses ISO dates.

---

## ai-rules [1.1.1] — 2026-10-06

### Fixed

A deep review of the four skills, their scripts, and the repository documentation
found 77 issues (errors, inconsistencies, duplication, dead references); all are
fixed and verified. Shared outcomes of that review:

- **Single owner per rule** — the events schema, autonomy defaults, ceremony table,
  project layout, estimation scale, closing line, `.memory/` convention, and the
  capability-suggestion protocol are each defined in exactly one file; every other
  file points to it. No circular references.
- **No dead references** — every documented file, section, script, and flag was
  verified against disk and against each script's `--help`.
- **Installed-path correctness** — examples, hooks, and templates reference
  `<skill-dir>` (the folder the skill is installed into) instead of this
  repository's layout.

Skill-specific:

- The `.memory/` convention moves to `frameworks/memory-convention.md` as its
  single owner; `SKILL.md` keeps a summary and a pointer.
- `metadata.json` gains an abstract; user-project paths are code spans, not links.

---

## agentic-agile [1.0.1] — 2026-10-06

### Fixed

A deep review of the four skills, their scripts, and the repository documentation
found 77 issues (errors, inconsistencies, duplication, dead references); all are
fixed and verified. Shared outcomes of that review:

- **Single owner per rule** — the events schema, autonomy defaults, ceremony table,
  project layout, estimation scale, closing line, `.memory/` convention, and the
  capability-suggestion protocol are each defined in exactly one file; every other
  file points to it. No circular references.
- **No dead references** — every documented file, section, script, and flag was
  verified against disk and against each script's `--help`.
- **Installed-path correctness** — examples, hooks, and templates reference
  `<skill-dir>` (the folder the skill is installed into) instead of this
  repository's layout.

Skill-specific:

- **`trace`** no longer counts other projects' test fixtures as evidence: file
  matching is case-insensitive (`LoginTest.java` now counts) and `fixtures`,
  `testdata`, `__fixtures__`, `.work`, `templates`, `expected`, `golden(s)` and
  `(__)snapshots` are skipped. On this repository it reported 331 foreign matches.
- **`baseline`** rejects `--file` paths outside the project and never records a
  blocking question or a CRITICAL finding as accepted — a pending decision cannot
  be baselined away.
- **`check-structure`** requires `plans/agile/hooks.md`; **`audit-agile`** no
  longer reports template drift on `constitution.md`, whose articles are team
  content that amendments rename by design.
- **`check-spec`** anchors its section regexes (`Non-functional requirements` no
  longer matches `Functional requirements`) and runs each initiative once in
  `--all` mode; **`doctor`** reads the Docker object instead of the first JSON
  match; `--help` is byte-identical between `.sh` and `.ps1`; JSON escapers
  handle tabs and control characters; `lab-probe` computes available RAM on macOS.
- Examples show real script output, and the spec template documents the ninth
  edge-case category (encoding).

---

## Repository — 2026-10-05

Repository-wide changes shipped with devils-advocate 3.0.0, sar-cybersecurity 2.0.0, ai-rules 1.1.0, and agentic-agile 1.0.0.

### Install and agents

- `AGENTS.md` now carries the former `CLAUDE.md` guidance (`CLAUDE.md` imports it).
- **`docs/INSTALL.md`** — single per-agent install matrix (70+ agents via the `skills` CLI; Claude Code, Antigravity IDE `antigravity` and CLI `agy` `antigravity-cli`, Cursor, Windsurf/Devin Desktop, GitHub Copilot, Codex, Gemini CLI, Cline, Roo Code, OpenCode, Kiro, Amp, Replit, Kimi) with project/global paths, always-on files, guard, and manual install; READMEs link to it; `--list` documented correctly.
- **Fourth skill wiring** — `validate.sh` check 27 (agentic-agile consistency) and checks 16/17 include it; README, AGENTS.md, `.ai-context.md`, CONTRIBUTING, INSTALL, SECURITY, and copilot-instructions list four skills.

### Guards (`integrations/`)

- **Guards for every agent with blocking hooks** — one deterministic classifier (`integrations/core/`, no AI, no network, no writes, no dependencies; vendored into each adapter and drift-checked by `sync-core.mjs --check`) with adapters for Claude Code (plugin + `.claude-plugin/marketplace.json`), GitHub Copilot, Cursor (+ advisory `.mdc` rule), Gemini CLI, Codex, Windsurf/Devin, Cline, OpenCode (stable), Kiro and Antigravity `agy` (experimental), plus an advisory Roo rule; edits to agent hook/permission config are Tier 2; Claude Code strict mode denies in unattended modes. 229 tests in CI.
- **Classifier hardened after a SAR run on this repository (F01)** — a single `&`, `awk`/`sed`, interpreters, `tee`/`xargs`, `sort -o`/`tree -o`/`uniq in out`, `--output`, file redirects including `2>`/`&>`, process substitution, `FOO=bar` prefixes, git `-c`/`--config-env`/`--exec-path`/`--output`/`--upload-pack`, and MCP `query`/`search`/`execute` tools now ask; MCP read-only limited to `get`/`list`/`read`/`describe`; the Antigravity adapter never emits `allow`.

### Multi-OS scripts and `.memory/`

- **Selective `.memory/`** — root `.gitignore` ignores only `.memory/local/`, `*.local.*`, `*.recovered.json`, plus `.codegraph/` and `.docgraph/`.
- **Multi-OS scripts** — dependency-free `.sh` + `.ps1` twins with parity tests; `lab-probe` (vendored in every skill) detects Docker, Compose, RAM, CPUs, disk, and `vm.max_map_count`, then picks tools by criticality within the available budget. CI `scripts-parity` job runs on Ubuntu and Windows (bash, pwsh 7, Windows PowerShell 5.1).
- **Test fixtures** no longer contain provider-formatted fake secrets (they tripped secret scanners and would be blocked by push protection).
- **Ignore rules** — committed test fixture `node_modules/` no longer ignored; Windows `Zone.Identifier` streams and `tests/scripts/.work/` ignored; extensionless Cline hook forced to LF.

### Quality gates and audit

- **`validate.sh`** — per-skill version/CHANGELOG/root-badge checks (all four skills), SAR index + boundary + scoring-arithmetic checks, six-safeguard check for every `SKILL.md`, selective `.memory/` convention, pinned and pipe-free install commands in `capabilities.md`, no install commands in any `SKILL.md`, guard core sync, no stale "40+ agents" wording, Docker lab hygiene (every `image:`/`FROM` line carries a `@sha256:` digest, ports bound to `127.0.0.1`, no literal credentials), no `[ ]` checkboxes under `skills/`, shared-script vendoring, `.sh`/`.ps1` twins plus parity tests, no global agent directories without approval wording, `audit-agile`/`doctor`/`check-structure` indexed in agentic-agile, every `.ps1` ASCII outside comments. Hardcoded check counts removed from docs; the README validation badge reflects the CI workflow.
- **Markdown hygiene** — markdownlint structural issues reduced from 5,123 to 152 (remaining: intentional inline HTML badges/details and emphasis style); every fenced block declares a language.
- **Local skills.sh-equivalent audit** — `scripts/audit-skills.sh`/`.ps1` (Docker, digest-pinned Python) runs `agentskills validate` (skills-ref 0.1.1) and Cisco `skill-scanner` 2.2.1 with offline analyzers only; nothing leaves the machine; any finding fails. CI `skills-audit` job runs the same checks and uploads SARIF (actions pinned by SHA). Manual `snyk-agent-scan` workflow (`workflow_dispatch`, `SNYK_TOKEN`; uploads skill content to Snyk). Result: 21 findings → 0; all four skills pass the spec validator. Prohibitions are worded without the literal patterns they forbid.
- **Agent Skills spec compliance** — `version` moved to `metadata.version` in every `SKILL.md` (a top-level `version:` is rejected by the reference validator); `validate.sh` reads `metadata.version`.
- **Comparison-driven roadmap delivered** — agentic-agile now covers every capability where GitHub Spec Kit or AI Unified Process led (constitution, IDs + traceability, clarify, analyze, tasks with parallelism, converge, brownfield baseline, domain model/contracts, presets, single entry point, Spec Kit importer), validated deterministically in CI.

---

## agentic-agile [1.0.0] — 2026-10-05

### Added

- **New skill: agentic agility for Scrum with Spec-Driven Development.** Four gated SDD phases (Spec → Design → Implementation → Verification) in versioned `specs/<initiative>/`; Gherkin behavioral contracts with Origin per scenario, explicit out of scope, success criteria mapped to scenarios, the 8 architecture elements and 10 principles in design, and a verification matrix with evidence and a ✅/⚠️/❌ verdict.
- **Honest-agent operating rules** — autonomy levels N0–N4 set by the cost of being wrong (sprint commitment, closing/transitioning items, final prioritisation, and assessing people are never delegated); Verified / Documented / Proposed labels on every claim; mandatory attribution (contradictions are surfaced, never resolved); no invented numbers or inferred readiness; anti-anchoring estimation (the agent speaks after the vote); contrast with the real system before drafting; stop and ask when the owning capability is unavailable.
- **Scrum ceremonies mapped to agent actions** — pre-refinement from transcripts, adversarial refinement (delegated to devils-advocate), capacity planning with Fibonacci 1–13 (split at 13, forbidden ≥ 20), daily health (facts only), review, close with team-defined KPIs ("not measurable" instead of invalid numbers), retro, decision records with who decided and a review date.
- **Versioned project layout** — `specs/` and `plans/` (agile operating system, sprints, initiatives, decisions, drafts, `metrics/events.jsonl`); only raw transcripts go to `.memory/local/agentic-agile/` under the selective `.memory/.gitignore`; nothing is written to global agent directories.
- **Transcripts** — consent and retention preconditions, normalized schema (speaker, start, end, text, redactions), PII redaction before persistence, proper-noun verification, refusal of summaries of summaries.
- **Capability-slot integrations over MCP** — tracker, docs, chat, observability, transcript source, warehouse/semantic layer, code graph, doc graph; vendor adapters as examples only; project-level pinned MCP config; tracker writes at most N3 with the exact payload approved; four authorization questions for third-party capabilities.
- **Adoption and measurement** — seven preconditions, three adoption phases, six agentic indicators computed from an append-only event log, no targets before two baseline cycles.
- **35 templates** with numbered ✅/❌/⚠️ gate items (no checkboxes), 9 examples, and 12 multi-OS scripts (`aa`, `analyze`, `audit-agile`, `baseline`, `check-spec`, `check-structure`, `doctor`, `import-speckit`, `init`, `lab-probe`, `trace`, `transcript-normalize`) as `.sh` + `.ps1` twins — final counts for 1.0.0; the bullets below describe how each piece was added.
- **`check-spec` hardening** — reads Gherkin inside `gherkin`, `feature`, and `cucumber` fenced blocks; rejects unfilled `<placeholders>` in prose (code spans, Gherkin fences, HTML tags, and autolinks excluded); the spec template gains Open questions and the verification template a `Verdict` line.
- **`lab-probe` noise control** — skips `fixtures/`, `testdata/`, `__fixtures__/`, `.work/`, and `templates/` by default; extra paths in a root `.labprobeignore`; exit code 4 when Docker is unavailable.
- **Phase 0 structural gate** — no spec, plan, draft, sprint artifact, ticket, or decision record until `scripts/check-structure` (`.sh` + `.ps1`, parity-tested) confirms the team's operating system in `plans/agile/`: files exist with no placeholders/TBD/checkboxes, sprint length and scale, ≥ 3 DoR/DoD items, a role with capacity, every capability slot decided, Gherkin language, N0–N4 per task, and a status per adoption precondition; Proposed values need a `Confirmed by:` line (warning, failure with `--strict`). `check-spec` runs the gate first (`--root`), `init` points at it, and the agent completes the structure one finding at a time without inventing team facts.
- `transcript-normalize.sh` no longer uses `eval`; JSON records are built with fixed `printf` formats (output unchanged).
- **Complete Gherkin contract** — `frameworks/gherkin.md` covers the full en/es keyword set (Rule/Regla, Background/Antecedentes, Example, Scenario Outline/Template, Examples/Scenarios, `*`), tags, data tables, doc strings, `# language:`, structure rules, results with evidence (a pass without evidence is not verified; ❌ blocks close), anti-patterns, legacy bullet-AC conversion, and a numbered pre-publish checklist.
- **Stricter `check-spec`** — every scenario needs Given/When/Then (Background Givens count), Background holds only Given steps, one keyword language per Gherkin block; `--tickets` requires a QA test cases section in work-item drafts; `--all` validates every `specs/*/` with a summary and the highest exit code.
- **Hygiene scripts** (`.sh` + `.ps1`, parity-tested) — `check-structure --scorecard` (maturity L0–L4 per area, readiness score, capability gaps), `audit-agile` (overdue decision reviews, template drift, broken links, sprints without report, Done initiatives without a passing verification), and `doctor` (one-screen health with next actions).
- **Delivery** (`frameworks/delivery.md`) — plan → tickets with a 5-point quality check and exact-payload N3 approval; PR conformance against the spec (every change mapped to a scenario; an unmapped change is scope expansion back to Phase 1; failure analysis delegated to devils-advocate, security to sar-cybersecurity); changelog by initiative in user language; sprint data collection by date window with no per-person metrics.
- **KPIs** (`frameworks/kpi.md`) — gate zero (confirmed definition + data source verified in-session), state tree with a "not measurable" branch, mandatory row schema (KPI | value | threshold | state | notes/source), "a drop that is success" check, seven vendor-neutral close phases with a numbered checklist, calibration only after two baseline cycles.
- **Team safety** (`frameworks/team-safety.md`) — no destructive edits of shared docs/tracker without the exact change approved, backup before edit, IDs resolved at runtime, no bulk operations; draft-first messages, no mass mentions, breaking changes announced before merge, live vulnerabilities never broadcast; encrypted channel + second channel for sensitive sharing; data-domain authority (governance, access, hosting, write authority; system of record vs. system of analysis).
- **Ceremonies** — context refresh before every ceremony, capture flow for process facts (propose → confirm → apply → log), cross-team dependencies in planning, empty adversarial categories declared empty, weekly status, quarterly review, executive summary, blameless postmortem feeding devils-advocate.
- **Nine more templates** — impact analysis, migration plan, spike/PoC, postmortem, QA regression, weekly status, quarterly report, executive summary, ticket conventions (numbered ✅/❌ gates, no checkboxes or TBD); examples for PR conformance, blameless postmortem, and the structure gate.
- **Engineering constitution and Phase −1** — `plans/agile/constitution.md` with versioned MUST/SHOULD articles (simplicity, anti-abstraction, integration/contract-first, test-first, spec as source of truth, observability, security by default, human authority) and attributed amendments, required by the Phase 0 gate; every `design.md` carries a *Constitution check*, and an unjustified ❌ on a MUST article blocks the design.
- **Requirement IDs traced to evidence** — `FR-###` (P1–P3) and `SC-###` in the spec, `@FR-### @P#` scenario tags, `Req` columns in tasks and verification; `check-spec` enforces unique IDs, tagged scenarios, SC → scenario mapping, confirmed clarifications, no blocking question before Phase 2, a requirements-quality checklist (≥ 80% referenced), and `tasks.md` integrity (T### IDs, known requirements and dependencies, Fibonacci estimates, no cycles).
- **`trace`** — FR/SC matrix from spec to scenarios, tasks, tickets, tests, and verification; fails on untagged scenarios, unknown FRs, and FRs without a scenario, task, or verification row.
- **`analyze`** — read-only, deterministic cross-artifact analysis with CRITICAL–LOW severities and stable `A###` IDs: duplicates, ambiguous vocabulary (en + es, extendable per project), unresolved `[NEEDS CLARIFICATION]`, blocking questions, terminology drift, constitution violations, task cycles, checklist coverage.
- **`baseline`** — brownfield adoption: `--write` records today's findings in a versioned `plans/agile/baseline.txt`; `--check` fails only on new ones.
- **Clarify and converge** — at most 5 attributed questions per session with a recommended option, recorded in `## Clarifications`; a converge loop that classifies code↔spec gaps (missing, partial, contradictory, unrequested) into convergence tasks under a living-spec rule.
- **`aa <intent>` entry point** — one command for the whole workflow (init · structure · doctor · specify · clarify · plan · tasks · verify · trace · analyze · baseline · audit · converge · import-speckit), gate-aware scaffolding that never overwrites — slash-command ergonomics in any agent.
- **`import-speckit`** — dry-run-first migration from GitHub Spec Kit projects into `specs/` and `plans/agile/`, every imported item labelled Proposed.
- **Domain model, contracts, process, quality checklist, bug and idea flows** — Mermaid entity/state diagrams, OpenAPI/AsyncAPI contracts, process paths as end-to-end scenarios, `requirements-checklist.md` ("unit tests for English"), `bug.md` (mandatory regression scenario), `idea-assessment.md` (go / needs-clarification / kill + decision record).
- **Presets and hooks** — `init --preset scrum|kanban|regulated`; `plans/agile/hooks.md` lists commands the agent proposes at each phase transition but never runs automatically.
- **End-to-end example validated in CI** — a complete fictional project embedded in `examples/end-to-end.md`, rebuilt by `tests/scripts/run-e2e.sh` and checked with every validator under bash, pwsh 7, and Windows PowerShell 5.1.
- **Fixes found by dogfooding** — `doctor.sh` read the wrong `compose` key and reported Docker unavailable; `trace`/`analyze`/`baseline` now accept absolute or cwd-relative initiative paths; `analyze` no longer treats the Constitution-check header legend as a ❌ row and reads `| 1 — Title |` article numbers.

---

## [3.0.0] — 2026-10-05

Rewrite focused on output quality: reports were long, generic, and stopped the user up to three times per analysis.

### Changed

- **Risk-scaled depth (Tiers 0–3)** — read-only and trivial reversible actions pass with at most one line; contained changes get a 3–8 line quick check; only high-risk actions get the full critique. Git writes are never Tier 0.
- **Compact report** — verdict first, at most 5 risks, each with mandatory *Evidence* (file/line, quote, or scenario) and a specific *Fix*; sections without evidence are omitted instead of filled.
- **"What I'll do if you approve"** — every report ends with the original plan corrected by the fixes; the user approves that plan.
- **Single stop** — ⚡ Immediate Report and the 🛑 Handbrake round are merged into one Tier 3 *Critical stop* with 2–4 targeted questions.
- **Banned output list** — generic risks, copied framework templates, invented confidence percentages, strengths lists, and multiple stop rounds.
- **Report in the user's language**; identifiers stay as-is.
- **Natural-language gate** — replies are read by intent, in any language: an action verb ("dale", "procede", "go ahead") approves the corrected plan, a described change revises, "no" cancels. A bare "ok"/"sí" is acknowledgement, not approval, and gets a one-line confirmation question. `validate.sh` check 3 now requires the "reply in your own words" note instead of every literal label.
- **Deterministic and terminating** — same plan + same evidence → same tier, verdict, risks, and order; one gate per plan (approved steps are not re-gated, and the skill never analyzes its own output); revisions re-check only the delta, and from the second revision only a new 🔴 may be raised; at most one Tier 3 stop per plan.
- `SKILL.md` reduced from ~31.9K to ~14K characters; all six audit safeguards stated explicitly in one *Safety boundaries* section.
- `frameworks/output-format.md` rewritten as a good-vs-bad guide with length budgets; `frameworks/handbrake-protocol.md` rewritten as compact question banks.

- **Derived verdict** — Overall risk = highest severity before fixes; the verdict (Stop / Rethink / Go with changes / Go) follows a fixed first-match table, so the same plan gets the same verdict.
- **One meaning for `continue`** — only the bare word runs the original plan with its open risks; "continúa"/"sigue" are ordinary approval verbs. In a Tier 3 stop, "skip the questions" produces a worst-case report and then the Gate.
- **Ordered reply classification** — questions are never approval (even with an action verb), then cancel, `continue`, revise, approve, bare acknowledgement; `✅ Proceed` now reads "run the corrected plan".
- **Frameworks are internal thinking aids** — STRIDE summary, pre-mortem, performance and analysis templates marked internal; Pros/Strengths template removed; "Always paired with" → "See also (load only if it changes the analysis)"; risk-checklist percentage scoring removed.
- **Building Protocol scoped** — applies to code the approved plan writes; existing code is reported, never rewritten without approval; role question removed; style violations downgraded to 🟡/🟢 and never displace correctness or security risks.
- **Audit hardening** — "Example code boundary" note on all 13 frameworks containing code or commands; frontmatter declares `license: MIT`; AI-attribution rule shares one sentence with ai-rules.

- **Optional code-graph capability** — `frameworks/capabilities.md` suggests `@colbymchenry/codegraph@1.6.2` (local, telemetry disabled) at most once, only when blast radius can't be evidenced by reading; installed only through the Gate; caller/impact results become *Evidence*; `.codegraph/` is VCS-ignored. Decisions recorded in `.memory/local/devils-advocate/capabilities.json`; declined tools are never re-suggested.
- **Optional Docker lab (`frameworks/docker-lab.md`)** — stack-detected, one-shot, read-only, mostly offline containers that turn measurable facts into *Evidence* on files the plan touches: lizard 1.24.0 (complexity), jscpd 5.4.0 (duplication), dependency-cruiser 18.5.0 (cycles/layers), golangci-lint v2.14.0, actionlint 1.7.12, helm 4.3.0, sqlfluff 4.4.0; PgHero v4.0.1 dashboard for a local dev Postgres only (127.0.0.1, shared lab login). Reads SAR's SonarQube when running instead of defining another. Compose in `.memory/devsecops/compose.da.yaml` (versioned), results in `.memory/local/` (ignored). One-shot scans Tier 1; first pull and dashboards Tier 2.
- **Numbered options** — every option list, checklist, and "What I'll do if you approve" plan is numbered or lettered, never `[ ]`; partial approvals by reference ("dale con 1 y 3", "quita la 2", "todo menos b") are a Revise limited to those items, executed without re-asking when no new 🔴/🟠 appears.
- **Project-local installs** — codegraph installs as a dev dependency (`npm i -D`, run via `npx --no`); a global install needs explicit approval. Generated files stay inside the project (ai-rules *Project-Local Storage*).
- **Docker lab hardening** — every image, including the bases of locally built tools, pinned by digest; repository mounts hide `.memory/local/` (empty `tmpfs`); `config/jscpd.json` with default ignores and a documented pattern for intentionally vendored copies; capability installs use `npm i -D --save-exact` with the lockfile committed.

### Removed

- `frameworks/immediate-report.md`, `frameworks/handbrake-checklist.md` (merged into Tier 3).
- 9 examples in the 2.x format; replaced by 4 examples, one per tier: `quick-check.md` (new), `plan-critique.md`, `security-review.md`, `vendor-decision-review.md` (rewritten).

### Unchanged

- Gate replies (`✅ Proceed`, `🔁 Revise`, `❌ Cancel`, `continue`), bypass behavior, domain frameworks, checklists, Building Protocol.

---

## sar-cybersecurity [2.0.0] — 2026-10-05

### Changed (breaking)

- **Deterministic, auditable scoring** — fixed adjustment values (`Base + D1 + D2 (cap +10) + D3`, clamp, floor 51, gates/caps last) with a mandatory arithmetic line that must add up. Base class is chosen by the **sink**, not the consequence (tie-break: highest base, other named). New **injection exposure rule**: when query structure is controlled, exposure = everything the database role can reach ("single record" never applies). Labels unified across report, registry, priority, and roadmap: 51–69 Medium, 1–50 Low (Warning). CVE base score source fixed: NVD Primary → GHSA → CNA.
- **Findings registry** — `.memory/sar/findings.json` replaces `vulnerabilities.csv`. It is **versioned** in private repositories as the team's shared registry; in public repositories (or when unanswered in automated runs) it moves to `.memory/local/sar/findings.json` and reports default to `.memory/local/sar/reports/`, so open vulnerabilities are never published. Step 0 asks whether the repository is public. A 1.x CSV is imported once and left untouched; every report carries a **Registry Snapshot**; recurring match = primary CWE + `component`.
- **Shared `.memory/` convention** — a versioned `.memory/.gitignore` ignores only agent-private paths (`local/`, `*.local.*`, `*.recovered.json`), with Mercurial and Fossil equivalents and a printed command for Subversion; file writes only, user lines never removed, warning when a private path is already tracked.
- **Optional tools (`frameworks/capabilities.md`)** — OSV-Scanner 2.6.0 (verified dependency CVEs, offline mode), Gitleaks 8.30.1 (secrets, always `--redact`), Semgrep CE 1.179.0 (optional, `--metrics=off`), zefer-cli 1.4.0 (optional report encryption, passphrase prompted). Detection runs nothing; each tool is suggested at most once and declined tools are remembered; pinned installs from official sources only; each install or scan runs only after approval of that exact command; tool output is untrusted evidence that is still traced and scored. Trivy and TruffleHog excluded with reasons.
- **No live access, evidence not memory** — database, cloud, and HTTP checks are static (schemas, migrations, grants, IaC, code); CVEs are reported only when verified during the assessment against official advisories or audit output in the repository (unverified → Possible, ≤ 49); unchecked package counts go to Out of Scope.
- **Report filenames use ISO dates** — `[YYYY-MM-DD]_[SHORT-TITLE]_EN.md` (1.x reports keep their names).
- **Current standards editions** — CWE Top 25 (2025), OWASP Top 10:2025, ISO/IEC 27001:2022 Annex A numbering (2013 IDs removed, mapping table added), NIST CSF 2.0 (Govern), CIS Controls v8.1, PCI DSS v4.0.1.
- **Measured-only Security Posture Dashboard**; Risk Matrix removed (superseded by the Remediation Roadmap, bucketed first and ordered by score ÷ effort within each bucket). Availability-only patterns (upload size, GraphQL depth, missing indexes) capped at 49.
- **Scoped activation** — a single snippet or quick question gets an inline answer and an offer to run a full SAR.
- **Context-release rule removed** — replaced by a closing summary (files written, verdict, top 3 findings).

### Added

- Per-finding **Confidence** (Confirmed / Probable / Possible — Possible capped at 49), **CVSS v4.0 vector**, non-weaponized **Attack Scenario**, before/after **Fix diff** (must compile), **How to Verify the Fix**, and **Effort** (S/M/L).
- Report sections: plain-language **Executive Summary** (≤ 5 lines, verdict first), mandatory **Out of Scope & Limitations**, **Remediation Roadmap**, **Registry Snapshot**, **Attack Chains**, optional Mermaid **Data Flow & Trust Boundaries**.
- Optional **SARIF 2.1.0** export on user request — report artifact only.
- **Docker lab (`frameworks/docker-lab.md`)** — when Docker is confirmed, one stack-based suggestion of profiles (sast, nosql, sca, secrets, iac, k8s, db, api, licence; Trivy opt-in only, digest-pinned with compromised 0.69.4–0.69.6 blocked), all images pinned by tag and digest in a versioned `images.lock`. Scanners are one-shot, mount the repo read-only, run with `read_only`, `cap_drop: ALL`, `no-new-privileges`, and no network where possible; every `docker` command needs approval of that exact command. Local DAST (ZAP, Nuclei) lives in a separate compose file and targets only the user's local app container.
- **Local dashboards, one at a time** — SonarQube Community Build and DefectDojo 3.3.300, bound to `127.0.0.1` only. One shared credential (`admin` + a generated 20-character password that meets SonarQube's policy) is created once per machine into `.memory/local/devsecops/credentials.env` by `sar-bootstrap`, applied to every dashboard with scanner/API tokens, never printed or versioned; weak user-chosen passwords are refused; DefectDojo's upstream default secret keys are replaced.
- **NoSQL injection tooling** — njsscan NoSQL rules, the Semgrep MongoDB registry rule, and skill-provided starter Semgrep rules (Mongoose operator injection, `$where`, PyMongo); ZAP rule 40033 only in local DAST. nosqli and NoSQLMap excluded with reasons.
- **Tool ingestion** — results are untrusted evidence, merged by primary CWE + component, and still traced and scored; a *Scope & Methodology (tools run)* table records version, image digest, and result file; optional DefectDojo push with `scan_type` names verified against DefectDojo's parsers.
- New example `examples/docker-lab-assessment.md` (NoSQL operator injection, 83).
- **Project-local tool installs** — Docker lab preferred; CLI tools install into `.memory/local/bin` (Go or release binaries) or `.memory/local/venv` (Semgrep); zefer-cli as a dev dependency; winget/scoop/brew/pipx/uv marked as system installs needing explicit approval. Generated files stay inside the project.
- **Offline-verifiable standard IDs** — CWE lookup table (91 entries, official CWE-1000 names) and MITRE ATT&CK table (30 techniques) in `compliance-standards.md`; IDs outside them are verified in-session or cited by number only.
- **Scoring gaps closed** — base classes for security-control bypass/misclassification (75) and secret exposure to third-party code or containers (70); D1 factor "requires an upstream compromise" (−15), separate from chaining; gates require Confirmed or Probable gating evidence; title ties break by Confidence, then registry id.
- **Non-service targets** — tooling repos, CLIs, plugins, hooks, and IaC count "components" as the surface; endpoint-only metrics become `N/A — no network surface`; the CWE Top 25 matrix allows grouped N/A rows.
- **Consistent evidence handling** — one results location (`.memory/local/devsecops/results/<date>/`); versions and digests from the shared `images.lock` (one section per lab skill); multi-file registry key = first sorted file + `#tag`; fix diffs are syntactically valid and may use `<value from: <command>>` placeholders.
- **Docker lab hardening (from a SAR run on this repository)** — scanners never see `.memory/local/` (empty `tmpfs` over every repository mount); dashboards get per-service env files with only the keys they need and `credentials.env` is never passed to a container; `DD_ALLOWED_HOSTS` restricted to localhost and the in-network proxy; Checkov writes `results/<date>/checkov.json`; the SonarQube first-boot password is no longer a literal in `bootstrap.sh`.
- Docker lab secrets reach curl only through 0600 `-K` config files under `.memory/local/devsecops/curl/` — never argv or pipes (`bootstrap.sh`, `dd-import.sh`). ATT&CK T1528 shown as "Application access token theft" with the official link.

### Fixed

- Example scores recomputed and machine-checked: SQLi comparison 90 vs 60 (was 92 vs 55), full-flow split into an IDOR (83) plus a mitigated missing-guard warning (30), ReDoS fix diff now valid JavaScript, public-bucket evidence derived from IaC (Probable) instead of live probing.

---

## ai-rules [1.1.0] — 2026-10-05

### Changed

- **Lazy project context** — removed the session-start questionnaire; context files are read silently, a single missing field is asked only when a rule needs it (never during read-only work), and name/email are never collected (authorship comes from the VCS configuration).
- **Personal data out of the repository** — `docs/project-context.md` holds project facts only (versioned); developer role/preferences move to `.memory/local/ai-rules/developer.md` (never versioned).
- **Selective `.memory/`** — shared team state under `.memory/<skill>/` stays versioned; only `local/`, `*.local.*` and `*.recovered.json` are ignored (Git/Jujutsu `.memory/.gitignore`, Mercurial, Fossil, Subversion instruction).
- **Optional capabilities** — `frameworks/capabilities.md` suggests a local-only `@carrilloapps/docgraph@1.0.4` (embedding provider pinned to `local`, no remote sources) for documentation search, and `skill-rules@0.3.0` for multi-agent sync. Pinned, official registry only, one at a time with explicit approval, never re-suggested once declined.
- **`docs/elementals.md` updates** only when code elements are created, renamed, or removed, as part of the approved change, and never during a SAR assessment.
- **No extra stop rounds** — documentation language defaults to the user's message language; conflicts with other skills get a one-line note and the more specific rule wins; "declare principles" applies only to Tier 2 changes; session-closing rule removed.
- **Confidence is qualitative** (High/Medium/Low + reason) — numeric percentages removed.
- **Security rules made followable** — secrets are redacted when reported; DB queries require schema/index checks on the touched tables and bounded results; git writes require explicit approval (delegates to the Devil's Advocate gate when installed).
- **Safeguards corrected** — untrusted-input boundary and web-search scoping aligned with Devil's Advocate §6; report-only/bounded-autonomy now list every file the skill writes; creating `AGENTS.md` is a suggestion that needs approval; AI attribution only when the user explicitly asks.
- **docgraph agent mode** — provider pinned to `local`, no remote sources, no pull-on-index; the calling agent reranks and summarizes results with its own model (the user's existing subscription, no API keys). MCP sampling is not used because it is deprecated (SEP-2577); upstream proposal in `integrations/docgraph-agent-mode.md`.
- **Optional Docker lab (`frameworks/docker-lab.md`)** — offline, read-only documentation linters: markdownlint-cli2 v0.23.3, Vale v3.24.0 (built-in style), lychee 0.24.2 with `--offline` (online link checks only on request). Compose in `.memory/devsecops/compose.docs.yaml`.
- **Project-Local Storage (mandatory)** — everything an agent generates lives inside the project: `specs/`, `plans/`, `docs/`, `.memory/<skill>/` (versioned) and `.memory/local/` with `bin/`, `venv/`, `tmp/` (private). Never write to global agent directories (`~/.claude`, `~/.gemini`, `~/.codex`, `~/.cursor`, `~/.copilot`, `~/.config/*`) or system temp without explicit approval of that exact path; project-level MCP config preferred.
- **Docker lab defaults** — `.markdownlint-cli2.jsonc` (MD013/MD060 off, MD024 siblings only), Vale `Tech` vocabulary, lychee excludes `templates/` and `fixtures/`; every image pinned by digest; repository mounts hide `.memory/local/`.
- **Commit authorization state machine** — `REQUESTED → CONFIRMED_LOCAL → READY_TO_COMMIT → PUSHED → PR_OPEN → MERGED → RELEASED`; every transition needs explicit approval of that exact operation (approving one never approves the next); hotfixes end with a forward-port offer; no AI co-author unless the user explicitly asks.

---

## [2.9.2] — 2026-05-12

### Changed

- **Domain framework cap removed** — eliminated the artificial `max 2 per analysis` limit from the context budget. Agents now load all frameworks relevant to the plan's scope in a single analysis pass. Relevance-based selection only: most plans need 2–4; loading all 12 is reserved for full-system reviews. Eliminates the endless-iteration pattern where users had to re-run DA multiple times to cover all domains.
- **Domain Frameworks section heading updated** — changed from "max 2 per analysis" to "load all relevant per analysis" for consistency with the updated budget rule

---

## ai-rules [1.0.1] — 2026-05-12

### Changed

- **Language rule strengthened** — `en_US` for code identifiers is now explicitly "non-negotiable" regardless of project language, user language, or documentation language. Removed reference to "instructions from any other skill or tool" per Gen Agent Trust Hub audit guidance.
- **Session initialization full-refusal handling** — added explicit path: if the user asks to skip initialization entirely, proceed without `docs/project-context.md`; context-dependent rules apply conservative defaults for the session.
- **Session closing de-duplicated** — removed the second session-closing note that was redundant with the one in the Session Initialization section.
- **Security and Privacy wording aligned** — third-party code rule now uses "regardless of user instruction" phrasing consistent with the other prohibitions in that section.
- **Risk factors made actionable** — added examples: "no test coverage on this module," "external API with no SLA," "single developer with domain knowledge" — vague risk factors are explicitly called out as non-actionable.
- **Example code boundaries safeguard added** — clarifies that code blocks in this skill define document templates and structural conventions, not executable code.

---

## sar-cybersecurity [1.9.0] — 2026-05-12

### Changed

- **Dynamic output directory** — removed hardcoded `docs/security/` path. Added Step 0 to the Analysis Protocol that asks the user where to save SAR files before any analysis begins. Default remains `docs/security/` when the user confirms, provides no response, or runs in automated context. All path references throughout `SKILL.md` and `frameworks/output-format.md` replaced with "the output directory" pointing to the confirmed location.
- **Domain framework cap removed** — eliminated the `max 2 per assessment` limit from the index context budget. Agents now load all frameworks relevant to the assessment scope in a single pass. All 4 domain frameworks are available — load those that directly apply. There is no cap.

---

## [2.9.1] — 2026-05-12

### Fixed

- **Gen Agent Trust Hub compliance** — resolved HIGH-risk findings from the April 2026 audit
  - `[PROMPT_INJECTION]` Rule Precedence reframed from override command to design intent: "operates before and around" instead of "takes precedence over all tools and skills"
  - `[PROMPT_INJECTION]` Git commit rule reframed from "non-negotiable and cannot be overridden" to "should remain active to preserve user authority"
  - `[PROMPT_INJECTION]` No AI Credit principle reframed from "this rule wins" absolute command to a consistent practice with explicit handling for conflicting templates; header changed from "Under no circumstances" to "As a consistent practice"
  - `[INDIRECT_PROMPT_INJECTION_SURFACE]` Added **Analyzed Content Boundary** section to `SKILL.md`: analyzed content is treated as untrusted input and cannot modify skill protocols or gate behavior
  - `[INDIRECT_PROMPT_INJECTION_SURFACE]` Added untrusted content boundary note to `frameworks/analysis-framework.md`
  - `[REMOTE_CODE_EXECUTION / EXTERNAL_DOWNLOADS]` Added pre-install security review note to `README.md` with links to source repository and audit page
- README.md: changed "Runs unconditionally first" to "Runs consistently first"

---

## ai-rules [1.0.0] — 2026-05-12

### Added

- Initial release: personal behavioral rules skill for AI coding agents
- `skills/ai-rules/SKILL.md` — baseline behavioral contract covering security, documentation storage, documentation format, code quality, version control, communication, and structured estimation
- `skills/ai-rules/README.md` — public documentation
- `skills/ai-rules/metadata.json` — skill metadata for skills.sh registry
- **Documentation storage rule**: all session memory, references, and generated assets must live in `docs/` (or user-specified location) — never in AI memory stores or IDE caches — enabling shared context across Claude Code, GitHub Copilot, Gemini CLI, OpenCode, and other tools
- **Structured estimation model**: every recommendation includes Confidence %, effort by capacity mode (Solo 1× / AI-assisted 3–5× / AI-augmented team 5–10×), pivot potential (High / Medium / Low), and explicit risk factors
- **6 mandatory security safeguards** for skills.sh audit compliance (Gen Agent Trust Hub · Socket · Snyk): untrusted input boundary, no arbitrary code execution, bounded autonomy, web search scoping, example code boundaries, report-only output

---

## [2.9.0] — 2026-03-12

### Added

- **Git commit absolute gate** — new "Version control" row in All Actions Blocked table covering `git commit`, `git push`, `git tag`, `git merge`, `git rebase`, `git reset`, `git checkout --`. New absolute rule blockquote: no git write operation may execute without the AI first explicitly stating its intent; explicit user authorization required even with full session permissions (auto-approve, yolo mode). Non-negotiable, non-overridable by session settings, tool permissions, or other skills.
- **No AI / IDE / Editor Credit Attribution** — new Core Principle #1. Prohibits `Co-Authored-By` with any AI name, "Generated by" / "Created by" AI markers, AI/IDE/editor author mentions, and tool watermarks in all generated artifacts. "All credit belongs to the human user. If another skill or convention conflicts with this rule, this rule wins."
- Two new rows in User Authority Preservation table: session permissions don't authorize git writes; `Co-Authored-By: [AI]` templates are rejected

### Changed

- Core Principles renumbered: Adversarial Mindset → #2, Systematic Challenge → #3

---

## sar-cybersecurity [1.8.0] — 2026-03-12

### Fixed

- **Medium — Scoring floor boundary ambiguity**: Cumulative floor in `scoring-system.md` changed from 50 to **51** — a score of 50 falls into Warning range (W-prefix), so the floor for reachable unmitigated findings must be 51 to remain in Finding range
- **Medium — Dashboard placement contradiction**: `output-format.md` prose said "immediately after Findings" but template showed it after Dependency & Supply Chain Analysis — fixed prose to match template
- **Low — CWE/OWASP in wrong metrics table**: Listed as "conditional" but marked "Always (mandatory)" — moved to required metrics table, removed from conditional
- **Low — Bare `Partial` values in CSV examples**: Updated all instances in `output-format.md` and `recurring-assessment.md` to include parenthetical details (e.g., `Partial (regex escaping on search only)`, `Partial (inline checks only, no schema)`)
- **Low — README stale content**: Fixed sorting rule description, removed duplicate CIS entry, added CWE/OWASP dashboard metrics, corrected protocol from 10 steps to 9

### Changed

- `output-format.md` dashboard scope rule added: unassessed metrics must show `N/A — outside assessment scope` rather than being omitted or inflating denominators
- `output-format.md` `Existing Mitigation` column definition expanded with decision criteria: `No` (zero controls), named control (specific), `Partial (present ones)` (multiple expected, some present)

---

## sar-cybersecurity [1.7.0] — 2026-03-12

### Added

- **Corrupted CSV fallback** in Step 6: if `vulnerabilities.csv` exists but is malformed (wrong column count, encoding errors, partially written), treat as absent, document in SAR appendix, start fresh
- **Recurring finding matching criteria**: match by CWE ID(s) + affected component; if uncertain, treat as new and note potential overlap
- **Step 8 explicit operations**: add new with `Pending`, update recurring scores, preserve team-managed fields, never delete rows — plus CSV validation sub-step (11 columns, no duplicate IDs, team fields preserved, sort order correct)
- **Sequential assessments exception** in Step 9: context release applies only after last assessment when scope is split into multiple assessments in same conversation
- **Bilingual opt-out** in Quick Reference: `Generate both EN + ES files` now says "unless user requests single-language output"
- **CWE staleness fallback** in `dependency-supply-chain.md`: when web search is unavailable, note in SAR appendix that CWE Top 25 list was not verified against current year's publication
- **Cross-reference budget annotations** in `injection-patterns.md`, `storage-exfiltration.md`, and `dependency-supply-chain.md`: all cross-reference links now note `*(domain framework — counts toward budget)*`

### Changed

- `compliance-standards.md` header updated: load only when full expanded reference or lesser-known standards are needed — agent can map well-known standards from training knowledge without loading this file
- SKILL.md constraint 3 sorting rule: "sorted by status group then Score descending" (was "Sort by Score descending")
- `output-format.md` generation rule 2: changed from "Sort by Score descending" to "Sort by status group, then Score descending" — open findings first, then open warnings, then mitigated entries

---

## sar-cybersecurity [1.6.0] — 2026-03-12

### Added

- **Vulnerabilities Registry** (`vulnerabilities.csv`) — persistent CSV registry with 11 columns, status lifecycle (`Pending → In Development → Processing → In QA → In Staging → Mitigated`), agent-controlled vs team-controlled fields, group-then-sort ordering, and ID continuity rules. Full schema and generation rules in `output-format.md`
- **Mitigated Findings section** — mandatory SAR section when CSV contains mitigated entries: `[MITIGATED]` label, detection/mitigation dates, original SAR link, ordered by mitigation date descending
- **Worst-finding title rule** — SAR filename and heading must reflect the highest-scoring vulnerability (SCREAMING-KEBAB-CASE, max 50 chars). Title derivation table with 7 examples in `output-format.md`
- **Dependency & Supply Chain Analysis** as mandatory Step 2 — `dependency-supply-chain.md` promoted to protocol file (free to load). Audits all packages (direct + transitive) against NVD, GitHub Advisories, OSV; evaluates integrated skills/plugins; maps to CWE/MITRE Top 25, OWASP Top 10 (A06, A08), SANS/CIS Top 20 (CIS 2, 7, 16, 18)
- **CWE ID mandatory for every finding** — Step 5 (Score and Document) now requires CWE identifier(s) cross-referenced against CWE/MITRE Top 25
- **Context release protocol** (Step 9) — after SAR and CSV are written, agent discards assessment context; generated files become single source of truth; exception for explicit continuation requests
- **Operating Constraints expanded** from 9 to 12: added #2 (Worst-finding title), #3 (Vulnerabilities registry), #12 (Context release after completion)
- **Recurring assessment example** (`examples/recurring-assessment.md`) — second SAR on same project showing mitigated finding (F01), recurring entries, CSV update flow
- CWE/MITRE Top 25 and OWASP Top 10 Alignment added as required dashboard metrics
- Dependency Vulnerability Rate, Version Pinning Rate, Skills/Plugins Security Rate added as conditional dashboard metrics
- New Quick Reference rows: SAR title from worst finding, update `vulnerabilities.csv`, overwrite team-managed fields (never), show mitigated findings, delete CSV rows (never), retain context after SAR (never), finding without CWE (never), skip dependency audit (never), skip skills evaluation (never)
- `compliance-standards.md`: added CWE/MITRE Top 25 to baseline table + expanded reference + 4 new selection guide rows (vulnerable dependency, supply chain integrity, excessive permissions, code-level findings)
- `metadata.json` keywords expanded: `owasp-top-10`, `cwe-top-25`, `sans-top-20`, `cis-controls`, `supply-chain-security`, `dependency-audit`

### Changed

- **Analysis Protocol restructured from 5 steps to 9 steps**: (1) Map Entry Points → (2) Audit Dependencies → (3) Trace Execution Flows → (4) Evaluate Controls → (5) Score and Document → (6) Read Vulnerabilities Registry → (7) Write Output Files → (8) Update Vulnerabilities Registry → (9) Release Context
- CIS Controls description updated from "formerly SANS Top 20" to "SANS Top 20, now CIS Controls v8 with 18 control categories"
- SKILL.md Index: `compliance-standards.md` description updated to "22 baseline standards"; `dependency-supply-chain.md` added to protocol files section
- README.md rewritten: 10-step workflow diagram, progressive context loading updated (3 protocol files), output section includes `vulnerabilities.csv`, edge cases expanded to 10

---

## sar-cybersecurity [1.5.0] — 2026-03-09

### Added

- **Security Posture Dashboard** — mandatory section in every SAR report with quantitative coverage metrics that serve as measurable OKRs
  - 13 required metrics: Assessment Coverage, Secure Surface, Critical/High/Medium Exposure, Auth Coverage, Input Validation Coverage, Parameterized Query Rate, Secrets Hygiene, Encryption Coverage, Compliance Alignment, Mean Finding Score, Remediation Priority Index
  - 6 conditional metrics: Cloud Storage Secure Rate, CORS Policy Compliance, Rate Limiting Coverage, Logging & Monitoring Rate, Dependency Vulnerability Rate, RBAC Enforcement Rate
  - Severity Distribution breakdown table (count + % of findings + % of surface per severity level)
  - Rating thresholds (✅ Good ≥ 80%, ⚠️ Needs improvement 50–79%, 🟥 Critical < 50%)
  - All metrics require both percentage and raw count — e.g., `62% (30/48)`
- Updated `output-format.md` with full dashboard specification, presentation format, and rating system
- Updated SKILL.md Step 5 to reference dashboard generation as mandatory
- Updated README.md with dashboard documentation and feature highlight

---

## sar-cybersecurity [1.4.0] — 2026-03-09

### Changed

- **Structural rewrite for Socket audit compliance**: Replaced all pseudocode `text` blocks in 5 flagged example files with narrative markdown (bullet lists + inline text). Previous v1.3.0 approach (token-level replacement) was insufficient — Socket performs semantic analysis, not keyword matching.
  - `nosql-operator-injection.md` — removed code block with database query methods and operator syntax; replaced Scenario with **Finding location** bullets referencing `injection-patterns.md`; abstracted Assessment Trace (no ORM/ODM method names)
  - `regex-redos-injection.md` — removed code block with regex constructor and database regex queries; replaced with narrative bullets; Evidence converted to inline text
  - `secrets-in-source-control.md` — removed all 3 code blocks (file discovery, sensitive content patterns, hardcoded credentials); replaced with narrative markdown; eliminated environment file names and connection string patterns
  - `mass-assignment.md` — removed code block with ORM update method, request body passthrough, and schema field listing; replaced Scenario and Assessment Trace with generic descriptions referencing framework tables
  - `public-cloud-bucket.md` — removed both code blocks (IaC pattern and bucket policy); eliminated cloud-provider-specific syntax; replaced with narrative bullets
- **README.md Edge Cases sanitized**: Replaced inline code references with natural language in NoSQL Operator Injection, Public Cloud Storage Bucket, and Secrets in Source Control sections; cleaned directory tree annotation
- **SKILL.md index table**: Replaced ORM-specific method reference with generic description

### Fixed

- `mass-assignment.md` Scenario section was not applied in v1.3.0 due to a silent replacement failure — now fully rewritten

---

## sar-cybersecurity [1.3.0] — 2026-03-09

### Changed

- **Socket security audit compliance** (superseded by v1.4.0): Initial attempt at sanitizing 5 example files — replaced specific operator syntax with natural language equivalents. Approach proved insufficient as Socket scanner uses semantic analysis rather than keyword detection.
  - `nosql-operator-injection.md` — replaced MongoDB operator syntax with natural language descriptions
  - `secrets-in-source-control.md` — replaced secret variable names with generic placeholders
  - `mass-assignment.md` — replaced privilege escalation payloads with descriptive text
  - `regex-redos-injection.md` — replaced regex attack patterns and MongoDB regex operator references
  - `public-cloud-bucket.md` — replaced Terraform/AWS policy syntax with natural language
- **Preventive sanitization**: Cleaned narrative-context patterns in `README.md` and `scoring-system.md`
- Updated SKILL.md index table (removed `$ne` operator syntax from description)

---

## sar-cybersecurity [1.2.0] — 2026-03-09

### Added

- **Confidentiality Primacy** principle in scoring system — data exfiltration always scores higher than availability-only
- 4 impact classifications: data exfiltration, integrity violation, dual-vector, availability-only
- Availability-only gate: vulnerabilities with zero data exposure capped at 49 (Warning max)
- Operating Constraint #9 (Confidentiality primacy) in SKILL.md
- Impact classification as first step in Step 4 analysis protocol

### Changed

- Rewrote `regex-redos-injection.md` — score driven by exfiltration vector, ReDoS noted as secondary
- Updated `injection-patterns.md` Regex section: split patterns by Primary Impact
- Updated `scoring-system.md` comparative table with exfiltration-aware scores

---

## sar-cybersecurity [1.1.0] — 2026-03-09

### Added

- **Multi-factor scoring system** with 3 dimensions: Exploitation Complexity, Impact Scope, Data Sensitivity
- Mandatory Score Justification field in all findings
- Comparative Scoring Reference table in `scoring-system.md`
- Operating Constraint #6 (Differentiated scoring) in SKILL.md
- `examples/sql-injection-comparison.md` — same vuln type with scores 92 vs 55

### Changed

- Rewrote `scoring-system.md` with multi-factor scoring methodology
- Updated `output-format.md` with Score Justification as mandatory field
- Expanded Steps 3 and 4 in SKILL.md analysis protocol

---

## sar-cybersecurity [1.0.0] — 2026-03-09

### Added

- **Initial release**: Automated Security Assessment Report (SAR) generator for AI coding agents — deep cybersecurity analysis mapped to 20+ compliance standards (ISO 27001, NIST, OWASP, PCI-DSS, GDPR, MITRE ATT&CK)
- `skills/sar-cybersecurity/SKILL.md` — core skill definition (~170 lines) with 7 operating constraints, progressive context loading via Index section with context budget rules, 5-step analysis protocol, bounded expert scope, and full skills.sh security audit compliance
- `skills/sar-cybersecurity/metadata.json` — skill metadata for skills.sh registry
- `skills/sar-cybersecurity/README.md` — comprehensive documentation with install commands, compatible agents table, workflow diagrams, edge cases, and full feature reference
- **Protocol files** (free to load):
  - `frameworks/output-format.md` — SAR output specification (directory, file naming, document structure)
  - `frameworks/scoring-system.md` — criticality scoring system (0–100) with decision flow
- **Domain frameworks** (max 2 per assessment):
  - `frameworks/compliance-standards.md` — 20 baseline compliance standards with expanded descriptions and selection guide
  - `frameworks/database-access-protocol.md` — SQL, NoSQL, Redis inspection protocol with bounded queries and index verification
  - `frameworks/injection-patterns.md` — 6 injection families: SQL, NoSQL Operator, Regex/ReDoS, Mass Assignment, GraphQL, ORM/ODM
  - `frameworks/storage-exfiltration.md` — 7 data leakage categories: cloud storage, secrets, file uploads, logging, message queues, CDN, IaC
- **Examples** (8 canonical edge cases):
  - `examples/unreachable-vulnerability.md` — dead code with SQL injection (score 35)
  - `examples/runtime-validation.md` — inline validation without formal structure (score 38)
  - `examples/full-flow-evaluation.md` — infrastructure-layer auth masking insecure code (score 30)
  - `examples/nosql-operator-injection.md` — MongoDB `$ne` injection, 15 endpoints (score 92)
  - `examples/regex-redos-injection.md` — ReDoS + data exfiltration, 23 occurrences (score 82)
  - `examples/mass-assignment.md` — IDOR + privilege escalation via unfiltered body (score 88)
  - `examples/public-cloud-bucket.md` — public S3 with PII, backups, and secrets (score 97)
  - `examples/secrets-in-source-control.md` — 12 secrets across 6 files, 14 months (score 93)
- All domain frameworks with code include `⚠️ Reference patterns only` boundary notes; all examples include `⚠️ Example only` boundary notes — required for skills.sh security audit compliance (Gen Agent Trust Hub, Socket, Snyk)

### Changed (repository-level)

- `.ai-context.md` created — AI agent safety context with skills.sh scanner documentation, mandatory safeguards checklist, current audit results table, and new skill onboarding guide
- `AGENTS.md` — added skills.sh Security Audit Compliance section with scanner table, 6 required safeguards, and devils-advocate gold standard reference; skills table expanded to include SAR Cybersecurity
- `.github/copilot-instructions.md` — added SAR Cybersecurity skill reference and skills.sh security audit compliance cross-reference
- Root `README.md` rewritten for professional monorepo presentation: correct badges, comprehensive skills table, detailed skill descriptions for both Devil's Advocate and SAR Cybersecurity, "How Skills Work Together" Mermaid diagram, compatible agents table, repository structure tree, quality gate, and contributing/security/license sections

---

## [2.8.8] — 2026-02-21

### Fixed

- **Low — Quality Standards table incomplete stale patterns**: `CONTRIBUTING.md` "No stale text" row now explicitly lists `carrilloapps/devils-advocate` alongside `with implementation` and `14-dimension` — matching all 3 patterns enforced by `validate.sh` Check 6

---

## [2.8.7] — 2026-02-21

### Fixed

- **Low — Contributor table missing DA gate files**: `CONTRIBUTING.md` "What Can I Contribute?" table now includes `AGENTS.md` and `copilot-instructions.md` as ⚠️ Discuss first
- **Low — PR template core protocol section missing DA gate files**: "If modifying core protocol files" section now explicitly covers `AGENTS.md` and `copilot-instructions.md` with the same issue-first requirement

---

## [2.8.6] — 2026-02-21

### Fixed

- **Low — PR template missing version stamp checkbox**: "If adding or modifying an example" section now includes `**Skill version**: X.Y.Z present and matches current SKILL.md version` — prevents Check 8 CI surprises for contributors

---

## [2.8.5] — 2026-02-21

### Fixed

- **Medium — PR template out of sync with quality standards**: added `carrilloapps/devils-advocate` stale pattern, en_US identifiers check, and `validate.sh` checkbox to "All PRs" section
- **Low — PR template Type of Change missing DA gate files**: `📦 Project infrastructure` type now explicitly includes `AGENTS.md` and `copilot-instructions.md`
- **Low — CONTRIBUTING.md not flagging DA gate files as special**: "Improving Existing Files" now warns against weakening references to `SKILL.md` in `AGENTS.md` / `copilot-instructions.md`

---

## [2.8.4] — 2026-02-21

### Fixed

- **Medium — False documentation claim**: `copilot-instructions.md` claimed "branch protection enforced" — replaced with actionable instruction to enable it in GitHub Settings
- **Medium — Missing AGENTS.md in repo tree**: root `README.md` repository structure tree now shows `AGENTS.md` with its purpose
- **Medium — Release checklist incomplete**: `CONTRIBUTING.md` step 3 now explicitly reminds maintainers to update the check count `(N checks)` in root `README.md` when checks are added/removed
- **Low — Quality Standards table missing Check 13**: `CONTRIBUTING.md` quality table now includes `SKILL.md token budget` row documenting the 8K-token / 32K-char CI enforcement
- **Low — AGENTS.md missing Conventions section**: added `## Conventions` (Conventional Commits, en_US, branch) to match `copilot-instructions.md` — all AI agents now receive the same contributor conventions regardless of which context file they load

---

## [2.8.3] — 2026-02-21

### Fixed

- **High — CI scope gap**: `validate.sh` Checks 2 (fence balance) and 6 (stale text) now scan `$REPO_ROOT` instead of `$ROOT` — root `README.md`, `CHANGELOG.md`, and all `.github/` files are now included in every CI run
- **High — Missing agent context**: Added `AGENTS.md` (repo root) and `.github/copilot-instructions.md` — contributors using GitHub Copilot, Claude Code, Cursor, Windsurf, and compatible agents now auto-load the Devil's Advocate skill when working on this repository
- **Medium — Stale token count**: `CONTRIBUTING.md` token estimate updated from ~7,068 to ~7,215 tokens (28,859 bytes)
- **Medium — Discovery gap**: `metadata.json` now includes `keywords` field for `npx skills find` search indexing
- **Low — Domain count update path**: `CONTRIBUTING.md` new framework checklist now lists all three locations where the domain count must be updated

### Added

- `validate.sh` **Check 13**: SKILL.md token budget enforcement — fails if file exceeds 32,000 chars (~8,000 tokens)
- `validate.sh` **Check 7**: `AGENTS.md` and `.github/copilot-instructions.md` added to required files list
- Total checks: 46 → **49**

---

## [2.8.2] — 2026-02-21

### Fixed

- Root `README.md` check count corrected: `43 checks` → `46 checks`
- `metadata.json` `date` field removed — was hardcoded and stale; not required by skills.sh
- `CONTRIBUTING.md` release checklist step 3 updated: added `metadata.json`, root `README.md` badge, and correct file paths to cascade list
- `CONTRIBUTING.md` release checklist step 6 updated: added `git tag vX.Y.Z` and `--tags` to push command

---

## [2.8.1] — 2026-02-21

### Fixed

- `.gitignore` `skills/` pattern removed — was silently ignoring all future skills in the monorepo; added inline explanation for OpenClaw users
- `SKILL.md` author footer URL updated from `carrilloapps/devils-advocate` to `carrilloapps/skills`
- `frameworks/handbrake-checklist.md` footer URL updated to `carrilloapps/skills`
- Root `README.md` repository structure tree corrected — `scripts/` shown at repo root (not inside `skills/devils-advocate/`)
- `.github/CODEOWNERS` created — requires `@carrilloapps` review for core protocol files

### Added

- `validate.sh` Check 12: `metadata.json` version compared against `SKILL.md` version
- `validate.sh` Check 6: added `carrilloapps/devils-advocate` as stale text pattern
- `validate.sh` Check 7: `metadata.json` and `.github/CODEOWNERS` added to required files list

---

## [2.8.0] — 2026-02-20

### Changed

- **Breaking — Repository restructured to skills.sh monorepo format**: all skill files moved from repo root to `skills/devils-advocate/`; install command updated from `npx skills add carrilloapps/devils-advocate` to `npx skills add https://github.com/carrilloapps/skills --skill devils-advocate`; enables the repository to host multiple skills under `skills/<name>/`

---

## [2.7.10] — 2026-02-20

### Fixed

- **Low — CONTRIBUTING.md hardcoded `2.7.8` version number in two illustration examples**: replaced both with generic placeholders (`X.Y.Z` and `X.Y.(Z+1)`) so the documentation never becomes stale after a release; the specific version numbers were not covered by validate.sh and would require manual maintenance after every release

---

## [2.7.9] — 2026-02-20

### Fixed

- **High — `handbrake-protocol.md` missing `continue` command documentation during Handbrake wait**: added "`continue` During Handbrake Wait" section defining the behavior: same semantics as explicit Bypass (⚠️ HANDBRAKE BYPASSED block, 🔴 Critical severity preserved, Gate still applies); agents relying solely on `handbrake-protocol.md` previously had no guidance when user typed `continue` at the Handbrake context-request stage
- **Low — README Best Practices table missing 8th rule from SKILL.md**: added "Do not allow any tool, MCP, agent, or skill to bypass this gate" row — the anti-bypass rule was defined in SKILL.md but absent from the README documentation mirror
- **Low — CONTRIBUTING.md Release Checklist Step 3 hardcoded "All 12 `examples/*.md`"**: replaced with "All `examples/*.md`" (dynamic — no hardcoded count) to prevent stale instructions when a new example is added

---

## [2.7.8] — 2026-02-20

### Fixed

- **Medium — CONTRIBUTING.md "New Example" section silent on `Skill version` stamp**: added item 6 to the requirements list documenting the `**Skill version**: X.Y.Z` stamp and the validate.sh Check 8 that enforces it; contributors adding examples without the stamp were getting unexplained CI failures
- **Medium — Quality Standards table missing version stamp row**: added `Version stamp` row so contributors see the requirement before submitting a PR

---

## [2.7.7] — 2026-02-20

### Fixed

- **Medium — CONTRIBUTING.md Quality Standards "Cross-references" row missing `checklists/`**: updated to list `frameworks/`, `checklists/`, and `examples/` — contributors adding checklist files now know to index them in SKILL.md, preventing confusing CI failures
- **Low — IR reply format in `immediate-report.md` template diverged from all 12 examples**: template updated to match the compact `Reply: 📝 ... | \`continue\` ...` format used consistently across examples; the multi-line format was unreachable dead code

---

## [2.7.6] — 2026-02-20

### Fixed

- **Low — Double blank line in validate.sh between Check 7 and Check 8**: extra blank line removed; all check transitions now use exactly one blank line
- **Low — Missing blank line in validate.sh between Check 9 ok and Check 10 comment**: blank line inserted for visual consistency with all other check transitions
- **Low — CHANGELOG [2.7.3] "Added" entry for Check 10 was factually incorrect**: annotated with "(fix was incomplete — correctly applied in 2.7.4)"

---

## [2.7.5] — 2026-02-20

### Fixed

- **Low — validate.sh `head()` shadowed system `head` binary**: renamed function to `section()` — eliminates silent collision if a contributor adds `| head -N` to the script
- **Low — Check 4 emitted `ok` before canonical source checks ran**: moved `ok` call to after both example and canonical checks complete — CI output no longer shows `✅` followed by `❌` within the same check
- **Low — Check 10 section label inconsistent with ok-message**: `head "Framework index coverage"` updated to `section "Framework and checklist index coverage"` to match the extended scope

---

## [2.7.4] — 2026-02-20

### Fixed

- **Medium — validate.sh Check 10 missing `checklists/` coverage**: CHANGELOG 2.7.3 stated the fix was applied, but code only iterated `frameworks/`; added `checklists/` to the Check 10 glob — both `frameworks/*.md` and `checklists/*.md` on disk are now verified against SKILL.md Index
- **Low — CHANGELOG [2.7.2] Check 1 description inaccurate**: described an intermediate implementation that was superseded by the final SIGPIPE-free fix

---

## [2.7.3] — 2026-02-20

### Fixed

- **High — `appleboy/ssh-action@v1.0.0` mutable tag in cicd-pipeline-review.md**: comment in "corrected" YAML example still referenced a floating semver tag; updated comment to warn that SHA-pinning is required before use
- **Medium — `immediate-report.md` missing `---` separator before General Analysis template**: Performance template block was not visually separated from General Analysis section; `---` added
- **Medium — `[Unreleased]` block mis-positioned in CHANGELOG.md**: appeared after `[2.7.2]` instead of as first section; moved to top per Keep a Changelog spec
- **Medium — `validate.yml` missing top-level `permissions: {}`**: deny-all baseline not set; added `permissions: {}` between `on:` and `jobs:` blocks
- **Low — IR Flash Format domain list truncated**: `[Architecture / Data / Security / Code / Product / UX / Strategy / ...]` replaced with full 12-domain list

### Added

- validate.sh **Check 10** extended to cover `checklists/` directory in addition to `frameworks/` *(fix was incomplete — correctly applied in 2.7.4)*
- Check 4 canonical source check: verifies `continue` wording in `SKILL.md` and `output-format.md`

---

## [2.7.2] — 2026-02-20

### Fixed

- **High — validate.sh Check 1 gawk-specific**: replaced 3-arg `match()` (gawk extension) with `grep -m1 '^## \[[0-9]'` — matches only versioned headers (digit after bracket), exits cleanly after first match, no SIGPIPE under `set -euo pipefail`; compatible with macOS default awk and all POSIX environments
- **High — README.md version badge stale at 2.7.0**: updated to `2.7.2`; added validate.sh Check 11 to detect badge/version drift going forward
- **High — Handbrake Output Block missing Performance domain**: added `/ Performance` to closed domain list in `handbrake-protocol.md` Output Block template
- **High — Check 9 did not cover `checklists/`**: broadened regex from `frameworks/...` to `(frameworks|checklists)/...` — risk-checklist.md and questioning-checklist.md now covered
- **Medium — validate.yml missing `permissions: contents: read`**: added minimal-permission block at job level per `version-control.md` GitHub Actions guidance
- **Medium — Check 8 silent pass on missing stamp**: added `else: fail()` branch — examples without a `Skill version` line now correctly fail CI

### Added

- validate.sh **Check 10**: iterates `frameworks/*.md` on disk and verifies each file appears in SKILL.md Index — catches unindexed new frameworks
- validate.sh **Check 11**: verifies README.md version badge matches SKILL.md version — catches badge drift on every version bump
- Standard framework headers (`> **Role** / **Load when** / **Always paired with**`) added to `performance.md` and `security-stride.md`

---

## [2.7.1] — 2026-02-20

### Fixed

- **High — validate.sh Check 1 broken**: grep -m1 returned only [Unreleased] before -v filter; fixed to grep | grep -v Unreleased | head -1 so CHANGELOG_VER correctly resolves to latest released version
- **High — validate.sh Check 2 FENCE_ISSUES never counted**: FENCE_ISSUES was referenced but never initialized or incremented; added FENCE_ISSUES=0 init and ((FENCE_ISSUES++)) increment so fence-balance failures now correctly set non-zero count
- **High — CHANGELOG.md had UTF-8 BOM**: bytes xEF 0xBB 0xBF present since initial write; stripped to plain UTF-8 without BOM
- **High — Performance domain missing from Handbrake escalation map**: added Performance bottlenecks, scalability, resource limits, N+1 queries row with Senior Developer / Tech Lead as responsible role
- **High — Performance domain missing from IR context templates**: added ### ⚡ Performance — Bottlenecks / Scalability / Resource Limits template (6 questions) to immediate-report.md; updated template count from 13 → 14
- **Medium — actions/checkout mutable tag in CI**: SHA-pinned to `11bd71901bbe5b1630ceea73d27597364c9af683` (v4.2.2) per `version-control.md` guidance
- **Medium — building-protocol.md described as unconditionally free**: CONTRIBUTING.md now correctly states it is conditionally free (loaded with code, skipped for pure text/strategy)

### Added

- validate.sh check 9 (retroactively documented): verifies all framework files referenced in SKILL.md Index exist on disk
- CONTRIBUTING.md: 8K token budget warning for SKILL.md — contributors must not add content without delegating equivalent content to framework files

---

## [2.7.0] — 2026-02-20

### Added

- `frameworks/handbrake-checklist.md` — new 8-question rapid-sweep checklist to determine if Handbrake should activate; includes minimum steps and bypass disclosure template
- `.gitattributes` — enforces LF line endings on `scripts/validate.sh` and GitHub Actions workflows for cross-platform compatibility
- `.github/workflows/validate.yml` — GitHub Actions CI: runs `bash scripts/validate.sh` on every push and PR to `main`

### Fixed

- **Critical — IR `continue` vs Handbrake conflict**: `continue` at the IR stage now explicitly documented to skip IR context collection only, NOT bypass the Handbrake; if finding is 🔴 Critical the Handbrake still activates as the next mandatory step (`immediate-report.md`, `SKILL.md`)
- **High — validate.sh CRLF line endings**: re-saved with LF only; Windows contributors can now run `bash scripts/validate.sh` in Git Bash without `$'\r': command not found` errors
- **High — example version stamps stale**: all 12 examples updated from `v2.4.1` to current `v2.6.9`; new validate.sh check 8 enforces version stamp consistency going forward
- **High — premortem.md budget conflict**: reclassified from Domain Framework (counted against 2-framework budget) to Protocol File (free); Handbrake Step 6 mandates it, so it was self-defeating to count it; domain count updated 13 → 12 in `SKILL.md`, `CONTRIBUTING.md`
- **High — "bypass is recorded" wording**: replaced with "visible in the conversation history" in `SKILL.md` Gate Protocol and `handbrake-protocol.md` — the previous wording implied non-existent persistence
- **Medium — duplicate scope guard**: removed shorter/incomplete scope guard from `Rule Precedence` section; single authoritative definition remains in `Automatic Trigger Detection` with full Disambiguation rule
- **Medium — IR+Handbrake merge cross-reference missing**: added merge note to `handbrake-protocol.md` Output Block section pointing to `immediate-report.md` for combined format
- **Medium — `handbrake-checklist.md` referenced but missing**: created the file; added to SKILL.md Index under Protocol Files

### Changed

- **SKILL.md slimmed** (~25% size reduction): removed duplicated Handbrake flow diagram, role escalation table, IR flash format template, and Building Protocol tables — these are all defined authoritatively in their dedicated framework files; SKILL.md now contains minimal summaries with explicit load references
- `premortem.md` moved from Domain Frameworks section to Protocol Files section in SKILL.md Index
- `CONTRIBUTING.md`: domain count updated to 12; `premortem.md` added to protocol files exclusion list
- validate.sh check 7: added `.gitattributes` and `.github/workflows/validate.yml` to required files list
- validate.sh: added check 8 — example version stamps must match `SKILL.md` version

---

## [2.6.9] — 2026-02-20

### Added

- 6 new examples covering all remaining major domains: Product/PM, Data Pipeline, CI/CD Pipeline, Vendor/Strategy, UX/Checkout, Performance
- `README.md` — public project documentation for GitHub and skill.sh
- `LICENSE` — MIT license
- `CONTRIBUTING.md` — contributor guide with quality standards and PR process
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1
- `CHANGELOG.md` — version history (this file)
- `SECURITY.md` — vulnerability reporting policy
- `.gitignore` — standard ignores for OS, editor, and Node tooling
- `.github/ISSUE_TEMPLATE/` — bug report and feature request YAML templates
- `.github/PULL_REQUEST_TEMPLATE.md` — structured PR checklist

---

## [2.6.8] — 2026-02-20

### Added

- `frameworks/version-control.md` — new domain framework: platform detection (GitHub/GitLab/generic), branching strategy, force push & history rewriting, secrets-in-repo remediation, PR/MR workflow, branch protection rules, GitHub Actions security, GitLab CI/CD variables, access control, tag & release management, monorepo/polyrepo trade-offs
- `examples/version-control-review.md` — full protocol stack: leaked DB credentials + force push to main → ⚡ IR + 🛑 Multi-role Handbrake + git filter-repo remediation plan
- Version Control domain added to `handbrake-protocol.md` (Role→Escalation Map + Context Question Template)
- Version Control Context Request Template added to `immediate-report.md`
- Version Control added to IR domain list, Handbrake escalation table, trigger table, and "When to Use" in `SKILL.md`
- Developer/DevOps row added to "When to Use This Skill" table

---

## [2.6.7] — 2026-02-20

### Fixed

- Missing `---` separator before `## Handbrake Bypass` section in `handbrake-protocol.md` (accidentally removed during v2.6.6 restructuring)

---

## [2.6.6] — 2026-02-20

### Added

- `examples/security-review.md` — JWT authentication audit: STRIDE analysis, AppSec Handbrake, Building Protocol Critical violation (hardcoded secret in git)
- `examples/ai-context-review.md` — AI Optimization example: AGENTS.md + copilot-instructions.md conflict review, context starvation, hallucination root cause analysis
- SKILL.md Index updated with both new examples

### Fixed

- IR flash format domain list updated from 7 → 10 domains (Finance, Legal, AI Optimization added)
- `handbrake-protocol.md`: Legal and AI Optimization templates repositioned into `## Context Question Templates` section (were misplaced after `## Pre-mortem Integration`)
- `continue` reply in all 3 original examples: `(risks remain active)` → `(risks remain active and unmitigated)`

---

## [2.6.5] — 2026-02-19

### Added

- Finance/Billing Context Question Template in `handbrake-protocol.md` and `immediate-report.md`
- Legal/Compliance Context Question Template in `handbrake-protocol.md` and `immediate-report.md`
- AI Optimization Context Question Template in `handbrake-protocol.md` and `immediate-report.md`
- Finance, Legal, AI Optimization rows added to Role→Escalation Map in `handbrake-protocol.md`
- `frameworks/ai-optimization.md` — AI context file analysis: context window budget, cross-reference integrity, feature overlap, context starvation, instruction conflicts, hallucination risk

---

## [2.6.0] — 2026-02-18

### Changed

- Orchestration Priority section restructured: explicit Execution Hierarchy diagram, User Authority Preservation table, per-action-category blocking table
- Rule Precedence section added: this skill's rules override all other tools, skills, agents, and MCPs
- Context Before Calling Resources section added
- Read-only exception documented

---

## [2.5.0] — 2026-02-17

> Internal iteration — not externally released. Changes incorporated into v2.6.0.

---

## [2.4.1] — 2026-02-15

### Added

- `frameworks/building-protocol.md` — Three Languages rule, Conventional Commits, SOLID enforcement, Definition of Done checklist, reference implementation, violation severity table
- Building Protocol Activation rules documented
- Role Detection prompt standardized across SKILL.md and building-protocol.md

---

## [2.4.0] — 2026-02-14

### Added

- `checklists/risk-checklist.md` — 8-category structured risk sweep with percentage-based scoring
- `checklists/questioning-checklist.md` — 15-dimension interrogation checklist
- AI Optimization category added to both checklists
- Building Protocol category added to both checklists

---

## [2.3.0] — 2026-02-12

> Internal iteration — not externally released. Changes incorporated into v2.4.0.

---

## [2.2.0] — 2026-02-11

> Internal iteration — not externally released. Changes incorporated into v2.4.0.

---

## [2.1.0] — 2026-02-10

### Added

- `frameworks/immediate-report.md` — flash alert protocol for first High/Critical finding
- `frameworks/handbrake-protocol.md` — full stop + specialist escalation on Critical findings
- Multi-role Handbrake protocol
- Pre-mortem Integration step in Handbrake flow
- Handbrake Bypass behavior documented

---

## [2.0.0] — 2026-02-05

### Added

- `frameworks/output-format.md` — standard report template with PRECONDITIONS A/B/C
- `examples/architecture-critique.md` — microservices with distributed transaction gap
- `examples/plan-critique.md` — database migration with zero-downtime risk
- `examples/handbrake-example.md` — data pipeline PII multi-role Handbrake

### Changed

- Gate Protocol formalized: 4-step INTERCEPT → ANALYSE → REPORT → GATE flow
- Verification Prompt standardized with exact ✅ / 🔁 / ❌ / `continue` wording

---

## [1.0.0] — 2026-01-28

### Added

- Initial release
- Core adversarial analysis framework
- `frameworks/analysis-framework.md` — 5-step analysis: attack surfaces, assumption challenges, pros/cons, FMEA, edge cases
- `frameworks/security-stride.md` — STRIDE threat model + extended threats
- `frameworks/performance.md` — bottleneck identification and scalability limits
- `frameworks/premortem.md` — forward-looking failure analysis
- `frameworks/vulnerability-patterns.md` — known failure patterns
- `frameworks/product-risks.md` — feature assumptions, launch risks, metrics
- `frameworks/design-ux-risks.md` — dark patterns, WCAG, cognitive load
- `frameworks/leadership-strategy-risks.md` — build vs buy, vendor risk, Type 1/2 decisions
- `frameworks/architecture-risks.md` — distributed systems, coupling, CAP theorem
- `frameworks/data-analytics-risks.md` — pipeline reliability, PII governance, schema drift
- `frameworks/developer-risks.md` — testing gaps, CI/CD risks, dependency management
- Proactive Prevention Mode and automatic trigger detection
