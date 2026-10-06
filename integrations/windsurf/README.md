# Devil's Advocate Guard — Windsurf / Devin Desktop (Cascade)

Cascade pre-hooks (`pre_run_command`, `pre_write_code`, `pre_mcp_tool_use`) using the shared deterministic classifier ([`../core/classifier.mjs`](../core/classifier.mjs)).

## Decision mapping

Cascade blocks a pre-hook action when the hook **exits with code 2**; there is no "ask":

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | exit 0, silent | exit 0 | exit 0 |
| 1 | exit 0, notice (shown with `show_output`) | exit 2 | exit 0, notice |
| 2 | **exit 2**, reason on stderr | exit 2 | exit 0, notice |

## Install (workspace)

Requires Node.js 18+ on `PATH`.

```bash
mkdir -p .devin/hooks
cp -r integrations/windsurf/hooks/devils-advocate .devin/hooks/
cp integrations/windsurf/hooks.json .devin/hooks.json   # or merge
```

Legacy Windsurf: `.windsurf/hooks.json` is read only when `.devin/hooks.json` is absent; if you use it, change the paths in the commands from `.devin/` to `.windsurf/`. Each entry has both `command` (macOS/Linux, `bash -c`) and `powershell` (Windows).

## Uninstall

Remove the three entries from `.devin/hooks.json` and delete `.devin/hooks/devils-advocate/`.

## Guarantees and limits

- Non-zero exits other than 2 "proceed normally": a missing `node` **fails open**.
- Malformed events and unknown `agent_action_name` values are blocked (exit 2).
- The hook command runs from the workspace root; use absolute paths if your setup differs.

## Sources

- Cascade hooks (locations, events, `tool_info` fields, `command`/`powershell`/`show_output`, exit code 2): <https://docs.devin.ai/desktop/cascade/hooks>
