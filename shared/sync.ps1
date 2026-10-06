# sync.ps1 — vendor the canonical shared scripts (shared/scripts/*) byte-identical into every
# skills/<skill>/scripts/ folder, so each skill keeps working when installed alone.
#
# Usage: shared/sync.ps1 [-Check]     (-Check / --check: report drift, change nothing, exit 1 on drift)
# Bash twin: shared/sync.sh.
$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$Check = $false
foreach ($a in $args) {
  switch (([string]$a -replace '^-+', '').ToLowerInvariant()) {
    'check' { $Check = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: sync.ps1 [-Check]'; exit 0 }
    default { [Console]::Error.WriteLine("sync: unknown option: $a"); exit 3 }
  }
}
function Test-Same([string]$a, [string]$b) {
  if (-not (Test-Path -LiteralPath $b -PathType Leaf)) { return $false }
  $x = [System.IO.File]::ReadAllBytes($a); $y = [System.IO.File]::ReadAllBytes($b)
  if ($x.Length -ne $y.Length) { return $false }
  for ($k = 0; $k -lt $x.Length; $k++) { if ($x[$k] -ne $y[$k]) { return $false } }
  return $true
}
$n = 0; $drift = 0
$skills = [System.IO.Directory]::GetDirectories((Join-Path $Repo 'skills')); [Array]::Sort($skills, [StringComparer]::Ordinal)
$sources = [System.IO.Directory]::GetFiles((Join-Path (Join-Path $Repo 'shared') 'scripts')); [Array]::Sort($sources, [StringComparer]::Ordinal)
foreach ($skill in $skills) {
  if (-not ((Test-Path -LiteralPath (Join-Path $skill 'SKILL.md')) -or (Test-Path -LiteralPath (Join-Path $skill 'frameworks')))) { continue }
  foreach ($src in $sources) {
    $dest = Join-Path (Join-Path $skill 'scripts') ([System.IO.Path]::GetFileName($src))
    $rel = $dest.Substring($Repo.Length + 1).Replace('\', '/')
    if (Test-Same $src $dest) { continue }
    $n++
    if ($Check) { Write-Output "$n. drift: $rel"; $drift = 1 }
    else { [void][System.IO.Directory]::CreateDirectory((Split-Path $dest)); [System.IO.File]::Copy($src, $dest, $true); Write-Output "$n. synced: $rel" }
  }
}
if ($n -eq 0) { Write-Output 'All vendored shared scripts are in sync.' }
exit $drift
