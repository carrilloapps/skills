# aa.ps1 — single entry point for the agentic-agile workflow (any agent, any OS).
#
# PowerShell twin of aa.sh (Windows PowerShell 5.1 and PowerShell 7+): same intents, same output,
# same exit codes. Scaffolding intents (specify, plan, tasks) require the Phase 0 gate to be open
# and never overwrite a file. converge groups the trace + analyze findings of one initiative into
# numbered next tasks (missing, partial, contradictory, unrequested). No network.
#
# Usage: aa.ps1 <intent> [args]            aa.ps1 help   (intent list)
# Exit:  the dispatched script's exit code; scaffolding: 0 ok, 1 blocked; 3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$Here = $PSScriptRoot
$Skill = (Resolve-Path -LiteralPath (Join-Path $Here '..')).Path
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function Fail([string]$msg) { [Console]::Error.WriteLine("aa: $msg"); exit 3 }

function Show-Usage {
  Write-Output 'Usage: aa <intent> [args]'
  Write-Output 'Intents:'
  Write-Output '1. init [--preset NAME] [--dry-run]  scaffold plans/agile/, plans/, specs/ (scripts/init)'
  Write-Output '2. structure [--scorecard]           Phase 0 gate (scripts/check-structure)'
  Write-Output '3. doctor                            one-screen health (scripts/doctor)'
  Write-Output '4. specify <slug>                    create specs/<slug>/spec.md (gate open)'
  Write-Output '5. clarify <slug>                    open questions and unconfirmed answers (frameworks/clarify.md)'
  Write-Output '6. plan <slug>                       create design.md, domain-model.md, requirements-checklist.md (spec passes)'
  Write-Output '7. tasks <slug>                      create tasks.md (design passes)'
  Write-Output '8. verify <slug> [--strict]          validate the initiative (scripts/check-spec)'
  Write-Output '9. trace / analyze / baseline        traceability, cross-artifact analysis, accepted findings'
  Write-Output '10. audit                            hygiene of the team''s system (scripts/audit-agile)'
  Write-Output '11. converge <slug>                  trace + analyze gaps as numbered next tasks'
  Write-Output '12. import-speckit [--from DIR] [--write]  convert a Spec Kit project (dry run by default)'
  Write-Output '13. help                             this list'
  Write-Output 'Common option: --root DIR (project root, default: current directory).'
}

if ($args.Count -eq 0) { Show-Usage; exit 3 }
$Intent = [string]$args[0]
$Argv = @(); if ($args.Count -gt 1) { $Argv = @($args[1..($args.Count - 1)] | ForEach-Object { [string]$_ }) }
$Root = '.'; $Slug = ''; $Rest = @()
for ($k = 0; $k -lt $Argv.Count; $k++) {
  $a = $Argv[$k]
  if ($a -eq '--root' -or $a -eq '-Root') { if ($k + 1 -ge $Argv.Count) { Fail '--root needs a value' }; $k++; $Root = $Argv[$k] }
  elseif ($a.StartsWith('-')) { $Rest += $a }
  elseif ($Slug -eq '') { $Slug = $a } else { $Rest += $a }
}
$RL = $Root.Replace('\', '/'); while ($RL.Length -gt 1 -and $RL.EndsWith('/')) { $RL = $RL.Substring(0, $RL.Length - 1) }

function Invoke-Sib([string]$name, [string[]]$argv) { # runs scripts/<name>.ps1 and exits with its code
  $f = Join-Path $Here "$name.ps1"
  if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { Fail "scripts/$name.ps1 not found (install the complete agentic-agile skill)" }
  & $f @argv; exit $LASTEXITCODE
}
$script:Spec = ''
function Use-Slug {
  if ($Slug -eq '') { Fail "$Intent needs an initiative slug (e.g. aa $Intent invoice-export)" }
  if ($Slug -cnotmatch '^[a-z0-9][a-z0-9-]*$') { Fail "invalid slug: $Slug (use kebab-case: a-z, 0-9, -)" }
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
  if ($RL -eq '.') { $script:Spec = "specs/$Slug" } else { $script:Spec = "$RL/specs/$Slug" }
}
function Assert-Gate {
  $null = & (Join-Path $Here 'check-structure.ps1') --root $Root; $x = $LASTEXITCODE
  if ($x -eq 3) { Fail "check-structure failed on root: $Root" }
  if ($x -ne 0) { Write-Output "Blocked: Phase 0 gate closed. Run: aa structure --root $RL, then complete plans/agile/ with the team."; exit 1 }
}
function Test-SpecPasses { $null = & (Join-Path $Here 'check-spec.ps1') $script:Spec --root $Root; return ($LASTEXITCODE -eq 0) }
function Assert-Templates([string[]]$names) { foreach ($t in $names) { if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $Skill 'templates') $t) -PathType Leaf)) { Fail "missing template: templates/$t" } } }
$script:N = 0
function New-Scaffold([string]$tpl, [string]$name) {
  $f = "$($script:Spec)/$name"; $script:N++
  if (Test-Path -LiteralPath $f) { Write-Output "$($script:N). skip $f (exists)" }
  else {
    [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine((Get-Location).Path, $script:Spec))
    [System.IO.File]::Copy((Join-Path (Join-Path $Skill 'templates') $tpl), [System.IO.Path]::Combine((Get-Location).Path, $f))
    Write-Output "$($script:N). create $f"
  }
}
function Get-Cells([string]$row) {
  $r = $row.Trim(); if ($r.StartsWith('|')) { $r = $r.Substring(1) }; if ($r.EndsWith('|')) { $r = $r.Substring(0, $r.Length - 1) }
  return , @($r.Split('|') | ForEach-Object { $_.Trim() })
}
function Get-Col([string]$hdr, [string]$pattern) {
  $c = Get-Cells $hdr; $re = New-Object regex($pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  for ($i = 0; $i -lt $c.Count; $i++) { if ($re.IsMatch($c[$i])) { return $i } }
  return -1
}
function Get-At($arr, [int]$i) { if ($i -ge 0 -and $i -lt $arr.Count) { return [string]$arr[$i] }; return '' }

switch -CaseSensitive ($Intent) {
  { $_ -eq 'help' -or $_ -eq '-h' -or $_ -eq '--help' } { Show-Usage; exit 0 }
  'init' { Invoke-Sib 'init' $Argv }
  'structure' { Invoke-Sib 'check-structure' $Argv }
  'doctor' { Invoke-Sib 'doctor' $Argv }
  'audit' { Invoke-Sib 'audit-agile' $Argv }
  'trace' { Invoke-Sib 'trace' $Argv }
  'analyze' { Invoke-Sib 'analyze' $Argv }
  'baseline' { Invoke-Sib 'baseline' $Argv }
  'import-speckit' { Invoke-Sib 'import-speckit' $Argv }
  'verify' { Use-Slug; Invoke-Sib 'check-spec' (@($script:Spec, '--root', $Root) + $Rest) }

  'specify' {
    Use-Slug; Assert-Templates @('spec.md'); Assert-Gate
    Write-Output "aa specify $EM $($script:Spec)"
    New-Scaffold 'spec.md' 'spec.md'
    Write-Output "Next: fill Phase 1 (FR-### table, Gherkin scenarios tagged @FR-### and @P1-@P3, open questions), then run: aa clarify $Slug"
    exit 0
  }

  'clarify' {
    Use-Slug
    $f = "$($script:Spec)/spec.md"
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { Fail "spec not found: $f (run: aa specify $Slug)" }
    $sect = ''; $lvl = 0; $fence = $false; $hdr = ''; $qn = 0; $blocking = 0; $answers = 0; $unconf = 0; $QList = @()
    foreach ($line in [System.IO.File]::ReadAllLines([System.IO.Path]::Combine((Get-Location).Path, $f), $Utf8)) {
      $line = $line.TrimEnd("`r")
      if ($line -match '^\s*(```|~~~)') { $fence = -not $fence; continue }
      if ($fence) { continue }
      $m = [regex]::Match($line, '^(#{1,6})[ \t]+(.*)$')
      if ($m.Success) {
        $hl = $m.Groups[1].Value.Length; $h = $m.Groups[2].Value; $hdr = ''
        if ($sect -ne '' -and $hl -le $lvl) { $sect = '' }
        if ($sect -eq '') {
          if ($h -match 'open questions|preguntas abiertas') { $sect = 'open'; $lvl = $hl }
          elseif ($h -match 'clarifications|aclaraciones') { $sect = 'clar'; $lvl = $hl }
        }
        continue
      }
      if ($sect -eq 'open') {
        if ($line -notmatch '^\s*\|') { $hdr = ''; continue }
        if ($line -notmatch '[^-|:\s]') { continue }
        if ($hdr -eq '') { $hdr = $line; continue }
        $qc = Get-Col $hdr 'question|pregunta'; $fc = Get-Col $hdr '^for$|^para$|owner|responsable'; $bc = Get-Col $hdr 'block|bloquea'
        $c = Get-Cells $line
        $q = Get-At $c $qc; if ($q -eq '') { continue }
        $fo = '-'; if ($fc -ge 0) { $fo = Get-At $c $fc }; if ($fo -eq '') { $fo = '-' }
        $bl = '-'; if ($bc -ge 0) { $bl = Get-At $c $bc }; if ($bl -eq '') { $bl = '-' }
        $qn++; $QList += "$qn. $q $EM for $fo $EM blocks sprint: $bl"
        if (@('yes', 'y', 'si', "s$([char]0x00ed)", 'true') -ccontains $bl.ToLowerInvariant()) { $blocking++ }
      } elseif ($sect -eq 'clar') {
        if ($line -notmatch '^\s*[0-9]+[.)]\s') { continue }
        $answers++
        if ($line -notmatch '(confirmed by|confirmado por)\s*:') { $unconf++ }
      }
    }
    Write-Output "aa clarify $EM $($script:Spec)"
    if ($qn -eq 0) { Write-Output 'Open questions: none' } else { Write-Output 'Open questions:'; foreach ($x in $QList) { Write-Output $x } }
    Write-Output "Clarifications: $answers answer(s), $unconf without Confirmed by"
    Write-Output "Protocol: frameworks/clarify.md $EM at most 5 questions, one at a time, numbered options with a recommended one; record each answer under ## Clarifications > ### Session YYYY-MM-DD with Confirmed by: <name> (<role>)."
    if ($blocking -gt 0 -or $unconf -gt 0) { Write-Output "Result: $blocking blocking question(s), $unconf unconfirmed answer(s) $EM ATTENTION"; exit 1 }
    Write-Output "Result: 0 blocking question(s), 0 unconfirmed answer(s) $EM READY"; exit 0
  }

  'plan' {
    Use-Slug; Assert-Templates @('design.md', 'domain-model.md', 'requirements-checklist.md'); Assert-Gate
    if (-not (Test-Path -LiteralPath "$($script:Spec)/spec.md" -PathType Leaf)) { Fail "spec not found: $($script:Spec)/spec.md (run: aa specify $Slug)" }
    if (-not (Test-SpecPasses)) { Write-Output "Blocked: $($script:Spec) does not pass check-spec. Run: aa verify $Slug"; exit 1 }
    Write-Output "aa plan $EM $($script:Spec)"
    New-Scaffold 'design.md' 'design.md'
    New-Scaffold 'domain-model.md' 'domain-model.md'
    New-Scaffold 'requirements-checklist.md' 'requirements-checklist.md'
    Write-Output "Next: fill design.md (8 elements), domain-model.md and requirements-checklist.md, then run: aa tasks $Slug"
    exit 0
  }

  'tasks' {
    Use-Slug; Assert-Templates @('tasks.md'); Assert-Gate
    if (-not (Test-Path -LiteralPath "$($script:Spec)/design.md" -PathType Leaf)) { Write-Output "Blocked: $($script:Spec)/design.md missing. Run: aa plan $Slug"; exit 1 }
    if (-not (Test-SpecPasses)) { Write-Output "Blocked: $($script:Spec) does not pass check-spec (spec and design). Run: aa verify $Slug"; exit 1 }
    Write-Output "aa tasks $EM $($script:Spec)"
    New-Scaffold 'tasks.md' 'tasks.md'
    Write-Output "Next: list T### tasks per phase (mark [P] when parallel, map Req to FR-###), estimate only after the team votes, then run: aa verify $Slug"
    exit 0
  }

  'converge' {
    Use-Slug
    foreach ($s in @('trace', 'analyze')) { if (-not (Test-Path -LiteralPath (Join-Path $Here "$s.ps1") -PathType Leaf)) { Fail "scripts/$s.ps1 not found (install the complete agentic-agile skill)" } }
    $groups = [ordered]@{ Missing = @(); Partial = @(); Contradictory = @(); Unrequested = @() }
    foreach ($s in @('trace', 'analyze')) {
      $j = (@(& (Join-Path $Here "$s.ps1") --root $Root --spec "specs/$Slug" --json) -join "`n"); $x = $LASTEXITCODE
      if ($x -eq 3) { Fail "$s failed on $($script:Spec)" }
      foreach ($om in [regex]::Matches($j, '\{[^{}]*\}')) {
        $o = $om.Value
        $mm = [regex]::Match($o, '"message":"((?:[^"\\]|\\.)*)"'); if (-not $mm.Success) { continue }
        $msg = $mm.Groups[1].Value.Replace('\"', '"').Replace('\\', '\')
        $r = ''; $rm = [regex]::Match($o, '"rule":"([^"]*)"'); if ($rm.Success) { $r = $rm.Groups[1].Value }
        $cat = ''; $cm = [regex]::Match($o, '"category":"([^"]*)"'); if ($cm.Success) { $cat = $cm.Groups[1].Value }
        if ($cat -eq '') {
          $k = ("$r $msg").ToLowerInvariant()
          if ($k -match 'unrequested|unmapped|orphan|not requested') { $cat = 'unrequested' }
          elseif ($k -match 'contradict|conflict|inconsisten|mismatch') { $cat = 'contradictory' }
          elseif ($k.Contains('partial')) { $cat = 'partial' }
          else { $cat = 'missing' }
        }
        $e = "$msg ($s"; if ($r -ne '') { $e += ": $r" }; $e += ')'
        switch -CaseSensitive ($cat) { 'partial' { $groups.Partial += $e } 'contradictory' { $groups.Contradictory += $e } 'unrequested' { $groups.Unrequested += $e } default { $groups.Missing += $e } }
      }
    }
    Write-Output "aa converge $EM $($script:Spec)"
    $n = 0
    foreach ($g in $groups.Keys) {
      if ($groups[$g].Count -eq 0) { continue }
      Write-Output "${g}:"
      foreach ($e in $groups[$g]) { $n++; Write-Output "$n. $e" }
    }
    if ($n -eq 0) { Write-Output 'No gaps: spec, tasks and code converge.'; exit 0 }
    Write-Output "Next: add $n task(s) under '## Phase N: Convergence' in $($script:Spec)/tasks.md (one per gap, mapped to its FR-###), then run: aa converge $Slug"
    exit 1
  }

  default { Fail "unknown intent: $Intent (run: aa help)" }
}
