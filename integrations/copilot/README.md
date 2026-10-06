# Devil's Advocate Guard — GitHub Copilot (CLI, cloud agent, VS Code)

`preToolUse` hook that classifies every tool call with the shared deterministic classifier ([`../core/classifier.mjs`](../core/classifier.mjs)) and asks for confirmation on Tier 1–2.

## Decision mapping

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | no output (normal permission flow) | no output | no output |
| 1–2 | `permissionDecision: "ask"` + reason | `"deny"` | no output |

The decision is written both top-level (Copilot CLI format) and under `hookSpecificOutput` (VS Code format), so one script serves both harnesses. The guard never returns `allow`.

## Install (repository)

Requires Node.js 18+ on `PATH`.

```bash
mkdir -p .github/hooks
cp -r integrations/copilot/hooks/devils-advocate .github/hooks/
cp integrations/copilot/devils-advocate.json .github/hooks/
```

Commit both if the whole team should get the guard.

## Uninstall

Delete `.github/hooks/devils-advocate.json` and `.github/hooks/devils-advocate/`.

## Guarantees and limits

- **Copilot CLI**: `ask` prompts you. A crash or non-zero exit **denies** (fail closed); a timeout **fails open**.
- **Cloud coding agent**: there is no one to answer, so `ask` is treated as **deny** — every Tier 1–2 call is blocked. If you use the cloud agent, set `DA_GUARD_MODE=warn` in its environment (Copilot environment variables) or do not commit the hook.
- **VS Code**: hooks are in Preview; VS Code reads `.github/hooks/*.json`. Its built-in tool names are not documented, so the classifier recognizes them by name pattern (shell: `run_in_terminal`; edits: names containing write/edit/create/replace/insert/patch/delete).
- MCP tool naming in Copilot is not documented; MCP calls that don't use the `mcp__server__tool` form are not gated.

## Sources

- Hooks configuration reference (file location, `preToolUse` input `toolName`/`toolArgs`, `permissionDecision`, exit codes, fail-closed/timeout behavior, cloud agent `ask` → deny): <https://docs.github.com/en/copilot/reference/hooks-configuration>
- Copilot CLI hooks tutorial (`toolArgs` is a JSON string; example payload): <https://github.com/github/docs/blob/main/content/copilot/tutorials/copilot-cli-hooks.md>
- VS Code hooks (locations, `hookSpecificOutput.permissionDecision`, Preview status): <https://code.visualstudio.com/docs/agent-customization/hooks>
