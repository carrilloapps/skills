# The `.memory/` Convention

> Owner of the rule for every skill in this collection. Other skills quote the five-line ignore block and link here; they do not restate the rest.

`.memory/<skill>/` at the project root holds skill state. **Shared team state stays versioned; only agent-private paths are ignored.**

| Path | Versioned? | Holds |
|---|---|---|
| `.memory/<skill>/…` | Yes | State the team shares (e.g. a findings registry) |
| `.memory/local/<skill>/…`, `*.local.*`, `*.recovered.json` | **No** | Agent-private state: developer preferences, capability decisions (`capabilities.json`), caches, tool outputs, recovery copies |
| `.memory/local/tmp/`, `.memory/local/bin/`, `.memory/local/venv/` | **No** | Temporary files, project-local tool binaries and virtualenvs |

`<skill>` is the skill's folder name, with one deliberate short name: `sar-cybersecurity` writes to `.memory/sar/` and `.memory/local/sar/`. `devsecops` is the shared Docker-lab folder used by every skill.

## Before the first write under `.memory/`

Use **file writes only** — never run a VCS command. Existing lines written by the user are never removed; only missing lines are appended.

1. Ensure `.memory/.gitignore` exists with this block (Git, and tools that honor `.gitignore`, such as Jujutsu). The file itself **is versioned**, so every clone ignores the same paths:

```gitignore
# Managed by carrilloapps/skills — ignores agent-private paths only.
# Shared team state under .memory/<skill>/ stays versioned.
local/
*.local.*
*.recovered.json
```

2. Detect other version control systems by their marker at the project root (read-only check) and add the missing rules:

| VCS | Marker at the project root | Rule |
|---|---|---|
| Mercurial | `.hg/` | Append to `.hgignore` in `regexp` syntax (the default; if the file has any `syntax:` line, append `syntax: regexp` first): `^\.memory/local/` · `^\.memory/.*\.local\.` · `^\.memory/.*\.recovered\.json$` |
| Fossil | `.fossil-settings/`, or a `.fslckout` / `_FOSSIL_` checkout file | Append to `.fossil-settings/ignore-glob`: `.memory/local/*` · `.memory/*.local.*` · `.memory/*.recovered.json` (Fossil's `*` also matches `/`) |
| Subversion | `.svn/` | Ignore rules are a property the agent cannot set. Tell the user once: `svn propset svn:ignore local .memory` and, if private files use the `.local.` / `.recovered.json` naming, `svn propset svn:global-ignores "*.local.* *.recovered.json" .memory` (never run them) |
| Other / unknown | — | Tell the user once which paths must be excluded |

3. If a private path (anything under `.memory/local/`, or a public-repository registry) is **already tracked** — it appears in a VCS file listing available to the agent's read-only tools — warn the user. Ignore rules do not affect tracked files; the team untracks them. The agent never untracks, deletes, or rewrites history.

4. Never write secrets, credentials, or another person's personal data anywhere under `.memory/` — shared or private. Machine-local tool indexes outside `.memory/` (`.codegraph/`, `.docgraph/`, `.skill-rules/`) are ignored with the same VCS rules.

## Recording capability decisions

Every skill records its optional-tool decisions in `.memory/local/<skill>/capabilities.json`:

```json
[{ "tool": "<package>", "status": "declined", "version": "<pinned>", "date": "YYYY-MM-DD" }]
```

`status`: `suggested` · `declined` · `installed` · `failed`. One entry per tool, updated in place. A `declined` tool is never suggested again unless the user asks. The suggestion protocol itself lives in [`capabilities.md`](capabilities.md).
