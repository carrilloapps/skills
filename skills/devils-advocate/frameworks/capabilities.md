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

## Protocol, record, and MCP config location

Suggestion protocol, `capabilities.json` record (`suggested` · `declined` · `installed` · `failed`), and the per-agent MCP config table: ai-rules `frameworks/capabilities.md` — when ai-rules is not installed, apply the same protocol standalone: detect read-only first, suggest each tool at most once, record the decision in `.memory/local/devils-advocate/capabilities.json`, never re-suggest a declined tool, one tool at a time after explicit approval of the exact pinned command from an official registry (never a downloaded script handed to a shell interpreter, never an unpinned `npx -y`), then verify with one real call. `.memory/` ignore rules (five-line `.memory/.gitignore` block with `local/`, `*.local.*`, `*.recovered.json`; Mercurial/Fossil/SVN): ai-rules `frameworks/memory-convention.md`.

Devil's Advocate specifics: suggest codegraph only inside a report, one line under *Unverified assumptions*, when it would have turned an *Unverified* risk into evidenced one; installing it is a Tier 2 action through the Gate; after install: version check → telemetry off → MCP config → VCS ignore → one real `codegraph_explore` call.

---

Sources: npm registry metadata (`registry.npmjs.org/@colbymchenry/codegraph/latest`, fetched 2026-10-05); [codegraph README](https://github.com/colbymchenry/codegraph) — install, MCP tools, `CODEGRAPH_MCP_TOOLS`, telemetry (`codegraph telemetry off`, `CODEGRAPH_TELEMETRY=0`, `DO_NOT_TRACK=1`).
