# Devil's Advocate Guard — Claude Code plugin

> **Optional and separate from the skill.** `npx skills add carrilloapps/skills@devils-advocate` installs only Markdown instructions. This plugin is the only executable part of the project and must be installed explicitly.

A skill is text: a model can skip it. This plugin moves the gate into the Claude Code harness. Before every side-effecting tool call, a **deterministic** classifier (no AI, no network) assigns a Devil's Advocate risk tier, and Claude Code shows you a confirmation dialog with the reason:

```text
Devil's Advocate · Tier 2 — git push publishes history
```

## What it guarantees — and what it does not

| Guaranteed | Not guaranteed |
|------------|----------------|
| Every Tier 1–2 tool call (see below) stops for your confirmation in normal permission modes, even if a settings allow rule or `acceptEdits` would have let it run | That the model writes a good Devil's Advocate analysis — the plugin cannot read or grade the analysis |
| Same tool call → same tier and same reason, every time | Protection in `auto`, `bypassPermissions`, `--dangerously-skip-permissions`, or `-p` mode: Claude Code turns `ask` into `allow` there (see [Strict mode](#strict-mode)) |
| A reminder of the gate rules is added to Claude's context on every prompt | Protection if `node` is not on `PATH` (see [Requirements](#requirements)) |

## How actions are classified

| Tier | Decision | Examples |
|------|----------|----------|
| 0 | none — Claude Code's normal permission flow applies | `Read`, `Grep`, `Glob`, `WebFetch`; `ls`, `cat`, `rg`, `git status/log/diff/show`; MCP tools named `get_*`, `list_*`, `read_*`, `describe_*` (not `query`/`search`, which can write) |
| 1 | **ask** | Any file edit; `git commit/add/checkout`; commands not known to be read-only (`npm test`, scripts); output redirection to a file; `sed -i`; `rm` of single files; MCP tools that may write |
| 2 | **ask** | `git push` (any), `reset --hard`, `clean -f`, `rebase`, `merge`, `filter-repo`, branch/tag create or delete; `rm -rf`, `sudo`; destructive SQL; `terraform apply/destroy`; `kubectl delete/apply`; `npm publish`; deploys; `curl -X DELETE/POST/PUT/PATCH`; edits to migrations, `.env*`, auth, payments, infrastructure, CI workflows, Dockerfiles, lockfiles, and agent hook/permission configuration (`.claude/settings*`, `.github/hooks/`, `.cursor/hooks*`, …) |

Compound commands (`&&`, `||`, `;`, `|`, `$(…)`, backticks) take the **riskiest** part. Anything the guard cannot parse is treated as Tier 1 and asks — it never fails open by its own logic.

Commands are split without honoring quotes. That can only produce extra fragments, which classify as Tier 1 and ask, so the error always goes toward asking.

## Requirements

- Claude Code with plugin support.
- **Node.js 18+ on `PATH`.** The native Claude Code binary does not ship Node.js, so check with `node --version`. If `node` is missing, Claude Code treats the hook failure as a non-blocking error and the tool call proceeds without the guard — install Node.js before relying on it.

## Install

From the marketplace published at the root of this repository:

```text
/plugin marketplace add carrilloapps/skills
/plugin install devils-advocate-guard@carrilloapps-skills
```

Or from a shell:

```bash
claude plugin marketplace add carrilloapps/skills
claude plugin install devils-advocate-guard@carrilloapps-skills
```

To try it from a local clone without a marketplace:

```bash
claude --plugin-dir ./integrations/claude-code
```

Run `/reload-plugins` (or restart the session) after installing. Install the `devils-advocate` skill too, so the model writes the analysis the dialog is asking you to review.

## Strict mode

In `auto` and `bypassPermissions` modes Claude Code skips `ask` prompts. Enable **Strict mode** in the plugin's options (`/config`, or the prompt shown when the plugin is enabled) to **deny** Tier 1–2 actions in those modes instead of letting them run. In `-p` (headless) mode `ask` is always converted to `allow` by Claude Code; strict mode only applies when the session reports `auto` or `bypassPermissions`.

## Uninstall

```text
/plugin uninstall devils-advocate-guard@carrilloapps-skills
```

## Customize

The rules live in the shared classifier [`../core/classifier.mjs`](../core/classifier.mjs): `READ_ONLY` (commands treated as Tier 0), `DESTRUCTIVE` and `SENSITIVE_PATH` (Tier 2 patterns), `MCP_READ_ONLY`. [`hooks/classifier.mjs`](hooks/classifier.mjs) is a synced copy (a plugin cannot load files outside its own directory). After editing the core, sync and test:

```bash
node integrations/sync-core.mjs
node --test integrations/core/core.test.mjs integrations/claude-code/test/classifier.test.mjs
```

## Security notes

- Reads only the hook event JSON on stdin; writes only the decision JSON (or the reminder text) on stdout.
- No network access, no file writes, no child processes, no dependencies.
- Never returns `allow`: Tier 0 returns no decision, so your deny rules and normal permission flow stay in force.
- Hooks run with your user's permissions — review [`hooks/guard.mjs`](hooks/guard.mjs) and [`hooks/classifier.mjs`](hooks/classifier.mjs) before installing, as with any plugin.

## Sources

- Hooks reference (PreToolUse decisions, precedence, `-p` behavior, exec form, timeouts): <https://code.claude.com/docs/en/hooks>
- Plugin manifest and layout (`.claude-plugin/plugin.json`, `hooks/hooks.json`, `${CLAUDE_PLUGIN_ROOT}`, `userConfig`, `CLAUDE_PLUGIN_OPTION_<KEY>`): <https://code.claude.com/docs/en/plugins-reference>
- Marketplaces (`.claude-plugin/marketplace.json`, relative `source`, install commands): <https://code.claude.com/docs/en/plugin-marketplaces>
- Installation (native binary, no bundled Node.js): <https://code.claude.com/docs/en/setup>
