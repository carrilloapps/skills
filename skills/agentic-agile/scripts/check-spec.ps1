# check-spec.ps1 — validate an SDD initiative folder (specs/<initiative>/) before its gates.
#
# PowerShell twin of check-spec.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS):
# same rules, same output, same exit codes. Gherkin rules: every scenario has Given, When and
# Then (Background Givens count), Background holds only Given steps, one keyword language per
# Gherkin block. Traceability: unique FR-### rows, @FR-### / @P1-@P3 scenario tags, SC-### to
# scenario mapping, confirmed clarifications, no blocking open question once design.md exists,
# tasks.md format/references/cycles, requirements-checklist.md coverage. Unfilled <placeholders>
# in prose are errors. Read-only. Fenced code is ignored
# except ```gherkin / ```feature / ```cucumber fences. --tickets also checks the work-item drafts
# in plans/initiatives/<initiative>/tickets/; --all walks every specs/*/ folder under --root.
#
# Phase 0 first: the project structure must pass check-structure.ps1 (run from --root, default
# the current directory); while it fails, only the structure-gate finding is reported.
#
# Usage: check-spec.ps1 <specs/initiative> [--root DIR] [--strict] [--json] [--tickets]
#        check-spec.ps1 --all [--root DIR] [--strict] [--json]     (-Root, -Strict, -Json also accepted)
#        (--skip-structure exists for the parity tests only)
# Exit:  0 pass · 1 errors · 2 warnings with --strict · 3 configuration error (--all: highest)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014

$Dir = ''; $Strict = $false; $Json = $false; $Root = '.'; $Skip = $false; $Tickets = $false; $All = $false
function Fail([string]$msg) { [Console]::Error.WriteLine("check-spec: $msg"); exit 3 }
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  if ($a.StartsWith('-')) {
    switch (($a -replace '^-+', '').ToLowerInvariant()) {
      'strict' { $Strict = $true }
      'json' { $Json = $true }
      'tickets' { $Tickets = $true }
      'all' { $All = $true }
      'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
      'skip-structure' { $Skip = $true }
      { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: check-spec <specs/initiative> [--root DIR] [--strict] [--json] [--tickets] | --all [--root DIR] [--strict] [--json]'; exit 0 }
      default { Fail "unknown option: $a" }
    }
  } else { if ($Dir -ne '') { Fail 'only one initiative folder is allowed' }; $Dir = $a }
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RL = $Root.Replace('\', '/'); while ($RL.Length -gt 1 -and $RL.EndsWith('/')) { $RL = $RL.Substring(0, $RL.Length - 1) }
if ($All) {
  if ($Dir -ne '') { Fail '--all takes no initiative folder' }
  $Label = "$RL/specs (all)"
} else {
  if ($Dir -eq '') { Fail 'missing initiative folder (e.g. specs/my-initiative)' }
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { Fail "initiative folder not found: $Dir" }
  $Label = $Dir.Replace('\', '/').TrimEnd('/')
  $DirFull = (Resolve-Path -LiteralPath $Dir).Path
}

$Findings = New-Object System.Collections.Generic.List[object]
$FrIds = New-Object System.Collections.Generic.List[string]
function Add-Finding($sev, $file, $line, $rule, $msg) { $Findings.Add([pscustomobject]@{ Sev = $sev; File = $file; Line = [int]$line; Rule = $rule; Msg = $msg }) }

$I = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$ReFence = [regex]'^\s*(```|~~~)'
$ReGFence = New-Object regex('^\s*(```|~~~)\s*(gherkin|feature|cucumber)(\s|$)', $I)
$ReHead = [regex]'^#{1,6}[ \t]+(.*)$'
$ReCheck = [regex]'^\s*([-*+]|[0-9]+[.)])\s+\[( |x|X)\]'
$ReTbd = [regex]'(^|[^A-Za-z0-9_])TBD([^A-Za-z0-9_]|$)'
$ReScen = New-Object regex('^\s*(scenario|scenario outline|scenario template|escenario|esquema del escenario|plantilla del escenario)\s*:', $I)
$ReScenG = [regex]'^\s*(Example|Ejemplo)\s*:'
$ReBg = [regex]'^\s*(Background|Antecedentes)\s*:'
$ReEnd = [regex]'^\s*(Feature|Rule|Examples|Scenarios|Caracter\u00edstica|Regla|Ejemplos|Escenarios)\s*:'
$ReGiven = [regex]'^\s*(Given|Dado|Dada|Dados|Dadas)\s'
$ReWhen = [regex]'^\s*(When|Cuando)\s'
$ReThen = [regex]'^\s*(Then|Entonces)\s'
$ReEn = [regex]'^\s*((Feature|Rule|Background|Scenario Outline|Scenario Template|Scenario|Example|Examples|Scenarios)\s*:|(Given|When|Then|And|But)\s)'
$ReEs = [regex]'^\s*((Caracter\u00edstica|Regla|Antecedentes|Esquema del escenario|Plantilla del escenario|Escenario|Ejemplo|Ejemplos|Escenarios)\s*:|(Dado|Dada|Dados|Dadas|Cuando|Entonces|Y|E|Pero)\s)'
$ReOrigin = New-Object regex('(^|[^a-z])(origin|origen)([*][*])?\s*:', $I)
$ReTable = New-Object regex('^\s*[|].*(result|resultado)', $I)
$ReVWord = New-Object regex('(verdict|veredicto)', $I)
$ReMark = [regex]'(\u2705|\u26a0|\u274c)'

function Read-Lines([string]$path) { # non-fenced lines (plus Gherkin fences: G = 1, B = block number) as objects { No, Text, G, B }
  $out = New-Object System.Collections.Generic.List[object]
  $n = 0; $fence = $false; $g = 0; $b = 0
  foreach ($l in [System.IO.File]::ReadAllLines($path, (New-Object System.Text.UTF8Encoding($false)))) {
    $n++; $l = $l.TrimEnd("`r")
    if ($ReFence.IsMatch($l)) {
      if (-not $fence) { $fence = $true; $g = 0; if ($ReGFence.IsMatch($l)) { $g = 1; $b++ } } else { $fence = $false; $g = 0 }
      continue
    }
    if ($fence -and $g -eq 0) { continue }
    $bb = 0; if ($g -eq 1) { $bb = $b }
    $out.Add([pscustomobject]@{ No = $n; Text = $l; G = $g; B = $bb })
  }
  return , $out
}
# Heading match: the pattern must start the heading text (after optional "1.2 " numbering) and end
# at a word boundary -- "Non-functional requirements" or "Known problems" do not count.
function Get-HeadPattern([string]$pattern) { return ('^([0-9]+([.][0-9]+)*[.)]?\s+)?(' + $pattern + ')([^A-Za-z]|$)') }
function Test-Heading($lines, [string]$pattern) {
  $re = New-Object regex((Get-HeadPattern $pattern), $I)
  foreach ($l in $lines) { if ($l.G -eq 1) { continue }; $m = $ReHead.Match($l.Text); if ($m.Success -and $re.IsMatch($m.Groups[1].Value)) { return $true } }
  return $false
}
function Invoke-LineScan($lines, [string]$file, [bool]$tbd, [bool]$ph) {
  foreach ($l in $lines) {
    if ($tbd -and $ReTbd.IsMatch($l.Text)) { Add-Finding 'error' $file $l.No 'tbd' 'TBD left in the spec' }
    if ($ReCheck.IsMatch($l.Text)) { Add-Finding 'error' $file $l.No 'checkbox' 'checkbox list item; use numbered or lettered items with a state' }
    if (-not $ph) { continue }
    if ($l.G -eq 1) { continue } # Gherkin <params> are legitimate (Scenario Outline)
    $p = Get-Placeholders $l.Text
    if ($p -ne '') { Add-Finding 'error' $file $l.No 'placeholder' "unfilled template placeholder(s): $p" }
  }
}
# Unfilled <placeholders> of a prose line (code spans, HTML tags and autolinks skipped), comma-joined.
$HtmlTags = @('a','b','i','u','p','em','br','hr','li','ol','ul','td','th','tr','sub','sup','kbd','pre','code','div','span','small','strong','table','thead','tbody','details','summary')
$RePh = [regex]'<([A-Za-z][-A-Za-z0-9 _.,:/|]*)>'
function Get-Placeholders([string]$text) {
  $rest = $text
  while ($rest -match '^(.*)`[^`]*`(.*)$') { $rest = $Matches[1] + ' ' + $Matches[2] }
  $found = @()
  foreach ($m in $RePh.Matches($rest)) {
    $c = $m.Groups[1].Value; $lc = $c.ToLowerInvariant()
    if ($lc.Contains('://') -or ($HtmlTags -contains $lc)) { continue }
    $found += "<$c>"
  }
  return ($found -join ', ')
}

# Gherkin rules over a file's lines. Returns the scenario count. Regions: a scenario or Background
# runs until the next scenario, Background, Feature/Rule/Examples keyword, Markdown heading or the
# end of its Gherkin block.
$ScTitles = New-Object System.Collections.Generic.List[string]
function Invoke-GherkinChecks($lines, [string]$f, [bool]$warnOrigin, [bool]$tagCheck = $false) {
  $st = @{ Kind = 'none'; Line = 0; B = 0; G = $false; W = $false; T = $false; O = $false; N = 0; P = ''; R = ''; S = '' }
  $bg = @{}; $en = @{}; $es = @{}; $bstart = @{}; $ftags = @{}
  $ScTitles.Clear()
  $close = {
    if ($st.Kind -eq 'scen') {
      if ($bg.ContainsKey($st.B)) { $st.G = $true }
      $miss = @()
      if (-not $st.G) { $miss += 'Given' }
      if (-not $st.W) { $miss += 'When' }
      if (-not $st.T) { $miss += 'Then' }
      if ($miss.Count -gt 0) { Add-Finding 'error' $f $st.Line 'scenario-steps' "scenario without $($miss -join ', ') step(s)" }
      if ($tagCheck) {
        $frs = $false; $pri = $false
        foreach ($t in ($st.S -split '\s+')) {
          if ($t -cmatch '^@(FR-[0-9]+)$') {
            $frs = $true; $id = $Matches[1]
            if (-not $FrIds.Contains($id)) { Add-Finding 'error' $f $st.Line 'scenario-fr' "scenario tags unknown requirement $id" }
          }
          if ($t -cmatch '^@P[1-3]$') { $pri = $true }
        }
        if (-not $frs) { Add-Finding 'error' $f $st.Line 'scenario-fr' 'scenario without an @FR-### tag' }
        if (-not $pri) { Add-Finding 'warning' $f $st.Line 'scenario-priority' 'scenario without a priority tag (@P1, @P2 or @P3)' }
      }
      if ($warnOrigin -and -not $st.O) { Add-Finding 'warning' $f $st.Line 'scenario-origin' 'scenario without Origin:/Origen: line' }
    }
    $st.Kind = 'none'
  }
  foreach ($l in $lines) {
    $x = $l.Text; $b = $l.B
    if ($b -ne 0) {
      if (-not $bstart.ContainsKey($b)) { $bstart[$b] = $l.No }
      if ($ReEn.IsMatch($x)) { $en[$b] = $true }
      if ($ReEs.IsMatch($x)) { $es[$b] = $true }
    }
    if ($st.Kind -ne 'none' -and $b -ne $st.B) { & $close }
    if ($x -match '^\s*@') { $st.P += " $x"; continue }
    $isScen = $ReScen.IsMatch($x) -or ($b -ne 0 -and $ReScenG.IsMatch($x))
    if ($isScen) {
      & $close
      $st.Kind = 'scen'; $st.Line = $l.No; $st.B = $b; $st.G = $false; $st.W = $false; $st.T = $false; $st.O = $false; $st.N++
      $ft = ''; if ($ftags.ContainsKey($b)) { $ft = $ftags[$b] }
      $st.S = "$ft $($st.R) $($st.P)"; $st.P = ''
      $ScTitles.Add($x.Substring($x.IndexOf(':') + 1).Trim())
      continue
    }
    if ($ReBg.IsMatch($x)) { & $close; $st.Kind = 'bg'; $st.B = $b; $st.P = ''; continue }
    if ($ReEnd.IsMatch($x) -or ($b -eq 0 -and $ReHead.IsMatch($x))) {
      & $close
      if ($x -cmatch '^\s*(Feature|Caracter\u00edstica)\s*:') { $ftags[$b] = $st.P; $st.R = '' }
      elseif ($x -cmatch '^\s*(Rule|Regla)\s*:') { $st.R = $st.P }
      elseif ($b -eq 0) { $st.R = '' }
      $st.P = ''; continue
    }
    if ($st.Kind -eq 'scen') {
      if ($ReGiven.IsMatch($x)) { $st.G = $true }
      if ($ReWhen.IsMatch($x)) { $st.W = $true }
      if ($ReThen.IsMatch($x)) { $st.T = $true }
      if ($ReOrigin.IsMatch($x)) { $st.O = $true }
    } elseif ($st.Kind -eq 'bg') {
      if ($ReGiven.IsMatch($x)) { $bg[$st.B] = $true }
      if ($ReWhen.IsMatch($x) -or $ReThen.IsMatch($x)) { Add-Finding 'error' $f $l.No 'background-steps' 'Background may only contain Given steps' }
    }
  }
  & $close
  foreach ($b in ($bstart.Keys | Sort-Object)) {
    if ($en.ContainsKey($b) -and $es.ContainsKey($b)) { Add-Finding 'error' $f $bstart[$b] 'gherkin-language' 'Gherkin block mixes English and Spanish keywords; use one language per block' }
  }
  return $st.N
}
function Get-JsonEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }
function Get-Verdict([int]$x) { switch ($x) { 0 { 'PASS' } 1 { 'FAIL' } 2 { 'WARN' } default { 'ERROR' } } }


# ── Section and table helpers ────────────────────────────────────────────────
function Get-Cells([string]$row) { # cells of a table row without the outer pipes
  $r = $row.Trim(); if ($r.StartsWith('|')) { $r = $r.Substring(1) }; if ($r.EndsWith('|')) { $r = $r.Substring(0, $r.Length - 1) }
  return , @($r.Split('|') | ForEach-Object { $_.Trim() })
}
function Test-Sep([string]$l) { return ($l -match '^\s*\|' -and $l -notmatch '[^-|:\s]' -and $l.Contains('-')) }
# Prose lines and table data rows inside the section whose heading matches $pattern (case-insensitive;
# '' = whole file) → @{ Lines; Rows } (Rows carry Hdr = the table header row).
function Get-Section($lines, [string]$pattern) {
  $outL = New-Object System.Collections.Generic.List[object]; $outR = New-Object System.Collections.Generic.List[object]
  $in = ($pattern -eq ''); $lvl = 0; $hdr = ''
  $re = $null; if ($pattern -ne '') { $re = New-Object regex((Get-HeadPattern $pattern), $I) }
  foreach ($l in $lines) {
    if ($l.G -eq 1) { continue }
    $x = $l.Text
    $m = [regex]::Match($x, '^(#{1,6})[ \t]+(.*)$')
    if ($m.Success) {
      $hl = $m.Groups[1].Value.Length; $hdr = ''
      if ($pattern -eq '') { continue }
      if ($in -and $hl -le $lvl) { $in = $false }
      if (-not $in -and $re.IsMatch($m.Groups[2].Value)) { $in = $true; $lvl = $hl }
      continue
    }
    if (-not $in) { continue }
    if ($x -match '^\s*\|') {
      if (Test-Sep $x) { continue }
      if ($hdr -eq '') { $hdr = $x } else { $outR.Add([pscustomobject]@{ No = $l.No; Text = $x; Hdr = $hdr }) }
    } else { $hdr = ''; $outL.Add([pscustomobject]@{ No = $l.No; Text = $x }) }
  }
  return @{ Lines = $outL; Rows = $outR }
}
function Get-Col([string]$hdr, [string]$pattern) { # 0-based column whose header matches, or -1
  $c = Get-Cells $hdr; $re = New-Object regex($pattern, $I)
  for ($k = 0; $k -lt $c.Count; $k++) { if ($re.IsMatch($c[$k])) { return $k } }
  return -1
}
function Get-At($arr, [int]$k) { if ($k -ge 0 -and $k -lt $arr.Count) { return [string]$arr[$k] }; return '' }

# ── Phase 0 ──────────────────────────────────────────────────────────────────
$Gate = $false
if (-not $Skip) {
  $cs = Join-Path $PSScriptRoot 'check-structure.ps1'
  if (-not (Test-Path -LiteralPath $cs -PathType Leaf)) { Fail 'check-structure.ps1 not found next to check-spec.ps1' }
  $sj = (@(& $cs --root $Root --json) -join "`n"); $sx = $LASTEXITCODE
  if ($sx -eq 3) { Fail "check-structure failed on root: $Root" }
  if ($sx -ne 0) {
    $Gate = $true
    $se = ''; if ($sj -match '"errors":(\d+)') { $se = $Matches[1] }
    Add-Finding 'error' 'structure' 0 'structure-gate' "Phase 0 structure incomplete ($se error(s)); run scripts/check-structure --root $RL and complete plans/agile/ with the team before any spec"
  }
}

# ── --all: one child run per initiative ──────────────────────────────────────
if ($All -and -not $Gate) {
  $child = @('--root', $Root, '--skip-structure', '--tickets'); if ($Strict) { $child += '--strict' }
  $names = @()
  $specsDir = Join-Path $Root 'specs'
  if (Test-Path -LiteralPath $specsDir -PathType Container) {
    $list = [string[]]@(Get-ChildItem -LiteralPath $specsDir -Directory | ForEach-Object { $_.Name })
    [Array]::Sort($list, [StringComparer]::Ordinal); $names = $list
  }
  $runs = @()
  foreach ($d in $names) { # one child run per initiative; its output is reused for the report
    $e = 0; $w = 0
    if ($Json) {
      $j = (@(& $PSCommandPath "$Root/specs/$d" @child --json) -join "`n"); $x = $LASTEXITCODE
      if ($j -match '"errors":(\d+)') { $e = [int]$Matches[1] }
      if ($j -match '"warnings":(\d+)') { $w = [int]$Matches[1] }
    } else {
      $j = (@(& $PSCommandPath "$Root/specs/$d" @child) -join "`n"); $x = $LASTEXITCODE
      $rm = [regex]::Matches($j, '(?m)^Result: ([0-9]+) error\(s\), ([0-9]+) warning\(s\)')
      if ($rm.Count -gt 0) { $e = [int]$rm[$rm.Count - 1].Groups[1].Value; $w = [int]$rm[$rm.Count - 1].Groups[2].Value }
    }
    $runs += [pscustomobject]@{ Name = $d; Exit = $x; E = $e; W = $w; Json = $j }
  }
  $E = 0; $W = 0; $Exit = 0
  foreach ($r in $runs) { $E += $r.E; $W += $r.W; if ($r.Exit -gt $Exit) { $Exit = $r.Exit } }
  if ($Json) {
    $st = 'false'; if ($Strict) { $st = 'true' }
    Write-Output ('{"root":"' + (Get-JsonEsc $RL) + '","initiatives":[' + (($runs | ForEach-Object { $_.Json }) -join ',') + '],"count":' + $runs.Count + ',"errors":' + $E + ',"warnings":' + $W + ',"strict":' + $st + ',"exit":' + $Exit + '}')
  } else {
    Write-Output "check-spec $EM $Label"
    if ($runs.Count -eq 0) { Write-Output 'No initiatives under specs/.' }
    foreach ($r in $runs) { Write-Output ''; Write-Output $r.Json }
    Write-Output ''
    Write-Output 'Summary:'
    for ($k = 0; $k -lt $runs.Count; $k++) {
      $r = $runs[$k]
      Write-Output ("$($k + 1). specs/$($r.Name) $EM $(Get-Verdict $r.Exit) ($($r.E) error(s), $($r.W) warning(s))")
    }
    Write-Output "Result: $($runs.Count) initiative(s), $E error(s), $W warning(s) $EM $(Get-Verdict $Exit)"
  }
  exit $Exit
}

# ── Phase 1 ──────────────────────────────────────────────────────────────────
if ($Gate -or $All) { }
elseif (-not (Test-Path -LiteralPath (Join-Path $DirFull 'spec.md') -PathType Leaf)) {
  Add-Finding 'error' 'spec.md' 0 'phase1-missing' 'spec.md not found (Phase 1 is mandatory)'
} else {
  $Lines = Read-Lines (Join-Path $DirFull 'spec.md')
  $sections = @(
    @('Problem', 'problem|problema'),
    @('Behavioral contract', 'behaviou?ral contract|contrato de comportamiento|contrato conductual|comportamiento esperado'),
    @('Out of scope', 'out of scope|out-of-scope|fuera de alcance'),
    @('Success criteria', 'success criteria|criterios de (\u00e9|\u00c9|e)xito'),
    @('Constraints', 'constraints|restricciones'),
    @('Open questions', 'open questions|preguntas abiertas')
  )
  foreach ($s in $sections) { if (-not (Test-Heading $Lines $s[1])) { Add-Finding 'error' 'spec.md' 0 'missing-section' "missing section: $($s[0])" } }
  foreach ($r in (Get-Section $Lines 'functional requirements|requisitos funcionales').Rows) {
    $c = Get-Cells $r.Text; $id = Get-At $c 0
    if ($id -cnotmatch '^FR-[0-9]+$') { continue }
    if ($FrIds.Contains($id)) { Add-Finding 'error' 'spec.md' $r.No 'fr-duplicate' "duplicate requirement ID $id" } else { $FrIds.Add($id) }
  }
  if ($FrIds.Count -eq 0) { Add-Finding 'error' 'spec.md' 0 'fr-missing' 'no Functional requirements table with FR-### rows' }
  $count = Invoke-GherkinChecks $Lines 'spec.md' $true $true
  if ($count -eq 0) { Add-Finding 'error' 'spec.md' 0 'no-scenarios' 'no Gherkin scenario (Scenario:/Escenario:)' }
  foreach ($r in (Get-Section $Lines 'success criteria|criterios de (\u00e9|\u00c9|e)xito').Rows) {
    $c = Get-Cells $r.Text; $id = Get-At $c 0
    if ($id -cnotmatch '^SC-[0-9]+$') { continue }
    $ci = Get-Col $r.Hdr 'scenario|escenario'
    if ($ci -lt 0) { Add-Finding 'warning' 'spec.md' $r.No 'sc-scenario' "success criterion $id has no Scenario(s) column"; continue }
    $v = Get-At $c $ci
    if ($v -eq '' -or $v -eq '-') { Add-Finding 'warning' 'spec.md' $r.No 'sc-scenario' "success criterion $id maps to no scenario"; continue }
    foreach ($e in $v.Split(',')) {
      $e = $e.Trim().Replace('"', '')
      $found = $false; foreach ($t in $ScTitles) { if ([string]::Equals($t, $e, [StringComparison]::OrdinalIgnoreCase)) { $found = $true } }
      if (-not $found) { Add-Finding 'warning' 'spec.md' $r.No 'sc-scenario' "success criterion $id maps to unknown scenario: $e" }
    }
  }
  foreach ($l in (Get-Section $Lines 'clarifications|aclaraciones').Lines) {
    if ($l.Text -notmatch '^\s*[0-9]+[.)]\s') { continue }
    if ($l.Text -notmatch '(confirmed by|confirmado por)\s*:') { Add-Finding 'error' 'spec.md' $l.No 'clarify-unconfirmed' 'clarification answer without Confirmed by:' }
  }
  if (Test-Path -LiteralPath (Join-Path $DirFull 'design.md') -PathType Leaf) {
    foreach ($r in (Get-Section $Lines 'open questions|preguntas abiertas').Rows) {
      $bc = Get-Col $r.Hdr 'block|bloquea'; if ($bc -lt 0) { continue }
      $qc = Get-Col $r.Hdr 'question|pregunta'
      $c = Get-Cells $r.Text; $v = (Get-At $c $bc).ToLowerInvariant()
      if (@('yes', 'y', 'si', "s$([char]0x00ed)", 'true') -ccontains $v) {
        $q = "row $($r.No)"; if ($qc -ge 0) { $q = Get-At $c $qc }
        Add-Finding 'error' 'spec.md' $r.No 'blocking-question' "blocking open question still open: $q; cannot enter Phase 2"
      }
    }
  }
  Invoke-LineScan $Lines 'spec.md' $true $true
}

# ── Phase 2 ──────────────────────────────────────────────────────────────────
if (-not $Gate -and -not $All -and (Test-Path -LiteralPath (Join-Path $DirFull 'design.md') -PathType Leaf)) {
  $Lines = Read-Lines (Join-Path $DirFull 'design.md')
  if (-not (Test-Heading $Lines 'architecture (&|and) design|arquitectura y dise(\u00f1|\u00d1)o')) { Add-Finding 'error' 'design.md' 0 'phase2-heading' "missing '## Architecture & Design' section" }
  $elements = @(
    @('Architectural style', 'architectural style|estilo arquitect(\u00f3|\u00d3|o)nico'),
    @('Layers', 'layers|capas'),
    @('Bounded context', 'bounded[- ]context|contexto acotado|contexto delimitado'),
    @('Patterns', 'patterns|patrones'),
    @('State model', 'state model|modelo de estado'),
    @('Composition points', 'composition points|puntos de composici(\u00f3|\u00d3|o)n'),
    @('Public surface', 'public surface|superficie p(\u00fa|\u00da|u)blica'),
    @('Anti-violations', 'anti-violations|anti-violaciones|antiviolaciones')
  )
  foreach ($e in $elements) { if (-not (Test-Heading $Lines $e[1])) { Add-Finding 'warning' 'design.md' 0 'design-element' "design element not found: $($e[0])" } }
  Invoke-LineScan $Lines 'design.md' $false $true
}

# ── Tasks (tasks.md) ─────────────────────────────────────────────────────────
if (-not $Gate -and -not $All -and (Test-Path -LiteralPath (Join-Path $DirFull 'tasks.md') -PathType Leaf)) {
  $Lines = Read-Lines (Join-Path $DirFull 'tasks.md')
  $tIds = New-Object System.Collections.Generic.List[string]; $tRows = New-Object System.Collections.Generic.List[object]
  foreach ($r in (Get-Section $Lines '^(phase|fase)\s+[0-9]+').Rows) {
    $c = Get-Cells $r.Text; $id = Get-At $c 0
    if ($id -cnotmatch '^T[0-9]+$' -or $c.Count -lt 7) { Add-Finding 'error' 'tasks.md' $r.No 'task-format' 'row is not a task (| T### | P | Req | Task | Depends | Est | Status |)'; continue }
    if ($tIds.Contains($id)) { Add-Finding 'error' 'tasks.md' $r.No 'task-duplicate' "duplicate task ID $id"; continue }
    $tIds.Add($id); $tRows.Add($r)
  }
  if ($tIds.Count -eq 0) { Add-Finding 'error' 'tasks.md' 0 'task-format' 'no task rows (T###)' }
  $tDep = @{}
  foreach ($r in $tRows) {
    $c = Get-Cells $r.Text; $id = $c[0]; $req = $c[2]; $dep = $c[4]; $est = $c[5]
    $deps = New-Object System.Collections.Generic.List[string]
    if ($req -ne '-' -and $req -ne '') {
      foreach ($x in ($req.Replace(',', ' ') -split '\s+' | Where-Object { $_ -ne '' })) {
        if ($x -cnotmatch '^FR-[0-9]+$') { Add-Finding 'error' 'tasks.md' $r.No 'task-req' "task $id has an invalid requirement reference: $x" }
        elseif (-not $FrIds.Contains($x)) { Add-Finding 'error' 'tasks.md' $r.No 'task-req' "task $id references unknown requirement $x" }
      }
    }
    if ($dep -ne '-' -and $dep -ne '') {
      foreach ($x in ($dep.Replace(',', ' ') -split '\s+' | Where-Object { $_ -ne '' })) {
        if ($tIds.Contains($x)) { $deps.Add($x) } else { Add-Finding 'error' 'tasks.md' $r.No 'task-depends' "task $id depends on unknown task $x" }
      }
    }
    $tDep[$id] = $deps
    if (@('1', '2', '3', '5', '8', '13', '-') -cnotcontains $est) { Add-Finding 'error' 'tasks.md' $r.No 'task-estimate' "task $id estimate '$est' is not Fibonacci (1, 2, 3, 5, 8, 13) or -" }
  }
  $done = New-Object System.Collections.Generic.List[string]; $changed = $true
  while ($changed) {
    $changed = $false
    foreach ($id in $tIds) {
      if ($done.Contains($id)) { continue }
      $ready = $true; foreach ($x in $tDep[$id]) { if (-not $done.Contains($x)) { $ready = $false } }
      if ($ready) { $done.Add($id); $changed = $true }
    }
  }
  $left = @($tIds | Where-Object { -not $done.Contains($_) })
  if ($left.Count -gt 0) { Add-Finding 'error' 'tasks.md' 0 'task-cycle' "dependency cycle among: $($left -join ', ')" }
  Invoke-LineScan $Lines 'tasks.md' $false $true
}

# ── Requirements-quality checklist (requirements-checklist.md) ───────────────
if (-not $Gate -and -not $All) {
  $ck = Join-Path $DirFull 'requirements-checklist.md'
  if (Test-Path -LiteralPath $ck -PathType Leaf) {
    $Lines = Read-Lines $ck
    $tot = 0; $refd = 0
    foreach ($r in (Get-Section $Lines '').Rows) {
      $c = Get-Cells $r.Text; if ((Get-At $c 0) -cnotmatch '^CHK[0-9]+$') { continue }
      $tot++; $rc = Get-Col $r.Hdr '^ref'
      if ($rc -ge 0) { $v = Get-At $c $rc; if ($v -ne '' -and $v -ne '-') { $refd++ } }
    }
    if ($tot -eq 0) { Add-Finding 'warning' 'requirements-checklist.md' 0 'checklist-empty' 'no CHK### items' }
    elseif ($refd * 100 -lt $tot * 80) { Add-Finding 'warning' 'requirements-checklist.md' 0 'checklist-ref' "only $([int][math]::Floor($refd * 100 / $tot))% of checklist items reference the spec (80% required)" }
    Invoke-LineScan $Lines 'requirements-checklist.md' $false $true
  } elseif (Test-Path -LiteralPath (Join-Path $DirFull 'design.md') -PathType Leaf) {
    Add-Finding 'warning' 'requirements-checklist.md' 0 'checklist-missing' 'requirements-checklist.md missing (required before Phase 2 under --strict)'
  }
}

# ── Phase 4 ──────────────────────────────────────────────────────────────────
if (-not $Gate -and -not $All -and (Test-Path -LiteralPath (Join-Path $DirFull 'verification.md') -PathType Leaf)) {
  $Lines = Read-Lines (Join-Path $DirFull 'verification.md')
  $table = $false; $verdict = $false
  foreach ($l in $Lines) {
    if ($ReTable.IsMatch($l.Text)) { $table = $true }
    if ($ReVWord.IsMatch($l.Text) -and $ReMark.IsMatch($l.Text)) { $verdict = $true }
  }
  if (-not $table) { Add-Finding 'error' 'verification.md' 0 'phase4-table' 'no results table with a Result/Resultado column' }
  if (-not $verdict) { Add-Finding 'error' 'verification.md' 0 'phase4-verdict' 'no Verdict/Veredicto line with a check, warning or cross mark' }
  Invoke-LineScan $Lines 'verification.md' $false $true
}

# ── Work-item drafts (--tickets) ─────────────────────────────────────────────
if (-not $Gate -and -not $All -and $Tickets) {
  $slug = $Label.Substring($Label.LastIndexOf('/') + 1)
  $td = Join-Path (Join-Path (Join-Path (Join-Path $Root 'plans') 'initiatives') $slug) 'tickets'
  if (Test-Path -LiteralPath $td -PathType Container) {
    $files = [string[]]@(Get-ChildItem -LiteralPath $td -File -Filter '*.md' | ForEach-Object { $_.Name })
    [Array]::Sort($files, [StringComparer]::Ordinal)
    foreach ($t in $files) {
      $tl = "plans/initiatives/$slug/tickets/$t"
      $Lines = Read-Lines (Join-Path (Resolve-Path -LiteralPath $td).Path $t)
      if (-not (Test-Heading $Lines 'qa test cases|casos de prueba')) { Add-Finding 'error' $tl 0 'ticket-qa' 'work item without a QA test cases section' }
      [void](Invoke-GherkinChecks $Lines $tl $false)
      Invoke-LineScan $Lines $tl $false $false
    }
  }
}

# ── Report ───────────────────────────────────────────────────────────────────
$E = 0; $W = 0
foreach ($f in $Findings) { if ($f.Sev -eq 'error') { $E++ } else { $W++ } }
$Exit = 0; if ($E -gt 0) { $Exit = 1 } elseif ($Strict -and $W -gt 0) { $Exit = 2 }

if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"initiative":"' + (Get-JsonEsc $Label) + '","findings":[')
  for ($k = 0; $k -lt $Findings.Count; $k++) {
    $f = $Findings[$k]; if ($k -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"n":' + ($k + 1) + ',"severity":"' + $f.Sev + '","file":"' + (Get-JsonEsc $f.File) + '","line":' + $f.Line + ',"rule":"' + $f.Rule + '","message":"' + (Get-JsonEsc $f.Msg) + '"}')
  }
  $st = 'false'; if ($Strict) { $st = 'true' }
  [void]$sb.Append('],"errors":' + $E + ',"warnings":' + $W + ',"strict":' + $st + ',"exit":' + $Exit + '}')
  Write-Output $sb.ToString()
} else {
  Write-Output "check-spec $EM $Label"
  if ($Findings.Count -eq 0) { Write-Output 'No findings.' }
  for ($k = 0; $k -lt $Findings.Count; $k++) {
    $f = $Findings[$k]; $loc = $f.File; if ($f.Line -gt 0) { $loc += ":$($f.Line)" }
    Write-Output ("$($k + 1). $($f.Sev) $loc [$($f.Rule)] $($f.Msg)")
  }
  $v = 'WARN'; if ($Exit -eq 0) { $v = 'PASS' } elseif ($Exit -eq 1) { $v = 'FAIL' }
  Write-Output "Result: $E error(s), $W warning(s) $EM $v"
}
exit $Exit
