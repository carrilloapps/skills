# Installing carrilloapps/skills in any agent

Single source of truth for installing `ai-rules`, `devils-advocate`, `sar-cybersecurity`, `agentic-agile`, and `postmortem-writing` in every supported AI coding agent. Skill READMEs link here, and the root [README](../README.md#install-per-tool) carries the per-tool install commands.

> **Before installing**: review the source at [github.com/carrilloapps/skills](https://github.com/carrilloapps/skills) and the latest audit results at [skills.sh/audits](https://skills.sh/audits). The commands below fetch content from a remote repository.

Legend: ✅ verified in the agent's official docs or the [`skills` CLI README](https://github.com/vercel-labs/skills) (checked 2026-10-06; install verified with `skills` CLI 1.7.0) · ⚠️ third-party source or not re-verified — check your agent's docs.

---

## 1. Install with the `skills` CLI (recommended)

```bash
# All five skills, every agent detected in the current project
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

### After installing: where the skills live and how scripts run

Verified with `skills` CLI 1.7.0 (`npx skills add carrilloapps/skills -a claude-code -a antigravity -a codex -y`, 2026-10-06):

1. The canonical copy goes to `.agents/skills/<skill>/` (shared by Antigravity, Codex, Cursor, Gemini CLI, Copilot, OpenCode and others); agents with their own folder get a symlink (e.g. `.claude/skills/<skill>` → `.agents/skills/<skill>`). `--copy` writes real copies instead.
2. Agents load `SKILL.md` automatically; you use the skills by talking to the agent. Scripts (agentic-agile, and `lab-probe` in every skill) are proposed by the agent and run only after you approve the exact command.
3. To run a script yourself, call it from the project root through the installed folder — no `PATH` changes, nothing installed globally:

   ```bash
   bash .agents/skills/agentic-agile/scripts/aa.sh doctor --root .
   bash .agents/skills/sar-cybersecurity/scripts/lab-probe.sh --root .
   ```

   ```powershell
   pwsh -File .agents\skills\agentic-agile\scripts\aa.ps1 doctor --root .
   powershell -ExecutionPolicy Bypass -File .agents\skills\agentic-agile\scripts\aa.ps1 doctor --root .   # Windows PowerShell 5.1
   ```

4. Every script writes inside the project (`plans/`, `specs/`, `.memory/`). With a global install (`-g`), `lab-probe` only auto-discovers catalogs inside the project, so pass `--catalog <skill-dir>/frameworks/lab-catalog.tsv` for each globally installed skill.

---

## 2. Per-agent matrix

| Agent | `-a` id | Project skills path | Global skills path | Always-on instruction file | Optional guard |
|-------|---------|--------------------|--------------------|----------------------------|----------------|
| Claude Code ✅ | `claude-code` | `.claude/skills/` → symlink to `.agents/skills/` (CLI 1.7.0) | `~/.claude/skills/` | `CLAUDE.md` (can import `@AGENTS.md`) | [`claude-code/`](../integrations/claude-code/) (plugin) |
| Antigravity IDE ✅ | `antigravity` | `.agents/skills/` | `~/.gemini/antigravity/skills/` ⚠️ (see note) | `GEMINI.md`, `AGENTS.md`, `.agents/rules/*.md` ⚠️ | — (IDE hooks unverified) |
| Antigravity CLI (`agy`) ✅ | `antigravity-cli` | `.agents/skills/` | `~/.gemini/antigravity-cli/skills/` | same as Antigravity IDE ⚠️ | [`antigravity/`](../integrations/antigravity/) (experimental) |
| Cursor ✅ | `cursor` | `.agents/skills/` or `.cursor/skills/` | `~/.cursor/skills/`, `~/.agents/skills/` | `.cursor/rules/*.mdc` (`alwaysApply`), `AGENTS.md` | [`cursor/`](../integrations/cursor/) |
| Windsurf → Devin Desktop ✅ | `windsurf` | `.devin/skills/` (preferred), `.windsurf/skills/` (legacy, still read; the CLI installs here), `.agents/skills/` | `~/.codeium/windsurf/skills/`, `~/.config/devin/skills/` | rules, `AGENTS.md` | [`windsurf/`](../integrations/windsurf/) |
| GitHub Copilot (VS Code, CLI, cloud agent) ✅ | `github-copilot` | `.github/skills/`, `.claude/skills/`, `.agents/skills/` | `~/.copilot/skills/`, `~/.agents/skills/` | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md` | [`copilot/`](../integrations/copilot/) |
| OpenAI Codex CLI ✅ | `codex` | `.agents/skills/` (cwd, parents, repo root) | `~/.agents/skills/` (docs); the CLI table lists `~/.codex/skills/` | `AGENTS.md` | [`codex/`](../integrations/codex/) |
| Gemini CLI ✅ | `gemini-cli` | `.agents/skills/` (wins over `.gemini/skills/`) | `~/.agents/skills/`, `~/.gemini/skills/` | `GEMINI.md` ⚠️ (`context.fileName` can add `AGENTS.md`) | [`gemini-cli/`](../integrations/gemini-cli/) |
| Cline ✅ | `cline` | `.agents/skills/` (CLI); Cline docs mention `.clinerules/skills/` ⚠️ | `~/.agents/skills/` | `.clinerules/` | [`cline/`](../integrations/cline/) (installs under `.clinerules/hooks/`) |
| Roo Code ✅ | `roo` | `.roo/skills/` | `~/.roo/skills/` | `.roo/rules/`, `~/.roo/rules/` | [`roo/`](../integrations/roo/) (advisory rule only) |
| OpenCode ✅ | `opencode` | `.agents/skills/` | `~/.config/opencode/skills/` | `AGENTS.md` ⚠️ | [`opencode/`](../integrations/opencode/) (plugin) |
| Kiro (IDE + CLI) ✅ | `kiro-cli` | `.kiro/skills/` | `~/.kiro/skills/` | `.kiro/steering/*.md` | [`kiro/`](../integrations/kiro/) (experimental) |
| Amp ✅ | `amp` | `.agents/skills/` | `~/.config/agents/skills/` | `AGENTS.md` ⚠️ | — |
| Replit ✅ | `replit` | `.agents/skills/` | `~/.config/agents/skills/` | `AGENTS.md` ⚠️ | — |
| Grok Build ✅ | `grok` | `.grok/skills/` | `~/.grok/skills/` | ⚠️ not documented in the CLI table | — |
| Zed · Warp · Kimi Code CLI · Dexto · Loaf · Pi · Sarvam Code ✅ | `zed` · `warp` · `kimi-code-cli` · `dexto` · `loaf` · `pi` · `sarvam-code` | `.agents/skills/` | `~/.agents/skills/` | `AGENTS.md` ⚠️ | — |
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
2. From the clone root, copy (or symlink) `skills/<skill-name>/` into the agent's project or global skills path from the table (for example `cp -r skills/agentic-agile .agents/skills/`). **The folder name must equal the skill `name`** (`devils-advocate`, `sar-cybersecurity`, `ai-rules`, `agentic-agile`, `postmortem-writing`) — Cursor requires it.
3. For an agent without native skill support, add one line to its always-on instruction file pointing at the skill, for example in `AGENTS.md`:

   ```markdown
   Before acting, follow `.agents/skills/devils-advocate/SKILL.md`.
   ```

Equivalent CLI command: `npx skills add carrilloapps/skills@<skill> -a <id> --copy`.

---

## 4. Optional guards (harness enforcement)

Skill instructions cannot force an agent to follow them. The optional guards in [`integrations/`](../integrations/) move the Devil's Advocate gate into each agent's own pre-tool hook, using one deterministic classifier (no AI, no network, no writes). They are **not** installed by `npx skills add`; install them per agent from the adapter README.

The *Optional guard* column above links each adapter; the status matrix (stable / experimental / advisory), hook events, decision mapping, and limits are maintained only in [`integrations/README.md`](../integrations/README.md). Requires Node.js ≥ 18 on `PATH` (except OpenCode).

---

## 5. Agent-private state (`.memory/`)

Skills that keep state write to `.memory/<skill>/` at the project root with selective versioning (shared team state versioned; `local/`, `*.local.*`, `*.recovered.json` ignored by a versioned `.memory/.gitignore`). Summary in [`AGENTS.md` → *Skill state*](../AGENTS.md); the full rule is owned by [`skills/ai-rules/frameworks/memory-convention.md`](../skills/ai-rules/frameworks/memory-convention.md).
