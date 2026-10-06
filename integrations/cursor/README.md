# Devil's Advocate Guard — Cursor

Two parts, use either or both:

| File | Install to | Strength |
|------|------------|----------|
| [`devils-advocate.mdc`](devils-advocate.mdc) | `.cursor/rules/` | Advisory: rule with `alwaysApply: true`, always in context |
| [`hooks.json`](hooks.json) + [`hooks/devils-advocate/`](hooks/devils-advocate/) | `.cursor/hooks.json`, `.cursor/hooks/devils-advocate/` | Hook: `ask` on Tier 1–2 shell, MCP, and file-write calls |

## Decision mapping

| Hook | Input | Tier 0 | Tier 1–2 | strict | warn |
|------|-------|--------|----------|--------|------|
| `beforeShellExecution` | `command` | `{}` | `permission: "ask"` | `"deny"` | `{}` |
| `beforeMCPExecution` | `tool_name`, `mcp_server_name` | `{}` | `"ask"` | `"deny"` | `{}` |
| `preToolUse` (matcher: write tools only) | `tool_name`, `tool_input.path` | `{}` | `"ask"` | `"deny"` | `{}` |

`user_message` and `agent_message` carry the tier reason. Mode via `DA_GUARD_MODE` in Cursor's environment.

## Install (project)

Requires Node.js 18+ on `PATH`.

```bash
mkdir -p .cursor/hooks .cursor/rules
cp -r integrations/cursor/hooks/devils-advocate .cursor/hooks/
cp integrations/cursor/hooks.json .cursor/hooks.json        # or merge
cp integrations/cursor/devils-advocate.mdc .cursor/rules/
```

## Uninstall

Remove the three entries from `.cursor/hooks.json`, delete `.cursor/hooks/devils-advocate/` and `.cursor/rules/devils-advocate.mdc`.

## Guarantees and limits

- `failClosed: true` is set on all three hooks: if the guard crashes, times out, or `node` is missing, Cursor **blocks** the action instead of letting it through (Cursor's default is fail-open).
- Community reports say `deny` did not always block, and that hooks were intermittently non-functional on Windows. Verify in your Cursor version with a harmless Tier 2 command (for example `git push --dry-run`) before relying on it.
- Cursor's `preToolUse` tool names and argument keys are not fully documented (`Write`, `StrReplace`, `Delete`, … with `path`). The matcher lists the known write tools; read tools are never sent to the guard.

## Sources

- Cursor hooks (events, `permission`, `user_message`/`agent_message`, `failClosed`, `matcher`, exit codes, fail-open default): <https://cursor.com/docs/agent/hooks>
- Cursor rules (`.mdc`, `alwaysApply`): <https://cursor.com/docs/context/rules>
- `deny` reliability report: <https://forum.cursor.com/t/hooks-returning-deny-do-not-seem-to-block-tool-execution-possible-security-concern/154377>
- Windows reliability report: <https://forum.cursor.com/t/hooks-intermittently-non-functional-on-windows-pretooluse-worked-then-stopped-after-hooks-json-edit/154608>
- `preToolUse` tool names/keys (`StrReplace`, `path`), third-party: <https://github.com/vshulcz/deja-vu/issues/4191> · <https://ntorres.dev/blog/cursor-hooks-json-guide>
