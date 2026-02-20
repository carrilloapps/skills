# carrilloapps/skills

> A collection of adversarial analysis and quality-gate skills for AI coding agents — compatible with GitHub Copilot, Claude Code, Cursor, Windsurf, and 40+ more.

## Available Skills

| Skill | Description | Install |
|-------|-------------|---------|
| [`devils-advocate`](skills/devils-advocate/) | Mandatory adversarial risk gate — intercepts every plan before execution | `npx skills add https://github.com/carrilloapps/skills --skill devils-advocate` |

---

## Quick Install

```bash
# Install a specific skill
npx skills add https://github.com/carrilloapps/skills --skill devils-advocate

# Or install all skills
npx skills add https://github.com/carrilloapps/skills
```

## Structure

Each skill lives in `skills/<name>/` and contains:

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill instructions (always loaded by agents) |
| `README.md` | Human-readable documentation |
| `CHANGELOG.md` | Version history |
| `metadata.json` | Skill metadata |
| `frameworks/` | Domain analysis frameworks |
| `checklists/` | Structured risk checklists |
| `examples/` | Real-world analysis examples |
| `scripts/validate.sh` | CI quality gate |

## License

[MIT](LICENSE) — free to use, modify, and distribute.

---

*Built by [José Carrillo](https://carrillo.app)*
