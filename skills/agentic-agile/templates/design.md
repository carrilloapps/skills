# Design: <Initiative title>

**Initiative**: `<initiative-kebab>` · **Phase**: 2 — Design · **Spec**: [`spec.md`](spec.md)
**Supporting artifacts** (when they apply; link them once they exist): `domain-model.md` · `contracts/` · `process.md` · `tasks.md`

## Constitution check

Phase −1 gate: every article of `plans/agile/constitution.md` is checked before design starts and again before tasks. A ❌ on a MUST article blocks the design unless the team amends the constitution or records a justified exception here.

| Article | Status ✅/❌/⚠️ | Justification |
|---------|----------------|---------------|
| 1 — Simplicity | <✅ / ❌ / ⚠️> | <why the design is the smallest that satisfies the spec> |
| 2 — Anti-abstraction | <✅ / ❌ / ⚠️> | <wrappers or interfaces introduced, and why> |
| 3 — Integration-first, contract-first | <✅ / ❌ / ⚠️> | <contracts written in `contracts/`> |
| 4 — Test-first | <✅ / ❌ / ⚠️> | <tests planned before implementation in `tasks.md`> |
| 5 — Spec as source of truth | <✅ / ❌ / ⚠️> | <spec updated for every behavior change> |
| 6 — Observability | <✅ / ❌ / ⚠️> | <logs, metrics, alerts per success criterion> |
| 7 — Security by default | <✅ / ❌ / ⚠️> | <trust boundaries, secrets, review delegated> |
| 8 — Human authority | <✅ / ❌ / ⚠️> | <no never-delegated action automated> |

## Architecture & Design

### 1. Architectural style

<As the codebase actually is, with the path that shows it.>

### 2. Layers in scope

<Layers that change · layers that must not change.>

### 3. Bounded-context owner

<Module/service that owns the data and the rule.>

### 4. Patterns to mirror

<Existing code to imitate, with paths.>

### 5. State model

<Where state lives; idempotency; multi-instance safety.>

### 6. Composition points

<New collaborators and where they are wired.>

### 7. Public surface delta

| Surface | Added / Changed / Removed | Consumers affected |
|---------|---------------------------|--------------------|

### 8. Anti-violations

<Principles at risk (SSoT, DRY, SRP, layer purity, DIP, YAGNI, stateless, error isolation, type honesty, context cohesion) and how the design avoids each.>

## Module / file map

| Path | Change |
|------|--------|

## Contracts

Public surfaces are written as machine-readable contracts in `specs/<initiative-kebab>/contracts/` **before** implementation (constitution Article 3): one file per surface in the standard's own format (OpenAPI 3.1 for HTTP, AsyncAPI 3.0 for events), every operation or message carrying `x-requirements: [FR-###]` so `trace` links it, contract tests written first and naming the same `FR-###`. Breaking changes are announced before merge (the skill's `frameworks/team-safety.md`).

| File | Standard | Surface | Req |
|------|----------|---------|-----|
| `contracts/<file>` | <OpenAPI 3.1 / AsyncAPI 3.0> | <surface> | <FR-###> |

## Interfaces

<Signatures of new or changed functions, endpoints, events.>

## Data model changes

<Schemas, migrations, backfills — or `N/A — reason`. Entities and state machines live in `domain-model.md`; public contracts in `contracts/`.>

## Rollout & rollback

1. Rollout: <steps, flags, order>
2. Rollback: <how, how long, data implications>

## Gate to Phase 3

1. ⚠️ All 8 elements filled or justified N/A — <evidence>
2. ⚠️ Constitution check has no ❌ on a MUST article without a recorded exception — <evidence>
3. ⚠️ Rollback described — <evidence>
