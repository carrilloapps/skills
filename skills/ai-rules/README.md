# ai-rules

[![v1.0.1](https://img.shields.io/badge/version-1.0.1-blue.svg)](../../CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-red.svg)](../../LICENSE)
[![skills.sh](https://img.shields.io/badge/skills.sh-carrilloapps-black.svg)](https://skills.sh/carrilloapps/skills)

> Personal behavioral rules for AI tools — documentation discipline, secure practices, code quality, version control, and structured estimation across any project.

## Install

> **Before installing**: Review the source at [github.com/carrilloapps/skills](https://github.com/carrilloapps/skills) and verify the latest audit results at [skills.sh/audits](https://skills.sh/audits). The install command below fetches content from a remote repository — review before using in production or sensitive environments.

```bash
npx skills add carrilloapps/skills@ai-rules
```

## What It Does

ai-rules defines a behavioral contract that all AI coding agents must follow when working in your projects:

- **Session initialization**: At the start of each session, asks for project data (name, description, stage, stack) and developer data (name, email, role, organization). Saves it to `docs/project-context.md`. This file may contain PII — you decide whether to add it to `.gitignore`.
- **Documentation storage**: Forces all session memory, references, and generated assets into `docs/` (not IDE caches or AI memory stores), making them accessible to every tool — Claude Code, GitHub Copilot, Gemini CLI, OpenCode, and others.
- **Security constraints**: Hard prohibitions on reading secrets, executing dangerous commands, or querying databases without prior schema analysis.
- **Code quality**: SOLID, KISS, and DRY enforcement with a mandatory `docs/elementals.md` to prevent duplication across components and functions.
- **Version control**: Conventional Commits, focused commits, and a living `AGENTS.md` that stays in sync with all project agents and context files.
- **Structured estimation**: Every recommendation includes Confidence %, effort by capacity mode, pivot potential, and risk factors.

## Interaction with Other Skills

This skill operates as a baseline behavioral layer.

[Devil's Advocate](../devils-advocate/) has analytical precedence in findings — in any conflict between an ai-rules rule and a Devil's Advocate finding, apply the Devil's Advocate analysis and note the conflict to the user.

## Author

**José Carrillo** — [carrillo.app](https://carrillo.app)
GitHub: [carrilloapps](https://github.com/carrilloapps)
