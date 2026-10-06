# Devil's Advocate Guard — Cline

`PreToolUse` hook using the shared deterministic classifier ([`../core/classifier.mjs`](../core/classifier.mjs)).

## Decision mapping

Cline hooks return `{ cancel, errorMessage, contextModification }`; there is no "ask":

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | `cancel: false` | `cancel: false` | `cancel: false` |
| 1 | `cancel: false` + `contextModification` note | `cancel: true` | note |
| 2 | **`cancel: true`** + `errorMessage` | `cancel: true` | note |

Cline's own approval settings still apply on top: keep auto-approve off for commands and edits to get a prompt on Tier 1.

## Install (project)

Requires Node.js 18+ on `PATH`.

```bash
mkdir -p .clinerules/hooks
cp -r integrations/cline/hooks/devils-advocate .clinerules/hooks/
# macOS / Linux
cp integrations/cline/hooks/PreToolUse .clinerules/hooks/ && chmod +x .clinerules/hooks/PreToolUse
# Windows
cp integrations/cline/hooks/PreToolUse.ps1 .clinerules/hooks/
```

Global install: same files under `~/Documents/Cline/Hooks/`.

## Uninstall

Delete `.clinerules/hooks/PreToolUse` (or `PreToolUse.ps1`) and `.clinerules/hooks/devils-advocate/`.

## Guarantees and limits

- Cline's docs do not state exit-code or timeout behavior, so a missing `node` may fail open.
- On Windows, PowerShell's execution policy can block `.ps1` scripts; if Cline reports that, allow local scripts (`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`) after reviewing the script.
- Tool names: `execute_command` (`command`), `write_to_file` / `replace_in_file` (`path`), `use_mcp_tool` (`tool_name`). The event key is read as `preToolUse.tool` or `preToolUse.toolName` (sources differ).

## Sources

- Cline hooks (locations, naming, `.ps1` on Windows, input `preToolUse.tool`/`parameters`, output `cancel`/`errorMessage`/`contextModification`): <https://mintlify.wiki/cline/cline/customization/hooks>
- Release notes: <https://cline.ghost.io/cline-v3-36-hooks/>
