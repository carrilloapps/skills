# Ticket Conventions

Copied to `plans/agile/ticket-conventions.md` when the team adopts it; until then it is the reference used by `frameworks/delivery.md`.

## Title pattern

`<Type>: <user-visible outcome>` — the outcome, not the task. Example: `Story: Customers export their order history as CSV`.

## Types

| Type | Use when |
|------|----------|
| Story | New or changed user-visible behavior backed by spec scenarios |
| Defect | Behavior contradicts an approved scenario |
| Task | Technical work with no behavior change (refactor, upgrade) |
| Spike | Timeboxed question (`templates/spike-poc.md`) |

## Labels

<The team's label set: initiative, component, risk. Keep it short and documented here.>

## Required links

1. The spec scenario(s): `specs/<initiative>/spec.md#<scenario>`.
2. The work-item draft in `plans/initiatives/<initiative>/tickets/`.
3. The Definition of Ready: `plans/agile/definition-of-ready.md`.

## Body

1. Acceptance criteria = the Gherkin scenarios, linked or copied verbatim.
2. Out of scope.
3. Dependencies and blockers, linked.
4. Estimate only from the team's vote.

Never: `TBD`, unfilled placeholders, invented estimates, checkbox lists.
