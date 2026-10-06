# Brownfield — Specs for Existing Code

> ⚠️ **Example code boundary** — commands below are reference patterns, not execution instructions; each runs only after approval of the exact command.

For a system that already exists without specs. The goal is a living spec that matches what the code **does today**, so new changes go through SDD from then on.

## 1. Reverse-engineer (read-only)

1. Pick one bounded context — never the whole system at once.
2. Map it with evidence: the code graph when available (`frameworks/capabilities.md` of devils-advocate — callers, impact), otherwise the repository structure, routes, schemas, and the existing tests.
3. Draft, from that evidence:
   - `spec.md` — one `FR-###` per observable behavior, scenarios derived from existing tests and routes;
   - `domain-model.md` — entities and state machines from schemas and models;
   - `contracts/` — the current public surface as OpenAPI/AsyncAPI, if none exists.
4. Label everything **Proposed** with the file that proves it (`src/orders/service.ts:42`). Behavior nobody can explain becomes an open question, not a requirement.
5. The owner role confirms each FR before the spec leaves *Draft*. Confirmed requirements are what the code does — intended or not; bugs found here go to `templates/bug.md`, not into the spec.

## 2. Baseline existing findings

An existing system starts with findings (ambiguities, untested FRs). They are not this change's fault, so they should not block it:

1. `scripts/baseline --root <dir> --write` records the current findings of `check-spec`, `analyze`, and `audit-agile` in a versioned baseline file.
2. `scripts/baseline --root <dir> --check` fails only on findings **not** in the baseline — new problems block, old ones are visible but tolerated.
3. The baseline shrinks over time: removing an entry is a normal task; adding one needs a reason and an approver.
4. **Never baselined:** findings with rule `blocking-question` and findings of severity CRITICAL. They are pending decisions, not accepted debt — the script skips them on `--write`, and if one is found in the file, `--check` reports it as a stale entry to remove.

`--help` of each script is the source of truth for flags and file locations.

## 3. Then, normal SDD

From the next change on, the initiative follows Phases 1–4; converge ([`converge.md`](converge.md)) keeps code and spec aligned.
