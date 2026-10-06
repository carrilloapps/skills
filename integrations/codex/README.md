# Devil's Advocate Guard — OpenAI Codex CLI

`PreToolUse` hook for `Bash`, `apply_patch`, `Edit`, `Write`, and MCP tools, using the shared deterministic classifier ([`../core/classifier.mjs`](../core/classifier.mjs)). For `apply_patch`, every file named in the patch body is checked against the sensitive-path rules.

## Decision mapping

Codex parses `permissionDecision: "ask"` but does not support it yet, so the guard can only deny:

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | no output | no output | no output |
| 1 | no output (Codex's own approval policy applies) | `deny` | no output |
| 2 | `deny` with the reason | `deny` | no output |

For a prompt on Tier 1, keep Codex's approval policy on (`on-request` / `untrusted`).

## Install (project)

Requires Node.js 18+ on `PATH`. Hooks are enabled by default; if you disabled them, set `[features] hooks = true` in `config.toml`.

```bash
mkdir -p .codex/hooks
cp -r integrations/codex/hooks/devils-advocate .codex/hooks/
cp integrations/codex/hooks.json .codex/hooks.json   # or merge into an existing one
```

The command path is relative to the directory Codex runs hooks from (the repository root in a normal session). If you start Codex elsewhere, use an absolute path.

## Uninstall

Remove the entry from `.codex/hooks.json` and delete `.codex/hooks/devils-advocate/`.

## Guarantees and limits

- Errors and timeouts **fail open** in Codex ("don't block the operation").
- Malformed events are denied by the guard's own logic.

## Sources

- Codex hooks (locations, `PreToolUse` input, tool names, `permissionDecision` support, fail-open behavior): <https://developers.openai.com/codex/hooks> (redirects to <https://learn.chatgpt.com/docs/hooks>)
