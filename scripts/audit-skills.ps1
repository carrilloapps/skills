# audit-skills.ps1 — PowerShell twin of scripts/audit-skills.sh (same checks, same exit codes).
#
#   1. agentskills validate (skills-ref, the Agent Skills reference validator) on every skill
#   2. Cisco skill-scanner (static + YARA + pipeline taint + behavioral analyzers, OFFLINE)
#
# Runs inside a digest-pinned Python container; the repository is mounted read-only.
# Skill content never leaves the machine (no --use-llm, no --use-virustotal).
# Results: .memory/local/devsecops/results/<YYYY-MM-DD>/skills-audit/ (git-ignored).
# Exit codes: 0 clean, 1 validator error or scanner finding, 3 configuration error (no Docker).
# Usage: pwsh scripts/audit-skills.ps1   (Windows PowerShell 5.1 works too)

$ErrorActionPreference = 'Stop'

$Image = 'python:3.13.16-slim@sha256:3dd7cc108ec1493442514f5c2a871af6af0ec31d768ff6e378a93340c3b3db5f'
$SkillsRef = 'skills-ref==0.1.1'
$SkillScanner = 'cisco-ai-skill-scanner==2.2.1'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$OutRel = ".memory/local/devsecops/results/$(Get-Date -Format 'yyyy-MM-dd')/skills-audit"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { [Console]::Error.WriteLine('audit-skills: docker not found'); exit 3 }
docker info *> $null
if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine('audit-skills: Docker daemon not reachable'); exit 3 }

$OutDir = Join-Path $RepoRoot $OutRel
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

docker run --rm `
  -v "${RepoRoot}:/src:ro" -v "${OutDir}:/out" `
  -e "SKILLS_REF=$SkillsRef" -e "SKILL_SCANNER=$SkillScanner" `
  $Image sh /src/scripts/audit-skills.container.sh
$status = $LASTEXITCODE
Write-Output "Results: $OutRel/"
exit $status
