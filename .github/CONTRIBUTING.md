# Contributing to carrilloapps/skills

Thank you for your interest in improving this skills repository! The collection is built on the idea that adversarial thinking makes software better — and we apply that same principle to contributions: every proposal is welcome, and every concern will be heard.

This repository publishes five skills: **devils-advocate**, **sar-cybersecurity**, **ai-rules**, **agentic-agile**, and **postmortem-writing**. Each skill is independently versioned and installable.

---

## Table of Contents

- [What Can I Contribute?](#what-can-i-contribute)
- [Before You Start](#before-you-start)
- [Development Setup](#development-setup)
- [Contribution Types](#contribution-types)
  - [New Skill](#new-skill)
  - [New Framework](#new-framework)
  - [New Example](#new-example)
  - [New or Changed Script](#new-or-changed-script)
  - [agentic-agile Templates and Examples](#agentic-agile-templates-and-examples)
  - [Improving Existing Files](#improving-existing-files)
  - [Bug Reports](#bug-reports)
- [Quality Standards](#quality-standards)
- [Pull Request Process](#pull-request-process)
- [Releasing a New Version](#releasing-a-new-version)
- [Code of Conduct](#code-of-conduct)

---

## What Can I Contribute?

| Type | Welcome? | Notes |
|------|----------|-------|
| New domain framework (`frameworks/*.md`) | ✅ Yes | Must follow template structure; requires example |
| New example (`examples/*.md`) | ✅ Yes | Must show a tier from `SKILL.md` §1 with evidence-backed risks + Gate |
| Improvements to existing frameworks | ✅ Yes | Keep scope tight; explain the improvement |
| Bug fixes (incorrect guidance, broken references) | ✅ Yes | Include evidence that the current text is wrong |
| Translations | ⚠️ Discuss first | Open an issue to coordinate |
| New checklists | ⚠️ Discuss first | High bar — must not overlap existing ones |
| Changes to core protocol files | ⚠️ Discuss first | `SKILL.md`, `output-format.md`, `handbrake-protocol.md` — open an issue first |
| Changes to DA gate activation files | ⚠️ Discuss first | `AGENTS.md`, `copilot-instructions.md` — these activate the DA gate for all contributors; open an issue first |

---

## Before You Start

1. **Search open issues** — your idea may already be in progress
2. **Open an issue first for large changes** — before writing a full framework or changing core protocol, discuss the scope
3. **Read the existing files** — especially `SKILL.md` and `frameworks/output-format.md` to understand the conventions

---

## Development Setup

No build step. Skills are Markdown; scripts are dependency-free.

| Tool | Needed for |
|------|-----------|
| bash (Linux, macOS, Git Bash, WSL) | `scripts/validate.sh`, `.sh` scripts, parity tests |
| PowerShell 7 (`pwsh`); Windows PowerShell 5.1 on Windows | `.ps1` scripts and their parity tests |
| Node.js ≥ 18 | guard tests in `integrations/` |
| Docker (optional) | `scripts/audit-skills.*` and the Docker lab |

```bash
git clone https://github.com/carrilloapps/skills.git
cd skills
bash scripts/validate.sh
```

---

## Contribution Types

### New Skill

1. Create `skills/<name>/` with `SKILL.md` (frontmatter: `name` = directory name, `description`, `license`, `metadata.version` — no other top-level fields), `README.md` (badge `version-X.Y.Z-blue`), and `metadata.json` (`"version"`).
2. Include the six safeguards (see `.ai-context.md`) and keep `SKILL.md` small (target ≤ 20,000 chars; `validate.sh` hard limit 32,000).
3. Index every `frameworks/`, `templates/`, `examples/`, and `scripts/` file in `SKILL.md`.
4. Run `bash shared/sync.sh` — it vendors the shared scripts (`lab-probe`) into every `skills/*/scripts/`. If the skill uses the Docker lab, add `frameworks/lab-catalog.tsv` (header: `id skill criticality ram_mb disk_mb kind profile compose signals requires notes`).
5. Add the skill to `scripts/validate.sh` (version and CHANGELOG checks), the root `README.md` catalog, `AGENTS.md`, `docs/INSTALL.md`, `.ai-context.md`, and the PR template.
6. Add a `## <name> [X.Y.Z]` entry to `CHANGELOG.md`.
7. Run every quality gate and `bash scripts/audit-skills.sh` (0 findings).

### New Framework

A new framework file in `skills/<skill>/frameworks/` must:

1. **Follow the header convention**:

   ```markdown
   # [Framework Name]

   > **Role**: [Who should load this]
   > **Load when**: [Trigger conditions — be specific]
   > **See also**: [Related files — load only if they change the analysis]
   ```

2. **Not duplicate** existing framework coverage — check the skill's `SKILL.md` index (Devil's Advocate: the *Domain frameworks* table in §5).

   > Protocol files (`output-format.md`, `handbrake-protocol.md`, `premortem.md`) are always free. `building-protocol.md` is conditionally free: loaded at no cost when the analysis involves code; skipped for pure text or strategy reviews.
3. **Include an adversarial lens** — not just "here are best practices" but "here are the risks and how they fail"
4. **Be a thinking aid, not a report template** — its conclusions reach the report; its tables and templates never do (`SKILL.md` §2, *Banned output*)
5. **Include an example code boundary note** under the H1 if it contains commands, SQL, or code
6. **Be added to the skill's `SKILL.md` index** (Devil's Advocate: the *Domain frameworks* table in §5)
7. **Keep SKILL.md small** — it is always loaded in full: target ≤ 20,000 chars; `validate.sh` hard limit 32,000 chars.

### New Example

An example file in `examples/` must:

1. **Start with the thing being analyzed**, marked as fictional:

   ```markdown
   **Plan [fictional]:** [1–3 sentences describing what was proposed]
   ```

   Use `**Request:**` for single-action Tier 0/1 examples.

2. **Show one tier from `SKILL.md` §1**:
   - Tier 3: the single Critical stop block, the (fictional) answers, then the report
   - Tier 2: the compact report from `SKILL.md` §3 — every risk with Evidence + Fix, ending with "What I'll do if you approve"
   - The Gate

3. **End with the Gate as defined in `SKILL.md` §3** — the labels plus the line telling the user they can reply in their own words. The labels are a guide, not a password; `validate.sh` checks for `✅ Proceed` and the "own words" note.

4. **Cover a domain not already well-represented** in existing examples (check `examples/` before writing)

5. **Be added to the Index** in `SKILL.md` under `### 📂 examples/`

6. **Include the version stamp** in the full report header:

   ```markdown
   **Skill version**: [current version from SKILL.md frontmatter — e.g. X.Y.Z]
   ```

   `validate.sh` Check 8 enforces this and will fail if it is missing or mismatched.

### New or Changed Script

1. Write both twins: `<name>.sh` (POSIX, bash 3.2-compatible) and `<name>.ps1` (Windows PowerShell 5.1 and pwsh 7) with identical flags, output, exit codes, and side effects. No `eval`, no network, no installs; build JSON with `printf` formats; keep `.ps1` code ASCII (use `\uXXXX` escapes — `validate.sh` check 32).
2. Shared scripts go in `shared/scripts/`; run `bash shared/sync.sh` to vendor them into every skill.
3. Add cases to `tests/scripts/cases.tsv` and fixtures under `tests/scripts/fixtures/`, generate goldens with `bash tests/scripts/run-parity.sh --update --only bash`, review the diff, then run the full parity suite in bash and `pwsh tests/scripts/run-parity.ps1`.
4. Document the script in the skill's `SKILL.md` index and `README.md`.
5. Run `bash scripts/audit-skills.sh` — the scanner must stay at 0 findings.

### agentic-agile Templates and Examples

1. Templates use numbered gate items (`1. ✅/❌/⚠️ <item> — evidence`), never checkboxes or `TBD`; `<placeholders>` only where the team must fill in a value — `check-structure` and `check-spec` fail on unfilled ones.
2. Structure templates (`plans/agile/*`) must keep the content `check-structure` expects (see `frameworks/sdd-phases.md`); add or update parity fixtures when that changes.
3. Examples are fictional, start with an "Example only" note, and carry `**Skill version**: X.Y.Z`.
4. Gherkin follows `frameworks/gherkin.md`: Given/When/Then per scenario, one language per block, `Origin:` per scenario.

### Improving Existing Files

- Keep changes minimal and surgical
- Explain in the PR description what was wrong and why your version is better
- Do not change the Gate semantics, version stamps in examples, or core protocol flow without opening an issue first
- Do not weaken references to `SKILL.md` in `AGENTS.md` or `copilot-instructions.md` without opening an issue first — these files activate the DA gate for all contributors

### New Assessment Pattern or Edge Case (sar-cybersecurity)

A new example in `skills/sar-cybersecurity/examples/` must:

1. Follow the per-finding format in `frameworks/output-format.md` — see existing examples for structure
2. Cover a vulnerability class or scoring scenario not already represented
3. Include a complete finding with CWE mapping, Confidence, CVSS v4.0 vector, and a score arithmetic line that adds up (`Base N +a (…) −b (…) = Y … → Final Z`) — `validate.sh` checks the sum
4. Carry the "⚠️ Example only" boundary note
5. Be added to the Index in `skills/sar-cybersecurity/SKILL.md`

A change to `skills/sar-cybersecurity/frameworks/` (scoring rules, output format, compliance standards, injection patterns, storage categories, database protocol, dependency audit) must:

1. Not contradict existing scoring or output format rules without a version bump
2. Be consistent with the 6 security safeguards required for skills.sh audit compliance

### New Behavioral Rule (ai-rules)

A change to `skills/ai-rules/SKILL.md` must:

1. Not conflict with Devil's Advocate protocols — ai-rules defines HOW to act; DA defines WHETHER to act
2. Preserve all 6 mandatory security safeguards (untrusted input boundary, no arbitrary code execution, bounded autonomy, web search scoping, example code boundaries, report-only output)
3. Stay within the `SKILL.md` budget (target ≤ 20,000 chars; `validate.sh` hard limit 32,000) — ai-rules is always loaded in full
4. Never add a stop-and-wait round of its own (ask for one missing field only when a rule needs it)
5. Include a version bump (patch for clarifications, minor for new behavioral rules) with full cascade

---

### Bug Reports

Use the [Bug Report issue template](ISSUE_TEMPLATE/bug_report.yml). A good bug report includes:

- The file and line number containing the incorrect guidance
- Why it is incorrect (citation, evidence, or clear reasoning)
- A suggested correction

---

## Quality Standards

All contributions must pass these checks before merge:

| Check | Requirement |
|-------|-------------|
| Fence balance | Every ` ``` ` opener has a matching closer |
| Gate | Every Devil's Advocate example ends with the Gate (`✅ Proceed` + "reply in your own words" note) |
| `continue` line | Must say `(risks remain active and unmitigated)` — not `(risks remain active)` |
| Version stamp | Every example must contain `**Skill version**: X.Y.Z` matching the current SKILL.md version |
| Cross-references | Any file added to `frameworks/`, `checklists/`, or `examples/` of any skill must be added to that skill's `SKILL.md` Index |
| SAR arithmetic | Every `Base N … = Y` scoring line in SAR files must add up |
| Safeguards | Every `SKILL.md` keeps the six audit safeguards; any skill mentioning `.memory/` documents the selective `.memory/.gitignore` (`local/`, `*.local.*`, `*.recovered.json`); `SKILL.md` contains no install commands; `frameworks/capabilities.md` pins every install and never pipes downloads into a shell |
| Domain coverage | New frameworks must not duplicate an existing domain |
| en_US identifiers | All code in examples follows the Building Protocol |
| No stale text | No references to removed protocols (`immediate-report`, `handbrake-checklist`, "full adversarial analysis") or other legacy phrasing |
| SKILL.md budget | Every `SKILL.md` targets ≤ 20,000 chars; `validate.sh` fails above 32,000 |
| Numbered options | Options and checklists inside `skills/` are numbered or lettered (with `✅/❌/⚠️` state where needed) — never `- [ ]` checkboxes. GitHub templates under `.github/` keep checkboxes because GitHub renders them clickable |
| Multi-OS scripts | Every `skills/*/scripts/*.sh` has a `.ps1` twin (Windows PowerShell 5.1 + pwsh 7) with identical flags, output, exit codes, and side effects; no runtime dependencies, no network, no installs; parity tests in `tests/scripts/` pass on Ubuntu and Windows. Shared scripts live in `shared/` and are vendored with `bash shared/sync.sh` |
| Project-local storage | Skills never advertise global agent directories (`~/.claude`, `~/.gemini`, `~/.codex`, …) or the system temp directory as write targets without explicit user approval; generated files go to `specs/`, `plans/`, `docs/`, `.memory/` |

CI runs all of the above on every PR. Run the commands listed in [`AGENTS.md` → *Commands*](../AGENTS.md#commands) locally before submitting (quality gate, parity + end-to-end example, guard tests, shared-script sync). **Before publishing**, also run `bash scripts/audit-skills.sh` (or `pwsh scripts/audit-skills.ps1`) — what it checks, what the scanners flag, and how to write around them: [`.ai-context.md` → *Local Pre-Publish Audit*](../.ai-context.md#local-pre-publish-audit).

---

## Pull Request Process

1. **Branch naming**: `feat/<description>`, `fix/<description>`, `docs/<description>`
2. **Commit messages**: Conventional Commits format (`feat:`, `fix:`, `docs:`)
3. **PR title**: Same format as commit message
4. **PR description**: Fill in the PR template completely
5. **One concern per PR**: Don't combine a new framework with changes to core protocol

### Review turnaround

| PR type | Target review time |
|---------|-------------------|
| Bug fix (typo, broken reference) | 2–3 days |
| New example | 5–7 days |
| New framework | 7–14 days |
| Core protocol change | 14+ days (requires community discussion) |

### skills.sh indexing

The skill is distributed directly from GitHub — no manual submission to skills.sh is required. Once the repository is public and contains a valid `SKILL.md`, anyone can install it with:

```bash
npx skills add carrilloapps/skills@devils-advocate
```

The [skills.sh](https://skills.sh) leaderboard and `npx skills find` search index are **telemetry-driven**: skills appear automatically once they accumulate installs through the CLI. There is no registration form or publish command.

---

## Releasing a New Version

> **Maintainers only.** Contributors should not change version numbers.

When merging a batch of fixes, follow this checklist to cut a release:

1. **Run the validator** — must be 0 failures before bumping:

   ```bash
   bash scripts/validate.sh
   ```

2. **Bump the version** — update `metadata.version` in the `SKILL.md` frontmatter (a `version: "X.Y.Z"` entry nested under `metadata:`, per the Agent Skills spec — a top-level `version:` fails `agentskills validate`) (e.g. `X.Y.Z` → `X.Y.(Z+1)`)

3. **Cascade the version** to all versioned files (applies to each skill independently):

   **For devils-advocate:**
   - `skills/devils-advocate/SKILL.md` — `metadata.version` in frontmatter *(already done in step 2)*
   - `skills/devils-advocate/README.md` — badge `version-X.Y.Z-blue`
   - `skills/devils-advocate/metadata.json` — `"version"` field
   - `README.md` (root) — skill catalog badges (catalog table and Skill Details heading)
   - All `skills/devils-advocate/examples/*.md` — `**Skill version**: X.Y.Z` line (run `validate.sh` to catch any missed)

   **For sar-cybersecurity:**
   - `skills/sar-cybersecurity/SKILL.md` — `metadata.version` in frontmatter
   - `skills/sar-cybersecurity/README.md` — badge `version-X.Y.Z-blue`
   - `skills/sar-cybersecurity/metadata.json` — `"version"` field
   - `README.md` (root) — skill catalog badge

   **For ai-rules:**
   - `skills/ai-rules/SKILL.md` — `metadata.version` in frontmatter
   - `skills/ai-rules/README.md` — badge `version-X.Y.Z-blue`
   - `skills/ai-rules/metadata.json` — `"version"` field
   - `README.md` (root) — skill catalog badge

   **For agentic-agile:**
   - `skills/agentic-agile/SKILL.md` — `metadata.version` in frontmatter
   - `skills/agentic-agile/README.md` — badge `version-X.Y.Z-blue`
   - `skills/agentic-agile/metadata.json` — `"version"` field
   - `README.md` (root) — skill catalog badge
   - All `skills/agentic-agile/examples/*.md` — `**Skill version**: X.Y.Z` line

4. **Add a CHANGELOG entry** — edit `CHANGELOG.md` at the **repo root**, below `[Unreleased]`: `## [X.Y.Z] — YYYY-MM-DD` for devils-advocate, `## <skill-name> [X.Y.Z] — YYYY-MM-DD` for the others. `validate.sh` checks that every skill's current version has its entry:

   ```markdown
   ## [X.Y.Z] — YYYY-MM-DD

   ### Fixed
   - **Severity — Short description**: what was wrong and what the fix does
   ```

5. **Run every quality gate again** — `validate.sh`, parity, guard tests, `shared/sync.sh --check`, and `bash scripts/audit-skills.sh` (0 findings)

6. **Commit, tag, push, and publish the release** — one tag prefix per skill:

   | Skill | Tag | Release title |
   |-------|-----|---------------|
   | devils-advocate | `vX.Y.Z` | `Devil's Advocate vX.Y.Z` |
   | sar-cybersecurity | `sar-vX.Y.Z` | `SAR Cybersecurity vX.Y.Z` |
   | ai-rules | `ai-rules-vX.Y.Z` | `ai-rules vX.Y.Z` |
   | agentic-agile | `agentic-agile-vX.Y.Z` | `agentic-agile vX.Y.Z` |

   ```bash
   git add -A
   git commit -m "feat: release <skill> vX.Y.Z"      # or fix:/docs: per Conventional Commits
   git tag -a <tag> -m "<tag>"
   git push origin main <tag>
   gh release create <tag> --title "<Release title>" --notes-file <notes.md>   # notes = that skill's CHANGELOG section
   ```

   Several skills released together share one commit and get one tag and one release each. Tags are never moved after publishing.

The skills.sh install counter updates automatically as users run `npx skills update` or install fresh.

---

## Code of Conduct

All contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Be direct, be honest, be kind.
