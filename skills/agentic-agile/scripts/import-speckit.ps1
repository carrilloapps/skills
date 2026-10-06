# import-speckit.ps1 — convert a GitHub Spec Kit project into the agentic-agile layout.
#
# PowerShell twin of import-speckit.sh (Windows PowerShell 5.1 and PowerShell 7+): same mapping,
# same output, same files, same exit codes. Reads <from>/specs/NNN-<feature>/ and
# <from>/.specify/memory/constitution.md; writes specs/<feature>/{spec.md, design.md,
# domain-model.md, tasks.md, contracts/} and plans/agile/constitution.md (only if absent), all
# labelled Proposed. Dry run by default; --write applies it. Never overwrites a file. No network.
#
# Usage: import-speckit.ps1 [--root DIR] [--from DIR] [--write]
# Exit:  0 ok; 3 configuration error (no Spec Kit features found, bad paths)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function Fail([string]$msg) { [Console]::Error.WriteLine("import-speckit: $msg"); exit 3 }

$Root = '.'; $From = ''; $Write = $false
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'from' { if ($k + 1 -ge $args.Count) { Fail '--from needs a value' }; $k++; $From = [string]$args[$k] }
    'write' { $Write = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: import-speckit.ps1 [--root DIR] [--from DIR] [--write]'; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if ($From -eq '') { $From = $Root }
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
if (-not (Test-Path -LiteralPath $From -PathType Container)) { Fail "Spec Kit project not found: $From" }
function Get-Norm([string]$p) { $p = $p.Replace('\', '/'); while ($p.Length -gt 1 -and $p.EndsWith('/')) { $p = $p.Substring(0, $p.Length - 1) }; return $p }
$RL = Get-Norm $Root; $FL = Get-Norm $From
$RootFull = (Resolve-Path -LiteralPath $Root).Path; $FromFull = (Resolve-Path -LiteralPath $From).Path
function Get-Rel([string]$p) { if ($RL -eq '.') { return $p }; return "$RL/$p" }

$Feats = @()
$sd = Join-Path $FromFull 'specs'
if (Test-Path -LiteralPath $sd -PathType Container) {
  $list = [string[]]@(Get-ChildItem -LiteralPath $sd -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'spec.md') -PathType Leaf } | ForEach-Object { $_.Name })
  [Array]::Sort($list, [StringComparer]::Ordinal); $Feats = $list
}
if ($Feats.Count -eq 0) { Fail "no Spec Kit features found under $FL/specs (expected specs/NNN-<feature>/spec.md)" }

$LabelPre = "Proposed $EM imported from spec-kit ``"
$LabelPost = '`, needs confirmation.'
$script:N = 0
function Write-Step([string]$t) { $script:N++; Write-Output "$($script:N). $t" }
function Write-Target([string]$t, [string]$label, [string]$content, [bool]$copy = $false) {
  $full = Join-Path $RootFull $t
  if (Test-Path -LiteralPath $full) { Write-Step "skip $(Get-Rel $t) (exists)"; return }
  Write-Step "create $(Get-Rel $t) (from $label)"
  if (-not $Write) { return }
  [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($full))
  if ($copy) { [System.IO.File]::Copy($content, $full) } else { [System.IO.File]::WriteAllText($full, $content, $Utf8) }
}
function Read-Lines([string]$path) { return [System.IO.File]::ReadAllLines($path, $Utf8) | ForEach-Object { $_.TrimEnd("`r") } }
function Get-Demoted([string]$path) { # headings demoted by two levels, fenced code untouched; no trailing newline
  $out = New-Object System.Collections.Generic.List[string]; $fence = $false
  foreach ($line in (Read-Lines $path)) {
    if ($line -match '^\s*(```|~~~)') { $fence = -not $fence; $out.Add($line); continue }
    $m = [regex]::Match($line, '^(#{1,6})\s(.*)$')
    if (-not $fence -and $m.Success) {
      $h = '##' + $m.Groups[1].Value; if ($h.Length -gt 6) { $h = $h.Substring(0, 6) }
      $out.Add("$h $($m.Groups[2].Value)")
    } else { $out.Add($line) }
  }
  return ($out -join "`n").TrimEnd("`n")
}
function Get-CellSafe([string]$v) { return $v.Replace('|', '/') }

$ReStory = [regex]'^###\s+User Story\s+([0-9]+)\s*[^A-Za-z0-9\s]+\s*(.*)$'
$RePrio = [regex]'[(]Priority:\s*(P[1-3])[)]'
$ReAcc = [regex]'^\s*[0-9]+[.]\s+[*][*]Given[*][*]\s*(.*),\s*[*][*]When[*][*]\s*(.*),\s*[*][*]Then[*][*]\s*(.*)$'
$ReFr = [regex]'^\s*[-*]\s+[*][*](FR-[0-9]+)[*][*]\s*:?\s*(.*)$'
$ReSc = [regex]'^\s*[-*]\s+[*][*](SC-[0-9]+)[*][*]\s*:?\s*(.*)$'
$ReNc = [regex]'\[NEEDS CLARIFICATION:\s*([^\]]*)\]'
$ReQ = [regex]'^\s*[-*]\s+(Q:.*)$'
$ReBullet = [regex]'^\s*[-*]\s+(.*)$'
$ReH2 = [regex]'^##\s+(.*)$'
$ReH3 = [regex]'^###\s+(.*)$'
$RePhase = [regex]'^##\s+Phase\s+([0-9]+)\s*:?\s*(.*)$'
$ReTask = [regex]'^\s*[-*]\s+\[( |x|X)\]\s+(T[0-9]+)\s+(.*)$'
$ReTitle = [regex]'^#\s+(Feature Specification:\s*)?(.*)$'
$NL = "`n"

foreach ($feat in $Feats) {
  $slug = $feat -replace '^[0-9]*', ''; if ($slug.StartsWith('-')) { $slug = $slug.Substring(1) }; if ($slug -eq '') { $slug = $feat }
  $src = "specs/$feat"; $dst = "specs/$slug"; $srcFull = Join-Path $FromFull $src
  Write-Output "Feature: $src $([char]0x2192) $(Get-Rel $dst)"

  # spec.md
  $title = $slug; $frs = @(); $frt = @(); $scs = @(); $sct = @(); $qs = @(); $asm = @(); $edge = @(); $openq = @()
  $st = New-Object System.Collections.Generic.List[object]
  $sec = ''; $sub = ''; $story = 0; $sp = ''; $stitle = ''
  foreach ($line in (Read-Lines (Join-Path $srcFull 'spec.md'))) {
    $m = $ReTitle.Match($line)
    if ($m.Success -and $title -ceq $slug) { $t = $m.Groups[2].Value.Trim(); if ($t -ne '') { $title = $t }; continue }
    foreach ($nc in $ReNc.Matches($line)) { $openq += $nc.Groups[1].Value.Trim() }
    $m = $ReStory.Match($line)
    if ($m.Success) {
      $story = [int]$m.Groups[1].Value; $stitle = $m.Groups[2].Value; $sp = '-'
      $pm = $RePrio.Match($stitle); if ($pm.Success) { $sp = $pm.Groups[1].Value }
      $ix = $stitle.IndexOf('(Priority'); if ($ix -ge 0) { $stitle = $stitle.Substring(0, $ix) }
      $stitle = $stitle.Trim(); $sub = 'story'; continue
    }
    $m = $ReH2.Match($line); if ($m.Success) { $sec = $m.Groups[1].Value; $sub = ''; $story = 0; continue }
    $m = $ReH3.Match($line); if ($m.Success) { $sub = $m.Groups[1].Value; $story = 0; continue }
    if ($story -gt 0) {
      $m = $ReAcc.Match($line)
      if ($m.Success) { $st.Add([pscustomobject]@{ T = "US$story $stitle"; P = $sp; N = $story; G = $m.Groups[1].Value.Trim(); W = $m.Groups[2].Value.Trim(); H = $m.Groups[3].Value.Trim() }); continue }
    }
    $m = $ReFr.Match($line); if ($m.Success) { $frs += $m.Groups[1].Value; $frt += $m.Groups[2].Value; continue }
    $m = $ReSc.Match($line); if ($m.Success) { $scs += $m.Groups[1].Value; $sct += $m.Groups[2].Value; continue }
    if ($sec.StartsWith('Clarifications')) { $m = $ReQ.Match($line); if ($m.Success) { $qs += $m.Groups[1].Value } }
    elseif ($sec.StartsWith('Assumptions')) { $m = $ReBullet.Match($line); if ($m.Success) { $asm += $m.Groups[1].Value } }
    if ($sub.StartsWith('Edge Cases')) { $m = $ReBullet.Match($line); if ($m.Success) { $edge += $m.Groups[1].Value } }
  }
  $only = ''; if ($frs.Count -eq 1) { $only = $frs[0] }
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append("# Spec: $title$NL$NL$LabelPre$src/spec.md$LabelPost$NL$NL")
  [void]$sb.Append("## 1.1 Problem$NL${NL}Proposed $EM imported, needs confirmation: state the problem, its value and the stakeholders (Spec Kit has no Problem section; see the user stories below).$NL$NL")
  [void]$sb.Append("## Functional requirements$NL$NL| ID | Requirement | Priority |$NL|----|-------------|----------|$NL")
  for ($i = 0; $i -lt $frs.Count; $i++) { [void]$sb.Append("| $($frs[$i]) | $(Get-CellSafe $frt[$i]) | - |$NL") }
  [void]$sb.Append("$NL## 1.2 Behavioral contract$NL$NL``````gherkin$NL# language: en${NL}Feature: $title$NL")
  for ($i = 0; $i -lt $st.Count; $i++) {
    $s = $st[$i]
    $tags = ''; if ($only -ne '') { $tags = "@$only " }; if ($s.P -ne '-') { $tags += "@$($s.P)" }; $tags = $tags.Trim()
    [void]$sb.Append($NL)
    if ($tags -ne '') { [void]$sb.Append("  $tags$NL") }
    [void]$sb.Append("  Scenario: $($s.T) - $($i + 1)$NL")
    [void]$sb.Append("    # Origin: imported from spec-kit $src/spec.md (User Story $($s.N)); Proposed, link @FR-### and confirm$NL")
    [void]$sb.Append("    Given $($s.G)$NL    When $($s.W)$NL    Then $($s.H)$NL")
  }
  [void]$sb.Append("``````$NL$NL## 1.3 Out of scope$NL${NL}Proposed $EM imported, needs confirmation: Spec Kit has no out-of-scope section; list the exclusions with the team.$NL$NL")
  [void]$sb.Append("## 1.4 Success criteria$NL$NL| ID | Criterion | Scenario(s) |$NL|----|-----------|-------------|$NL")
  for ($i = 0; $i -lt $scs.Count; $i++) { [void]$sb.Append("| $($scs[$i]) | $(Get-CellSafe $sct[$i]) | - |$NL") }
  [void]$sb.Append("$NL## 1.5 Constraints & assumptions$NL$NL")
  if ($asm.Count -eq 0) { [void]$sb.Append("Proposed $EM imported, needs confirmation: none listed in Spec Kit.$NL") }
  else { for ($i = 0; $i -lt $asm.Count; $i++) { [void]$sb.Append("$($i + 1). $($asm[$i]) (Proposed)$NL") } }
  if ($qs.Count -gt 0) {
    [void]$sb.Append("$NL## Clarifications$NL$NL### Session imported$NL$NL")
    for ($i = 0; $i -lt $qs.Count; $i++) { [void]$sb.Append("$($i + 1). $($qs[$i]) $EM Proposed, imported; needs Confirmed by$NL") }
  }
  [void]$sb.Append("$NL## Open questions$NL$NL| # | Question | For | Blocks sprint? |$NL|---|----------|-----|----------------|$NL")
  for ($i = 0; $i -lt $openq.Count; $i++) { [void]$sb.Append("| $($i + 1) | $(Get-CellSafe $openq[$i]) | team | Yes |$NL") }
  if ($edge.Count -gt 0) {
    [void]$sb.Append("$NL## Imported notes$NL${NL}Edge cases from Spec Kit (turn each into a scenario or an out-of-scope item):$NL$NL")
    for ($i = 0; $i -lt $edge.Count; $i++) { [void]$sb.Append("$($i + 1). $($edge[$i])$NL") }
  }
  Write-Target "$dst/spec.md" "$src/spec.md" $sb.ToString()

  # design.md (plan.md + research.md + quickstart.md)
  if (Test-Path -LiteralPath (Join-Path $srcFull 'plan.md') -PathType Leaf) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("# Design: $title$NL$NL$LabelPre$src/plan.md$LabelPost$NL$NL## Architecture & Design$NL$NL")
    foreach ($e in @('1. Architectural style', '2. Layers', '3. Bounded context', '4. Patterns to mirror', '5. State model', '6. Composition points', '7. Public surface delta', '8. Anti-violations')) {
      [void]$sb.Append("### $e$NL${NL}Proposed $EM fill from the imported notes below.$NL$NL")
    }
    [void]$sb.Append("## Imported notes$NL")
    foreach ($f in @('plan', 'research', 'quickstart')) {
      $fp = Join-Path $srcFull "$f.md"
      if (-not (Test-Path -LiteralPath $fp -PathType Leaf)) { continue }
      [void]$sb.Append("$NL### From $f.md$NL$NL$(Get-Demoted $fp)$NL")
    }
    Write-Target "$dst/design.md" "$src/plan.md" $sb.ToString()
  }

  # domain-model.md
  $dm = Join-Path $srcFull 'data-model.md'
  if (Test-Path -LiteralPath $dm -PathType Leaf) {
    Write-Target "$dst/domain-model.md" "$src/data-model.md" "# Domain model: $title$NL$NL$LabelPre$src/data-model.md$LabelPost$NL$NL$(Get-Demoted $dm)$NL"
  }

  # contracts/
  $cd = Join-Path $srcFull 'contracts'
  if (Test-Path -LiteralPath $cd -PathType Container) {
    $files = [string[]]@([System.IO.Directory]::GetFiles($cd, '*', [System.IO.SearchOption]::AllDirectories) | ForEach-Object { $_.Substring($cd.Length + 1).Replace('\', '/') })
    [Array]::Sort($files, [StringComparer]::Ordinal)
    foreach ($c in $files) { Write-Target "$dst/contracts/$c" "$src/contracts/$c" (Join-Path $cd $c) $true }
  }

  # tasks.md
  $tf = Join-Path $srcFull 'tasks.md'
  if (Test-Path -LiteralPath $tf -PathType Leaf) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("# Tasks: $title$NL$NL$LabelPre$src/tasks.md$LabelPost$NL")
    $th = "| ID | P | Req | Task | Depends | Est | Status |$NL|----|---|-----|------|---------|-----|--------|$NL"
    $inphase = $false
    foreach ($line in (Read-Lines $tf)) {
      $m = $RePhase.Match($line)
      if ($m.Success) { [void]$sb.Append("$NL## Phase $($m.Groups[1].Value): $($m.Groups[2].Value)$NL$NL$th"); $inphase = $true; continue }
      $m = $ReTask.Match($line); if (-not $m.Success) { continue }
      if (-not $inphase) { [void]$sb.Append("$NL## Phase 1: Imported$NL$NL$th"); $inphase = $true }
      $status = '-'; if ($m.Groups[1].Value -ne ' ') { $status = [string][char]0x2705 }
      $id = $m.Groups[2].Value; $d = $m.Groups[3].Value; $p = '-'; $req = '-'
      $pm = [regex]::Match($d, '^\[P\]\s*(.*)$'); if ($pm.Success) { $p = '[P]'; $d = $pm.Groups[1].Value }
      $um = [regex]::Match($d, '^\[US[0-9]+\]\s*(.*)$'); if ($um.Success) { $d = $um.Groups[1].Value; if ($only -ne '') { $req = $only } }
      [void]$sb.Append("| $id | $p | $req | $(Get-CellSafe $d) | - | - | $status |$NL")
    }
    Write-Target "$dst/tasks.md" "$src/tasks.md" $sb.ToString()
  }
}

# constitution
$c = '.specify/memory/constitution.md'
$cf = Join-Path $FromFull $c
if (Test-Path -LiteralPath $cf -PathType Leaf) {
  $body = $Utf8.GetString([System.IO.File]::ReadAllBytes($cf)).Replace("`r", '').TrimEnd("`n")
  Write-Target 'plans/agile/constitution.md' $c "$LabelPre$c$LabelPost$NL$NL$body$NL"
}

Write-Output 'Imported content is Proposed: confirm it with the team (Confirmed by), link scenarios to FR-###, then run: aa verify <feature>'
if ($Write) { Write-Output "Written: $($script:N) action(s) applied (existing files skipped)." }
else { Write-Output 'Dry run: nothing written. Re-run with --write to apply.' }
exit 0
