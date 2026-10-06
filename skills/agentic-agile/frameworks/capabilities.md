# Optional Capabilities

The skill works with no extra tools. These make it stronger; each is **suggested at most once**, the decision is recorded in `.memory/local/agentic-agile/capabilities.json` (`{tool, status: suggested|declined|installed|failed, version, date}`), and a declined tool is never suggested again unless the user asks.

No overlap with the other skills: install instructions for shared tools live in the skill that owns them.

| Tool | Helps with | Owner of the install docs |
|------|-----------|---------------------------|
| codegraph | Contrasting a requirement with how the code works today; blast radius for `design.md` element 7 | `devils-advocate` → `frameworks/capabilities.md` |
| docgraph (agent mode, local only) | Searching `plans/`, `specs/`, and project docs for prior decisions | `ai-rules` → `frameworks/capabilities.md` |
| Tracker / docs / chat / observability MCPs | The capability slots | [`integrations.md`](integrations.md) |
| Docker lab tools | Measured quality and security facts for verification | [`docker-lab.md`](docker-lab.md) and each skill's `docker-lab.md` |

If the owning skill is not installed, point the user to its README instead of duplicating instructions.

**Speech-to-text** is out of scope: the skill consumes transcripts the team already produces. It does not install or run transcription engines.

Rules for any install the user accepts: pinned version, official registry or release page only, one tool at a time, exact command shown and approved, verified afterwards (`--version` and one real call), project-level configuration only.
