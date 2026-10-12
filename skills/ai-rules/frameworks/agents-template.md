# AGENTS.md — Advanced Template

> *Protocol file — load when a project needs its agent contract written or upgraded.*
>
> `SKILL.md` → *Version Control* carries the four-line minimum. This file is the full version: one document that wires every capability this collection offers — load order, gates, storage, quality thresholds, security controls, test policy, autonomy, and capability slots — so any agent that reads `AGENTS.md` behaves the same way.

> ⚠️ **Example code boundary** — the template below is a document to copy and edit. Command lines inside it are placeholders for the project's own commands; they are reference patterns, not execution instructions, and the agent never runs them on its own.

---

## How to use it

1. **Never create it unannounced.** `AGENTS.md` is a project-wide contract: propose it, show what it will contain, and write it only after the user approves (`SKILL.md` → *Bounded autonomy*).
2. **Copy only the blocks that apply.** A project with no sprints deletes the autonomy and ceremonies block. An unreferenced block is worse than a missing one: agents follow it anyway.
3. **Replace every `<placeholder>`.** A placeholder left in place becomes an instruction to invent the value.
4. **Keep it short enough to be read in full.** Target 150–250 lines. Details live in the linked files, never copied here — when a rule exists in a skill, link it instead of restating it, so the two cannot drift apart.
5. **Point every agent at it.** Each agent reads its own instruction file; the common pattern is a one-line file that refers to `AGENTS.md` (`CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/`, `.windsurfrules`, `GEMINI.md`, or the equivalent). Project-level files only — a global agent directory is written to only with the user's explicit approval of that exact path.
6. **Language**: write it in the project's documentation language; identifiers, paths, and commands stay `en_US`.

---

## The template

~~~markdown
# AGENTS.md

<One sentence: what this project is, who uses it, what breaks if it misbehaves.>

**Stack**: <languages, frameworks, package manager, runtime versions>
**Stage**: <prototype | pre-launch | production>
**Documentation language**: <es | en | …>  ·  **Code identifiers**: always `en_US`

## Skill load order (required)

1. `<path>/ai-rules/SKILL.md`          — behavioural baseline (always first): HOW to act
2. `<path>/devils-advocate/SKILL.md`   — risk-scaled pre-execution gate: WHETHER to act
3. On demand — `agentic-agile` (specify, plan, deliver), `sar-cybersecurity` (assess), `postmortem-writing` (learn)

If a skill is not installed, apply the remaining ones and state in one line which check was unavailable.

## Gate before acting (required)

Before proposing or implementing a change, apply the Devil's Advocate at the depth its risk tier requires:
read-only work and trivial reversible edits pass with at most one line; non-trivial changes get a short
evidence-based critique; every non-trivial action and **every version-control write** waits for explicit
approval. Approval of one step never approves the next.

## Context files

| File | Holds | Versioned |
|---|---|---|
| `docs/project-context.md` | Project facts: name, stage, stack, documentation language | Yes |
| `docs/elementals.md` | Index of code elements — checked before creating one, updated when elements are created, renamed, or removed | Yes |
| `.memory/local/ai-rules/developer.md` | Personal preferences of the current developer | No — ignored |

## Storage layout (required)

Everything an agent generates stays inside the project:

| Path | Versioned | Holds |
|---|---|---|
| `specs/<initiative>/` | <yes/no> | Specifications — what and why |
| `plans/` | <yes/no> | Plans, designs, decisions, verification records |
| `docs/` | Yes | Team documentation |
| `.memory/<skill>/` | Yes | Shared skill state |
| `.memory/local/` | No | Agent-private state, tool binaries, virtualenvs, temp files |

Never write to a home or global agent directory, or to the system temp directory, without the user's
explicit approval of that exact path.

## Commands

Run before every commit — all must pass (CI runs them too):

1. `<install>` — dependencies from the lockfile
2. `<lint>` — formatter check, linter, complexity thresholds
3. `<typecheck>` — if the stack has one
4. `<unit tests with coverage>` — must meet the coverage gate below
5. `<e2e tests>` — on the critical paths listed in the test policy
6. `<security scan>` — dependency audit and secret scan

## Quality gates

| Gate | Threshold | Source of truth |
|---|---|---|
| Formatting and linting | Zero warnings | Project config |
| Function complexity | Cyclomatic ≤ 10 · ≤ 30 lines · ≤ 3 parameters · nesting ≤ 3 | `ai-rules/frameworks/code-craft.md` |
| Design review | SOLID smell table; no abstraction with a single implementation | `ai-rules/frameworks/code-craft.md` |
| Unit coverage | **100%** of the declared set — lines, branches, functions, statements | `agentic-agile/frameworks/test-policy.md` |
| Coverage exclusions | Only entries present in `docs/coverage-exclusions.md`, each with a reason and a date | `agentic-agile/frameworks/test-policy.md` |
| Mutation score | ≥ <value>% on <scope> | `agentic-agile/frameworks/test-policy.md` |
| End-to-end | Every `@P1` scenario of the spec has a passing e2e test | `agentic-agile/frameworks/test-policy.md` |
| Pre-launch security | The 20 controls pass or carry an accepted, dated exception | `sar-cybersecurity/frameworks/launch-gate.md` |

A change that lowers a threshold is a decision record, not a commit message.

## Security baseline

- Secrets never reach the repository, the client bundle, logs, or error messages. <Where they do live.>
- Every data-access path is authorized per record, not only per route.
- Every external input is validated at its boundary and every query is parameterized.
- Before a release, run the pre-launch gate and record the result in `<path>`.
- Report a suspected vulnerability through `<channel>`; never open a public issue with exploit detail.

## Architecture rules

1. `<domain layer>` must not import `<infrastructure or vendor SDKs>` — enforced by `<architecture test>`.
2. <Rule that reviewers keep repeating, written once here.>
3. <Boundary or module nobody may bypass, and why.>

## Delivery (when running agentic-agile)

- **Phase 0 gate** — run `<path>/agentic-agile/scripts/check-structure` before creating anything under `specs/` or `plans/`.
- **Autonomy** — N0 human-only · N1 propose · N2 execute with review · N3 execute and report · N4 autonomous.
  Default for this project: <N#>. Operations always at N0: <release, migration, production data, …>.
- **Definition of Done** — `plans/agile/definition-of-done.md`; a scenario without evidence is not done.
- **Traceability** — every scenario carries `@FR-###` and a priority tag; every requirement ends in a test.

## Capability slots (optional tools)

| Slot | Tool in use | Notes |
|---|---|---|
| Issue tracker | <tool / none> | <project key, ticket convention> |
| CI | <tool> | <workflow file> |
| Coverage report | <tool> | <where the report is published> |
| Security scanning | <tool / none> | <schedule> |
| MCP servers | <names / none> | Project-level configuration only |

Tools are suggested once and installed only after the user approves the exact pinned command.

## Conventions

- **Commits**: Conventional Commits, under 72 characters, one logical change per commit.
- **Branches**: `type/description-in-kebab-case`, description in `en_US`.
- **Pull requests**: what changed, why, and how to test it — one sentence minimum each.
- **Options in any agent output**: numbered or lettered, never checkboxes, so they can be approved by number.
- **Attribution**: <no AI co-author lines | the project's rule>.
- **Version-control writes**: never without explicit approval of that exact operation, branch, and files.

## Not done when

1. A quality gate was lowered instead of met.
2. A coverage exclusion was added without a reason and a date.
3. A security control failed with no accepted, dated exception.
4. A change outside the approved scope shipped silently.
~~~

---

## Block reference

| Block | Why it is in the contract | Owner of the detail |
|---|---|---|
| Skill load order | Without an explicit order, each agent resolves its own, and the baseline may load after the gate | `ai-rules/SKILL.md` → *Execution Priority* |
| Gate before acting | The approval point for every non-trivial action and every version-control write | `devils-advocate/SKILL.md` §1 |
| Context files | Stops agents asking for facts the project already records | `ai-rules/frameworks/project-files.md` |
| Storage layout | Keeps generated artifacts inside the project and out of global directories | `ai-rules/SKILL.md` → *Project-Local Storage* |
| Commands | One list that CI and every agent share; drift here is the usual cause of "works for me" | Project |
| Quality gates | Turns principles into numbers a run can fail on | `code-craft.md`, `test-policy.md`, `launch-gate.md` |
| Security baseline | The five rules that apply to every change, not only at release | `sar-cybersecurity` |
| Architecture rules | Review comments that repeat are rules that were never written down | Project |
| Delivery | Only for projects running specs, sprints, and autonomy levels | `agentic-agile/SKILL.md` |
| Capability slots | Declares which optional tools exist, so agents stop re-suggesting them | `frameworks/capabilities.md` of each skill |
| Conventions | Commits, branches, pull requests, attribution, option formatting | `ai-rules/SKILL.md` |
| Not done when | The exit criteria, stated as failures rather than aspirations | Project |

---

## Keeping it true

`AGENTS.md` is read as fact by every agent, so a stale line is an instruction to do the wrong thing.

1. Update it in the **same change** that moves a command, a threshold, or a path.
2. Review it when a skill is installed or removed, and when the project changes stage.
3. If a rule in it conflicts with an installed skill, note the conflict in one line and apply the more specific rule (`ai-rules/SKILL.md` → *Execution Priority*).
4. Never copy a rule that lives in a skill — link it. Two copies drift; one link cannot.
