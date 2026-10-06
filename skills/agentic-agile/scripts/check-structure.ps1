# check-structure.ps1 — Phase 0 gate: is the project's agentic-agile structure complete?
#
# PowerShell twin of check-structure.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS):
# same rules, same output, same exit codes. Nothing (spec, plan, draft, sprint artifact,
# ticket, decision record) may be created while this gate fails. Read-only.
# --scorecard adds a maturity level per area (L0 missing · L1 started · L2 filled ·
# L3 confirmed · L4 in use), a readiness score, and the capability slots marked "none".
#
# Usage: check-structure.ps1 [--root DIR] [--strict] [--json] [--scorecard]     (-Root, -Strict, -Json also accepted)
# Exit:  0 pass · 1 errors · 2 warnings with --strict · 3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014

$Root = '.'; $Strict = $false; $Json = $false; $Score = $false
function Fail([string]$msg) { [Console]::Error.WriteLine("check-structure: $msg"); exit 3 }
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'strict' { $Strict = $true }
    'json' { $Json = $true }
    'scorecard' { $Score = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: check-structure [--root DIR] [--strict] [--json] [--scorecard]'; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$Label = $Root.Replace('\', '/'); while ($Label.Length -gt 1 -and $Label.EndsWith('/')) { $Label = $Label.Substring(0, $Label.Length - 1) }
$RootFull = (Resolve-Path -LiteralPath $Root).Path
function P([string]$rel) { return (Join-Path $RootFull $rel) }

$Findings = New-Object System.Collections.Generic.List[object]
$Gaps = New-Object System.Collections.Generic.List[string]
function Add-Finding($sev, $file, $line, $rule, $msg) { $Findings.Add([pscustomobject]@{ Sev = $sev; File = $file; Line = [int]$line; Rule = $rule; Msg = $msg }) }

$I = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$ReFence = [regex]'^\s*(```|~~~)'
$ReHead = [regex]'^#{1,6}[ \t]+(.*)$'
$ReCheck = [regex]'^\s*([-*+]|[0-9]+[.)])\s+\[( |x|X)\]'
$ReTbd = [regex]'(^|[^A-Za-z0-9_])TBD([^A-Za-z0-9_]|$)'
$ReNum = [regex]'^\s*[0-9]+[.)]\s+\S'
$ReProposed = New-Object regex('(^|[^a-z])(proposed|propuest[oa]s?)([^a-z]|$)', $I)
$ReConfirmed = New-Object regex('(confirmed by|confirmado por)\s*:', $I)
$ReTableRow = [regex]'^\s*\|'
$RePh = [regex]'<([A-Za-z][-A-Za-z0-9 _.,:/|]*)>'
$HtmlTags = @('a','b','i','u','p','em','br','hr','li','ol','ul','td','th','tr','sub','sup','kbd','pre','code','div','span','small','strong','table','thead','tbody','details','summary')

function Remove-Spans([string]$text) { $rest = $text; while ($rest -match '^(.*)`[^`]*`(.*)$') { $rest = $Matches[1] + ' ' + $Matches[2] }; return $rest }
function Get-Placeholders([string]$text) {
  $found = @()
  foreach ($m in $RePh.Matches((Remove-Spans $text))) {
    $c = $m.Groups[1].Value; $lc = $c.ToLowerInvariant()
    if ($lc.Contains('://') -or ($HtmlTags -contains $lc)) { continue }
    $found += "<$c>"
  }
  return ($found -join ', ')
}
function Test-Sep([string]$l) { return ($ReTableRow.IsMatch($l) -and $l -notmatch '[^-|:\s]' -and $l.Contains('-')) }
function Read-Doc([string]$path) { # prose lines (fences skipped) and table data rows with their heading
  $lines = New-Object System.Collections.Generic.List[object]; $rows = New-Object System.Collections.Generic.List[object]
  $n = 0; $fence = $false; $data = $false; $head = ''
  foreach ($l in [System.IO.File]::ReadAllLines($path, (New-Object System.Text.UTF8Encoding($false)))) {
    $n++; $l = $l.TrimEnd("`r")
    if ($ReFence.IsMatch($l)) { $fence = -not $fence; continue }
    if ($fence) { continue }
    $lines.Add([pscustomobject]@{ No = $n; Text = $l })
    $m = $ReHead.Match($l)
    if ($m.Success) { $head = $m.Groups[1].Value; $data = $false; continue }
    if (Test-Sep $l) { $data = $true; continue }
    if ($ReTableRow.IsMatch($l)) { if ($data) { $rows.Add([pscustomobject]@{ No = $n; Text = $l; Head = $head }) } } else { $data = $false }
  }
  return @{ Lines = $lines; Rows = $rows }
}
function Get-Cell([string]$row, [int]$idx) { $c = $row.Split('|'); if ($idx -lt $c.Count) { return $c[$idx].Trim() }; return '' }

# ── Directories and shared files ─────────────────────────────────────────────
foreach ($d in @('plans/agile', 'plans/sprints', 'plans/initiatives', 'plans/decisions', 'plans/drafts', 'specs')) {
  if (-not (Test-Path -LiteralPath (P $d) -PathType Container)) { Add-Finding 'error' "$d/" 0 'missing-dir' 'missing directory (run scripts/init)' }
}
$f = 'plans/agile/metrics/events.jsonl'
if (-not (Test-Path -LiteralPath (P $f) -PathType Leaf)) { Add-Finding 'error' $f 0 'missing-file' 'missing file (run scripts/init)' }
$f = '.memory/.gitignore'
if (-not (Test-Path -LiteralPath (P $f) -PathType Leaf)) { Add-Finding 'error' $f 0 'missing-file' 'missing file (run scripts/init)' }
else {
  $gi = [System.IO.File]::ReadAllLines((P $f)) | ForEach-Object { $_.TrimEnd("`r") }
  foreach ($l in @('local/', '*.local.*', '*.recovered.json')) { if (@($gi) -cnotcontains $l) { Add-Finding 'error' $f 0 'gitignore-block' "missing line: $l" } }
}

# ── Team operating system (plans/agile/) ─────────────────────────────────────
foreach ($t in @('methodology', 'definition-of-ready', 'definition-of-done', 'ceremonies', 'team', 'capabilities', 'kpi-directives', 'language', 'autonomy', 'constitution', 'hooks')) {
  $f = "plans/agile/$t.md"
  if (-not (Test-Path -LiteralPath (P $f) -PathType Leaf)) { Add-Finding 'error' $f 0 'missing-file' 'missing file (run scripts/init, then complete it with the team)'; continue }
  $doc = Read-Doc (P $f); $DocLines = $doc.Lines; $DocRows = $doc.Rows
  $proposed = $false; $confirmed = $false; $nums = 0
  foreach ($l in $DocLines) {
    if ($ReTbd.IsMatch($l.Text)) { Add-Finding 'error' $f $l.No 'tbd' 'TBD left in the structure' }
    if ($ReCheck.IsMatch($l.Text)) { Add-Finding 'error' $f $l.No 'checkbox' 'checkbox list item; use numbered or lettered items with a state' }
    $ph = Get-Placeholders $l.Text
    if ($ph -ne '') { Add-Finding 'error' $f $l.No 'placeholder' "unfilled template placeholder(s): $ph" }
    if ($ReNum.IsMatch($l.Text)) { $nums++ }
    $p = Remove-Spans $l.Text
    if ($ReProposed.IsMatch($p)) { $proposed = $true }
    if ($ReConfirmed.IsMatch($p)) { $confirmed = $true }
  }
  function Test-Any([string]$pattern) { $re = New-Object regex($pattern, $I); foreach ($l in $DocLines) { if ($re.IsMatch($l.Text)) { return $true } }; return $false }
  switch ($t) {
    'methodology' {
      if (-not (Test-Any '(sprint length|duraci(\u00f3|o)n del sprint)\s*:\s*\S')) { Add-Finding 'error' $f 0 'content' "no sprint length (e.g. 'Sprint length: 2 weeks')" }
      if (-not (Test-Any '(scale|escala)\s*:\s*\S')) { Add-Finding 'error' $f 0 'content' "no estimation scale (e.g. 'Scale: Fibonacci 1, 2, 3, 5, 8, 13')" }
    }
    { $_ -eq 'definition-of-ready' -or $_ -eq 'definition-of-done' } { if ($nums -lt 3) { Add-Finding 'error' $f 0 'content' 'fewer than 3 numbered items' } }
    { $_ -eq 'ceremonies' -or $_ -eq 'kpi-directives' -or $_ -eq 'hooks' } { if ($DocRows.Count -eq 0) { Add-Finding 'error' $f 0 'content' 'no table rows' } }
    'team' {
      $ok = $false; foreach ($r in $DocRows) { if ((Get-Cell $r.Text 1) -ne '' -and (Get-Cell $r.Text 4) -ne '') { $ok = $true } }
      if (-not $ok) { Add-Finding 'error' $f 0 'content' 'no role row with a usual capacity' }
    }
    'capabilities' {
      $seen = $false
      foreach ($r in $DocRows) {
        if ($r.Head -notmatch '(slots|ranuras)') { continue }
        $seen = $true
        if ((Get-Cell $r.Text 2) -eq '') { Add-Finding 'error' $f $r.No 'content' "slot '$(Get-Cell $r.Text 1)' has no tool, 'none' or 'not applicable'" }
        if ((Get-Cell $r.Text 2) -eq 'none') { $Gaps.Add((Get-Cell $r.Text 1)) }
      }
      if (-not $seen) { Add-Finding 'error' $f 0 'content' 'no Slots table' }
    }
    'language' { if (-not (Test-Any 'gherkin[^:]*:\s*\S')) { Add-Finding 'error' $f 0 'content' 'no Gherkin keyword language' } }
    'autonomy' {
      $levels = $false
      foreach ($r in $DocRows) {
        if ($r.Head -match '(levels|niveles)') {
          $levels = $true
          if ((Get-Cell $r.Text 2) -notmatch '^N[0-4]$') { Add-Finding 'error' $f $r.No 'content' "task '$(Get-Cell $r.Text 1)' has no autonomy level N0-N4" }
        } elseif ($r.Head -match '(adoption|adopci)') {
          if ((Get-Cell $r.Text 3) -eq '') { Add-Finding 'error' $f $r.No 'content' "precondition '$(Get-Cell $r.Text 2)' has no status" }
        }
      }
      if (-not $levels) { Add-Finding 'error' $f 0 'content' "no 'Levels per task' table" }
    }
    'constitution' {
      if (-not (Test-Any '(^|[^a-z])version\s*:\s*[0-9]+[.][0-9]+[.][0-9]+')) { Add-Finding 'error' $f 0 'content' "no 'Version: X.Y.Z' line" }
      $ok = $false
      $reArt = New-Object regex('(article|art(\u00ed|i)culo)\s+[0-9]+.*[(]MUST[)]', $I)
      foreach ($l in $DocLines) { $m = $ReHead.Match($l.Text); if ($m.Success -and $reArt.IsMatch($m.Groups[1].Value)) { $ok = $true } }
      if (-not $ok) { Add-Finding 'error' $f 0 'content' ("no MUST article ('### Article N " + $EM + " <title> (MUST)')") }
      if (-not (Test-Any '^\s*[|]\s*version\s*[|]\s*date\s*[|].*decided\s+by')) { Add-Finding 'error' $f 0 'content' 'no Amendments table (| Version | Date | Change | Rationale | Decided by |)' }
    }
  }
  if ($proposed -and -not $confirmed) { Add-Finding 'warning' $f 0 'unconfirmed' "mentions Proposed values but has no 'Confirmed by:' line" }
}

# ── Report ───────────────────────────────────────────────────────────────────
$E = 0; $W = 0
foreach ($x in $Findings) { if ($x.Sev -eq 'error') { $E++ } else { $W++ } }
$Exit = 0; if ($E -gt 0) { $Exit = 1 } elseif ($Strict -and $W -gt 0) { $Exit = 2 }
$Gate = 'closed'; if ($Exit -eq 0) { $Gate = 'open' }
function Get-JsonEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }

# ── Scorecard ────────────────────────────────────────────────────────────────
$Areas = @('process', 'capabilities', 'autonomy', 'metrics', 'transcripts')
$AreaFiles = @{ process = @('methodology', 'definition-of-ready', 'definition-of-done', 'ceremonies', 'constitution', 'hooks'); capabilities = @('capabilities'); autonomy = @('autonomy', 'team'); metrics = @('kpi-directives'); transcripts = @('language') }
function Test-AnyFile([string]$dir, [string]$name) { # dir/*/name or dir/*name
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return $false }
  foreach ($d in Get-ChildItem -LiteralPath $dir -Directory) { if (Test-Path -LiteralPath (Join-Path $d.FullName $name) -PathType Leaf) { return $true } }
  return $false
}
function Test-InUse([string]$area) { # L4 evidence that the area is used, not only written down
  switch ($area) {
    'process' { return (Test-AnyFile (P 'plans/sprints') 'retro.md') }
    'capabilities' { return ($Gaps.Count -eq 0) }
    'autonomy' { $ev = P 'plans/agile/metrics/events.jsonl'; return ((Test-Path -LiteralPath $ev -PathType Leaf) -and ([System.IO.File]::ReadAllText($ev) -match '\S')) }
    'metrics' { return (Test-AnyFile (P 'plans/sprints') 'report.md') }
    'transcripts' { $td = P '.memory/local/agentic-agile/transcripts'; return ((Test-Path -LiteralPath $td -PathType Container) -and @(Get-ChildItem -LiteralPath $td -File -Filter '*.jsonl').Count -gt 0) }
  }
  return $false
}
$Levels = @(); $ScoreSum = 0
if ($Score) {
  foreach ($a in $Areas) {
    $present = 0; $errs = 0; $warns = 0
    foreach ($t in $AreaFiles[$a]) {
      if (Test-Path -LiteralPath (P "plans/agile/$t.md") -PathType Leaf) { $present++ }
      foreach ($x in $Findings) { if ($x.File -ne "plans/agile/$t.md") { continue }; if ($x.Sev -eq 'error') { $errs++ } else { $warns++ } }
    }
    $lv = 3; if ($present -eq 0) { $lv = 0 } elseif ($errs -gt 0) { $lv = 1 } elseif ($warns -gt 0) { $lv = 2 }
    if ($lv -eq 3 -and (Test-InUse $a)) { $lv = 4 }
    $Levels += $lv; $ScoreSum += $lv
  }
}
$Pct = [int][math]::Floor($ScoreSum * 100 / 20)

if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"root":"' + (Get-JsonEsc $Label) + '","findings":[')
  for ($k = 0; $k -lt $Findings.Count; $k++) {
    $x = $Findings[$k]; if ($k -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"n":' + ($k + 1) + ',"severity":"' + $x.Sev + '","file":"' + (Get-JsonEsc $x.File) + '","line":' + $x.Line + ',"rule":"' + $x.Rule + '","message":"' + (Get-JsonEsc $x.Msg) + '"}')
  }
  $st = 'false'; if ($Strict) { $st = 'true' }
  [void]$sb.Append('],"errors":' + $E + ',"warnings":' + $W + ',"strict":' + $st + ',"gate":"' + $Gate + '"')
  if ($Score) {
    [void]$sb.Append(',"scorecard":{')
    for ($k = 0; $k -lt $Areas.Count; $k++) { [void]$sb.Append('"' + $Areas[$k] + '":' + $Levels[$k] + ',') }
    [void]$sb.Append('"score":' + $ScoreSum + ',"max":20,"percent":' + $Pct + '},"gaps":[' + (($Gaps | ForEach-Object { '"' + (Get-JsonEsc $_) + '"' }) -join ',') + ']')
  }
  [void]$sb.Append(',"exit":' + $Exit + '}')
  Write-Output $sb.ToString()
} else {
  Write-Output "check-structure $EM $Label"
  if ($Findings.Count -eq 0) { Write-Output 'No findings.' }
  for ($k = 0; $k -lt $Findings.Count; $k++) {
    $x = $Findings[$k]; $loc = $x.File; if ($x.Line -gt 0) { $loc += ":$($x.Line)" }
    Write-Output ("$($k + 1). $($x.Sev) $loc [$($x.Rule)] $($x.Msg)")
  }
  $v = 'WARN'; if ($Exit -eq 0) { $v = 'PASS' } elseif ($Exit -eq 1) { $v = 'FAIL' }
  Write-Output "Result: $E error(s), $W warning(s) $EM $v"
  if ($Gate -eq 'open') { Write-Output 'Phase 0 gate: open.' }
  else { Write-Output 'Phase 0 gate: closed. Do not create specs, plans, drafts, sprint artifacts, tickets or decision records; complete the items above with the team first.' }
  if ($Score) {
    $MD = [string][char]0x00b7
    Write-Output "Scorecard (L0 missing $MD L1 started $MD L2 filled $MD L3 confirmed $MD L4 in use):"
    for ($k = 0; $k -lt $Areas.Count; $k++) { Write-Output ("$($k + 1). $($Areas[$k]) $EM L$($Levels[$k])") }
    Write-Output "Readiness: $Pct% ($ScoreSum/20)"
    $g = 'none'; if ($Gaps.Count -gt 0) { $g = $Gaps -join ', ' }
    Write-Output "Capability gaps (slot = none): $g"
  }
}
exit $Exit
