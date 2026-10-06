# Shared scripts

Canonical copies of scripts that every skill needs. Skills are installed independently (`npx skills add carrilloapps/skills@<skill>`), so each skill carries its own byte-identical copy in `skills/<skill>/scripts/`.

| Script | Purpose |
|--------|---------|
| `scripts/lab-probe.sh` · `scripts/lab-probe.ps1` | Detect Docker, Compose, RAM, CPUs, disk, and `vm.max_map_count`; match the project's stack against each installed skill's `frameworks/lab-catalog.tsv`; suggest lab tools most critical first within the available resources. Options: `--root DIR`, `--catalog FILE` (repeatable), `--budget-ram MB`, `--include-dashboards`, `--json`. Exit: `0` ok · `3` configuration error · `4` Docker unavailable |

## Workflow

1. Edit only the files in `shared/scripts/` (both twins, identical behavior).
2. Vendor them into every skill: `bash shared/sync.sh` (or `pwsh shared/sync.ps1`).
3. Verify: `bash shared/sync.sh --check` exits `1` on any drift; `validate.sh` (check 29) and CI run it too.
4. Run the parity tests: `bash tests/scripts/run-parity.sh`.
