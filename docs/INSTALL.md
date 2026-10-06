# Installing carrilloapps/skills in any agent

Single source of truth for installing `ai-rules`, `devils-advocate`, `sar-cybersecurity`, and `agentic-agile` in every supported AI coding agent. Skill READMEs link here.

> **Before installing**: review the source at [github.com/carrilloapps/skills](https://github.com/carrilloapps/skills) and the latest audit results at [skills.sh/audits](https://skills.sh/audits). The commands below fetch content from a remote repository.

Legend: ✅ verified in the agent's official docs or the [`skills` CLI README](https://github.com/vercel-labs/skills) (checked 2026-10-05) · ⚠️ third-party source or not re-verified — check your agent's docs.

---

## 1. Install with the `skills` CLI (recommended)

```bash
# All four skills, every agent detected in the current project
npx skills add carrilloapps/skills

# One skill
npx skills add carrilloapps/skills@devils-advocate

# A specific agent (id from the table below) — repeat -a for several
npx skills add carrilloapps/skills@sar-cybersecurity -a antigravity -a claude-code

# Every supported agent
npx skills add carrilloapps/skills -a '*'
```

| Flag | Effect |
|------|--------|
| `-a <id>` | Install for that agent only (repeatable); `-a '*'` = all agents |
| `-g` | Global install (every project) instead of the current project |
| `-s <skill>` | Pick skills from the repository (repeatable) |
| `--copy` | Copy files instead of symlinking to one canonical copy |
| `-y` | Non-interactive (CI-friendly) |
| `-l`, `--list` | List the **skills** in a repository (not the agents) |

Keep up to date with `npx skills check` and `npx skills update`. Remove with `npx skills remove <skill> [-g] [-a <id>]`.

The CLI supports **70+ agents**. For agents not listed below, see the [supported agents table](https://github.com/vercel-labs/skills) in the `skills` CLI README.

---

## 2. Per-agent matrix

| Agent | `-a` id | Project skills path | Global skills path | Always-on instruction file | Optional guard |
|-------|---------|--------------------|--------------------|----------------------------|----------------|
| Claude Code ✅ | `claude-code` | `.claude/skills/` | `~/.claude/skills/` | `CLAUDE.md` (can import `@AGENTS.md`) | [`claude-code/`](../integrations/claude-code/) (plugin) |
| Antigravity IDE ✅ | `antigravity` | `.agents/skills/` | `~/.gemini/antigravity/skills/` ⚠️ (see note) | `GEMINI.md`, `AGENTS.md`, `.agents/rules/*.md` ⚠️ | — (IDE hooks unverified) |
| Antigravity CLI (`agy`) ✅ | `antigravity-cli` | `.agents/skills/` | `~/.gemini/antigravity-cli/skills/` | same as Antigravity IDE ⚠️ | [`antigravity/`](../integrations/antigravity/) (experimental) |
| Cursor ✅ | `cursor` | `.agents/skills/` or `.cursor/skills/` | `~/.cursor/skills/`, `~/.agents/skills/` | `.cursor/rules/*.mdc` (`alwaysApply`), `AGENTS.md` | [`cursor/`](../integrations/cursor/) |
| Windsurf → Devin Desktop ✅ | `windsurf` | `.devin/skills/` (preferred), `.windsurf/skills/` (legacy, still read; the CLI installs here), `.agents/skills/` | `~/.codeium/windsurf/skills/`, `~/.config/devin/skills/` | rules, `AGENTS.md` | [`windsurf/`](../integrations/windsurf/) |
| GitHub Copilot (VS Code, CLI, cloud agent) ✅ | `github-copilot` | `.github/skills/`, `.claude/skills/`, `.agents/skills/` | `~/.copilot/skills/`, `~/.agents/skills/` | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md` | [`copilot/`](../integrations/copilot/) |
| OpenAI Codex CLI ✅ | `codex` | `.agents/skills/` (cwd, parents, repo root) | `~/.agents/skills/` (docs); the CLI table lists `~/.codex/skills/` | `AGENTS.md` | [`codex/`](../integrations/codex/) |
| Gemini CLI ✅ | `gemini-cli` | `.agents/skills/` (wins over `.gemini/skills/`) | `~/.agents/skills/`, `~/.gemini/skills/` | `GEMINI.md` ⚠️ (`context.fileName` can add `AGENTS.md`) | [`gemini-cli/`](../integrations/gemini-cli/) |
| Cline ✅ | `cline` | `.agents/skills/` (CLI); Cline docs mention `.clinerules/skills/` ⚠️ | `~/.agents/skills/` | `.clinerules/` | [`cline/`](../integrations/cline/) |
| Roo Code ✅ | `roo` | `.roo/skills/` | `~/.roo/skills/` | `.roo/rules/`, `~/.roo/rules/` | [`roo/`](../integrations/roo/) (advisory rule only) |
| OpenCode ✅ | `opencode` | `.agents/skills/` | `~/.config/opencode/skills/` | `AGENTS.md` ⚠️ | [`opencode/`](../integrations/opencode/) (plugin) |
| Kiro (IDE + CLI) ✅ | `kiro-cli` | `.kiro/skills/` | `~/.kiro/skills/` | `.kiro/steering/*.md` | [`kiro/`](../integrations/kiro/) (experimental) |
| Amp ✅ | `amp` | `.agents/skills/` | `~/.config/agents/skills/` | `AGENTS.md` ⚠️ | — |
| Replit ✅ | `replit` | `.agents/skills/` | `~/.config/agents/skills/` | `AGENTS.md` ⚠️ | — |
| Kimi Code CLI | `kimi-code-cli` | see CLI table ⚠️ | see CLI table ⚠️ | ⚠️ | — |
| Others (Continue, Goose, Augment, Droid, Kilo Code, OpenHands, Trae, Zed, Warp, Junie, Qwen Code, Zencoder, …) | see [CLI table](https://github.com/vercel-labs/skills) | ⚠️ | ⚠️ | mostly `AGENTS.md` ⚠️ | — |

### Agent notes

- **Antigravity global path** — the documented global path is `~/.gemini/antigravity/skills/`. A Google Developer Expert reports that `~/.gemini/skills/` (shared by all Antigravity tools) worked when the documented path did not ([source](https://dev.to/gde/configuring-mcp-servers-and-skills-for-antigravity-cli-and-ide-2bh0)) ⚠️. If a global install is not picked up, copy the skill folder there as well. Project installs (`.agents/skills/`) are not affected.
- **Antigravity CLI** — the binary is `agy` ⚠️ (third-party source). Install it from [antigravity.google](https://antigravity.google/docs/cli/features/).
- **Windsurf** is now **Devin Desktop**. `.devin/skills/` is preferred; `.windsurf/skills/` is legacy but still read.
- **Kiro** — the default agent loads `.kiro/skills/` automatically. Only **custom agents** need the skill added to `resources` in `.kiro/agents/<agent>.json`:

  ```json
  { "resources": ["skill://.kiro/skills/**/SKILL.md"] }
  ```

- **Load order** — when installing several skills, load `ai-rules` first, then `devils-advocate`. Agents that read `AGENTS.md` follow the order stated there.

---

## 3. Manual install (no CLI)

1. Clone the repository: `git clone https://github.com/carrilloapps/skills.git`
2. Copy (or symlink) `skills/<skill-name>/` into the agent's project or global skills path from the table. **The folder name must equal the skill `name`** (`devils-advocate`, `sar-cybersecurity`, `ai-rules`) — Cursor requires it.
3. For an agent without native skill support, add one line to its always-on instruction file pointing at the skill, for example in `AGENTS.md`:

   ```markdown
   Before acting, follow `.agents/skills/devils-advocate/SKILL.md`.
   ```

Equivalent CLI command: `npx skills add carrilloapps/skills@<skill> -a <id> --copy`.

---

## 4. Optional guards (harness enforcement)

Skill instructions cannot force an agent to follow them. The optional guards in [`integrations/`](../integrations/) move the Devil's Advocate gate into each agent's own pre-tool hook, using one deterministic classifier (no AI, no network, no writes). They are **not** installed by `npx skills add`; install them per agent from the adapter README.

| Agent | Guard | Status |
|-------|-------|--------|
| Claude Code, GitHub Copilot, Cursor, Gemini CLI, OpenAI Codex CLI, Windsurf / Devin Desktop, Cline, OpenCode | blocks or asks before side-effecting tool calls | Stable |
| Kiro, Antigravity CLI (`agy`) | same | Experimental |
| Roo Code | advisory rule (no blocking hook found) | Advisory |

Requires Node.js ≥ 18 on `PATH` (except OpenCode). Full matrix, decision mapping, and limits: [`integrations/README.md`](../integrations/README.md).

---

## 5. Agent-private state (`.memory/`)

Skills that keep state write to `.memory/<skill>/` at the project root. Shared team state (for example `.memory/sar/findings.json` in private repositories) is versioned; agent-private paths are ignored by a versioned `.memory/.gitignore` containing `local/`, `*.local.*`, and `*.recovered.json` (equivalent rules for Mercurial and Fossil; Subversion gets a printed command). Tool indexes such as `.codegraph/` and `.docgraph/` are ignored too. In public repositories, SAR keeps its registry and reports under `.memory/local/sar/` so open vulnerabilities are never published.
