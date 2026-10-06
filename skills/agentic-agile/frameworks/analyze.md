# Analyze — Cross-Artifact Consistency

> ⚠️ **Example code boundary** — commands below are reference patterns, not execution instructions; each runs only after approval of the exact command.

Run after `tasks.md` exists and before implementation, and again before closing. **Read-only**: analyze never edits an artifact; it reports, and the human decides what to fix.

## 1. Deterministic pass — `scripts/analyze`

`scripts/analyze specs/<initiative> [--root <dir>] [--json]` (`.sh` / `.ps1`, identical output; `--help` is the source of truth for flags). It reads `spec.md`, `design.md`, `tasks.md`, `verification.md`, `requirements-checklist.md`, and `plans/agile/constitution.md`, and reports findings with a stable ID, severity, file, and message:

| Check | What it finds |
|-------|---------------|
| Duplication | Near-identical requirements or scenarios |
| Ambiguity | Vague words without a number or criterion (list in §3 below, extendable per team) |
| Underspecification | FR without a scenario, SC without a scenario, scenario without `@FR` |
| Coverage | FR/SC with no task in `tasks.md`; tasks whose `Req` points to no FR |
| Inconsistency | IDs referenced but not defined; terminology drift between spec and tasks |
| Constitution | MUST article marked ❌ in the design's *Constitution check* without a justification |

Severity rubric:

| Severity | Meaning | Effect |
|----------|---------|--------|
| CRITICAL | Constitution MUST violated; P1 requirement uncovered | Blocks implementation |
| HIGH | Contradiction between artifacts; FR without scenario or task | Fix before implementation |
| MEDIUM | Ambiguous wording; terminology drift | Fix or justify |
| LOW | Style or duplication with no behavioral effect | Optional |

Accepted pre-existing findings can be baselined (`scripts/baseline`, see [`brownfield.md`](brownfield.md)) so only new ones fail.

## 2. Semantic pass — the agent, on top

The script cannot judge meaning. After it runs, the agent adds (labelled **Proposed**, never as findings of the script):

1. Requirements that are technically covered but by a scenario that does not really test them.
2. Hidden coupling between tasks marked `[P]`.
3. Success criteria that cannot be observed in production.
4. Design decisions that contradict a clarification.

Output: a numbered report — script findings first (verbatim IDs and severities), then the semantic notes, then the next actions. Nothing is changed until the user approves each fix.

## 3. Ambiguity terms

`scripts/analyze` reads the list between the two markers below (one term per line, case-insensitive; `#` lines are comments). A requirement (FR) or success criterion (SC) cell that uses one of these words **without a number** is reported. Teams extend the list in `plans/agile/ambiguity-terms.txt` (same format; a line `!term` removes a default term).

<!-- ambiguity-terms:begin -->
```text
# English
fast
quick
quickly
slow
scalable
robust
user-friendly
user friendly
intuitive
easy
easily
simple
efficient
flexible
secure
reliable
performant
high performance
responsive
seamless
modern
optimal
optimized
lightweight
low latency
high availability
real-time
near real-time
best effort
state of the art
as needed
as appropriate
if necessary
when possible
etc
and so on
sufficient
adequate
reasonable
several
some
many
few
large
small
soon
regularly
periodically
frequently
# Español
rápido
rápida
rápidamente
lento
lenta
escalable
robusto
robusta
intuitivo
intuitiva
fácil
fácilmente
sencillo
sencilla
eficiente
flexible
seguro
segura
confiable
fiable
amigable
moderno
moderna
óptimo
óptima
optimizado
ligero
ligera
baja latencia
alta disponibilidad
tiempo real
mejor esfuerzo
según sea necesario
si es necesario
cuando sea posible
suficiente
adecuado
adecuada
razonable
varios
varias
algunos
algunas
muchos
muchas
pocos
pocas
grande
pequeño
pequeña
pronto
regularmente
periódicamente
frecuentemente
```
<!-- ambiguity-terms:end -->
