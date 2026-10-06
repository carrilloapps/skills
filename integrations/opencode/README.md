# Devil's Advocate Guard — OpenCode

Plugin with a `tool.execute.before` hook using the shared deterministic classifier ([`devils-advocate/classifier.mjs`](devils-advocate/classifier.mjs), a synced copy of [`../core/classifier.mjs`](../core/classifier.mjs)).

## Decision mapping

A plugin blocks a tool call by throwing; it cannot ask:

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | passes | passes | passes |
| 1 | passes | **throws** | passes |
| 2 | **throws** with the reason | throws | passes |

For a real confirmation prompt on Tier 1, combine the plugin with OpenCode's own permissions in `opencode.json`:

```json
{
  "permission": {
    "edit": "ask",
    "bash": "ask"
  }
}
```

## Install (project)

Requires an OpenCode version with plugin support (plugins run on OpenCode's bundled runtime; no separate Node.js needed).

```bash
mkdir -p .opencode
cp -r integrations/opencode/plugins integrations/opencode/devils-advocate .opencode/
```

Global install: same layout under `~/.config/opencode/`.

## Uninstall

Delete `.opencode/plugins/devils-advocate-guard.js` and `.opencode/devils-advocate/`.

## Guarantees and limits

- The plugin runs inside OpenCode, so there is no separate process to crash; a thrown error always blocks.
- Tool names: `bash` (`command`), `edit` / `write` (`filePath`), `patch`. MCP tool naming is not documented; MCP calls are not gated unless named `mcp__server__tool`.
- The plugin file exports only the plugin function, because OpenCode treats every export of a plugin file as a plugin.

## Sources

- Plugins (locations, `tool.execute.before`, blocking by throwing, tool names): <https://opencode.ai/docs/plugins/>
- Permissions (`allow` / `ask` / `deny`): <https://opencode.ai/docs/permissions/>
