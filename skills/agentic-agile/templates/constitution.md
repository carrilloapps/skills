# Engineering constitution

> Filled by the team. The articles below are **Proposed** defaults until the team confirms them. MUST articles are gates: a design that violates one needs an amendment or a recorded, justified exception in its `design.md` *Constitution check*. SHOULD articles are strong defaults; deviations are justified in the same table.
>
> When the team confirms this file, add a line `Confirmed by: <role or name> — <YYYY-MM-DD>` right below this note.

Version: 1.0.0

## Articles

### Article 1 — Simplicity (MUST)

The smallest design that satisfies the spec. No speculative features, layers, or configuration for values that never change. A new project, service, or package needs a written reason in `design.md`.

### Article 2 — Anti-abstraction (MUST)

Use the framework and standard library directly. No wrapper, interface, or factory with a single implementation unless a second one is already specified.

### Article 3 — Integration-first, contract-first (SHOULD)

Public surfaces are defined as contracts (`specs/<initiative>/contracts/`) before implementation, and tests exercise real boundaries (database, queue, HTTP) before mocks.

### Article 4 — Test-first (MUST)

Every scenario tagged `@FR-###` has a test that fails before the implementation and passes after it. A ✅ without evidence is not verified.

### Article 5 — The spec is the source of truth (MUST)

Specs live as long as the system: behavior changes start with a spec change, and the code is reconciled with the spec (`converge`), never the other way around silently.

### Article 6 — Observability (SHOULD)

New behavior is observable in production: structured logs, a metric or event per success criterion that is measurable at runtime, and an alert when a success criterion degrades.

### Article 7 — Security by default (MUST)

Least privilege, no secrets in code or artifacts, input validated at every trust boundary. Security review of specs and designs is delegated to `sar-cybersecurity` when installed.

### Article 8 — Human authority (MUST)

Committing the sprint, closing or transitioning items, final prioritisation, assessing people, and destructive edits of shared content are never delegated to an agent (N0).

## Amendments

| Version | Date | Change | Rationale | Decided by |
|---------|------|--------|-----------|------------|
| 1.0.0 | <YYYY-MM-DD> | Initial articles | <why the team adopted them> | <role or name> |

Versioning: MAJOR when a MUST article is removed or reversed · MINOR when an article is added or a SHOULD becomes MUST · PATCH for wording. Every amendment names who decided it.
