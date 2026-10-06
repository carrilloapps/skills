# trace.ps1 — requirement traceability matrix for SDD initiatives (specs/<initiative>/).
#
# PowerShell twin of trace.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): same rules,
# same output, same exit codes. FR-### / SC-### from spec.md -> Gherkin scenarios (@FR / @SC
# tags, inherited from Feature/Rule tags) -> tasks.md (Req column) -> tickets in
# plans/initiatives/<initiative>/tickets/ -> test files -> verification.md rows. Phase 0 first
# (check-structure.ps1). Read-only.
#
# Usage: trace.ps1 [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--tests-dir DIR]...
#                  [--strict] [--json]          (--skip-structure exists for the parity tests only)
# Exit:  0 pass · 1 errors · 2 warnings with --strict · 3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Root = '.'; $Spec = ''; $All = $false; $Strict = $false; $Json = $false; $Skip = $false; $TDirs = @()
function Fail([string]$msg) { [Console]::Error.WriteLine("trace: $msg"); exit 3 }
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  if (-not $a.StartsWith('-')) { if ($Spec -ne '') { Fail 'only one initiative folder is allowed' }; $Spec = $a; continue }
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'spec' { if ($k + 1 -ge $args.Count) { Fail '--spec needs a value' }; $k++; $Spec = [string]$args[$k] }
    'all' { $All = $true }
    'tests-dir' { if ($k + 1 -ge $args.Count) { Fail '--tests-dir needs a value' }; $k++; $TDirs += [string]$args[$k] }
    'strict' { $Strict = $true }
    'json' { $Json = $true }
    'skip-structure' { $Skip = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } {
      Write-Output 'Usage: trace [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--tests-dir DIR]... [--strict] [--json]'
      Write-Output "Test files: tests/, test/, spec/, __tests__/, src/ (names with 'test' or '.spec.', case-insensitive) and every --tests-dir."
      Write-Output 'Skipped: node_modules, .git, .memory/local, fixtures, testdata, __fixtures__, .work, templates, expected, golden, goldens, snapshots, __snapshots__.'
      exit 0
    }
    default { Fail "unknown option: $a" }
  }
}
if ($All -and $Spec -ne '') { Fail '--all takes no initiative folder' }
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RL = $Root.Replace('\', '/'); while ($RL.Length -gt 1 -and $RL.EndsWith('/')) { $RL = $RL.Substring(0, $RL.Length - 1) }
$RootFull = (Resolve-Path -LiteralPath $Root).Path

$Findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($sev, $file, $line, $rule, $msg) { $Findings.Add([pscustomobject]@{ Sev = $sev; File = $file; Line = [int]$line; Rule = $rule; Msg = $msg }) }
function JEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }

$I = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$ReFence = [regex]'^\s*(```|~~~)'
$ReGFence = New-Object regex('^\s*(```|~~~)\s*(gherkin|feature|cucumber)(\s|$)', $I)
$ReScen = New-Object regex('^\s*(scenario|scenario outline|scenario template|escenario|esquema del escenario|plantilla del escenario|example|ejemplo)\s*:\s*(.*)$', $I)
$ReCont = New-Object regex('^\s*(feature|rule|caracter\u00edstica|regla)\s*:', $I)
$ReFeat = New-Object regex('^\s*(feature|caracter)', $I)
$ReTagL = [regex]'^\s*@'
$ReFrRow = [regex]'^\s*[|]\s*(FR-[0-9]+)\s*[|]'
$ReScRow = [regex]'^\s*[|]\s*(SC-[0-9]+)\s*[|]'
$ReTRow = [regex]'^\s*[|]\s*(T[0-9]+)\s*[|]'
$ReSep = [regex]'^\s*[|]?\s*:?-{3,}'
$ReRow = [regex]'^\s*[|]'
$ReScenCol = New-Object regex('(scenario|escenario)', $I)
$ReKeep = [regex]'^\s*(#|$)'
$ReMark = [regex]'(\u2705|\u26a0\ufe0f|\u26a0|\u274c)'
$ReFr = [regex]'FR-[0-9]+'

function Read-Lines([string]$path) { # non-fenced lines (Gherkin fences kept) as objects { No, Text }
  $out = New-Object System.Collections.Generic.List[object]
  $n = 0; $fence = $false; $g = $false
  foreach ($l in [System.IO.File]::ReadAllLines($path, $Utf8)) {
    $n++; $l = $l.TrimEnd("`r")
    if ($ReFence.IsMatch($l)) {
      if (-not $fence) { $fence = $true; $g = $ReGFence.IsMatch($l) } else { $fence = $false; $g = $false }
      continue
    }
    if ($fence -and -not $g) { continue }
    $out.Add([pscustomobject]@{ No = $n; Text = $l })
  }
  return , $out
}
function Get-Cells([string]$row) {
  $r = $row.Trim(); if ($r.StartsWith('|')) { $r = $r.Substring(1) }; $r = $r.Trim(); if ($r.EndsWith('|')) { $r = $r.Substring(0, $r.Length - 1) }
  return , @($r.Split('|') | ForEach-Object { $_.Trim() })
}
function Get-Ids([string]$text, [string]$prefix) {
  $ids = New-Object System.Collections.Generic.List[string]
  foreach ($m in [regex]::Matches($text, $prefix + '-[0-9]+')) { if (-not $ids.Contains($m.Value)) { $ids.Add($m.Value) } }
  return , $ids
}
function Inc([hashtable]$h, [string]$key) { if ($h.ContainsKey($key)) { $h[$key] = $h[$key] + 1 } else { $h[$key] = 1 } }

# Phase 0
$Gate = $false
if (-not $Skip) {
  $cs = Join-Path $PSScriptRoot 'check-structure.ps1'
  if (-not (Test-Path -LiteralPath $cs)) { Fail 'check-structure.ps1 not found next to trace.ps1' }
  $null = & $cs --root $Root --json 2>$null; $sx = $LASTEXITCODE
  if ($sx -eq 3) { Fail "check-structure failed on root: $RL" }
  if ($sx -ne 0) {
    $Gate = $true
    Add-Finding 'error' 'structure' 0 'structure-gate' "Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
  }
}

# Initiatives
$Names = New-Object System.Collections.Generic.List[string]
if (-not $Gate) {
  if ($Spec -ne '') {
    $s = $Spec.Replace('\', '/').TrimEnd('/')
    if (-not ((Test-Path -LiteralPath (Join-Path $RootFull $s) -PathType Container) -or ((Test-Path -LiteralPath $s -PathType Container) -and (Test-Path -LiteralPath (Join-Path (Join-Path $RootFull 'specs') ($s -split '/')[-1]) -PathType Container)))) { Fail "initiative folder not found: $RL/$s" }
    $Names.Add(($s -split '/')[-1])
  } elseif (Test-Path -LiteralPath (Join-Path $RootFull 'specs') -PathType Container) {
    $ds = @(Get-ChildItem -LiteralPath (Join-Path $RootFull 'specs') -Directory -Force | Where-Object { -not $_.Name.StartsWith('.') } | ForEach-Object { $_.Name })
    [Array]::Sort($ds, [System.StringComparer]::Ordinal)
    foreach ($d in $ds) { $Names.Add($d) }
  }
}

# Test corpus: one id set per test file
$TestIds = New-Object System.Collections.Generic.List[object]
function Scan-Dir([string]$rel, [bool]$namesOnly) {
  $full = Join-Path $RootFull $rel
  if (-not (Test-Path -LiteralPath $full -PathType Container)) { return }
  foreach ($f in Get-ChildItem -LiteralPath $full -Recurse -File -Force) {
    $p = $f.FullName.Substring($RootFull.Length).Replace('\', '/')
    if ($p -match '/(node_modules|\.git|fixtures|testdata|__fixtures__|\.work|templates|expected|golden|goldens|snapshots|__snapshots__)/' -or $p -match '/\.memory/local/') { continue }
    if ($namesOnly -and -not ($f.Name -like '*test*' -or $f.Name -like '*.spec.*')) { continue }
    $text = [System.IO.File]::ReadAllText($f.FullName, $Utf8)
    $ids = @{}
    foreach ($m in $ReFr.Matches($text)) { $ids[$m.Value] = 1 }
    if ($ids.Count -gt 0) { $TestIds.Add($ids) }
  }
}
if (-not $Gate -and $Names.Count -gt 0) {
  foreach ($d in @('tests', 'test', 'spec', '__tests__')) { Scan-Dir $d $false }
  Scan-Dir 'src' $true
  foreach ($d in $TDirs) { Scan-Dir $d.Replace('\', '/') $false }
}
function Test-Count([string]$id) { $n = 0; foreach ($t in $TestIds) { if ($t.ContainsKey($id)) { $n++ } }; return $n }

$MSpec = New-Object System.Collections.Generic.List[string]
$MRows = New-Object System.Collections.Generic.List[object]
foreach ($name in $Names) {
  $base = "specs/$name"; $dir = Join-Path (Join-Path $RootFull 'specs') $name
  $frs = New-Object System.Collections.Generic.List[string]; $scs = New-Object System.Collections.Generic.List[string]
  $unk = New-Object System.Collections.Generic.List[object]
  $scn = @{}; $tk = @{}; $tkt = @{}; $ver = @{}; $scmap = @{}
  $rows = New-Object System.Collections.Generic.List[object]
  $specFile = Join-Path $dir 'spec.md'
  if (-not (Test-Path -LiteralPath $specFile -PathType Leaf)) {
    Add-Finding 'error' "$base/spec.md" 0 'spec-missing' 'spec.md not found'
    $MSpec.Add($base); $MRows.Add($rows); continue
  }
  $L = Read-Lines $specFile
  $scol = -1; $ftags = ''; $rtags = ''; $pend = ''
  for ($i = 0; $i -lt $L.Count; $i++) {
    $x = $L[$i].Text; $no = $L[$i].No
    $m = $ReFrRow.Match($x)
    if ($m.Success) { if (-not $frs.Contains($m.Groups[1].Value)) { $frs.Add($m.Groups[1].Value) }; continue }
    $m = $ReScRow.Match($x)
    if ($m.Success) {
      $id = $m.Groups[1].Value; if (-not $scs.Contains($id)) { $scs.Add($id) }
      if ($scol -ge 0) { $c = Get-Cells $x; if ($scol -lt $c.Count) { $v = $c[$scol]; if ($v -ne '' -and $v -ne '-') { $scmap[$id] = 1 } } }
      continue
    }
    if ($ReRow.IsMatch($x) -and ($i + 1) -lt $L.Count -and $ReSep.IsMatch($L[$i + 1].Text)) {
      $c = Get-Cells $x; $scol = -1
      for ($q = 0; $q -lt $c.Count; $q++) { if ($ReScenCol.IsMatch($c[$q])) { $scol = $q } }
      continue
    }
    if ($ReTagL.IsMatch($x)) { $pend += " $x"; continue }
    if ($ReCont.IsMatch($x)) {
      if ($ReFeat.IsMatch($x)) { $ftags = $pend; $rtags = '' } else { $rtags = $pend }
      $pend = ''; continue
    }
    $m = $ReScen.Match($x)
    if ($m.Success) {
      $title = $m.Groups[2].Value.TrimEnd()
      $frt = Get-Ids "$ftags $rtags $pend" 'FR'
      foreach ($id in (Get-Ids "$ftags $rtags $pend" 'SC')) { $scmap[$id] = 1 }
      $pend = ''
      if ($frt.Count -eq 0) { Add-Finding 'error' "$base/spec.md" $no 'scenario-untagged' "scenario without an @FR-### tag: $title"; continue }
      foreach ($id in $frt) {
        Inc $scn $id
        if (-not $frs.Contains($id)) { $unk.Add([pscustomobject]@{ No = $no; Id = $id; Title = $title }) }
      }
      continue
    }
    if (-not $ReKeep.IsMatch($x)) { $pend = '' }
  }
  foreach ($u in $unk) {
    if (-not $frs.Contains($u.Id)) { Add-Finding 'error' "$base/spec.md" $u.No 'scenario-unknown-req' ("scenario tag @" + $u.Id + " is not a declared requirement: " + $u.Title) }
  }
  if ($frs.Count -eq 0) { Add-Finding 'error' "$base/spec.md" 0 'no-requirements' 'no FR-### rows in a functional requirements table' }

  $hasT = $false
  $tf = Join-Path $dir 'tasks.md'
  if (Test-Path -LiteralPath $tf -PathType Leaf) {
    $hasT = $true
    foreach ($ln in (Read-Lines $tf)) {
      $m = $ReTRow.Match($ln.Text); if (-not $m.Success) { continue }
      $tid = $m.Groups[1].Value; $c = Get-Cells $ln.Text
      $req = ''; if ($c.Count -gt 2) { $req = $c[2] }
      foreach ($id in (Get-Ids $req 'FR')) {
        if ($frs.Contains($id)) { Inc $tk $id } else { Add-Finding 'error' "$base/tasks.md" $ln.No 'task-unknown-req' "task $tid references $id, which is not a declared requirement" }
      }
    }
  }
  $hasK = $false
  $td = Join-Path (Join-Path (Join-Path (Join-Path $RootFull 'plans') 'initiatives') $name) 'tickets'
  if (Test-Path -LiteralPath $td -PathType Container) {
    $hasK = $true
    foreach ($t in Get-ChildItem -LiteralPath $td -Filter '*.md' -File) {
      $ids = @{}
      foreach ($m in $ReFr.Matches([System.IO.File]::ReadAllText($t.FullName, $Utf8))) { $ids[$m.Value] = 1 }
      foreach ($id in $ids.Keys) { Inc $tkt $id }
    }
  }
  $hasV = $false
  $vf = Join-Path $dir 'verification.md'
  if (Test-Path -LiteralPath $vf -PathType Leaf) {
    $hasV = $true
    foreach ($ln in (Read-Lines $vf)) {
      $x = $ln.Text
      if (-not $ReRow.IsMatch($x)) { continue }
      $ids = Get-Ids $x 'FR'; if ($ids.Count -eq 0) { continue }
      $mark = '-'; $mm = $ReMark.Match($x); if ($mm.Success) { $mark = $mm.Groups[1].Value }
      if ($mark -eq ([string][char]0x26a0 + [char]0xfe0f)) { $mark = [string][char]0x26a0 }
      foreach ($id in $ids) { if (-not $ver.ContainsKey($id) -or $ver[$id] -eq '-') { $ver[$id] = $mark } }
    }
  }

  foreach ($id in $frs) {
    $sc = 0; if ($scn.ContainsKey($id)) { $sc = $scn[$id] }
    $tc = Test-Count $id
    $tkv = '-'; if ($hasT) { $tkv = 0; if ($tk.ContainsKey($id)) { $tkv = $tk[$id] } }
    $ktv = '-'; if ($hasK) { $ktv = 0; if ($tkt.ContainsKey($id)) { $ktv = $tkt[$id] } }
    $vr = '-'; if ($hasV) { $vr = 'none'; if ($ver.ContainsKey($id)) { $vr = $ver[$id] } }
    $rows.Add([pscustomobject]@{ Id = $id; Kind = 'FR'; Sc = "$sc"; Tk = "$tkv"; Kt = "$ktv"; Tc = "$tc"; Vr = $vr })
    if ($sc -le 0) { Add-Finding 'error' "$base/spec.md" 0 'fr-no-scenario' "$id has no scenario tagged @$id" }
    if ($hasT -and "$tkv" -eq '0') { Add-Finding 'error' "$base/tasks.md" 0 'fr-no-task' "$id has no task in tasks.md" }
    if ($hasV -and $vr -eq 'none') { Add-Finding 'error' "$base/verification.md" 0 'fr-no-verification' "$id has no row in verification.md" }
    if ($tc -le 0) { Add-Finding 'warning' "$base/spec.md" 0 'fr-no-test' "$id is not referenced by any test file" }
  }
  foreach ($id in $scs) {
    $mp = 'no'; if ($scmap.ContainsKey($id)) { $mp = 'yes' }
    $rows.Add([pscustomobject]@{ Id = $id; Kind = 'SC'; Sc = $mp; Tk = '-'; Kt = '-'; Tc = '-'; Vr = '-' })
    if ($mp -ne 'yes') { Add-Finding 'warning' "$base/spec.md" 0 'sc-no-scenario' "$id is not mapped to a scenario (Scenario(s) column or @$id tag)" }
  }
  $MSpec.Add($base); $MRows.Add($rows)
}

# Report
$E = @($Findings | Where-Object { $_.Sev -eq 'error' }).Count; $W = $Findings.Count - $E
$Exit = 0; if ($E -gt 0) { $Exit = 1 } elseif ($Strict -and $W -gt 0) { $Exit = 2 }
function Num([string]$v) { if ($v -eq '-' -or $v -eq 'none') { return 'null' }; return $v }

if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"root":"' + (JEsc $RL) + '","specs":[')
  for ($s = 0; $s -lt $MSpec.Count; $s++) {
    if ($s -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"spec":"' + (JEsc $MSpec[$s]) + '","matrix":[')
    $first = $true
    foreach ($r in $MRows[$s]) {
      if (-not $first) { [void]$sb.Append(',') }; $first = $false
      if ($r.Kind -eq 'SC') {
        $mp = 'false'; if ($r.Sc -eq 'yes') { $mp = 'true' }
        [void]$sb.Append('{"id":"' + $r.Id + '","kind":"SC","mapped":' + $mp + '}')
      } else {
        $vj = 'null'; if ($r.Vr -ne '-' -and $r.Vr -ne 'none') { $vj = '"' + $r.Vr + '"' }
        [void]$sb.Append('{"id":"' + $r.Id + '","kind":"FR","scenarios":' + $r.Sc + ',"tasks":' + (Num $r.Tk) + ',"tickets":' + (Num $r.Kt) + ',"tests":' + $r.Tc + ',"verify":' + $vj + '}')
      }
    }
    [void]$sb.Append(']}')
  }
  [void]$sb.Append('],"findings":[')
  for ($i = 0; $i -lt $Findings.Count; $i++) {
    $f = $Findings[$i]
    if ($i -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"n":' + ($i + 1) + ',"severity":"' + $f.Sev + '","file":"' + (JEsc $f.File) + '","line":' + $f.Line + ',"rule":"' + $f.Rule + '","message":"' + (JEsc $f.Msg) + '"}')
  }
  $st = 'false'; if ($Strict) { $st = 'true' }
  [void]$sb.Append('],"errors":' + $E + ',"warnings":' + $W + ',"strict":' + $st + ',"exit":' + $Exit + '}')
  Write-Output $sb.ToString()
} else {
  Write-Output "trace $EM $RL"
  if (-not $Gate -and $MSpec.Count -eq 0) { Write-Output 'No initiatives under specs/.' }
  for ($s = 0; $s -lt $MSpec.Count; $s++) {
    Write-Output ''
    Write-Output $MSpec[$s]
    if ($MRows[$s].Count -eq 0) { continue }
    Write-Output '| Req | Scenarios | Tasks | Tickets | Tests | Verify |'
    Write-Output '|-----|-----------|-------|---------|-------|--------|'
    foreach ($r in $MRows[$s]) { Write-Output ('| ' + $r.Id + ' | ' + $r.Sc + ' | ' + $r.Tk + ' | ' + $r.Kt + ' | ' + $r.Tc + ' | ' + $r.Vr + ' |') }
  }
  if ($MSpec.Count -gt 0) { Write-Output '' }
  if ($Findings.Count -eq 0) { Write-Output 'No findings.' }
  for ($i = 0; $i -lt $Findings.Count; $i++) {
    $f = $Findings[$i]; $loc = $f.File; if ($f.Line -gt 0) { $loc += ':' + $f.Line }
    Write-Output ('{0}. {1} {2} [{3}] {4}' -f ($i + 1), $f.Sev, $loc, $f.Rule, $f.Msg)
  }
  $v = 'WARN'; if ($Exit -eq 0) { $v = 'PASS' } elseif ($Exit -eq 1) { $v = 'FAIL' }
  Write-Output "Result: $E error(s), $W warning(s) $EM $v"
}
exit $Exit
