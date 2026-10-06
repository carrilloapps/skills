# Docker Lab — Capacity Probe

> ⚠️ **Example code boundary** — commands below are reference patterns; run them only after the user approves the exact command.

This skill defines **no containers of its own**: agility needs no heavy tooling, and the quality, security, and docs tools already belong to `devils-advocate`, `sar-cybersecurity`, and `ai-rules`. What it adds is the **probe**: before suggesting any lab tool, find out what this machine can actually run, then suggest in order of criticality.

## `scripts/lab-probe`

Same script in every skill (kept identical by the repository's sync check), as `.sh` and `.ps1`.

| Checks | How (read-only) |
|--------|-----------------|
| Docker CLI and daemon | `docker version` |
| Compose v2 | `docker compose version` |
| Memory available to Docker, CPUs | `docker info` |
| Free disk where the project lives | OS disk query |
| `vm.max_map_count` (SonarQube/Elasticsearch) | Linux/WSL `/proc/sys/vm/max_map_count`; reported as unknown elsewhere |

Then it reads one or more **catalogs** (TSV: tool, skill, profile, criticality 1–100, RAM MB, disk MB, needs `max_map_count`, stack signal) — one per installed skill, e.g. `skills/<skill>/frameworks/lab-catalog.tsv` — filters by the stack signals found in the project, sorts by criticality, and greedily keeps what fits in the available RAM and disk. **If only one tool fits, it is the most critical one.**

Output (numbered, so the user can answer "1 and 3"):

```text
Docker 29.x · Compose v5.x · 7.6 GB free for containers · 4 CPUs · 120 GB disk · max_map_count 65530 (SonarQube needs 524288)

Fits now, by criticality:
1. gitleaks   (sar-cybersecurity · secrets)  ~ 100 MB
2. semgrep    (sar-cybersecurity · sast)     ~ 1.5 GB
3. lizard     (devils-advocate · complexity) ~ 200 MB
Does not fit now:
a. sonarqube  — needs max_map_count ≥ 524288 and ~4 GB
```

Options: `--root <dir>` (project root, default current directory) · `--catalog <tsv>` (repeatable; installed skills are auto-discovered inside the project) · `--budget-ram <MB>` · `--include-dashboards` · `--json`. Exit codes: `0` probe done · `3` configuration error (catalog unreadable) · `4` Docker unavailable — the probe says why and points to the CLI routes in each skill's `capabilities.md`.

`lab-probe` skips `fixtures/`, `testdata/`, `__fixtures__/`, `.work/` and `templates/` when matching stack signals; list extra paths in a root `.labprobeignore` (one path or glob per line, `#` comments).

## Using the result

1. Run the probe (Tier 1 command, approved by the user).
2. Show its numbered list unchanged; do not re-rank by intuition.
3. The user picks; the owning skill's `docker-lab.md` has the compose service and the exact `docker compose run` command.
4. Results feed `specs/<i>/verification.md` (4.3 evidence) and the sprint report — as facts with the tool name, version, and result file.
