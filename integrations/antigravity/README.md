# Devil's Advocate Guard — Google Antigravity CLI (`agy`) (EXPERIMENTAL)

`PreToolUse` hook using the shared deterministic classifier ([`../core/classifier.mjs`](../core/classifier.mjs)).

**Experimental**: the hook contract is documented, but known bugs affect `allow` and how commands are executed (see limits).

## Decision mapping

| Tier | Default | `DA_GUARD_MODE=strict` | `DA_GUARD_MODE=warn` |
|------|---------|------------------------|----------------------|
| 0 | no decision (empty output) | no decision | no decision |
| 1 | `ask` | `deny` | no decision + stderr notice |
| 2 | **`force_ask`** (prompts even if "Always Allow" was granted before) | `deny` | no decision + stderr notice |

The guard **never emits `allow`**: an `allow` that agy starts honoring would override your own permission rules.

## Install (workspace)

Requires Node.js 18+ on `PATH`.

```bash
mkdir -p .agents/hooks
cp -r integrations/antigravity/hooks/devils-advocate .agents/hooks/
cp integrations/antigravity/hooks.json .agents/hooks.json   # or merge the "devils-advocate-guard" key
```

Global install: merge into `~/.gemini/config/hooks.json` and use an absolute path to `guard.mjs`.

## Uninstall

Remove the `devils-advocate-guard` key from `.agents/hooks.json` (or set `"enabled": false`) and delete `.agents/hooks/devils-advocate/`.

## Guarantees and limits

- **No `allow`, ever.** `allow` is advisory in current builds (google-antigravity/antigravity-cli#1053), but if that is fixed it would override your rules, so Tier 0 and warn mode print nothing.
- The ACP server runs hook commands with `shlex.split` + exec, not `sh -c` (antigravity-cli#1152). The shipped command (`node <path>`) uses no shell syntax, so it works in both modes.
- MCP tool naming in `agy` is not documented; names starting `mcp_` are treated like Gemini CLI (`mcp_<server>_<tool>`).
- Crash, timeout, and empty-output behavior is not documented; third-party reports say some builds treat empty output as deny. If your build blocks read-only steps because of that, update agy or remove the hook — do not patch the guard to print `allow`.
- The Antigravity **IDE** hook support was not verified; this adapter targets `agy`.

## Sources

- Antigravity hooks (locations, `PreToolUse`, camelCase input `toolCall.name`/`args`, `decision` values incl. `force_ask`, tool names): <https://antigravity.google/docs/hooks/>
- `allow` bug: <https://github.com/google-antigravity/antigravity-cli/issues/1053>
- ACP exec bug: <https://github.com/google-antigravity/antigravity-cli/issues/1152>
- Permissions reference (third-party): <https://agenticcontrolplane.com/blog/antigravity-permissions-reference>
