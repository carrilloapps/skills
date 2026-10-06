# analyze.ps1 — deterministic cross-artifact consistency checks for SDD initiatives (specs/<x>/).
#
# PowerShell twin of analyze.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): same rules,
# same output, same exit codes. Severities CRITICAL / HIGH / MEDIUM / LOW with stable IDs
# A001... after sorting (severity, file, line, rule, message). Phase 0 first
# (check-structure.ps1). Read-only.
#
# Usage: analyze.ps1 [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--strict] [--json]
#                    (--skip-structure exists for the parity tests only)
# Exit:  0 pass · 1 CRITICAL/HIGH findings · 2 MEDIUM/LOW findings with --strict · 3 config error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Root = '.'; $Spec = ''; $All = $false; $Strict = $false; $Json = $false; $Skip = $false
function Fail([string]$msg) { [Console]::Error.WriteLine("analyze: $msg"); exit 3 }
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  if (-not $a.StartsWith('-')) { if ($Spec -ne '') { Fail 'only one initiative folder is allowed' }; $Spec = $a; continue }
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'spec' { if ($k + 1 -ge $args.Count) { Fail '--spec needs a value' }; $k++; $Spec = [string]$args[$k] }
    'all' { $All = $true }
    'strict' { $Strict = $true }
    'json' { $Json = $true }
    'skip-structure' { $Skip = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: analyze [specs/<initiative> | --spec specs/<initiative> | --all] [--root DIR] [--strict] [--json]'; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if ($All -and $Spec -ne '') { Fail '--all takes no initiative folder' }
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RL = $Root.Replace('\', '/'); while ($RL.Length -gt 1 -and $RL.EndsWith('/')) { $RL = $RL.Substring(0, $RL.Length - 1) }
$RootFull = (Resolve-Path -LiteralPath $Root).Path

$Found = New-Object System.Collections.Generic.List[string]
function Add-Finding([string]$sev, [string]$file, [int]$line, [string]$rule, [string]$msg) {
  $r = 4; if ($sev -eq 'CRITICAL') { $r = 1 } elseif ($sev -eq 'HIGH') { $r = 2 } elseif ($sev -eq 'MEDIUM') { $r = 3 }
  $Found.Add(("{0}`t{1}`t{2:D6}`t{3}`t{4}`t{5}`t{6}" -f $r, $file, $line, $rule, $sev, $line, $msg))
}
function JEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }

$I = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$ReFence = [regex]'^\s*(```|~~~)'
$ReGFence = New-Object regex('^\s*(```|~~~)\s*(gherkin|feature|cucumber)(\s|$)', $I)
$ReHead = [regex]'^(#{1,6})[ \t]+(.*)$'
$ReScen = New-Object regex('^\s*(scenario|scenario outline|scenario template|escenario|esquema del escenario|plantilla del escenario|example|ejemplo)\s*:\s*(.*)$', $I)
$ReSep = [regex]'^\s*[|]?\s*:?-{3,}'
$ReRow = [regex]'^\s*[|]'
$ReNc = New-Object regex('\[(needs clarification[^\]]*)\]', $I)
$ReViol = New-Object regex('(violates|viola)\s*:\s*(article|art\u00edculo|articulo)\s+([0-9]+)', $I)
$ReArt = New-Object regex('^###\s+(article|art\u00edculo|articulo)\s+([0-9]+)\s*(\u2014|:|-)?\s*([^(]*)(.*)$', $I)
$ReLvl = New-Object regex('\((MUST|SHOULD)\)', $I)
$ReDrift = [regex]'(FR-[0-9]+)\s*(:|\s\u2014|\s-)\s+(.+)$'
$ReQHead = New-Object regex('(open questions|preguntas abiertas)', $I)
$ReCHead = New-Object regex('(constitution check|verificaci(\u00f3|o)n de (la )?constituci(\u00f3|o)n|chequeo de (la )?constituci(\u00f3|o)n)', $I)
$ReBCol = New-Object regex('(block|bloquea)', $I)
$ReQCol = New-Object regex('(question|pregunta)', $I)
$ReArtNum = New-Object regex('(article|art\u00edculo|articulo)\s+([0-9]+)', $I)
$ReTRow = [regex]'^\s*[|]\s*(T[0-9]+)\s*[|]'
$ReChk = [regex]'^\s*[|]\s*CHK[0-9]+\s*[|]'
$ReFrId = [regex]'^FR-[0-9]+$'
$ReScId = [regex]'^SC-[0-9]+$'
$ReT = [regex]'T[0-9]+'
$Cross = [string][char]0x274c

function Read-Lines([string]$path) {
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
function Cell($c, [int]$i) { if ($i -ge 0 -and $i -lt $c.Count) { return [string]$c[$i] }; return '' }
function Lower-Ascii([string]$s) { # A-Z only, like `tr 'A-Z' 'a-z'`
  $b = New-Object System.Text.StringBuilder
  foreach ($ch in $s.ToCharArray()) { if ($ch -ge 'A' -and $ch -le 'Z') { [void]$b.Append([char]([int]$ch + 32)) } else { [void]$b.Append($ch) } }
  return $b.ToString()
}
function Norm-Words([string]$s) {
  $w = [regex]::Replace((Lower-Ascii $s), '[^a-z0-9\u0080-\uffff]+', ' ').Trim(' ')
  return " $w "
}
function Norm-Text([string]$s) {
  $t = [regex]::Replace((Lower-Ascii $s).Replace("`t", ' '), ' {2,}', ' ')
  if ($t.StartsWith(' ')) { $t = $t.Substring(1) }
  if ($t.EndsWith(' ')) { $t = $t.Substring(0, $t.Length - 1) }
  if ($t.EndsWith('.')) { $t = $t.Substring(0, $t.Length - 1) }
  return $t
}

$Terms = New-Object System.Collections.Generic.List[string]
function Read-Terms([string]$path, [bool]$marked) { # $marked: only between the ambiguity-terms markers
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
  $on = -not $marked
  foreach ($t in [System.IO.File]::ReadAllLines($path, $Utf8)) {
    $t = $t.TrimEnd("`r").Trim()
    if ($t -eq '<!-- ambiguity-terms:begin -->') { $on = $true; continue }
    if ($t -eq '<!-- ambiguity-terms:end -->') { $on = $false; continue }
    if (-not $on) { continue }
    if ($t -eq '' -or $t.StartsWith('#') -or $t.StartsWith('```')) { continue }
    if ($t.StartsWith('!')) { $n = Norm-Words $t.Substring(1); while ($Terms.Contains($n)) { [void]$Terms.Remove($n) }; continue }
    $n = Norm-Words $t
    if ($n -eq '  ') { continue }
    if (-not $Terms.Contains($n)) { $Terms.Add($n) }
  }
}
function Get-Ambiguous([string]$text) {
  if ($text -match '[0-9]') { return '' }
  $w = Norm-Words $text; $found = ''
  foreach ($x in $Terms) { if ($w.Contains($x)) { $t = $x.Trim(' '); if ($found -eq '') { $found = $t } else { $found += ", $t" } } }
  return $found
}

# Phase 0
$Gate = $false
if (-not $Skip) {
  $cs = Join-Path $PSScriptRoot 'check-structure.ps1'
  if (-not (Test-Path -LiteralPath $cs)) { Fail 'check-structure.ps1 not found next to analyze.ps1' }
  $null = & $cs --root $Root --json 2>$null; $sx = $LASTEXITCODE
  if ($sx -eq 3) { Fail "check-structure failed on root: $RL" }
  if ($sx -ne 0) {
    $Gate = $true
    Add-Finding 'CRITICAL' 'structure' 0 'structure-gate' "Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
  }
}

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
  Read-Terms (Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'frameworks') 'analyze.md') $true
  Read-Terms (Join-Path $RootFull 'plans/agile/ambiguity-terms.txt') $false
}

# Constitution
$Arts = New-Object System.Collections.Generic.List[object]
$cf = Join-Path $RootFull 'plans/agile/constitution.md'
if (-not $Gate -and (Test-Path -LiteralPath $cf -PathType Leaf)) {
  foreach ($ln in (Read-Lines $cf)) {
    $m = $ReArt.Match($ln.Text); if (-not $m.Success) { continue }
    $lvl = ''; $lm = $ReLvl.Match($m.Groups[5].Value); if ($lm.Success) { $lvl = $lm.Groups[1].Value.ToUpperInvariant() }
    $Arts.Add([pscustomobject]@{ N = $m.Groups[2].Value; L = $lvl; T = $m.Groups[4].Value.TrimEnd() })
  }
}
function Check-Article([string]$num, [string]$file, [int]$line, [string]$ctx) {
  foreach ($a in $Arts) {
    if ($a.N -ne $num) { continue }
    if ($a.L -eq 'MUST') { Add-Finding 'CRITICAL' $file $line 'constitution-violation' "$ctx violates Article $num (MUST): $($a.T)" }
    else { Add-Finding 'MEDIUM' $file $line 'constitution-violation' "$ctx violates Article $num (SHOULD): $($a.T)" }
    return
  }
  Add-Finding 'HIGH' $file $line 'constitution-unknown-article' "$ctx references Article $num, which is not in plans/agile/constitution.md"
}

foreach ($name in $Names) {
  $base = "specs/$name"; $dir = Join-Path (Join-Path $RootFull 'specs') $name
  $frId = New-Object System.Collections.Generic.List[string]; $frKey = New-Object System.Collections.Generic.List[string]
  $specFile = Join-Path $dir 'spec.md'
  if (Test-Path -LiteralPath $specFile -PathType Leaf) {
    $L = Read-Lines $specFile
    $seen = New-Object System.Collections.Generic.List[string]; $inq = $false; $qlvl = 0; $bcol = -1; $qcol = 1
    for ($i = 0; $i -lt $L.Count; $i++) {
      $x = $L[$i].Text; $no = $L[$i].No
      $m = $ReHead.Match($x)
      if ($m.Success) {
        $h = $m.Groups[2].Value; $lv = $m.Groups[1].Value.Length
        if ($ReQHead.IsMatch($h)) { $inq = $true; $qlvl = $lv; $bcol = -1; $qcol = 1 }
        elseif ($inq -and $lv -le $qlvl) { $inq = $false }
        continue
      }
      if ($ReRow.IsMatch($x) -and -not $ReSep.IsMatch($x)) {
        $c = Get-Cells $x
        if (($i + 1) -lt $L.Count -and $ReSep.IsMatch($L[$i + 1].Text)) {
          if ($inq) {
            for ($q = 0; $q -lt $c.Count; $q++) { if ($ReBCol.IsMatch($c[$q])) { $bcol = $q }; if ($ReQCol.IsMatch($c[$q])) { $qcol = $q } }
          }
          continue
        }
        $c0 = Cell $c 0; $c1 = Cell $c 1
        if ($ReFrId.IsMatch($c0)) {
          $key = Norm-Text $c1; $j = $frKey.IndexOf($key)
          if ($j -ge 0 -and $key -ne '') { Add-Finding 'MEDIUM' "$base/spec.md" $no 'duplicate-requirement' "$c0 duplicates the text of $($frId[$j])" }
          $frId.Add($c0); $frKey.Add($key)
          $amb = Get-Ambiguous $c1; if ($amb -ne '') { Add-Finding 'HIGH' "$base/spec.md" $no 'ambiguous-term' "$c0 uses ambiguous term(s) without a measurable criterion: $amb" }
        } elseif ($ReScId.IsMatch($c0)) {
          $amb = Get-Ambiguous $c1; if ($amb -ne '') { Add-Finding 'MEDIUM' "$base/spec.md" $no 'ambiguous-term' "$c0 uses ambiguous term(s) without a measurable criterion: $amb" }
        } elseif ($inq -and $bcol -ge 0) {
          $b = Lower-Ascii (Cell $c $bcol)
          if (@('yes', 'y', 'si', ('s' + [char]0x00ed), 'true') -contains $b) { Add-Finding 'HIGH' "$base/spec.md" $no 'blocking-question' ("blocking open question: " + (Cell $c $qcol)) }
        }
        continue
      }
      $m = $ReScen.Match($x)
      if ($m.Success) {
        $t = $m.Groups[2].Value.TrimEnd(); $key = Norm-Text $t
        if ($seen.Contains($key)) { Add-Finding 'LOW' "$base/spec.md" $no 'duplicate-scenario' "scenario title repeats an earlier scenario: $t" } else { $seen.Add($key) }
      }
    }
  }

  foreach ($f in @('spec.md', 'design.md', 'tasks.md')) {
    $p = Join-Path $dir $f
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
    $inc = $false; $clvl = 0
    foreach ($ln in (Read-Lines $p)) {
      $x = $ln.Text; $no = $ln.No
      $m = $ReNc.Match($x); if ($m.Success) { Add-Finding 'HIGH' "$base/$f" $no 'needs-clarification' ("unresolved [" + $m.Groups[1].Value + "] marker") }
      $m = $ReViol.Match($x); if ($m.Success) { Check-Article $m.Groups[3].Value "$base/$f" $no $f }
      if ($f -ne 'design.md') { continue }
      $m = $ReHead.Match($x)
      if ($m.Success) {
        $lv = $m.Groups[1].Value.Length; $h = $m.Groups[2].Value
        if ($ReCHead.IsMatch($h)) { $inc = $true; $clvl = $lv } elseif ($inc -and $lv -le $clvl) { $inc = $false }
        continue
      }
      if ($inc -and $ReRow.IsMatch($x) -and -not $ReSep.IsMatch($x)) {
        # A row is failing when a status cell (any cell after the first) starts with the cross mark;
        # a legend in the header is not a status.
        $cells = $x.Split('|')
        if ($cells.Count -lt 3) { continue }
        $hit = $false
        for ($ci = 2; $ci -lt $cells.Count; $ci++) { $c = $cells[$ci].Trim(); if ($c.StartsWith($Cross) -and -not $c.Contains('/')) { $hit = $true } }
        if (-not $hit) { continue }
        $n = ''
        $m = $ReArtNum.Match($x)
        if ($m.Success) { $n = $m.Groups[2].Value } else { $m = [regex]::Match($cells[1], '^\s*([0-9]+)(?:[^0-9]|$)'); if ($m.Success) { $n = $m.Groups[1].Value } }
        if ($n -ne '') { Check-Article $n "$base/$f" $no 'constitution check' }
        else { Add-Finding 'HIGH' "$base/$f" $no 'constitution-unknown-article' "constitution check row marked $Cross without an article number" }
      }
    }
  }

  $drift = {
    param($path, $label)
    foreach ($ln in (Read-Lines $path)) {
      $m = $ReDrift.Match($ln.Text); if (-not $m.Success) { continue }
      $id = $m.Groups[1].Value; $txt = $m.Groups[3].Value.TrimEnd(); $key = Norm-Text $txt
      $k2 = $frId.IndexOf($id)
      if ($k2 -ge 0 -and $frKey[$k2] -ne $key) { Add-Finding 'MEDIUM' $label $ln.No 'term-drift' "$id text differs from spec.md: $txt" }
    }
  }
  $tf = Join-Path $dir 'tasks.md'
  if (Test-Path -LiteralPath $tf -PathType Leaf) {
    & $drift $tf "$base/tasks.md"
    $taskIds = New-Object System.Collections.Generic.List[string]; $taskDeps = New-Object System.Collections.Generic.List[object]; $taskLines = New-Object System.Collections.Generic.List[int]
    foreach ($ln in (Read-Lines $tf)) {
      $m = $ReTRow.Match($ln.Text); if (-not $m.Success) { continue }
      $tid = $m.Groups[1].Value; $c = Get-Cells $ln.Text
      if ($taskIds.Contains($tid)) { Add-Finding 'HIGH' "$base/tasks.md" $ln.No 'task-duplicate-id' "task ID $tid is used more than once"; continue }
      $deps = @($ReT.Matches((Cell $c 4)) | ForEach-Object { $_.Value })
      $taskIds.Add($tid); $taskDeps.Add($deps); $taskLines.Add($ln.No)
    }
    for ($i = 0; $i -lt $taskIds.Count; $i++) {
      foreach ($d in $taskDeps[$i]) { if (-not $taskIds.Contains($d)) { Add-Finding 'HIGH' "$base/tasks.md" $taskLines[$i] 'task-unknown-dep' "$($taskIds[$i]) depends on $d, which does not exist" } }
    }
    $done = New-Object 'bool[]' $taskIds.Count
    $changed = $true
    while ($changed) {
      $changed = $false
      for ($i = 0; $i -lt $taskIds.Count; $i++) {
        if ($done[$i]) { continue }
        $ok = $true
        foreach ($d in $taskDeps[$i]) { $k3 = $taskIds.IndexOf($d); if ($k3 -ge 0 -and -not $done[$k3]) { $ok = $false } }
        if ($ok) { $done[$i] = $true; $changed = $true }
      }
    }
    $left = @(); for ($i = 0; $i -lt $taskIds.Count; $i++) { if (-not $done[$i]) { $left += $taskIds[$i] } }
    if ($left.Count -gt 0) {
      $la = [string[]]$left; [Array]::Sort($la, [System.StringComparer]::Ordinal)
      Add-Finding 'HIGH' "$base/tasks.md" 0 'task-cycle' ("tasks in or blocked by a dependency cycle: " + ($la -join ', '))
    }
  }
  $td = Join-Path (Join-Path (Join-Path (Join-Path $RootFull 'plans') 'initiatives') $name) 'tickets'
  if (Test-Path -LiteralPath $td -PathType Container) {
    $ts = @(Get-ChildItem -LiteralPath $td -Filter '*.md' -File | ForEach-Object { $_.Name })
    [Array]::Sort($ts, [System.StringComparer]::Ordinal)
    foreach ($t in $ts) { & $drift (Join-Path $td $t) "plans/initiatives/$name/tickets/$t" }
  }
  $kf = Join-Path $dir 'requirements-checklist.md'
  if (Test-Path -LiteralPath $kf -PathType Leaf) {
    $tot = 0; $ref = 0
    foreach ($ln in (Read-Lines $kf)) {
      if (-not $ReChk.IsMatch($ln.Text)) { continue }
      $c = Get-Cells $ln.Text; $tot++; $r = Cell $c 3
      if ($r -ne '' -and $r -ne '-') { $ref++ }
    }
    if ($tot -gt 0 -and ($ref * 100) -lt ($tot * 80)) {
      Add-Finding 'HIGH' "$base/requirements-checklist.md" 0 'checklist-coverage' ("requirements checklist traces $ref of $tot items (" + [Math]::Floor($ref * 100 / $tot) + "%) to a spec reference; minimum 80%")
    }
  }
}

# Report
$sorted = [string[]]$Found.ToArray(); [Array]::Sort($sorted, [System.StringComparer]::Ordinal)
$nC = 0; $nH = 0; $nM = 0; $nL = 0
foreach ($row in $sorted) { switch ($row.Substring(0, 1)) { '1' { $nC++ } '2' { $nH++ } '3' { $nM++ } default { $nL++ } } }
$E = $nC + $nH; $W = $nM + $nL; $Exit = 0
if ($E -gt 0) { $Exit = 1 } elseif ($Strict -and $W -gt 0) { $Exit = 2 }

if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"root":"' + (JEsc $RL) + '","findings":[')
  for ($i = 0; $i -lt $sorted.Count; $i++) {
    $p = $sorted[$i].Split("`t", 7)
    if ($i -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append(('{{"n":{0},"id":"A{0:D3}","severity":"{1}","file":"{2}","line":{3},"rule":"{4}","message":"{5}"}}' -f ($i + 1), $p[4], (JEsc $p[1]), $p[5], $p[3], (JEsc $p[6])))
  }
  $st = 'false'; if ($Strict) { $st = 'true' }
  [void]$sb.Append('],"critical":' + $nC + ',"high":' + $nH + ',"medium":' + $nM + ',"low":' + $nL + ',"errors":' + $E + ',"warnings":' + $W + ',"strict":' + $st + ',"exit":' + $Exit + '}')
  Write-Output $sb.ToString()
} else {
  Write-Output "analyze $EM $RL"
  if (-not $Gate -and $Names.Count -eq 0) { Write-Output 'No initiatives under specs/.' }
  if ($sorted.Count -eq 0) { Write-Output 'No findings.' }
  for ($i = 0; $i -lt $sorted.Count; $i++) {
    $p = $sorted[$i].Split("`t", 7)
    $loc = $p[1]; if ([int]$p[5] -gt 0) { $loc += ':' + $p[5] }
    Write-Output ('{0}. A{0:D3} {1} {2} [{3}] {4}' -f ($i + 1), $p[4], $loc, $p[3], $p[6])
  }
  $v = 'WARN'; if ($Exit -eq 0) { $v = 'PASS' } elseif ($Exit -eq 1) { $v = 'FAIL' }
  Write-Output "Result: $($sorted.Count) finding(s): $nC critical, $nH high, $nM medium, $nL low $EM $v"
}
exit $Exit
