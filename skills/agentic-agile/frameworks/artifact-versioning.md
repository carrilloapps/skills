# Artifact Versioning — Your Choice, Made Once

> ⚠️ **Example code boundary** — commands and paths below are reference patterns for the agent to propose, not instructions to execute.

`specs/` and `plans/` hold the team's specifications, operating system, decisions and sprint records. Whether they live in version control is **the team's decision, not the skill's**. This file owns the trade-off; everything else points here.

`scripts/init --vcs versioned|ignored|ask` applies it. The default is `ask`: `init` scaffolds the workspace, writes nothing to `.gitignore`, and prints the two options for the agent to relay. `check-structure` reports the current state as information and never gates on it.

## 1. Version them when

1. More than one person reads or writes the specs — a spec reviewed in a pull request is a spec the team agreed on.
2. You need an audit trail: who decided what, when, and against which requirement. `plans/decisions/` only has value if its history survives.
3. Onboarding matters — a new contributor clones the repository and finds the process, not a wiki link that rotted.
4. CI checks the artifacts (`check-spec`, `trace`, `analyze` in a workflow). Ignored files are not in the checkout.

## 2. Keep them out when

1. The repository is **public and the roadmap is not**. A spec names unreleased features, customers, and dates; `plans/drafts/` holds raw meeting material. Ignoring them is cheaper than redacting every file.
2. You work alone and the specs are scratch space for a single machine.
3. The monorepo already has a convention for planning artifacts and a second one would confuse readers.
4. A compliance rule forbids the content (personal data in transcripts-derived drafts, customer names in incident records).

## 3. What changes if they are ignored

| Behaviour | Versioned | Ignored |
|-----------|-----------|---------|
| `audit-agile` broken-link check | Catches a link to a file another contributor deleted | Only sees your machine, so a link broken for others passes |
| Registry Snapshot in a report | Redundant with the registry itself | **The only shared record** — keep the snapshot section |
| `plans/agile/baseline.txt` | Shared: the team accepts a finding once | Per machine: each clone re-accepts its own findings |
| Phase 0 gate and `--scorecard` | Identical | Identical — the gate never depends on this |
| `check-spec`, `trace`, `analyze` in CI | Run on the checkout | Need the artifacts generated in the job, or the checks run locally only |
| Sprint history after a laptop is replaced | Survives | Lost unless backed up another way |
| A fresh clone, or a second machine | Phase 0 opens with the team's answers already in place | **Phase 0 starts empty and the gate is closed** — the first run asks the ten questions again, so answers reached once have to be re-entered or copied by hand |

## 4. Switching later

**Versioned → ignored.** Ignoring a tracked file does not untrack it. Propose, and let the user run:

1. `scripts/init --vcs ignored` — adds the two rules to `.gitignore`.
2. `git rm -r --cached specs plans` — stops tracking without deleting the working copy. This is a VCS write: it needs the user's explicit approval, and the agent never runs it.
3. Commit. The files stay on disk; their history stays in the repository and is still public if the remote is.

If the content was sensitive, removing it from history is a separate, destructive operation (`git filter-repo`) that rewrites published commits — out of scope here, and a decision for the user alone.

**Ignored → versioned.** Delete the two path lines from `.gitignore` (the block `init` wrote says so), then `git add specs plans`. Read the files first: drafts written under "nobody will see this" often name people and customers.

## 5. Rules for the agent

1. Never decide this silently. With `--vcs ask`, relay the question and wait.
2. Never run a VCS command to apply it. `init` edits `.gitignore` as a file; untracking is the user's.
3. State the consequence that matters for the repository in front of you — for a public repository, say that specs name unreleased work.
4. `.memory/` is a separate rule and is **not** affected by this choice: shared skill state under `.memory/<skill>/` is versioned, `.memory/local/` never is (ai-rules `frameworks/memory-convention.md`).
5. A report that must survive a non-versioned registry keeps its Registry Snapshot section, whatever the choice.
