# baseline.ps1 — accept today's findings so only NEW ones fail (brownfield adoption).
#
# PowerShell twin of baseline.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): same
# rules, same output, same exit codes. Runs check-spec, analyze, audit-agile and trace from this
# folder with --json and fingerprints findings as tool|rule|file|message (no line numbers).
# --write stores them in plans/agile/baseline.txt (--dry-run prints only); --check fails only on
# new fingerprints. Phase 0 first (check-structure.ps1). Writes only the baseline file.
#
# Usage: baseline.ps1 --write [--dry-run] | --check   [specs/<initiative> | --spec ... | --all]
#                     [--root DIR] [--file PATH] [--today YYYY-MM-DD] [--strict] [--json]
#                     (--skip-structure exists for the parity tests only)
# Exit:  0 ok · 1 new findings (or gate closed) · 2 stale baseline with --strict · 3 config error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Root = '.'; $Spec = ''; $Mode = ''; $Dry = $false; $File = 'plans/agile/baseline.txt'; $Today = ''; $Strict = $false; $Json = $false; $Skip = $false
function Fail([string]$msg) { [Console]::Error.WriteLine("baseline: $msg"); exit 3 }
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  if (-not $a.StartsWith('-')) { if ($Spec -ne '') { Fail 'only one initiative folder is allowed' }; $Spec = $a; continue }
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'write' { $Mode = 'write' }
    'check' { $Mode = 'check' }
    'dry-run' { $Dry = $true }
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'spec' { if ($k + 1 -ge $args.Count) { Fail '--spec needs a value' }; $k++; $Spec = [string]$args[$k] }
    'all' { }
    'file' { if ($k + 1 -ge $args.Count) { Fail '--file needs a value' }; $k++; $File = [string]$args[$k] }
    'today' { if ($k + 1 -ge $args.Count) { Fail '--today needs a value' }; $k++; $Today = [string]$args[$k] }
    'strict' { $Strict = $true }
    'json' { $Json = $true }
    'skip-structure' { $Skip = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: baseline.ps1 --write [--dry-run] | --check [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--file PATH] [--today YYYY-MM-DD] [--strict] [--json]'; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if ($Mode -eq '') { Fail 'choose --write or --check' }
if ($Dry -and $Mode -ne 'write') { Fail '--dry-run only applies to --write' }
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RL = $Root.Replace('\', '/'); while ($RL.Length -gt 1 -and $RL.EndsWith('/')) { $RL = $RL.Substring(0, $RL.Length - 1) }
$RootFull = (Resolve-Path -LiteralPath $Root).Path
$File = $File.Replace('\', '/')
function JEsc([string]$s) { return $s.Replace('\', '\\').Replace('"', '\"') }
function Invoke-Tool([string]$tool, [object[]]$targs) {
  $p = Join-Path $PSScriptRoot "$tool.ps1"
  $out = (@(& $p @targs 2>$null) -join "`n"); $x = $LASTEXITCODE
  if ($x -eq 3) { Fail "$tool failed with a configuration error" }
  return $out
}

# Phase 0
if (-not $Skip) {
  $cs = Join-Path $PSScriptRoot 'check-structure.ps1'
  if (-not (Test-Path -LiteralPath $cs)) { Fail 'check-structure.ps1 not found next to baseline.ps1' }
  $null = & $cs --root $Root --json 2>$null; $sx = $LASTEXITCODE
  if ($sx -eq 3) { Fail "check-structure failed on root: $Root" }
  if ($sx -ne 0) {
    $msg = "Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
    if ($Json) { Write-Output ('{"root":"' + (JEsc $RL) + '","mode":"' + $Mode + '","gate":"closed","message":"' + (JEsc $msg) + '","exit":1}') }
    else { Write-Output "baseline $EM $RL ($Mode)"; Write-Output "1. error structure [structure-gate] $msg"; Write-Output "Result: gate closed $EM FAIL" }
    exit 1
  }
}

$Names = New-Object System.Collections.Generic.List[string]
$Scope = @()
if ($Spec -ne '') {
  $s = $Spec.Replace('\', '/').TrimEnd('/')
  if (-not ((Test-Path -LiteralPath (Join-Path $RootFull $s) -PathType Container) -or ((Test-Path -LiteralPath $s -PathType Container) -and (Test-Path -LiteralPath (Join-Path (Join-Path $RootFull 'specs') ($s -split '/')[-1]) -PathType Container)))) { Fail "initiative folder not found: $RL/$s" }
  $leaf = ($s -split '/')[-1]; $Names.Add($leaf); $Scope = @('--spec', "specs/$leaf")
} elseif (Test-Path -LiteralPath (Join-Path $RootFull 'specs') -PathType Container) {
  $ds = @(Get-ChildItem -LiteralPath (Join-Path $RootFull 'specs') -Directory -Force | Where-Object { -not $_.Name.StartsWith('.') } | ForEach-Object { $_.Name })
  [Array]::Sort($ds, [System.StringComparer]::Ordinal)
  foreach ($d in $ds) { $Names.Add($d) }
}

# Collect fingerprints
$ReF = [regex]'"file":"((\\.|[^"\\])*)","line":[0-9]+,"rule":"([^"]*)","message":"((\\.|[^"\\])*)"'
$Fp = New-Object System.Collections.Generic.List[string]
function Collect([string]$tool, [string]$json, [string]$prefix) {
  foreach ($m in $ReF.Matches($json)) {
    $f = $m.Groups[1].Value
    if (-not ($f.StartsWith('plans/') -or $f.StartsWith('specs/') -or $f -eq 'structure')) { $f = $prefix + $f }
    $Fp.Add($tool + '|' + $m.Groups[3].Value + '|' + $f + '|' + $m.Groups[4].Value)
  }
}
foreach ($d in $Names) {
  $o = Invoke-Tool 'check-spec' @("$Root/specs/$d", '--root', $Root, '--skip-structure', '--tickets', '--json')
  Collect 'check-spec' $o "specs/$d/"
}
Collect 'analyze' (Invoke-Tool 'analyze' (@('--root', $Root, '--skip-structure', '--json') + $Scope)) ''
$aa = @('--root', $Root, '--json'); if ($Today -ne '') { $aa += @('--today', $Today) }
Collect 'audit-agile' (Invoke-Tool 'audit-agile' $aa) ''
Collect 'trace' (Invoke-Tool 'trace' (@('--root', $Root, '--skip-structure', '--json') + $Scope)) ''

$arr = [string[]]$Fp.ToArray(); [Array]::Sort($arr, [System.StringComparer]::Ordinal)
$Cur = New-Object System.Collections.Generic.List[string]
foreach ($x in $arr) { if ($Cur.Count -eq 0 -or $Cur[$Cur.Count - 1] -ne $x) { $Cur.Add($x) } }

if ($Mode -eq 'write') {
  if (-not $Dry) {
    $target = Join-Path $RootFull $File
    $parent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { $null = New-Item -ItemType Directory -Force -Path $parent }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("# agentic-agile baseline $EM accepted findings (tool|rule|file|message), one per line.`n")
    [void]$sb.Append("# Regenerate with scripts/baseline --write; scripts/baseline --check fails only on findings not listed here.`n")
    foreach ($x in $Cur) { [void]$sb.Append("$x`n") }
    [System.IO.File]::WriteAllText($target, $sb.ToString(), $Utf8)
  }
  if ($Json) {
    $dj = 'false'; if ($Dry) { $dj = 'true' }
    $items = @($Cur | ForEach-Object { '"' + (JEsc $_) + '"' }) -join ','
    Write-Output ('{"root":"' + (JEsc $RL) + '","mode":"write","dry_run":' + $dj + ',"file":"' + (JEsc $File) + '","fingerprints":[' + $items + '],"count":' + $Cur.Count + ',"exit":0}')
  } else {
    Write-Output "baseline $EM $RL (write)"
    for ($i = 0; $i -lt $Cur.Count; $i++) { Write-Output ('{0}. {1}' -f ($i + 1), $Cur[$i]) }
    if ($Dry) { Write-Output "Result: would write $($Cur.Count) fingerprint(s) to $File (dry run)" }
    else { Write-Output "Result: wrote $($Cur.Count) fingerprint(s) to $File" }
  }
  exit 0
}

$bf = Join-Path $RootFull $File
if (-not (Test-Path -LiteralPath $bf -PathType Leaf)) { Fail "baseline not found: $File (run --write first)" }
$Base = New-Object System.Collections.Generic.List[string]
foreach ($l in [System.IO.File]::ReadAllLines($bf, $Utf8)) {
  $l = $l.TrimEnd("`r")
  if ($l -eq '' -or $l.StartsWith('#')) { continue }
  $Base.Add($l)
}
$New = New-Object System.Collections.Generic.List[string]; $Res = New-Object System.Collections.Generic.List[string]; $Acc = 0
foreach ($c in $Cur) { if ($Base.Contains($c)) { $Acc++ } else { $New.Add($c) } }
$barr = [string[]]$Base.ToArray(); [Array]::Sort($barr, [System.StringComparer]::Ordinal)
$prev = $null
foreach ($b in $barr) { if ($b -eq $prev) { continue }; $prev = $b; if (-not $Cur.Contains($b)) { $Res.Add($b) } }
$Exit = 0; if ($New.Count -gt 0) { $Exit = 1 } elseif ($Strict -and $Res.Count -gt 0) { $Exit = 2 }

if ($Json) {
  $n1 = @($New | ForEach-Object { '"' + (JEsc $_) + '"' }) -join ','
  $r1 = @($Res | ForEach-Object { '"' + (JEsc $_) + '"' }) -join ','
  $st = 'false'; if ($Strict) { $st = 'true' }
  Write-Output ('{"root":"' + (JEsc $RL) + '","mode":"check","file":"' + (JEsc $File) + '","new":[' + $n1 + '],"resolved":[' + $r1 + '],"accepted":' + $Acc + ',"strict":' + $st + ',"exit":' + $Exit + '}')
} else {
  Write-Output "baseline $EM $RL (check)"
  if ($New.Count -eq 0) { Write-Output 'No new findings.' } else {
    Write-Output 'New findings:'
    for ($i = 0; $i -lt $New.Count; $i++) { Write-Output ('{0}. {1}' -f ($i + 1), $New[$i]) }
  }
  if ($Res.Count -gt 0) {
    Write-Output 'Resolved (no longer reported; refresh with --write):'
    for ($i = 0; $i -lt $Res.Count; $i++) { Write-Output ('{0}. {1}' -f ($i + 1), $Res[$i]) }
  }
  $v = 'WARN'; if ($Exit -eq 0) { $v = 'PASS' } elseif ($Exit -eq 1) { $v = 'FAIL' }
  Write-Output "Result: $($New.Count) new, $($Res.Count) resolved, $Acc accepted $EM $v"
}
exit $Exit
