## Summary

<!-- One paragraph: what does this PR do and why? Which skill(s) does it affect? -->

## Skill(s) Affected

- [ ] 🔴 devils-advocate
- [ ] 🛡️ sar-cybersecurity
- [ ] 📋 ai-rules
- [ ] 📦 Repository infrastructure (CI, templates, root docs)

## Type of Change

- [ ] 🐛 Bug fix — incorrect or misleading guidance corrected
- [ ] ✨ New example (`examples/*.md`) — devils-advocate only
- [ ] 📚 New framework (`frameworks/*.md`) — devils-advocate only
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
- [ ] No stale text: no `with implementation`, `14-dimension`, `carrilloapps/devils-advocate`, or other legacy phrasing
- [ ] All code identifiers in examples use `en_US`
- [ ] `bash scripts/validate.sh` runs with 0 failures locally
- [ ] Commit message follows Conventional Commits format

### If modifying devils-advocate — adding or modifying an example
- [ ] Example ends with the exact Gate prompt (✅ Proceed / 🔁 Revise / ❌ Cancel / `continue`)
- [ ] `continue` line reads: `proceed without addressing remaining issues (risks remain active and unmitigated)`
- [ ] `**Skill version**: X.Y.Z` present and matches current `SKILL.md` version
- [ ] Example added to the `SKILL.md` Index under `### 📂 examples/`
- [ ] Example covers a scenario not already covered by existing examples

### If modifying devils-advocate — adding a new framework
- [ ] File added to `SKILL.md` Index under `### 📂 Domain Frameworks`
- [ ] Framework does not duplicate an existing domain
- [ ] Matching example added to `examples/`
- [ ] Framework follows the header convention (Role, Load when, Always paired with)

### If modifying sar-cybersecurity
- [ ] Any new assessment pattern or edge case is consistent with existing scoring rules (`scoring-system.md`)
- [ ] Output format changes reflected in `frameworks/output-format.md`
- [ ] Version bumped in `SKILL.md` frontmatter if behavior changes
- [ ] `README.md` badge updated to match new version

### If modifying ai-rules
- [ ] New or changed rule does not conflict with Devil's Advocate protocols
- [ ] Security safeguards section updated if scope of autonomy changes
- [ ] Version bumped in `SKILL.md` frontmatter if behavior changes
- [ ] `README.md` badge updated to match new version

### If modifying any core SKILL.md or core protocol file
> Core files: `SKILL.md` (any skill), `frameworks/handbrake-protocol.md`, `frameworks/immediate-report.md`, `frameworks/output-format.md` (DA), `frameworks/output-format.md` (SAR)
> Activation files: `AGENTS.md`, `copilot-instructions.md`
- [ ] Issue was opened and discussed before this PR
- [ ] All cross-references are updated
- [ ] Version bumped and cascaded to README badge, metadata.json, and (for DA) all examples

## Testing

<!-- How did you verify these changes are correct? (e.g., "Read all related files for cross-reference accuracy", "Ran validate.sh locally") -->

## Related Issues

<!-- Closes #issue-number (if applicable) -->
