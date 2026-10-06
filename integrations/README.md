# Integrations — enforcing the Devil's Advocate gate

The skills in this repository are Markdown instructions, and a model can skip instructions. Only the agent's harness can stop a tool call. This directory holds **optional** guards that move the gate into each agent's own pre-tool hook.

None of this is installed by `npx skills add`. Each guard is opt-in, per project (or per user where the agent supports it).

## How it works

Every adapter calls the same deterministic classifier, [`core/classifier.mjs`](core/classifier.mjs). It has no AI, no network access, no file writes, and no dependencies. It assigns each tool call a Devil's Advocate risk tier:

| Tier | Meaning | Examples |
|------|---------|----------|
| 0 | Read-only | `ls`, `cat`, `rg`, `git status/log/diff`; read tools; MCP `get_*` / `list_*` / `read_*` / `describe_*` only (`query`/`search`/`execute` can write → ask). Not read-only: `awk`/`sed`, interpreters, `tee`, `xargs`, `sort -o`, `git -c …`, any `FOO=bar` prefix, file redirects |
| 1 | Contained side effect | file edits; `git commit/add`; commands not known to be read-only; MCP tools that may write |
| 2 | Hard to reverse / wide blast radius | `git push`, `reset --hard`, `rebase`; `rm -rf`, `sudo`; destructive SQL; `terraform apply`; `kubectl delete`; `npm publish`; deploys; edits to migrations, `.env*`, auth, payments, infra, CI, lockfiles, and **agent hook config** (so the agent can't quietly switch the guard off) |

Same input → same tier → same decision. Each adapter only translates its agent's event format in and its decision format out.

## Per-agent matrix

| Agent | Adapter | Hook event | Tier 1 → | Tier 2 → | If the hook fails | Status | Source |
|-------|---------|-----------|----------|----------|-------------------|--------|--------|
| **Claude Code** | [`claude-code/`](claude-code/) (plugin) | `PreToolUse` + `UserPromptSubmit` | ask | ask (strict: deny in unattended modes) | fails open (non-blocking error) | Stable | [hooks](https://code.claude.com/docs/en/hooks) |
| **GitHub Copilot** CLI / VS Code | [`copilot/`](copilot/) | `preToolUse` | ask | ask | CLI: crash denies, timeout fails open | Stable (VS Code hooks: Preview) | [hooks config](https://docs.github.com/en/copilot/reference/hooks-configuration) |
| **Cursor** | [`cursor/`](cursor/) (+ advisory `.mdc` rule) | `beforeShellExecution`, `beforeMCPExecution`, `preToolUse` | ask | ask | `failClosed: true` → blocks | Stable (see `deny` reliability reports) | [hooks](https://cursor.com/docs/agent/hooks) |
| **Antigravity CLI** (`agy`) | [`antigravity/`](antigravity/) | `PreToolUse` | ask | force_ask | undocumented | **Experimental** | [hooks](https://antigravity.google/docs/hooks/) |
| **Gemini CLI** | [`gemini-cli/`](gemini-cli/) | `BeforeTool` | notice | **deny** | likely fails open | Stable | [hooks reference](https://geminicli.com/docs/hooks/reference/) |
| **OpenAI Codex CLI** | [`codex/`](codex/) | `PreToolUse` | pass (Codex approval policy) | **deny** | fails open | Stable | [hooks](https://developers.openai.com/codex/hooks) |
| **Windsurf / Devin Desktop** | [`windsurf/`](windsurf/) | `pre_run_command`, `pre_write_code`, `pre_mcp_tool_use` | notice | **block (exit 2)** | fails open | Stable | [Cascade hooks](https://docs.devin.ai/desktop/cascade/hooks) |
| **Cline** | [`cline/`](cline/) | `PreToolUse` | context note | **cancel** | undocumented | Stable | [hooks](https://docs.cline.bot/) ⚠️ (vendor docs; the field names below were verified against a third-party mirror) |
| **Kiro** | [`kiro/`](kiro/) | `PreToolUse` | notice | **block (exit 2)** | fails open | **Experimental** | [hooks](https://kiro.dev/docs/hooks/) |
| **OpenCode** | [`opencode/`](opencode/) (plugin) | `tool.execute.before` | pass (pair with `permission: ask`) | **throw (block)** | in-process: always blocks | Stable | [plugins](https://opencode.ai/docs/plugins/) |
| **Roo Code** | [`roo/`](roo/) | — (no blocking hook found) | advisory rule | advisory rule | — | Advisory only | [rules](https://docs.roocode.com/features/custom-instructions) |

**ask** = the agent shows you a confirmation prompt with the reason. Agents whose hooks can only allow or block can't ask. For those, the default blocks Tier 2 and lets Tier 1 through with a notice, so the agent's own approval settings stay the prompt for everyday edits.

## Modes (agents without a native "ask")

Set `DA_GUARD_MODE` in the environment the agent starts with. A command the model runs can't change it.

| `DA_GUARD_MODE` | Effect |
|-----------------|--------|
| *(unset)* | Block Tier 2, notice on Tier 1 |
| `strict` | Block Tier 1 and Tier 2 (ask-capable agents: deny instead of ask) |
| `warn` | Never block; notices only |

Claude Code uses its plugin option **Strict mode** instead (see [`claude-code/README.md`](claude-code/README.md)).

## Requirements and honest limits

- **Node.js 18+ on `PATH`** for every adapter except OpenCode, which runs inside OpenCode. Without `node`, most agents fail open (Cursor blocks, because `failClosed: true` is set).
- A guard forces a stop. It can't make the model write a good analysis; install the `devils-advocate` skill for that.
- Unattended modes (Claude Code `auto`/`bypassPermissions`/`-p`, Copilot cloud agent, agy headless) turn "ask" into allow or deny. Each adapter README says which.
- The classifier is pattern-based. Commands are split without honoring quotes, which can only over-split toward asking. Unknown commands are Tier 1.

## Maintaining

- Edit the rules only in [`core/classifier.mjs`](core/classifier.mjs), then run `node integrations/sync-core.mjs`. Each adapter ships a byte-identical copy, because agents load hooks from the adapter's own directory. The drift test fails if any copy differs.
- Run every test:

```bash
node --test integrations/core/core.test.mjs integrations/*/test/*.test.mjs
```

(Pass files, not a directory: `node --test <dir>` doesn't work on Windows with Node 22.)
