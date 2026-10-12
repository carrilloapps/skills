# discover.ps1 — deterministic sweep of the project into one inventory list with stable IDs.
#
# PowerShell twin of discover.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): same rules,
# same output, same exit codes. Two input kinds, combinable: --pattern RE sweeps every line of
# every text file under the root (label Verified, with path:line), --from FILE normalizes a list
# the agent already produced (label Documented). Items are deduplicated by location + text,
# numbered I001.., and written to plans/initiatives/<slug>/inventory.md (or --out). Only that file
# is written. No network. The deep half of a deep search is the agent's protocol in
# frameworks/discover.md; this script is the reproducible half.
#
# Usage: discover.ps1 <slug> [--pattern RE]... [--from FILE]... [--root DIR] [--out PATH]
#                     [--include GLOB]... [--exclude GLOB]... [--ext EXT]... [--ignore-case]
#                     [--limit N] [--max-bytes N] [--label LABEL] [--json] [--dry-run] [--force]
#                     (--skip-structure exists for the parity tests only)
# Exit:  0 items inventoried · 1 nothing found, gate closed, or output exists without --force
#        3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Root = '.'; $Slug = ''; $Out = ''; $Limit = 200; $MaxB = 1048576; $Label = ''
$Json = $false; $Dry = $false; $Force = $false; $Skip = $false; $ICase = $false
$Pat = New-Object System.Collections.Generic.List[string]
$From = New-Object System.Collections.Generic.List[string]
$Inc = New-Object System.Collections.Generic.List[string]
$Exc = New-Object System.Collections.Generic.List[string]
$Ext = New-Object System.Collections.Generic.List[string]
$ExtDefault = 'md txt json jsonl yml yaml toml ini cfg conf env properties sh bash zsh ps1 psm1 py js mjs cjs ts tsx jsx vue svelte go rs java kt kts swift c h cpp cc hpp cs rb php pl sql html css scss sass less xml gradle tf tfvars graphql proto csv tsv'
$Prune = '.git node_modules .memory dist build out vendor .venv venv target coverage .next .nuxt .cache __pycache__ .terraform graphify-out .work'
function Fail([string]$msg) { [Console]::Error.WriteLine("discover: $msg"); exit 3 }

for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  if (-not $a.StartsWith('-')) { if ($Slug -ne '') { Fail 'only one initiative slug is allowed' }; $Slug = $a; continue }
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'pattern' { if ($k + 1 -ge $args.Count) { Fail '--pattern needs a value' }; $k++; $Pat.Add([string]$args[$k]) }
    'from' { if ($k + 1 -ge $args.Count) { Fail '--from needs a value' }; $k++; $From.Add([string]$args[$k]) }
    'include' { if ($k + 1 -ge $args.Count) { Fail '--include needs a value' }; $k++; $Inc.Add([string]$args[$k]) }
    'exclude' { if ($k + 1 -ge $args.Count) { Fail '--exclude needs a value' }; $k++; $Exc.Add([string]$args[$k]) }
    'ext' { if ($k + 1 -ge $args.Count) { Fail '--ext needs a value' }; $k++; $Ext.Add(([string]$args[$k]).TrimStart('.')) }
    'out' { if ($k + 1 -ge $args.Count) { Fail '--out needs a value' }; $k++; $Out = [string]$args[$k] }
    'label' { if ($k + 1 -ge $args.Count) { Fail '--label needs a value' }; $k++; $Label = [string]$args[$k] }
    'limit' { if ($k + 1 -ge $args.Count) { Fail '--limit needs a value' }; $k++; $Limit = [string]$args[$k] }
    'max-bytes' { if ($k + 1 -ge $args.Count) { Fail '--max-bytes needs a value' }; $k++; $MaxB = [string]$args[$k] }
    'ignore-case' { $ICase = $true }
    'json' { $Json = $true }
    'dry-run' { $Dry = $true }
    'force' { $Force = $true }
    'skip-structure' { $Skip = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } {
      Write-Output 'Usage: discover <slug> [--pattern RE]... [--from FILE]... [--root DIR] [--out PATH] [--include GLOB]... [--exclude GLOB]... [--ext EXT]... [--ignore-case] [--limit N] [--max-bytes N] [--label LABEL] [--json] [--dry-run] [--force]'
      Write-Output '  <slug>         initiative in kebab-case; output defaults to plans/initiatives/<slug>/inventory.md'
      Write-Output '  --pattern RE   sweep the project for lines matching RE (repeatable)'
      Write-Output '  --from FILE    normalize a list the agent already produced, one item per line (repeatable)'
      Write-Output '  --include/--exclude  glob on the relative path, * crosses directory separators'
      Write-Output '  --ext EXT      add a file extension to the text allow-list (repeatable)'
      exit 0 }
    default { Fail "unknown option: $a" }
  }
}

if ($Slug -eq '') { Fail 'discover needs an initiative slug (e.g. discover invoice-export --pattern TODO)' }
if ($Slug -notmatch '^[a-z0-9][a-z0-9-]*$') { Fail "invalid slug: $Slug (use kebab-case: a-z, 0-9, -)" }
if ($Pat.Count -eq 0 -and $From.Count -eq 0) { Fail 'nothing to search: pass at least one --pattern or --from' }
if ($Limit -notmatch '^[0-9]+$' -or [int]$Limit -le 0) { Fail '--limit must be a positive integer' }
if ($MaxB -notmatch '^[0-9]+$' -or [long]$MaxB -le 0) { Fail '--max-bytes must be a positive integer' }
$Limit = [int]$Limit; $MaxB = [long]$MaxB
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RL = $Root.Replace('\', '/'); while ($RL.Length -gt 1 -and $RL.EndsWith('/')) { $RL = $RL.Substring(0, $RL.Length - 1) }
$RootFull = (Resolve-Path -LiteralPath $Root).Path
if ($Out -eq '') { $Out = "plans/initiatives/$Slug/inventory.md" }
$Out = $Out.Replace('\', '/')
if ($Out.StartsWith('/') -or $Out -match '^[A-Za-z]:') { Fail '--out must be a path relative to the project' }
if (('/' + $Out + '/').Contains('/../')) { Fail "--out must not contain '..'" }
if ($Label -ne '' -and $Label -ne 'Verified' -and $Label -ne 'Documented' -and $Label -ne 'Proposed') { Fail '--label must be Verified, Documented or Proposed' }

function JEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }

# Phase 0 - the inventory is a plan artifact, so the structure gate owns it like every other one.
if (-not $Skip) {
  $cs = Join-Path $PSScriptRoot 'check-structure.ps1'
  if (-not (Test-Path -LiteralPath $cs)) { Fail 'check-structure.ps1 not found next to discover.ps1' }
  $null = & $cs --root $Root --json 2>$null; $sx = $LASTEXITCODE
  if ($sx -eq 3) { Fail "check-structure failed on root: $RL" }
  if ($sx -ne 0) {
    $msg = "Phase 0 structure incomplete; run scripts/check-structure --root $RL and complete plans/agile/ with the team first"
    if ($Json) { Write-Output ('{"root":"' + (JEsc $RL) + '","slug":"' + $Slug + '","gate":"closed","message":"' + (JEsc $msg) + '","exit":1}') }
    else { Write-Output "discover $EM $RL ($Slug)"; Write-Output "1. error structure [structure-gate] $msg"; Write-Output "Result: gate closed $EM FAIL" }
    exit 1
  }
}

$OutFull = Join-Path $RootFull $Out
if ((Test-Path -LiteralPath $OutFull) -and -not $Force -and -not $Dry) {
  $msg = "$Out exists; re-run with --force to replace it (IDs are renumbered) or pass --out PATH"
  if ($Json) { Write-Output ('{"root":"' + (JEsc $RL) + '","slug":"' + $Slug + '","out":"' + (JEsc $Out) + '","message":"' + (JEsc $msg) + '","exit":1}') }
  else { Write-Output "discover $EM $RL ($Slug)"; Write-Output "1. skip $Out (exists)"; Write-Output "Result: $msg $EM FAIL" }
  exit 1
}

# Sources
$SrcId = New-Object System.Collections.Generic.List[string]
$SrcKind = New-Object System.Collections.Generic.List[string]
$SrcVal = New-Object System.Collections.Generic.List[string]
foreach ($p in $Pat) { $SrcId.Add('S' + ($SrcId.Count + 1)); $SrcKind.Add('sweep'); $SrcVal.Add($p) }
foreach ($f in $From) { $SrcId.Add('S' + ($SrcId.Count + 1)); $SrcKind.Add('list'); $SrcVal.Add($f) }

$Exts = @{}
foreach ($e in (($ExtDefault -split ' ') + $Ext)) { if ($e -ne '') { $Exts[$e.ToLowerInvariant()] = $true } }
$PruneSet = @{}
foreach ($d in ($Prune -split ' ')) { if ($d -ne '') { $PruneSet[$d] = $true } }

function Test-TextExt([string]$rel) {
  $leaf = ($rel -split '/')[-1]
  if (-not $leaf.Contains('.')) { return $false }
  return $Exts.ContainsKey($leaf.Substring($leaf.LastIndexOf('.') + 1).ToLowerInvariant())
}
function Test-KeepPath([string]$rel) {
  if ($Inc.Count -gt 0) {
    $hit = $false
    foreach ($g in $Inc) { if ($rel -like $g) { $hit = $true; break } }
    if (-not $hit) { return $false }
  }
  foreach ($g in $Exc) { if ($rel -like $g) { return $false } }
  return $true
}
function Normalize([string]$s) {
  $s = $s.Replace("`t", ' ')
  $s = [regex]::Replace($s, ' +', ' ').Trim()
  if ($s.Length -gt 160) { $s = $s.Substring(0, 157) + '...' }
  return $s
}

$Item = New-Object System.Collections.Generic.List[string]
$Loc = New-Object System.Collections.Generic.List[string]
$Src = New-Object System.Collections.Generic.List[string]
$Lab = New-Object System.Collections.Generic.List[string]
$Seen = @{}
$Trunc = $false
function Add-Item2([string]$text, [string]$location, [string]$source, [string]$label) {
  $t = Normalize $text
  if ($t -eq '') { return }
  $key = "$location|$t"
  if ($Seen.ContainsKey($key)) { return }
  if ($Item.Count -ge $script:Limit) { $script:Trunc = $true; return }
  $Seen[$key] = $true
  $Item.Add($t); $Loc.Add($location); $Src.Add($source); $Lab.Add($label)
}

# Sweep
if ($Pat.Count -gt 0) {
  $opts = [System.Text.RegularExpressions.RegexOptions]::None
  if ($ICase) { $opts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
  $rx = @(); foreach ($p in $Pat) { $rx += New-Object System.Text.RegularExpressions.Regex($p, $opts) }
  $files = New-Object System.Collections.Generic.List[string]
  $stack = New-Object System.Collections.Generic.Stack[string]
  $stack.Push('')
  while ($stack.Count -gt 0) {
    $relDir = $stack.Pop()
    $abs = if ($relDir -eq '') { $RootFull } else { Join-Path $RootFull ($relDir -replace '/', [System.IO.Path]::DirectorySeparatorChar) }
    foreach ($e in @(Get-ChildItem -LiteralPath $abs -Force -ErrorAction SilentlyContinue)) {
      $rel = if ($relDir -eq '') { $e.Name } else { "$relDir/$($e.Name)" }
      if ($e.PSIsContainer) { if (-not $PruneSet.ContainsKey($e.Name)) { $stack.Push($rel) } }
      else { $files.Add($rel) }
    }
  }
  $farr = [string[]]$files.ToArray(); [Array]::Sort($farr, [System.StringComparer]::Ordinal)
  foreach ($rel in $farr) {
    if ($rel -eq $Out) { continue }
    if (-not (Test-TextExt $rel)) { continue }
    if (-not (Test-KeepPath $rel)) { continue }
    $full = Join-Path $RootFull ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    try { if ((Get-Item -LiteralPath $full -Force).Length -gt $MaxB) { continue } } catch { continue }
    try { $lines = [System.IO.File]::ReadAllLines($full, $Utf8) } catch { continue }
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i].TrimEnd("`r")
      for ($j = 0; $j -lt $rx.Count; $j++) {
        if ($rx[$j].IsMatch($line)) {
          $lb = $Label; if ($lb -eq '') { $lb = 'Verified' }
          Add-Item2 $line ("$rel" + ':' + ($i + 1)) ('S' + ($j + 1)) $lb
          break
        }
      }
    }
  }
}

# External lists
$ReLoc = [regex]'^([^\s|]+:[0-9]+)\s+(.*)$'
$ReBullet = [regex]'^\s*([-*+]\s+|[0-9]+[.)]\s+)'
for ($k = 0; $k -lt $From.Count; $k++) {
  $lf = $From[$k].Replace('\', '/')
  $lp = if ($lf.StartsWith('/') -or $lf -match '^[A-Za-z]:') { $lf } else { Join-Path $RootFull ($lf -replace '/', [System.IO.Path]::DirectorySeparatorChar) }
  if (-not (Test-Path -LiteralPath $lp -PathType Leaf)) { Fail "--from file not found: $($From[$k])" }
  $sid = 'S' + ($Pat.Count + $k + 1)
  $fence = $false
  foreach ($raw in [System.IO.File]::ReadAllLines($lp, $Utf8)) {
    $line = $raw.TrimEnd("`r")
    if ($line.StartsWith('```') -or $line.StartsWith('~~~')) { $fence = -not $fence; continue }
    if ($fence) { continue }
    if ($line -eq '' -or $line.StartsWith('#') -or $line.StartsWith('|') -or $line.StartsWith('>')) { continue }
    while ($true) { $m = $ReBullet.Match($line); if (-not $m.Success) { break }; $line = $line.Substring($m.Length) }
    # $itemLoc, not $loc: PowerShell variable names are case-insensitive, so $loc would
    # overwrite the $Loc list declared above.
    $itemLoc = '-'
    $m = $ReLoc.Match($line)
    if ($m.Success) { $itemLoc = $m.Groups[1].Value; $line = $m.Groups[2].Value }
    $lb = $Label; if ($lb -eq '') { $lb = 'Documented' }
    Add-Item2 $line $itemLoc $sid $lb
  }
}

# Report
function Pad([int]$n) { return 'I' + $n.ToString('000') }
$Count = $Item.Count
if ($Count -eq 0) {
  $msg = 'no item matched; widen the pattern, add --ext, or check --from'
  if ($Json) { Write-Output ('{"root":"' + (JEsc $RL) + '","slug":"' + $Slug + '","out":"' + (JEsc $Out) + '","items":[],"count":0,"truncated":false,"message":"' + (JEsc $msg) + '","exit":1}') }
  else { Write-Output "discover $EM $RL ($Slug)"; Write-Output "Result: 0 item(s) $EM $msg" }
  exit 1
}

if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"root":"' + (JEsc $RL) + '","slug":"' + $Slug + '","out":"' + (JEsc $Out) + '","sources":[')
  for ($i = 0; $i -lt $SrcId.Count; $i++) {
    if ($i -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"id":"' + $SrcId[$i] + '","kind":"' + $SrcKind[$i] + '","value":"' + (JEsc $SrcVal[$i]) + '"}')
  }
  [void]$sb.Append('],"items":[')
  for ($i = 0; $i -lt $Count; $i++) {
    if ($i -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"id":"' + (Pad ($i + 1)) + '","item":"' + (JEsc $Item[$i]) + '","location":"' + (JEsc $Loc[$i]) + '","source":"' + $Src[$i] + '","label":"' + $Lab[$i] + '"}')
  }
  $tj = 'false'; if ($Trunc) { $tj = 'true' }
  $dj = 'false'; if ($Dry) { $dj = 'true' }
  [void]$sb.Append('],"count":' + $Count + ',"truncated":' + $tj + ',"dry_run":' + $dj + ',"exit":0}')
  Write-Output $sb.ToString()
} else {
  Write-Output "discover $EM $RL ($Slug)"
  for ($i = 0; $i -lt $Count; $i++) { Write-Output ((Pad ($i + 1)) + ' ' + $Loc[$i] + " $EM " + $Item[$i]) }
  if ($Trunc) { Write-Output "Truncated at --limit $Limit; narrow the pattern or raise the limit to see the rest." }
  if ($Dry) { Write-Output "Result: $Count item(s) from $($SrcId.Count) source(s) $EM would write $Out (dry run)" }
  else { Write-Output "Result: $Count item(s) from $($SrcId.Count) source(s) $EM wrote $Out" }
}

if ($Dry) { exit 0 }

$parent = Split-Path -Parent $OutFull
if (-not (Test-Path -LiteralPath $parent -PathType Container)) { $null = New-Item -ItemType Directory -Force -Path $parent }
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("# Inventory: $Slug`n`n")
[void]$sb.Append('Generated by `scripts/discover` from ' + $SrcId.Count + " source(s). One row per item found, deduplicated by location and text. IDs are stable inside this file and are never reused; re-running with ``--force`` renumbers them.`n`n")
[void]$sb.Append("Labels: **Verified** $EM the line was read this run and carries its ``path:line`` " + [char]0x00B7 + " **Documented** $EM it comes from a list produced elsewhere " + [char]0x00B7 + " **Proposed** $EM the agent's own suggestion (never written by the script).`n`n")
[void]$sb.Append("Sources:`n`n")
for ($i = 0; $i -lt $SrcId.Count; $i++) {
  # Concatenation, not -f: Append(<format> -f a, b, c) parses a, b, c as three arguments to
  # Append and leaves the format operator with one.
  $kind = 'list'; if ($SrcKind[$i] -eq 'sweep') { $kind = 'sweep for' }
  [void]$sb.Append([string]($i + 1) + '. ' + $SrcId[$i] + ' ' + $EM + ' ' + $kind + ' `' + $SrcVal[$i] + '`' + "`n")
}
[void]$sb.Append("`n| ID | Item | Location | Source | Label | Priority | Status |`n")
[void]$sb.Append("|----|------|----------|--------|-------|----------|--------|`n")
for ($i = 0; $i -lt $Count; $i++) {
  [void]$sb.Append('| ' + (Pad ($i + 1)) + ' | ' + $Item[$i].Replace('|', '\|') + ' | ' + $Loc[$i] + ' | ' + $Src[$i] + ' | ' + $Lab[$i] + " | - | open |`n")
}
[void]$sb.Append("`n")
if ($Trunc) { [void]$sb.Append('Truncated at `--limit ' + $Limit + "`: the sweep found more than this file lists.`n`n") }
[void]$sb.Append('Next: set `Priority` per row with the team (P1/P2/P3), drop the rows that are not work, then split the rest into one self-contained brief per item with `scripts/fanout ' + $Slug + ' --from ' + $Out + '`.' + "`n")
[System.IO.File]::WriteAllText($OutFull, $sb.ToString(), $Utf8)
exit 0
