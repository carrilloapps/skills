# Devil's Advocate Guard — Kiro (EXPERIMENTAL)

`PreToolUse` command hook using the shared deterministic classifier ([`../core/classifier.mjs`](../core/classifier.mjs)).

**Experimental** because Kiro's PreToolUse stdin schema is only partly documented and some IDE builds do not send the event to command hooks (see limits).

## Decision mapping

Kiro blocks a tool call when a PreToolUse command **exits with code 2**; stderr is returned to the agent. There is no "ask":

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | exit 0, silent | exit 0 | exit 0 |
| 1 | exit 0, notice on stdout | exit 2 | exit 0, notice |
| 2 | **exit 2**, reason on stderr | exit 2 | exit 0, notice |

## Install (project)

Requires Node.js 18+ on `PATH`.

```bash
mkdir -p .kiro/hooks
cp -r integrations/kiro/hooks/devils-advocate .kiro/hooks/
cp integrations/kiro/devils-advocate.json .kiro/hooks/
```

## Uninstall

Delete `.kiro/hooks/devils-advocate.json` and `.kiro/hooks/devils-advocate/`.

## Guarantees and limits

- Exit codes other than 0 and 2 are "silent failure without blocking": a missing `node` **fails open**.
- Malformed JSON is blocked (exit 2). **Empty stdin is let through with a notice**: some Kiro IDE builds do not pass the event JSON to command hooks (kirodotdev/Kiro#7500); blocking there would stop every tool call.
- Tool names used by the matcher: `fs_write`, `str_replace`, `execute_bash`, `shell`, `write`, and `@server/tool` for MCP. Adjust `matcher` in `devils-advocate.json` if your Kiro version names them differently.
- Kiro Crew reports PreToolUse cannot deny on subagent/task-runner paths (kirodotdev/KiroCrew#7547).

## Sources

- Kiro hooks (file location `.kiro/hooks/*.json`, `version`, `trigger`, `matcher`, `action`, stdin JSON): <https://kiro.dev/docs/hooks/>
- Pre Tool Use trigger and tool categories: <https://kiro.dev/docs/hooks/types/>
- Exit code 2 blocks PreToolUse: <https://kiro.dev/docs/crew/capabilities/hooks/>
- IDE event JSON issue: <https://github.com/kirodotdev/Kiro/issues/7500>
- Subagent deny issue: <https://github.com/kirodotdev/KiroCrew/issues/7547>
