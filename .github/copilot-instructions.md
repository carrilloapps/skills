# Copilot Instructions

This repository publishes four AI agent skills: **devils-advocate**, **sar-cybersecurity**, **ai-rules**, and **agentic-agile**. A fifth skill (**postmortem-writing**) is planned. `AGENTS.md` is the full agent guide.

## Skill load order (required)

Before implementing any plan, proposal, or code change in this repository, load skills in this order:

```text
1. skills/ai-rules/SKILL.md          ← behavioral baseline (always first)
2. skills/devils-advocate/SKILL.md   ← risk-scaled pre-execution gate
3. others on demand                  ← sar-cybersecurity, agentic-agile
```

ai-rules establishes the behavioral baseline (documentation, code quality, language rules, estimation). Devil's Advocate then gates actions at the depth their risk tier requires (`SKILL.md` §1): read-only work and trivial reversible edits pass with at most one line; every non-trivial change and every git write needs the user's explicit approval, which they may give in their own words.

## Available skills

This repository contains the following skills:

| Skill | Path | Role |
|-------|------|------|
| ai-rules | `skills/ai-rules/SKILL.md` | Behavioral baseline — loads first |
| Devil's Advocate | `skills/devils-advocate/SKILL.md` | Risk-scaled pre-execution gate (Tiers 0–3) |
| SAR Cybersecurity | `skills/sar-cybersecurity/SKILL.md` | Deep security analysis on request |
| Agentic Agile | `skills/agentic-agile/SKILL.md` | Spec-driven development on Scrum — Phase 0 structure gate, Gherkin specs, ceremonies, autonomy N0–N4 |
| Postmortem Writing | *Planned* | Post-incident learning |

## Quality gate

Run the commands in `AGENTS.md` → *Commands* before every commit (quality gate, parity + end-to-end example, guard tests, shared-script sync); before publishing, `bash scripts/audit-skills.sh` (needs Docker). All must pass.

## Conventions

- **Version cascade**: bump `metadata.version` in the affected skill's `SKILL.md` frontmatter, then follow the per-skill cascade checklist in `.github/CONTRIBUTING.md`
- **Documentation**: `en_US` recommended; code identifiers always `en_US`
- **Commits**: Conventional Commits format (`feat:`, `fix:`, `docs:`)
- **Branch**: `main` only — enable branch protection in GitHub Settings → Branches (required status checks: `validate`, `scripts-parity`, `skills-audit`)

## skills.sh Security Audit Compliance

Every skill must pass all three security audits on [skills.sh/audits](https://skills.sh/audits): **Gen Agent Trust Hub** (SAFE), **Socket** (0 ALERTS), **Snyk** (LOW RISK). See `AGENTS.md` and `.ai-context.md` for the full safeguards checklist.
