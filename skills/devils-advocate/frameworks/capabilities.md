# Optional Capabilities — Devil's Advocate

> ⚠️ **Example code boundary** — commands and configuration below are reference material the agent shows to the user. They are never run without the user's explicit approval of the exact command.

Protocol file. The Devil's Advocate works fully without any tool here. It suggests one only when it would turn a guessed risk into an evidenced one.

Scope (no overlap with other skills): Devil's Advocate = **code graph** for blast-radius evidence. Documentation graphs and skill sync belong to ai-rules; security scanners belong to SAR. Docker-based quality and architecture tools (lizard, jscpd, dependency-cruiser, golangci-lint, actionlint, helm, sqlfluff, PgHero) → [`docker-lab.md`](docker-lab.md).

---

## `@colbymchenry/codegraph` — blast radius as Evidence

**Helps with** §2 *Second-order effects*: who calls the code the plan changes, and which files a change ripples into. Instead of "this may break callers", the risk cites them: *Evidence: called from `src/billing/invoice.ts:88`, `src/api/routes.ts:41` (codegraph)*.

| Fact | Value |
|---|---|
| Package | [`@colbymchenry/codegraph`](https://www.npmjs.com/package/@colbymchenry/codegraph) **1.6.2** (pinned), MIT, npm provenance attestation. The unscoped `codegraph` package is a different, unrelated project |
| Type | MCP server (stdio, `codegraph serve --mcp`) + CLI; bundles its own runtime |
| Storage | `.codegraph/codegraph.db` (SQLite) in the project |
| Network | Code stays local. **Anonymous usage telemetry is on by default** — always disable it (below) |

**Install** — a Tier 2 action: it installs software, so it goes through the Gate like any other plan. Shown to the user, run only after approval:

```bash
npm i -D --save-exact @colbymchenry/codegraph@1.6.2
npx --no codegraph telemetry off
npx --no codegraph init
```

Project-local by default (`devDependencies`, binary in `node_modules/.bin`; the package ships per-platform native builds as optional dependencies). A global install (`npm i -g`) is outside the project and needs explicit approval of that exact command (ai-rules *Project-Local Storage*). Without a `package.json`, ask before creating one, or use the Docker lab route. `--save-exact` keeps `package.json` from widening to `^`; commit the lockfile, which pins transitive versions and integrity hashes.

`codegraph init` creates `.codegraph/` and builds the graph for the current project. Do **not** use the upstream one-line installers that download a script and hand it to a shell interpreter, and do not run `codegraph install` (it rewrites MCP config for every detected agent globally). Configure only the project-level entry below.

**MCP entry** (telemetry off in the server environment too):

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "npx",
      "args": ["--no", "codegraph", "serve", "--mcp"],
      "env": { "CODEGRAPH_TELEMETRY": "0", "DO_NOT_TRACK": "1", "CODEGRAPH_MCP_TOOLS": "explore,callers,impact" }
    }
  }
}
```

By default the server exposes only `codegraph_explore` (source + call paths + a blast-radius summary). `CODEGRAPH_MCP_TOOLS` re-enables `codegraph_callers` and `codegraph_impact`, which map directly to *Evidence* lines.

**Ignore**: `.codegraph/` is a machine-local index → VCS-ignore it (`.gitignore` line `.codegraph/`; `.hgignore` `^\.codegraph/`; Fossil `.codegraph/*`; SVN → tell the user once). Write with file edits only.

**Verify**: `npx --no codegraph --version` prints `1.6.2`; `npx --no codegraph telemetry` reports off; one real MCP call (`codegraph_explore` on a symbol the plan touches) returns its callers.

**Detection (read-only)**: `mcp__codegraph__*` tools available in the session; a `.codegraph/` directory; a `codegraph` entry in the agent's MCP config.

**Using it in the analysis**: query the symbols/files the plan changes; cite the caller files and line numbers in *Evidence*; count affected files for blast radius. A stale or missing index is not evidence — say so and fall back to reading the code.

---

## Where the MCP entry goes (project-level, the agent in use)

| Agent | File | Shape |
|---|---|---|
| Claude Code | `.mcp.json` | `mcpServers.<name>` |
| Cursor | `.cursor/mcp.json` | `mcpServers.<name>` |
| Antigravity | `.agents/mcp_config.json` ⚠️ unverified | `mcpServers.<name>` |
| Gemini CLI | `.gemini/settings.json` | `mcpServers.<name>` |
| VS Code / GitHub Copilot | `.vscode/mcp.json` | `servers.<name>` |
| Codex CLI | `.codex/config.toml` (project) or `~/.codex/config.toml` (global — ask first) | `[mcp_servers.<name>]` + `[mcp_servers.<name>.env]` |
| Roo Code | `.roo/mcp.json` | `mcpServers.<name>` |
| Kiro | `.kiro/settings/mcp.json` | `mcpServers.<name>` |
| Other | Show the snippet; the user places it | — |

Edit non-destructively: keep every existing server and key.

---

## Suggestion protocol

1. **Detect read-only first** — session tools, config files, index directories. No probe commands when these answer the question.
2. **Suggest at most once**, inside the report only when it would have changed a risk from *Unverified* to evidenced: one line under *Unverified assumptions* — what it is, why it helps here, the pinned command, telemetry note, link.
3. **Record the answer** in `.memory/local/devils-advocate/capabilities.json` (VCS-ignored — see the `.memory/` rules below):

   ```json
   [{ "tool": "@colbymchenry/codegraph", "status": "declined", "version": "1.6.2", "date": "2026-10-05" }]
   ```

   `status`: `suggested` · `declined` · `installed` · `failed`. Never suggest a `declined` tool again unless the user asks.
4. **One tool at a time, through the Gate.** The user may also run the commands themselves (`! <command>` in Claude Code).
5. **Official registry only, pinned version.** Never never pipe a downloaded script into a shell interpreter (POSIX or PowerShell), no unpinned `npx -y`.
6. **Make it work, then prove it**: install → version check → telemetry off → MCP config → VCS ignore → one real call. On failure, record `failed`, say so in one line, and continue without it.

### `.memory/` rules (when writing `capabilities.json`)

Before the first write under `.memory/`, create `.memory/.gitignore` if missing (or append only the missing lines) — shared state under `.memory/<skill>/` stays versioned, private paths are ignored:

```gitignore
# Managed by carrilloapps/skills — ignores agent-private paths only.
# Shared team state under .memory/<skill>/ stays versioned.
local/
*.local.*
*.recovered.json
```

Mercurial: append `^\.memory/local/`, `^\.memory/.*\.local\.`, `^\.memory/.*\.recovered\.json$` to `.hgignore`. Fossil: append `.memory/local/*`, `.memory/*.local.*`, `.memory/*.recovered.json` to `.fossil-settings/ignore-glob`. Subversion/unknown: tell the user once (`svn propset svn:ignore local .memory`). File writes only; never run VCS commands.

---

Sources: npm registry metadata (`registry.npmjs.org/@colbymchenry/codegraph/latest`, fetched 2026-10-05); [codegraph README](https://github.com/colbymchenry/codegraph) — install, MCP tools, `CODEGRAPH_MCP_TOOLS`, telemetry (`codegraph telemetry off`, `CODEGRAPH_TELEMETRY=0`, `DO_NOT_TRACK=1`).
