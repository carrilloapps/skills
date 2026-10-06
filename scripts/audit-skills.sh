#!/usr/bin/env bash
# audit-skills.sh — reproduce, before publishing, the skills.sh audit checks that can run locally.
#
#   1. agentskills validate (skills-ref, the Agent Skills reference validator) on every skill
#   2. Cisco skill-scanner (static + YARA + pipeline taint + behavioral analyzers, OFFLINE)
#
# Runs inside a digest-pinned Python container. The repository is mounted read-only and copied
# to a temp dir inside the container; only the pinned packages are downloaded from PyPI.
# Skill content never leaves the machine (no --use-llm, no --use-virustotal).
# Results: .memory/local/devsecops/results/<YYYY-MM-DD>/skills-audit/ (git-ignored).
# Exit codes: 0 clean, 1 validator error or scanner finding, 3 configuration error (no Docker).
# Usage: bash scripts/audit-skills.sh        PowerShell twin: scripts/audit-skills.ps1

set -euo pipefail

IMAGE="python:3.13.16-slim@sha256:3dd7cc108ec1493442514f5c2a871af6af0ec31d768ff6e378a93340c3b3db5f"
SKILLS_REF="skills-ref==0.1.1"
SKILL_SCANNER="cisco-ai-skill-scanner==2.2.1"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_REL=".memory/local/devsecops/results/$(date +%Y-%m-%d)/skills-audit"

command -v docker >/dev/null 2>&1 || { echo "audit-skills: docker not found" >&2; exit 3; }
docker info >/dev/null 2>&1 || { echo "audit-skills: Docker daemon not reachable" >&2; exit 3; }
mkdir -p "$REPO_ROOT/$OUT_REL"

# Docker Desktop on Windows (Git Bash) needs a Windows path for bind mounts.
HOST_ROOT="$REPO_ROOT"
if (cd "$REPO_ROOT" && pwd -W) >/dev/null 2>&1; then HOST_ROOT="$(cd "$REPO_ROOT" && pwd -W)"; fi

status=0
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$HOST_ROOT:/src:ro" -v "$HOST_ROOT/$OUT_REL:/out" \
  -e SKILLS_REF="$SKILLS_REF" -e SKILL_SCANNER="$SKILL_SCANNER" \
  "$IMAGE" sh /src/scripts/audit-skills.container.sh || status=$?
echo "Results: $OUT_REL/"
exit "$status"
