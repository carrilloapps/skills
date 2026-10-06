# Devil's Advocate Guard — Gemini CLI

`BeforeTool` hook that classifies every shell command, file write, and MCP call with the shared deterministic classifier ([`../core/classifier.mjs`](../core/classifier.mjs)).

## Decision mapping

Gemini CLI hooks can **allow or deny**, not ask. So:

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | `{}` (no decision) | `{}` | `{}` |
| 1 | not blocked; `systemMessage` notice in the terminal | `decision: "deny"` | notice |
| 2 | `decision: "deny"` with the reason | `decision: "deny"` | notice |

A denied call returns the reason to the model as a tool error ("show the user the plan and ask for approval"). After approval, run the command yourself, or start the session with `DA_GUARD_MODE=warn`.

## Install (project)

Requires Node.js 18+ on `PATH`.

```bash
mkdir -p .gemini/hooks
cp -r integrations/gemini-cli/hooks/devils-advocate .gemini/hooks/
```

Merge [`settings.json`](settings.json) into `.gemini/settings.json` (keep your existing keys). Gemini CLI fingerprints project hooks and warns when they change; review and accept them with `/hooks`.

## Uninstall

Remove the `devils-advocate-guard` entry from `.gemini/settings.json` and delete `.gemini/hooks/devils-advocate/`.

## Guarantees and limits

- Exit 0 + JSON on stdout; the guard never uses exit 2.
- Malformed events are denied (fail closed by the guard's own logic).
- The docs do not state what Gemini CLI does if the hook crashes or times out; non-0/2 exit codes are documented as non-fatal warnings, so a missing `node` most likely **fails open**.
- MCP tools are named `mcp_<server>_<tool>`. When `mcp_context.server_name` is present the server prefix is stripped exactly; otherwise a one-word server name is assumed (a longer one only makes the check stricter).
- `$GEMINI_PROJECT_DIR` in the hook command is expanded by the shell; on Windows, if your shell does not expand it, replace it with the absolute project path.

## Sources

- Hooks reference (BeforeTool input/output, `decision`, `reason`, `systemMessage`, exit codes, MCP naming): <https://geminicli.com/docs/hooks/reference/>
- Hooks overview (settings location, matcher, `$GEMINI_PROJECT_DIR`, project hook fingerprinting): <https://geminicli.com/docs/hooks/>
