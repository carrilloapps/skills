# doctor.ps1 — one-screen health of an agentic-agile project (read-only, no network).
#
# PowerShell twin of doctor.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): aggregates the
# Phase 0 gate and scorecard (check-structure.ps1 --scorecard), hygiene findings (audit-agile.ps1),
# Docker lab availability (lab-probe.ps1) and capability slots marked "none"; then suggests the
# next actions. Same output and exit codes as doctor.sh.
#
# Usage: doctor.ps1 [--root DIR] [--json] [--today YYYY-MM-DD] [--templates DIR]
#        (--fake-resources-file FILE is passed to lab-probe for the parity tests only)
# Exit:  0 healthy (gate open, no hygiene findings) · 1 attention · 3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014

$Root = '.'; $Json = $false; $Today = ''; $Fake = ''; $Tpl = ''
function Fail([string]$msg) { [Console]::Error.WriteLine("doctor: $msg"); exit 3 }
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'today' { if ($k + 1 -ge $args.Count) { Fail '--today needs a value' }; $k++; $Today = [string]$args[$k] }
    'templates' { if ($k + 1 -ge $args.Count) { Fail '--templates needs a value' }; $k++; $Tpl = [string]$args[$k] }
    'fake-resources-file' { if ($k + 1 -ge $args.Count) { Fail '--fake-resources-file needs a value' }; $k++; $Fake = [string]$args[$k] }
    'json' { $Json = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: doctor [--root DIR] [--json] [--today YYYY-MM-DD] [--templates DIR]'; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$Label = $Root.Replace('\', '/'); while ($Label.Length -gt 1 -and $Label.EndsWith('/')) { $Label = $Label.Substring(0, $Label.Length - 1) }
function Get-Field([string]$j, [string]$name) { if ($j -match ('"' + $name + '":([^,}]*)')) { return $Matches[1] }; return '' }
function Get-SField([string]$j, [string]$name) { if ($j -match ('"' + $name + '":"([^"]*)"')) { return $Matches[1] }; return '' }

# ── Collect ──────────────────────────────────────────────────────────────────
$sj = (@(& (Join-Path $PSScriptRoot 'check-structure.ps1') --root $Root --scorecard --json) -join "`n"); $sx = $LASTEXITCODE
if ($sx -eq 3) { Fail "check-structure failed on root: $Root" }
$Gate = Get-SField $sj 'gate'; $SE = Get-Field $sj 'errors'; $SW = Get-Field $sj 'warnings'
$Pct = Get-Field $sj 'percent'; $Sum = Get-Field $sj 'score'
$Areas = @('process', 'capabilities', 'autonomy', 'metrics', 'transcripts')
$Lv = @(); foreach ($a in $Areas) { $Lv += (Get-Field $sj $a) }
$Gaps = @()
if ($sj -match '"gaps":\[([^\]]*)\]' -and $Matches[1] -ne '') { $Gaps = @($Matches[1].Trim('"') -split '","') }

$aa = @('--root', $Root, '--json'); if ($Today -ne '') { $aa += @('--today', $Today) }; if ($Tpl -ne '') { $aa += @('--templates', $Tpl) }
$aj = (@(& (Join-Path $PSScriptRoot 'audit-agile.ps1') @aa) -join "`n"); $ax = $LASTEXITCODE
if ($ax -eq 3) { Fail "audit-agile failed on root: $Root" }
$AN = [int](Get-Field $aj 'count')

$la = @('--root', $Root, '--json', '--catalog', (Join-Path (Split-Path -Parent $PSScriptRoot) 'frameworks/lab-catalog.tsv')); if ($Fake -ne '') { $la += @('--fake-resources-file', $Fake) }
$lj = ''; $lx = 3
try { $lj = (@(& (Join-Path $PSScriptRoot 'lab-probe.ps1') @la 2>$null) -join "`n"); $lx = $LASTEXITCODE } catch { $lx = 3 }
if ($lx -eq 3 -or $lj -eq '') { $Dock = 'unknown'; $DDet = 'lab-probe configuration error' }
else {
  # Read only the "docker":{...} object: "compose" also appears in every selected tool entry.
  $dj = ''; $dm = [regex]::Match($lj, '"docker":\{([^}]*)\}'); if ($dm.Success) { $dj = $dm.Groups[1].Value }
  if ((Get-Field $dj 'daemon') -eq 'true' -and (Get-Field $dj 'compose') -eq 'true') { $Dock = 'yes'; $DDet = 'Docker ' + (Get-SField $dj 'version') }
  else { $Dock = 'no'; $DDet = Get-SField $dj 'unavailable_reason'; if ($DDet -eq '') { $DDet = 'Docker not available' } }
}

# ── Next actions ─────────────────────────────────────────────────────────────
$Act = @()
if ($Gate -ne 'open') { $Act += "Complete plans/agile/ with the team: run scripts/check-structure --root $Label" }
$low = @(); for ($k = 0; $k -lt $Areas.Count; $k++) { if ([int]$Lv[$k] -lt 3) { $low += $Areas[$k] } }
if ($low.Count -gt 0) { $Act += "Fill and confirm the plans/agile/ files of: $($low -join ', ') (target L3)" }
if ($AN -gt 0) { $Act += "Fix the hygiene findings: run scripts/audit-agile --root $Label" }
if ($Dock -ne 'yes') { $Act += "Docker lab unavailable ($DDet): start Docker or use the CLI routes in frameworks/capabilities.md" }
$gl = $Gaps -join ', '
if ($gl -ne '') { $Act += "Decide a tool or 'not applicable' for the capability slots marked none: $gl" }
$Exit = 1; if ($Gate -eq 'open' -and $AN -eq 0) { $Exit = 0 }

# ── Report ───────────────────────────────────────────────────────────────────
function Get-JsonEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }
if ($Json) {
  $sc = ''; if ($sj -match '"scorecard":(\{[^}]*\})') { $sc = $Matches[1] }
  $dv = 'false'; if ($Dock -eq 'yes') { $dv = 'true' }
  $g = ($Gaps | ForEach-Object { '"' + (Get-JsonEsc $_) + '"' }) -join ','
  $ac = ($Act | ForEach-Object { '"' + (Get-JsonEsc $_) + '"' }) -join ','
  Write-Output ('{"root":"' + (Get-JsonEsc $Label) + '","gate":"' + $Gate + '","structure":{"errors":' + $SE + ',"warnings":' + $SW + '},"scorecard":' + $sc + ',"hygiene_findings":' + $AN + ',"docker":{"available":' + $dv + ',"detail":"' + (Get-JsonEsc $DDet) + '"},"gaps":[' + $g + '],"actions":[' + $ac + '],"exit":' + $Exit + '}')
} else {
  Write-Output "doctor $EM $Label"
  Write-Output "1. Phase 0 gate: $Gate ($SE error(s), $SW warning(s))"
  $lvs = @(); for ($k = 0; $k -lt $Areas.Count; $k++) { $lvs += "$($Areas[$k]) L$($Lv[$k])" }
  Write-Output "2. Readiness: $Pct% ($Sum/20) $EM $($lvs -join ', ')"
  Write-Output "3. Hygiene (audit-agile): $AN finding(s)"
  if ($Dock -eq 'yes') { Write-Output "4. Docker lab: available ($DDet)" } else { Write-Output "4. Docker lab: unavailable $EM $DDet" }
  $gs = 'none'; if ($gl -ne '') { $gs = $gl }
  Write-Output "5. Capability gaps: $gs"
  Write-Output 'Next actions:'
  $L = @('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h')
  if ($Act.Count -eq 0) { Write-Output 'a. No action needed.' }
  for ($k = 0; $k -lt $Act.Count; $k++) { Write-Output "$($L[$k]). $($Act[$k])" }
  if ($Exit -eq 0) { Write-Output 'Result: HEALTHY' } else { Write-Output 'Result: ATTENTION' }
}
exit $Exit
