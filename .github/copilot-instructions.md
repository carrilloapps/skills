# Copilot Instructions

This repository publishes three AI agent skills: **devils-advocate**, **sar-cybersecurity**, and **ai-rules**. A fourth skill (**postmortem-writing**) is planned.

## Skill load order (required)

Before implementing any plan, proposal, or code change in this repository, load skills in this order:

```
1. skills/ai-rules/SKILL.md          ← behavioral baseline (always first)
2. skills/devils-advocate/SKILL.md   ← adversarial gate (runs before every action)
```

ai-rules establishes the behavioral baseline (documentation, code quality, language rules, estimation). Devil's Advocate then gates every action — all changes require a full adversarial analysis and explicit user approval (`✅ Proceed`) before proceeding.

## Available skills

This repository contains the following skills:

| Skill | Path | Role |
|-------|------|------|
| ai-rules | `skills/ai-rules/SKILL.md` | Behavioral baseline — loads first |
| Devil's Advocate | `skills/devils-advocate/SKILL.md` | Adversarial gate — runs before every action |
| SAR Cybersecurity | `skills/sar-cybersecurity/SKILL.md` | Deep security analysis on request |
| Postmortem Writing | *Planned* | Post-incident learning |

## Quality gate

Run before every commit:

```bash
bash scripts/validate.sh
```

All checks must pass.

## Conventions

- **Version cascade**: bump `version:` in the affected skill's `SKILL.md` frontmatter, then follow the per-skill cascade checklist in `.github/CONTRIBUTING.md`
- **Documentation**: `en_US` recommended; code identifiers always `en_US`
- **Commits**: Conventional Commits format (`feat:`, `fix:`, `docs:`)
- **Branch**: `main` only — enable branch protection in GitHub Settings → Branches (required status check: `validate`)

## skills.sh Security Audit Compliance

Every skill must pass all three security audits on [skills.sh/audits](https://skills.sh/audits): **Gen Agent Trust Hub** (SAFE), **Socket** (0 ALERTS), **Snyk** (LOW RISK). See `AGENTS.md` and `.ai-context.md` for the full safeguards checklist.
