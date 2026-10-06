# Example: A Spec Request Blocked by Phase 0, Then Unblocked

> ⚠️ **Example only** — fictional team and project. Commands are illustrative; each runs only after the user approves it.

**Skill version**: 1.0.0

## 1. The request

> **User:** Write the spec for the CSV export of order history.

The agent runs the gate before anything else:

```text
$ scripts/check-structure.sh --root .
check-structure — .
1. error plans/agile/ [missing-dir] missing directory (run scripts/init)
…
17. error plans/agile/autonomy.md [missing-file] missing file (run scripts/init, then complete it with the team)
Result: 17 error(s), 0 warning(s) — FAIL
Phase 0 gate: closed. Do not create specs, plans, drafts, sprint artifacts, tickets or decision records; complete the items above with the team first.
```

## 2. The agent's reply (gate closed)

> Phase 0 gate closed — the project has no agile structure yet; nothing else will be created until it exists.
>
> 1. Scaffold it with `scripts/init.sh` (creates `plans/agile/`, `plans/{sprints,initiatives,decisions,drafts}/`, `specs/`; never overwrites).
> 2. Then we complete it together, one item at a time.
>
> Reply in your own words — for example "dale con 1".

No `specs/order-history-csv/` folder is created, not even an empty one.

## 3. Completing the structure, one finding at a time

After `init`, the gate reports the template placeholders and missing facts. The agent takes them in order and asks only what it cannot read from the project:

| # | Finding | The agent asks | Answer recorded (with attribution) |
|---|---------|----------------|------------------------------------|
| 1 | `methodology.md` — quarter rhythm placeholder | "How many sprints per quarter, and is there a buffer?" | `6 sprints and 1 buffer week` — Scrum master, 2026-10-01 |
| 2 | `ceremonies.md` — days, facilitators, recording | "Which day and who facilitates each ceremony? Are they recorded?" | Filled per ceremony — Scrum master |
| 3 | `team.md` — no role with capacity | "Which roles exist and their usual capacity per sprint?" | Product owner 2 days; Developer 8 days |
| 4 | `capabilities.md` — 8 slots undecided | "Which tool is your tracker? Docs? Is there a transcript source?" | Tracker = GitHub Issues · Chat = none · Observability = not applicable · … |
| 5 | `language.md` — Gherkin language | "Gherkin keywords in English or Spanish?" | `en` |
| 6 | `autonomy.md` — adoption phase and preconditions | "Which adoption phase are we in, and which preconditions are met?" | Phase 1 since 2026-10-01; preconditions 1–4 met, 5–7 not met |

Two rules the agent keeps while filling:

1. **No invention.** When the developer's capacity was unknown, the cell stayed empty and the gate stayed closed until the Scrum master answered.
2. **Confirmation is explicit.** Each file the team accepts gets `Confirmed by: Scrum master — 2026-10-01` under its note; a file that still mentions **Proposed** values without it is a warning (a failure with `--strict`).

## 4. Gate open

```text
$ scripts/check-structure.sh --root . --strict
check-structure — .
No findings.
Result: 0 error(s), 0 warning(s) — PASS
Phase 0 gate: open.
```

Only now does the agent go back to the original request and write `specs/order-history-csv/spec.md` from the template — and `check-spec` runs the same gate again before validating it.

## What this example shows

1. The gate runs **before** the first artifact, not after.
2. A closed gate produces exactly one kind of work: completing `plans/agile/`.
3. Every recorded fact has an owner and a date; unknowns block instead of being guessed.
