# Project Files Written by ai-rules

> Templates for the two team-facing files this skill maintains. Both are versioned; neither contains personal data.

## `docs/project-context.md`

Created on demand, one field at a time, when a rule needs a fact that cannot be inferred from the manifests (see *Project Context* in `SKILL.md`).

```markdown
# Project Context

- **Name**:
- **Description**:
- **Stage**: exploration / prototype / development / MVP / production / maintenance
- **Tech stack**:
- **Documentation language**:

*Last updated: YYYY-MM-DD*
```

## `docs/elementals.md`

The living index of project code elements. Updated only when elements are created, renamed, or removed, as part of the approved change (see *Code Quality* in `SKILL.md`). One table; the `Kind` column replaces separate sections.

```markdown
# Project Elementals

> Source of truth for all AI tools. Updated when code elements change.
> Project: [name] — Last updated: YYYY-MM-DD

| Kind | Name | Path | Signature / Type | Description | Status |
|---|---|---|---|---|---|
| component | | | | | Active |
| function | | | parameters (names and types when available) | | Active |
| constant | | | type | | Active |
| type | | | | | Active |
```

**Kind**: `component` · `function` (functions and services) · `constant` (constants and configuration) · `type` (types, interfaces, schemas).
**Status**: `Active` · `Beta` · `Experimental` · `Deprecated` · `Deprecated → renamed to [X]`. Rows are never deleted.
