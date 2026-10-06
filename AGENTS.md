# AGENTS.md

This repository publishes five AI agent skills — **ai-rules**, **devils-advocate**, **sar-cybersecurity**, **agentic-agile**, and **postmortem-writing** — as Markdown instruction files (plus dual `.sh`/`.ps1` helper scripts where a skill needs them) distributed through [skills.sh](https://skills.sh) (`npx skills add carrilloapps/skills@<skill-name>`).

## Skill load order (required)

When working in this repository, load skills in this order:

```text
1. skills/ai-rules/SKILL.md          ← behavioral baseline (always first)
2. skills/devils-advocate/SKILL.md   ← risk-scaled pre-execution gate
3. others on demand                  ← sar-cybersecurity, agentic-agile
```

ai-rules defines HOW to act (documentation, code quality, language, estimation). Devil's Advocate defines WHETHER to act. Both must be loaded; ai-rules must load first.

## Devil's Advocate gate (required)

Before proposing or implementing a change to this repository, apply the Devil's Advocate from `skills/devils-advocate/SKILL.md` **at the depth its risk tier requires** (§1): read-only work and trivial reversible edits pass with at most one line; non-trivial changes get a short evidence-based critique; every non-trivial action and **every git write** waits for the user's explicit approval. The user may approve in their own words (e.g. "dale", "proceed") — the gate labels are a guide, not a password.

This applies to `SKILL.md`, `frameworks/`, `checklists/`, `examples/`, `scripts/`, `integrations/`, and all root files.

**Optional harness enforcement**: instructions alone cannot guarantee the gate runs. Optional, separately installed guards in [`integrations/`](integrations/README.md) enforce it in each agent's pre-tool hook with one shared deterministic classifier (`integrations/core/classifier.mjs`); the per-agent matrix (stable / experimental / advisory, decision mapping) lives only in that README. Guards are not part of any skill and are never installed by `npx skills add`. Edit rules only in `integrations/core/classifier.mjs`, then run `node integrations/sync-core.mjs`.

## Commands

Run before every commit — all must pass (CI runs them too):

1. `bash scripts/validate.sh` — the repository quality gate.
2. `bash tests/scripts/run-parity.sh` (or `pwsh tests/scripts/run-parity.ps1`) — `.sh` / `.ps1` parity tests against golden outputs (Ubuntu and Windows in CI); `bash tests/scripts/run-e2e.sh` rebuilds the agentic-agile end-to-end example and runs every validator in each available shell.
3. `node --test integrations/core/core.test.mjs integrations/*/test/*.test.mjs` and `node integrations/sync-core.mjs --check` — guard classifier and adapters.
4. `bash shared/sync.sh --check` — vendored shared scripts identical in every skill (after editing `shared/scripts/`, run `bash shared/sync.sh`).

There is no build step. Executable artifacts: `scripts/validate.sh`, `scripts/audit-skills.*`; the optional `integrations/` guards (Node ≥ 18, not installed by `npx skills add`); and skill helper scripts in `skills/*/scripts/` (canonical shared ones in `shared/`).

**Before publishing** (numbered checklist in `README.md` → *Before publishing*): run `bash scripts/audit-skills.sh` (or `pwsh scripts/audit-skills.ps1`). It reproduces offline the skills.sh checks that can run locally — `agentskills validate` (Agent Skills spec) and Cisco `skill-scanner` (static, YARA, pipeline-taint, behavioral analyzers) — in a digest-pinned container, without sending skill content anywhere, and exits non-zero on any finding. CI runs the same checks (`skills-audit` job). The Snyk engine used by skills.sh is available only as the manual `snyk-agent-scan` workflow (it uploads skill content to Snyk and needs `SNYK_TOKEN`); Socket and Gen Agent Trust Hub run only on skills.sh after publishing.

**agentic-agile Phase 0**: agentic-agile enforces a Phase 0 gate — run `skills/agentic-agile/scripts/check-structure` before creating anything under `specs/` or `plans/` (other than `plans/agile/`).

**Multi-OS script parity (required)**: every skill script ships as a POSIX `.sh` **and** a PowerShell `.ps1` (Windows PowerShell 5.1 and pwsh 7) with identical flags, outputs, exit codes, and side effects — no runtime dependencies, no network, no installs, read-only except documented writes inside the project. A script without its twin fails `validate.sh`.

## Architecture

Each skill follows the same pattern:

- `SKILL.md` — always loaded in full by agents. Target ≤ 20,000 chars; `validate.sh` hard limit 32,000.
- `frameworks/` — loaded on demand: **protocol files** (free to load) and **domain frameworks** (loaded by relevance only — Devil's Advocate usually 0–2).
- `examples/` — reference outputs, loaded on demand.
- `metadata.json` — version, author, keywords.
- `README.md` — public documentation.

**Project-local storage (required)**: everything an agent generates lives inside the project, in this layout — `specs/<initiative>/` and `plans/` (`plans/agile/`, `plans/sprints/`, `plans/initiatives/`, `plans/decisions/`, `plans/drafts/` — versioned specifications and plans), `docs/` (versioned team docs), `.memory/<skill>/` (versioned shared state), `.memory/local/` (private: binaries in `bin/`, virtualenvs in `venv/`, temp in `tmp/`). Never write to global agent directories (`~/.claude`, `~/.gemini`, `~/.codex`, `~/.cursor`, `~/.copilot`, `~/.config/*`) or the system temp directory without the user's explicit approval of that exact path. Full rule: `skills/ai-rules/SKILL.md` → *Project-Local Storage*.

**Options are numbered or lettered**, never `- [ ]` checkboxes (the user approves or drops items by number: "dale con 1 y 3"). `validate.sh` rejects checkboxes under `skills/`.

**Skill state** lives in `.memory/<skill>/` at the project root and is **selectively** versioned (summary here; the full rule, VCS table, and `sar` short-name note are owned by [`skills/ai-rules/frameworks/memory-convention.md`](skills/ai-rules/frameworks/memory-convention.md)):

- **Shared team state** (for example `.memory/sar/findings.json` in private repositories) stays under `.memory/<skill>/` and **is versioned**.
- **Agent-private state** (developer preferences, capability decisions, caches, recovery files) lives under `.memory/local/` or uses `*.local.*` / `*.recovered.json` names and is **never versioned**. Before its first write, a skill creates or extends a versioned `.memory/.gitignore` containing `local/`, `*.local.*`, and `*.recovered.json` (appending only missing lines), adds the equivalent rules for Mercurial (`.hgignore`) or Fossil (`.fossil-settings/ignore-glob`) when detected, and prints the command for Subversion. Skills use file writes only — they never run VCS commands.
- **Public repositories**: SAR keeps its registry and reports under `.memory/local/sar/`, so open vulnerabilities are never published.
- Tool indexes created by optional capabilities (`.codegraph/`, `.docgraph/`) are ignored too.

Full rules: `skills/ai-rules/SKILL.md` and `skills/sar-cybersecurity/frameworks/output-format.md`.

**Optional capabilities**: each skill may ship `frameworks/capabilities.md` listing optional tools (pinned versions, official registries only) that it *suggests* at most once and installs only after the user approves the exact command. `SKILL.md` files never contain install commands. Installation instructions for every agent: [`docs/INSTALL.md`](docs/INSTALL.md).

**Cross-skill flow**: agentic-agile (specify, plan, deliver) → Devil's Advocate (prevent) → SAR Cybersecurity (assess) → planned Postmortem Writing (learn). agentic-agile delegates its adversarial pass to Devil's Advocate, security reviews to SAR, and language/docs to ai-rules, with a minimal built-in fallback when they are not installed. Each skill is independently installable.

## Version cascade

When bumping a skill version, update **all** of:

1. `SKILL.md` frontmatter (`metadata.version` — Agent Skills spec; never a top-level `version:`)
2. The skill's `README.md` version badge
3. The skill's `metadata.json` `"version"`
4. All `examples/*.md` `**Skill version**: X.Y.Z` stamps (Devil's Advocate and agentic-agile)
5. The root `README.md` catalog badges
6. A new `CHANGELOG.md` section (`## [X.Y.Z]` for Devil's Advocate, `## <skill> [X.Y.Z]` for the others)

`validate.sh` checks all of these. Full checklist: `.github/CONTRIBUTING.md` → "Releasing a New Version".

## Available skills

| Skill | Path | Purpose |
|-------|------|---------|
| ai-rules | `skills/ai-rules/SKILL.md` | Behavioral baseline — loads first, defines HOW to act (docs, code quality, language, version control, estimation) |
| Devil's Advocate | `skills/devils-advocate/SKILL.md` | Risk-scaled pre-execution gate (Tiers 0–3) — defines WHETHER to act |
| SAR Cybersecurity | `skills/sar-cybersecurity/SKILL.md` | Security Assessment Report generator — deterministic scoring, bilingual EN/ES reports |
| Agentic Agile | `skills/agentic-agile/SKILL.md` | Spec-driven development on Scrum with agentic agility — gated specs/plans, ceremonies, autonomy N0–N4, attribution, transcripts, MCP capability slots |
| Postmortem Writing | *Planned* | Incident postmortem authoring beyond the team flow in agentic-agile (scope pending decision) |

## Conventions

- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`).
- **Language**: code identifiers always `en_US`; repository documentation in `en_US`.
- **Branch**: `main` only.
- **No AI credit (repository rule)**: never add `Co-Authored-By` with any AI/IDE name, "Generated by" markers, or tool watermarks to commits, PRs, or files in this repository. All credit belongs to the human author.
- **Git operations**: never commit, push, tag, merge, or rebase without the user's explicit authorization, even with full session permissions.

---

## skills.sh Security Audit Compliance (mandatory)

Every skill must pass the three automated audits on [skills.sh/audits](https://skills.sh/audits) — Gen Agent Trust Hub (SAFE), Socket (PASS, 4/4), Snyk (PASS, LOW RISK). The six mandatory safeguards every `SKILL.md` must carry, what each scanner flags, the current audit status per skill, and the local pre-publish audit are maintained in one place: [`.ai-context.md`](.ai-context.md). `validate.sh` checks the safeguards; `scripts/audit-skills.sh` reproduces offline the checks that can run locally.
