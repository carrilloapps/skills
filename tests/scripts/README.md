# Script parity tests

Every skill script ships as a POSIX `.sh` and a PowerShell `.ps1` twin. These tests prove that both produce the same output, the same exit code, and the same files.

## Run

```bash
bash tests/scripts/run-parity.sh              # bash + pwsh + powershell.exe (whatever is installed)
bash tests/scripts/run-parity.sh --only bash  # one runner: bash | pwsh | powershell
bash tests/scripts/run-e2e.sh                 # rebuild examples/end-to-end.md and run all agentic-agile validators
pwsh tests/scripts/run-parity.ps1             # same suite driven from PowerShell
```

Exit codes: `0` all cases match · `1` at least one mismatch · `3` usage error. CI runs the suite on Ubuntu and Windows (bash, pwsh 7, Windows PowerShell 5.1).

## Layout

| Path | Contents |
|------|----------|
| `cases.tsv` | One case per row: `name`, `mode`, `impl`, `seed`, `args`, expected `exit` |
| `fixtures/` | Fake projects, specs, transcripts, catalogs, and `res-*.json` resource snapshots (committed, including their `node_modules/` and `.memory/local/` folders) |
| `expected/` | Golden outputs: `<name>.out` (stdout) and, for file-writing modes, `<name>.tree` (files produced) |
| `.work/` | Scratch directory for each run (git-ignored) |

Modes: `repo` runs the script from `fixtures/` (read-only scripts); `transcript` copies the sample transcripts into a fresh project; `init` / `init2` run `init` in a fresh project (`init2` runs it twice to prove idempotency). `seed` names a fixture folder copied into the project first (`-` for none). `lab-probe` and `doctor` cases use the test-only `--fake-resources-file` flag so results do not depend on the machine.

## Add a case

1. Add the fixture under `fixtures/` and a row to `cases.tsv`.
2. Generate the golden from bash: `bash tests/scripts/run-parity.sh --update --only bash`, and review the diff in `expected/` — only your new or intended files should change.
3. Run the full suite in every shell you have; both twins must match the golden.
