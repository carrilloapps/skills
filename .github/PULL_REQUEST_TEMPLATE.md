## Summary

<!-- One paragraph: what does this PR do and why? Which skill(s) does it affect? -->

## Skill(s) Affected

- [ ] 🔴 devils-advocate
- [ ] 🛡️ sar-cybersecurity
- [ ] 📋 ai-rules
- [ ] 🔁 agentic-agile
- [ ] 🧷 integrations (guards)
- [ ] 📦 Repository infrastructure (CI, templates, root docs, shared scripts)

## Type of Change

- [ ] 🐛 Bug fix — incorrect or misleading guidance corrected
- [ ] ✨ New example (`examples/*.md`)
- [ ] 📚 New framework (`frameworks/*.md`)
- [ ] 🔧 Improvement to existing framework, checklist, or rule
- [ ] 🏗️ Core protocol change (`SKILL.md` or a core framework file)
- [ ] 📦 Project infrastructure (README, CI, templates, `AGENTS.md`, `copilot-instructions.md`)

## Changes Made

<!-- List the files changed and what was changed in each -->

| File | Change |
|------|--------|
| | |

## Quality Checklist

### All PRs

- [ ] All ` ``` ` code fences are balanced (every opener has a closer)
- [ ] No stale text: no references to removed protocols (`immediate-report`, `handbrake-checklist`, "full adversarial analysis") or other legacy phrasing
- [ ] All code identifiers in examples use `en_US`
- [ ] `bash scripts/validate.sh` runs with 0 failures locally
- [ ] `bash scripts/audit-skills.sh` reports 0 findings (if any `skills/` file changed)
- [ ] Commit message follows Conventional Commits format

### If adding or changing a script (`skills/*/scripts/`, `shared/scripts/`)

- [ ] Both `.sh` and `.ps1` twins changed identically; `.ps1` code is ASCII
- [ ] Parity cases/fixtures/goldens updated; `bash tests/scripts/run-parity.sh` passes
- [ ] Shared scripts re-vendored with `bash shared/sync.sh`

### If modifying agentic-agile

- [ ] Templates use numbered gate items (no checkboxes, no `TBD`); structure templates still pass `check-structure` once filled
- [ ] Examples carry `**Skill version**: X.Y.Z` and the "Example only" note
- [ ] New frameworks/templates/examples/scripts indexed in `SKILL.md`

### If modifying integrations

- [ ] Rules changed only in `integrations/core/classifier.mjs`, then `node integrations/sync-core.mjs`
- [ ] `node --test integrations/core/core.test.mjs integrations/*/test/*.test.mjs` passes

### If modifying devils-advocate — adding or modifying an example

- [ ] Example ends with the Gate (✅ Proceed / 🔁 Revise / ❌ Cancel / `continue` + "reply in your own words" note)
- [ ] `continue` line reads: `proceed without addressing remaining issues (risks remain active and unmitigated)`
- [ ] `**Skill version**: X.Y.Z` present and matches the current `SKILL.md` `metadata.version`
- [ ] Example added to the *Examples* table in `SKILL.md` §5
- [ ] Example covers a scenario not already covered by existing examples

### If modifying devils-advocate — adding a new framework

- [ ] File added to the *Domain frameworks* table in `SKILL.md` §5
- [ ] Framework does not duplicate an existing domain
- [ ] Matching example added to `examples/`
- [ ] Framework follows the header convention (Role, Load when, See also) and has an example code boundary note if it contains code

### If modifying sar-cybersecurity

- [ ] Any new assessment pattern or edge case is consistent with existing scoring rules (`scoring-system.md`) and every `Base N … = Y` line adds up
- [ ] Output format changes reflected in `frameworks/output-format.md`
- [ ] Version bumped in `SKILL.md` frontmatter if behavior changes
- [ ] `README.md` badge updated to match new version

### If modifying ai-rules

- [ ] New or changed rule does not conflict with Devil's Advocate protocols
- [ ] Security safeguards section updated if scope of autonomy changes
- [ ] No new stop-and-wait round; any `.memory/` write follows the selective convention (shared `.memory/<skill>/` versioned, `local/` ignored)
- [ ] Install commands only in `frameworks/capabilities.md`, pinned, official sources, consent-gated
- [ ] Version bumped in `SKILL.md` frontmatter if behavior changes
- [ ] `README.md` badge updated to match new version

### If modifying any core SKILL.md or core protocol file
>
> Core files: `SKILL.md` (any skill), `frameworks/handbrake-protocol.md`, `frameworks/output-format.md` (DA), `frameworks/output-format.md` (SAR)
> Activation files: `AGENTS.md`, `copilot-instructions.md`

- [ ] Issue was opened and discussed before this PR
- [ ] All cross-references are updated
- [ ] Version bumped and cascaded to README badge, metadata.json, and (for DA) all examples

## Testing

<!-- How did you verify these changes are correct? (e.g., "Read all related files for cross-reference accuracy", "Ran validate.sh locally") -->

## Related Issues

<!-- Closes #issue-number (if applicable) -->
