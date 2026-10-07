# Example: Importing a Spec Kit Project

> ⚠️ **Example only** — fictional project and paths; shows the mapping. The import listing uses the real format of `import-speckit`; the `check-spec` block is illustrative (real rule ids, abridged messages).

**Skill version**: 1.0.2

**Request [fictional]:** "We used Spec Kit for two features. Move them to agentic-agile."

## 1. Gate first

> Phase 0 gate closed — `plans/agile/` does not exist yet. The import can convert the Spec Kit constitution into `plans/agile/constitution.md`, but the rest of the team's operating system (DoR, DoD, team, capabilities…) still has to be completed with you before any spec is created.
>
> 1. Run `aa init` and then import (recommended)
> 2. Only show what the import would do (the default: nothing is written without `--write`)
> 3. Stop

The user answers "1". The agent runs `aa init`, the team completes `plans/agile/`, and `check-structure` passes.

## 2. Import

Commands proposed and approved (`import-speckit --help` lists the exact flags; the first run is a dry run by default):

```bash
bash <skill-dir>/scripts/import-speckit.sh --from . --root .
bash <skill-dir>/scripts/import-speckit.sh --from . --root . --write
```

Dry-run listing (real format):

```text
Feature: specs/001-photo-albums → specs/photo-albums
1. create specs/photo-albums/spec.md (from specs/001-photo-albums/spec.md)
2. create specs/photo-albums/design.md (from specs/001-photo-albums/plan.md)
3. create specs/photo-albums/domain-model.md (from specs/001-photo-albums/data-model.md)
4. create specs/photo-albums/tasks.md (from specs/001-photo-albums/tasks.md)
5. skip plans/agile/constitution.md (exists)
Imported content is Proposed: confirm it with the team (Confirmed by), link scenarios to FR-###, then run: aa verify <feature>
Dry run: nothing written. Re-run with --write to apply.
```

Mapping applied:

| Spec Kit | agentic-agile | Conversion |
|----------|---------------|------------|
| `.specify/memory/constitution.md` | `plans/agile/constitution.md` | Principles → `### Article N — <title> (MUST\|SHOULD)`; version kept; amendment row added with the importer as change, **Proposed** until the team confirms |
| `specs/001-photo-albums/` | `specs/photo-albums/` | Numeric prefix dropped; kebab slug kept |
| `spec.md` user stories with P1–P3 | `spec.md` scenarios tagged `@FR-### @P#` | Given/When/Then prose wrapped in ```gherkin blocks; `# Origin: imported from Spec Kit` |
| `FR-###`, `SC-###` | same IDs | Preserved — no renumbering |
| `[NEEDS CLARIFICATION: …]` | *Open questions* with *Blocks sprint? = Yes* | Never resolved by the importer |
| `## Clarifications` sessions | `## Clarifications` | Kept; answers without a named person get `Confirmed by: unknown (imported)` and `check-spec --strict` flags them |
| `plan.md`, `research.md` | `design.md` (8 elements + *Constitution check*), research → design notes or decision records | Elements Spec Kit does not have are left for the team to fill |
| `data-model.md` | `domain-model.md` | Entities table; state machines added later |
| `contracts/` | `contracts/` | Copied as-is |
| `tasks.md` (`T###`, `[P]`, `[US#]`) | `tasks.md` table `ID \| P \| Req \| Task \| Depends \| Est \| Status` | `[US#]` mapped to the FRs of that story; `Est` = `-` until the team votes |
| `checklists/*.md` | `requirements-checklist.md` | Items renumbered `CHK###`, status from the original checkbox converted to ✅/❌ |

## 3. After the import

```text
check-spec — specs/photo-albums
1. error spec.md:41 [clarify-unconfirmed] clarification answer without 'Confirmed by:'
2. error design.md:12 [placeholder] unfilled template placeholder(s): <architectural style>, <state model>, <anti-violations>
Result: 2 error(s), 0 warning(s) — FAIL
```

> Imported 2 initiatives. Both fail `check-spec` on purpose: the importer never invents what Spec Kit did not record (design elements, attribution). Next:
>
> 1. Fill the missing design elements with the tech lead
> 2. Confirm the imported constitution articles in a 15-minute session
> 3. Run `analyze` on both initiatives
>
> Nothing was written to the tracker.
