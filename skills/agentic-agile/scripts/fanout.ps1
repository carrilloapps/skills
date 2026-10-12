# fanout.ps1 — split one list into many self-contained SDD briefs, one per item, each with the
# model tier that should run it.
#
# PowerShell twin of fanout.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): same rules,
# same output, same exit codes. Reads a list (default plans/initiatives/<slug>/inventory.md; also
# tasks.md, a converge dump, or any Markdown table or numbered list) and writes one brief per item
# from templates/dispatch-task.md into specs/<slug>/dispatch/, plus the manifest
# specs/<slug>/dispatch.md. A file with at least one table row is read as tables only; a file with
# no table is read as a numbered or bulleted list. Rows whose Status is done or dropped are skipped.
#
# The script writes files and nothing else: it never runs an agent, never dispatches anything, and
# never edits the spec, tasks.md or the tracker.
#
# Usage: fanout.ps1 <slug> [--from PATH] [--root DIR] [--model-tier small|default|deep]
#                   [--model NAME] [--autonomy N1|N2|N3|N4] [--only IDS] [--priority P#]
#                   [--limit N] [--json] [--dry-run] [--force]
#                   (--skip-structure exists for the parity tests only)
# Exit:  0 briefs written or already present · 1 gate closed or no item in the list
#        3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

$Root = '.'; $Slug = ''; $From = ''; $Tier = 'small'; $Model = ''; $Autonomy = 'N2'
$Only = ''; $Priority = ''; $Limit = 50; $Json = $false; $Dry = $false; $Force = $false; $Skip = $false
function Fail([string]$msg) { [Console]::Error.WriteLine("fanout: $msg"); exit 3 }

for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  if (-not $a.StartsWith('-')) { if ($Slug -ne '') { Fail 'only one initiative slug is allowed' }; $Slug = $a; continue }
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'from' { if ($k + 1 -ge $args.Count) { Fail '--from needs a value' }; $k++; $From = [string]$args[$k] }
    'model-tier' { if ($k + 1 -ge $args.Count) { Fail '--model-tier needs a value' }; $k++; $Tier = [string]$args[$k] }
    'model' { if ($k + 1 -ge $args.Count) { Fail '--model needs a value' }; $k++; $Model = [string]$args[$k] }
    'autonomy' { if ($k + 1 -ge $args.Count) { Fail '--autonomy needs a value' }; $k++; $Autonomy = [string]$args[$k] }
    'only' { if ($k + 1 -ge $args.Count) { Fail '--only needs a value' }; $k++; $Only = [string]$args[$k] }
    'priority' { if ($k + 1 -ge $args.Count) { Fail '--priority needs a value' }; $k++; $Priority = [string]$args[$k] }
    'limit' { if ($k + 1 -ge $args.Count) { Fail '--limit needs a value' }; $k++; $Limit = [string]$args[$k] }
    'json' { $Json = $true }
    'dry-run' { $Dry = $true }
    'force' { $Force = $true }
    'skip-structure' { $Skip = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } {
      Write-Output 'Usage: fanout <slug> [--from PATH] [--root DIR] [--model-tier small|default|deep] [--model NAME] [--autonomy N1|N2|N3|N4] [--only IDS] [--priority P#] [--limit N] [--json] [--dry-run] [--force]'
      Write-Output '  <slug>          initiative in kebab-case; briefs land in specs/<slug>/dispatch/'
      Write-Output '  --from PATH     the list to split (default plans/initiatives/<slug>/inventory.md)'
      Write-Output '  --model-tier    which model row of plans/agile/capabilities.md to use (default small)'
      Write-Output '  --model NAME    use this model instead of the recorded one'
      Write-Output '  --only IDS      comma-separated source IDs to include (e.g. I003,I007)'
      Write-Output '  --priority P#   only rows whose Priority column is P# (e.g. P1)'
      exit 0 }
    default { Fail "unknown option: $a" }
  }
}

if ($Slug -eq '') { Fail 'fanout needs an initiative slug (e.g. fanout invoice-export)' }
if ($Slug -notmatch '^[a-z0-9][a-z0-9-]*$') { Fail "invalid slug: $Slug (use kebab-case: a-z, 0-9, -)" }
if ($Tier -ne 'small' -and $Tier -ne 'default' -and $Tier -ne 'deep') { Fail '--model-tier must be small, default or deep' }
if ($Autonomy -notmatch '^N[1-4]$') { Fail '--autonomy must be N1, N2, N3 or N4 (N0 means the agent does not participate)' }
if ($Limit -notmatch '^[0-9]+$' -or [int]$Limit -le 0) { Fail '--limit must be a positive integer' }
$Limit = [int]$Limit
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RL = $Root.Replace('\', '/'); while ($RL.Length -gt 1 -and $RL.EndsWith('/')) { $RL = $RL.Substring(0, $RL.Length - 1) }
$RootFull = (Resolve-Path -LiteralPath $Root).Path
if ($From -eq '') { $From = "plans/initiatives/$Slug/inventory.md" }
$From = $From.Replace('\', '/')
if ($From.StartsWith('/') -or $From -match '^[A-Za-z]:') { Fail '--from must be a path relative to the project' }
if (('/' + $From + '/').Contains('/../')) { Fail "--from must not contain '..'" }
function RPath([string]$rel) { return (Join-Path $RootFull ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)) }
foreach ($t in @('dispatch-task.md', 'dispatch.md')) {
  if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $SkillDir 'templates') $t) -PathType Leaf)) { Fail "missing template: templates/$t" }
}
function JEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }

# Phase 0
if (-not $Skip) {
  $cs = Join-Path $PSScriptRoot 'check-structure.ps1'
  if (-not (Test-Path -LiteralPath $cs)) { Fail 'check-structure.ps1 not found next to fanout.ps1' }
  $null = & $cs --root $Root --json 2>$null; $sx = $LASTEXITCODE
  if ($sx -eq 3) { Fail "check-structure failed on root: $RL" }
  if ($sx -ne 0) {
    $msg = "Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
    if ($Json) { Write-Output ('{"root":"' + (JEsc $RL) + '","slug":"' + $Slug + '","gate":"closed","message":"' + (JEsc $msg) + '","exit":1}') }
    else { Write-Output "fanout $EM $RL ($Slug)"; Write-Output "1. error structure [structure-gate] $msg"; Write-Output "Result: gate closed $EM FAIL" }
    exit 1
  }
}

if (-not (Test-Path -LiteralPath (RPath $From) -PathType Leaf)) { Fail "list not found: $From (run scripts/discover $Slug --pattern ... first, or pass --from PATH)" }

# Helpers
$SEP = [string][char]0x01
function Get-Cells([string]$row) {
  $r = $row.Replace('\|', $SEP).Trim()
  if ($r.StartsWith('|')) { $r = $r.Substring(1) }
  if ($r.EndsWith('|')) { $r = $r.Substring(0, $r.Length - 1) }
  $parts = ($r + '|').Split('|')
  $out = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $parts.Count - 1; $i++) { $out.Add($parts[$i].Replace($SEP, '|').Trim()) }
  return $out
}
function Get-Col([System.Collections.Generic.List[string]]$hdr, [string[]]$pats) {
  foreach ($p in $pats) {
    for ($i = 0; $i -lt $hdr.Count; $i++) {
      if ([regex]::IsMatch($hdr[$i], $p, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) { return $i }
    }
  }
  return -1
}
function Get-Slug([string]$text) {
  $s = ($text.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
  if ($s.Length -gt 48) { $s = $s.Substring(0, 48) }
  $s = $s.TrimEnd('-')
  if ($s -eq '') { $s = 'item' }
  return $s
}
function Get-Title([string]$text) {
  if ($text.Length -gt 60) { return $text.Substring(0, 57) + '...' }
  return $text
}

# Read the list
$ReSepRow = [regex]'^\s*\|[-|: ]+\|?\s*$'
$ReId = [regex]'^[A-Za-z]+[0-9]{3}$'
$ReBullet = [regex]'^\s*([-*+]\s+|[0-9]+[.)]\s+)'
$ReFr = [regex]'FR-[0-9]{3}'
$ReLocTxt = [regex]'^([^\s|]+:[0-9]+)\s+(.*)$'
$Lines = @([System.IO.File]::ReadAllLines((RPath $From), $Utf8) | ForEach-Object { $_.TrimEnd("`r") })

$SId = New-Object System.Collections.Generic.List[string]
$SItem = New-Object System.Collections.Generic.List[string]
$SLoc = New-Object System.Collections.Generic.List[string]
$SReq = New-Object System.Collections.Generic.List[string]
$HasTable = $false
$hdr = $null; $prev = ''; $intbl = $false; $fence = $false
foreach ($line in $Lines) {
  if ($line.StartsWith('```') -or $line.StartsWith('~~~')) { $fence = -not $fence; continue }
  if ($fence) { continue }
  $t = $line.Trim()
  if ($t -eq '' -or -not $t.StartsWith('|')) { $intbl = $false; $prev = ''; continue }
  if (-not $intbl) {
    if ($ReSepRow.IsMatch($line) -and $prev -ne '') { $hdr = Get-Cells $prev; $intbl = $true; $prev = ''; continue }
    $prev = $line; continue
  }
  if ($ReSepRow.IsMatch($line)) { continue }
  $idc = Get-Col $hdr @('^id$')
  $itc = Get-Col $hdr @('^task$', '^item$', '^finding$', '^description$', '^summary$')
  $lcc = Get-Col $hdr @('^location$', '^file$', '^path$')
  $rqc = Get-Col $hdr @('^req$', '^requirement$', '^reqs$')
  $prc = Get-Col $hdr @('^priority$', '^prio$')
  $stc = Get-Col $hdr @('^status$', '^state$')
  $C = Get-Cells $line
  $id = ''
  if ($idc -ge 0) {
    if ($idc -lt $C.Count) { $id = $C[$idc] }
    if (-not $ReId.IsMatch($id)) { continue }
  }
  $it = ''
  if ($itc -ge 0) { if ($itc -lt $C.Count) { $it = $C[$itc] } }
  else { for ($i = 0; $i -lt $C.Count; $i++) { if ($i -eq $idc) { continue }; if ($C[$i] -ne '') { $it = $C[$i]; break } } }
  if ($it -eq '') { continue }
  $HasTable = $true
  $st = ''
  if ($stc -ge 0 -and $stc -lt $C.Count) { $st = $C[$stc].ToLowerInvariant() }
  if ($st -eq 'done' -or $st -eq 'dropped' -or $st -eq 'cancelled' -or $st -eq 'canceled' -or $st -eq 'descartado' -or $st -eq 'hecho') { continue }
  $pr = ''
  if ($prc -ge 0 -and $prc -lt $C.Count) { $pr = $C[$prc] }
  if ($Priority -ne '' -and $pr -ne $Priority -and -not $pr.Equals($Priority, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
  $lc = '-'
  if ($lcc -ge 0 -and $lcc -lt $C.Count -and $C[$lcc] -ne '') { $lc = $C[$lcc] }
  $rq = ''
  if ($rqc -ge 0 -and $rqc -lt $C.Count) { $rq = $C[$rqc] }
  if ($rq -eq '' -or $rq -eq '-') {
    $m = $ReFr.Match($it)
    if ($m.Success) { $rq = $m.Value } else { $rq = 'unmapped' }
  }
  if ($id -eq '') { $id = 'R' + ($SId.Count + 1).ToString('000') }
  if ($Only -ne '' -and -not (",$Only,").Contains(",$id,")) { continue }
  $SId.Add($id); $SItem.Add($it); $SLoc.Add($lc); $SReq.Add($rq)
}

if (-not $HasTable) {
  $SId.Clear(); $SItem.Clear(); $SLoc.Clear(); $SReq.Clear()
  $fence = $false; $n = 0
  foreach ($line in $Lines) {
    if ($line.StartsWith('```') -or $line.StartsWith('~~~')) { $fence = -not $fence; continue }
    if ($fence) { continue }
    $m = $ReBullet.Match($line)
    if (-not $m.Success) { continue }
    $it = $line.Substring($m.Length)
    while ($true) { $m2 = $ReBullet.Match($it); if (-not $m2.Success) { break }; $it = $it.Substring($m2.Length) }
    $it = $it.Trim()
    if ($it -eq '') { continue }
    $lc = '-'
    $m3 = $ReLocTxt.Match($it)
    if ($m3.Success) { $lc = $m3.Groups[1].Value; $it = $m3.Groups[2].Value }
    $rq = 'unmapped'
    $m4 = $ReFr.Match($it)
    if ($m4.Success) { $rq = $m4.Value }
    $n++
    $id = 'L' + $n.ToString('000')
    if ($Only -ne '' -and -not (",$Only,").Contains(",$id,")) { continue }
    $SId.Add($id); $SItem.Add($it); $SLoc.Add($lc); $SReq.Add($rq)
  }
}

$Total = $SId.Count
$Trunc = $false
if ($Total -gt $Limit) { $Trunc = $true; $Total = $Limit }

if ($Total -eq 0) {
  $msg = "no item in $From (expected a Markdown table with an Item or Task column, or a numbered list)"
  if ($Json) { Write-Output ('{"root":"' + (JEsc $RL) + '","slug":"' + $Slug + '","from":"' + (JEsc $From) + '","briefs":[],"count":0,"message":"' + (JEsc $msg) + '","exit":1}') }
  else { Write-Output "fanout $EM $RL ($Slug)"; Write-Output "Result: 0 brief(s) $EM $msg" }
  exit 1
}

# Model tier and runner from the team's capabilities
$Cap = 'plans/agile/capabilities.md'
$ModelSrc = 'flag'; $Runner = ''
if ($Model -eq '' -and (Test-Path -LiteralPath (RPath $Cap) -PathType Leaf)) {
  foreach ($raw in [System.IO.File]::ReadAllLines((RPath $Cap), $Utf8)) {
    $line = $raw.TrimEnd("`r")
    if (-not $line.Trim().StartsWith('|')) { continue }
    $C = Get-Cells $line
    if ($C.Count -lt 2) { continue }
    $key = $C[0]; $val = $C[1]
    if ($val -eq '' -or $val.StartsWith('<')) { continue }
    # A slot the team answered with none / not applicable is not a model name or a command.
    if (@('none', 'not applicable', 'no aplica', 'n/a', '-') -contains $val.ToLowerInvariant()) { continue }
    if ([regex]::IsMatch($key, '^model[^A-Za-z0-9]*' + $Tier + '$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) { $Model = $val; $ModelSrc = 'capabilities' }
    if ([regex]::IsMatch($key, '^agent[^A-Za-z0-9]*runner$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) { $Runner = $val }
  }
}
if ($Model -eq '') { $Model = '<model-not-recorded>'; $ModelSrc = 'unset' }
$RunnerSrc = 'capabilities'
if ($Runner -eq '') {
  $RunnerSrc = 'default'
  $Runner = '<agent-cli> --model {{MODEL}} "Execute the brief at {{BRIEF}} exactly as written. Do not touch files outside its allow-list. If a decision is needed, stop and return the question."'
}

# Write the briefs
$Spec = "specs/$Slug"
$SpecPath = "$Spec/spec.md"
$TasksPath = "$Spec/tasks.md"
$SpecMissing = -not (Test-Path -LiteralPath (RPath $SpecPath) -PathType Leaf)

$BId = New-Object System.Collections.Generic.List[string]
$BFile = New-Object System.Collections.Generic.List[string]
$BAct = New-Object System.Collections.Generic.List[string]
$OutLines = New-Object System.Collections.Generic.List[string]
$N = 0; $Created = 0; $Skipped = 0; $Unmapped = 0
$TplTask = [System.IO.File]::ReadAllLines((Join-Path (Join-Path $SkillDir 'templates') 'dispatch-task.md'), $Utf8)
for ($i = 0; $i -lt $Total; $i++) {
  $did = 'D' + ($i + 1).ToString('000')
  $rel = "$Spec/dispatch/$did-" + (Get-Slug $SItem[$i]) + '.md'
  if ($SReq[$i] -eq 'unmapped') { $Unmapped++ }
  $BId.Add($did); $BFile.Add($rel)
  $N++
  if ((Test-Path -LiteralPath (RPath $rel)) -and -not $Force) {
    $BAct.Add('skip'); $Skipped++
    $OutLines.Add("$N. skip $rel (exists)")
    continue
  }
  $BAct.Add('create'); $Created++
  $OutLines.Add("$N. create $rel ($($SId[$i]), Req $($SReq[$i]), $Tier/$Model)")
  if ($Dry) { continue }
  $title = Get-Title $SItem[$i]
  $inv = $Runner.Replace('{{MODEL}}', $Model).Replace('{{BRIEF}}', $rel)
  $dir = Split-Path -Parent (RPath $rel)
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $null = New-Item -ItemType Directory -Force -Path $dir }
  $sb = New-Object System.Text.StringBuilder
  foreach ($tl in $TplTask) {
    $s = $tl.TrimEnd("`r")
    $s = $s.Replace('{{ID}}', $did).Replace('{{TITLE}}', $title).Replace('{{SLUG}}', $Slug)
    $s = $s.Replace('{{SOURCE_ID}}', $SId[$i]).Replace('{{SOURCE_FILE}}', $From).Replace('{{REQ}}', $SReq[$i])
    $s = $s.Replace('{{AUTONOMY}}', $Autonomy).Replace('{{TIER}}', $Tier).Replace('{{MODEL}}', $Model)
    $s = $s.Replace('{{ITEM}}', $SItem[$i]).Replace('{{LOCATION}}', $SLoc[$i])
    $s = $s.Replace('{{SPEC_PATH}}', $SpecPath).Replace('{{TASKS_PATH}}', $TasksPath)
    $s = $s.Replace('{{INVOCATION}}', $inv)
    [void]$sb.Append($s + "`n")
  }
  [System.IO.File]::WriteAllText((RPath $rel), $sb.ToString(), $Utf8)
}

$Man = "$Spec/dispatch.md"
$N++
$ManAct = 'create'
if ((Test-Path -LiteralPath (RPath $Man)) -and -not $Force) { $ManAct = 'skip'; $OutLines.Add("$N. skip $Man (exists)") }
else { $OutLines.Add("$N. create $Man") }
if ($ManAct -eq 'create' -and -not $Dry) {
  $dir = Split-Path -Parent (RPath $Man)
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $null = New-Item -ItemType Directory -Force -Path $dir }
  $sb = New-Object System.Text.StringBuilder
  foreach ($tl in [System.IO.File]::ReadAllLines((Join-Path (Join-Path $SkillDir 'templates') 'dispatch.md'), $Utf8)) {
    $s = $tl.TrimEnd("`r")
    $s = $s.Replace('{{SLUG}}', $Slug).Replace('{{SOURCE_FILE}}', $From).Replace('{{COUNT}}', [string]$Total)
    $s = $s.Replace('{{TIER}}', $Tier).Replace('{{MODEL}}', $Model).Replace('{{AUTONOMY}}', $Autonomy)
    $s = $s.Replace('{{TASKS_PATH}}', $TasksPath)
    if ($s -eq '{{ROWS}}') {
      for ($i = 0; $i -lt $Total; $i++) {
        $leaf = ($BFile[$i] -split '/')[-1]
        [void]$sb.Append('| [' + $BId[$i] + '](dispatch/' + $leaf + ') | ' + (Get-Title $SItem[$i]).Replace('|', '\|') + ' | ' + $SId[$i] + ' | ' + $SReq[$i] + ' | ' + $Tier + ' | ' + $Model + ' | ' + $Autonomy + " | todo | - |`n")
      }
      continue
    }
    # RUNNER last: its own {{MODEL}} / {{BRIEF}} placeholders must survive into the manifest.
    $s = $s.Replace('{{RUNNER}}', $Runner)
    [void]$sb.Append($s + "`n")
  }
  [System.IO.File]::WriteAllText((RPath $Man), $sb.ToString(), $Utf8)
}

# Report
if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"root":"' + (JEsc $RL) + '","slug":"' + $Slug + '","from":"' + (JEsc $From) + '","manifest":"' + (JEsc $Man) + '","tier":"' + $Tier + '","model":"' + (JEsc $Model) + '","model_source":"' + $ModelSrc + '","autonomy":"' + $Autonomy + '","briefs":[')
  for ($i = 0; $i -lt $Total; $i++) {
    if ($i -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"id":"' + $BId[$i] + '","source":"' + $SId[$i] + '","req":"' + (JEsc $SReq[$i]) + '","file":"' + (JEsc $BFile[$i]) + '","action":"' + $BAct[$i] + '","item":"' + (JEsc $SItem[$i]) + '","location":"' + (JEsc $SLoc[$i]) + '"}')
  }
  $tj = 'false'; if ($Trunc) { $tj = 'true' }
  $dj = 'false'; if ($Dry) { $dj = 'true' }
  [void]$sb.Append('],"count":' + $Total + ',"created":' + $Created + ',"skipped":' + $Skipped + ',"unmapped":' + $Unmapped + ',"truncated":' + $tj + ',"dry_run":' + $dj + ',"exit":0}')
  Write-Output $sb.ToString()
} else {
  Write-Output "fanout $EM $RL ($Slug)"
  foreach ($l in $OutLines) { Write-Output $l }
  if ($Trunc) { Write-Output "Truncated at --limit $Limit; the list has more items than this dispatch covers." }
  if ($SpecMissing) { Write-Output "No $SpecPath yet: the briefs point at it, so run 'aa specify $Slug' and fill Phase 1 before dispatching them." }
  if ($Unmapped -gt 0) { Write-Output "Unmapped: $Unmapped brief(s) serve no FR-### $EM map them in $TasksPath before implementation, or drop them as not-work." }
  if ($ModelSrc -eq 'unset') {
    Write-Output ("Model for tier $Tier not recorded in $Cap (Slots row 'Model " + [char]0x00B7 + " $Tier'). Relay this to the user:")
    Write-Output "  1. record the model for this tier in $Cap, or re-run with --model <name> (recommended: the smallest model that can pass the acceptance criteria)"
    Write-Output "  2. run the briefs with each agent's default model and no routing"
  }
  if ($RunnerSrc -eq 'default') { Write-Output "Runner command not recorded in $Cap (Slots row 'Agent runner'); the briefs carry the generic shape with <agent-cli> to fill in." }
  if ($Dry) { Write-Output "Result: $Total brief(s) from $From $EM would create $Created, skip $Skipped (dry run)" }
  else { Write-Output "Result: $Total brief(s) from $From $EM created $Created, skipped $Skipped, manifest $Man" }
}
exit 0
