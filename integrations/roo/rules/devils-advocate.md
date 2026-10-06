# Devil's Advocate gate (advisory)

> Roo Code has no blocking pre-tool hook as of this writing, so this rule is **advisory**: it is always in the model's context but cannot stop a tool call. For a hard stop, keep Roo's own auto-approve settings off for write, execute, and MCP actions.

Before any action with side effects (edit, write, delete, run, deploy, migrate, MCP write, any git write), apply the `devils-advocate` skill:

- Classify the action by risk tier first. Read-only work and trivial reversible edits pass with at most one line.
- For Tier 1+, give the short evidence-based critique, then wait. The user may approve in their own words; a bare "ok" is acknowledgement, not approval.
- Git writes always wait for explicit approval.
- Approved plans are not re-gated; the same plan gets the same verdict.
