# Capabilities

> Filled by the team. Which tool fills each capability slot, and which third-party capabilities are authorized. Never put secrets here.
>
> When the team confirms this file, add a line `Confirmed by: <role or name> — <YYYY-MM-DD>` right below this note.

## Slots

| Slot | Tool / MCP | Version | Config file (project-level) | Owning or enrichment |
|------|------------|---------|-----------------------------|----------------------|
| Tracker | | | | owning |
| Docs | | | | owning |
| Chat | | | | enrichment |
| Observability | | | | enrichment |
| Transcript source | | | | owning (for drafts) |
| Warehouse / semantic layer | | | | enrichment |
| Code graph | | | | enrichment |
| Doc / memory graph | | | | enrichment |
| Search | | | | enrichment |
| Model · small | | | | owning |
| Model · default | | | | owning |
| Model · deep | | | | owning |
| Agent runner | | | | owning |

The last five rows are read by `scripts/fanout`. **Model · small / default / deep** hold the model identifier each tier maps to — small is the cheapest model that can execute a self-contained brief, deep is the one reserved for design and ambiguity; put the identifier in the *Tool / MCP* column. **Agent runner** holds the one-line command that runs a brief in the team's agent, with `{{MODEL}}` and `{{BRIEF}}` as placeholders (for example `claude -p --model {{MODEL}} "Execute the brief at {{BRIEF}}"`); fill it from that agent's own `--help`. Like every other slot, an empty cell keeps the Phase 0 gate closed: a team that does not route by model writes `not applicable`, and fanout then asks for the model instead of assuming one.

## Authorized third-party capabilities (four questions)

| Name | Provider | Version | Data reached | Write permissions | Processing & retention | Internal owner | Approved on | Approved by | Review on |
|------|----------|---------|--------------|-------------------|------------------------|----------------|-------------|-------------|-----------|

## Team capability catalogue

| Capability | Have it? | Maturity | Procedure |
|------------|----------|----------|-----------|
| Conversation → work item | | | |
| Adversarial refinement | | | |
| Defect from a thread | | | |
| Sprint summary | | | |
| Estimation against history | | | |
| Blocker detection | | | |
| Changelog | | | |
| Decision record | | | |
