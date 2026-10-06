# audit-agile.ps1 — hygiene of the team operating system after Phase 0 (read-only).
#
# PowerShell twin of audit-agile.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): same
# checks, same output, same exit codes. Reports, in this order: review-overdue decision records,
# template-drift between skill templates and plans/agile/ copies, broken relative links in plans/
# and specs/, sprints past their end date without report.md, and initiatives in state Done whose
# verification is missing, unfilled or ❌. Fenced code and code spans are ignored.
#
# Usage: audit-agile.ps1 [--root DIR] [--json] [--templates DIR] [--today YYYY-MM-DD]
# Exit:  0 clean · 1 findings · 3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014

$Root = '.'; $Json = $false; $Tpl = ''; $Today = ''
function Fail([string]$msg) { [Console]::Error.WriteLine("audit-agile: $msg"); exit 3 }
for ($k = 0; $k -lt $args.Count; $k++) {
  $a = [string]$args[$k]
  switch (($a -replace '^-+', '').ToLowerInvariant()) {
    'root' { if ($k + 1 -ge $args.Count) { Fail '--root needs a value' }; $k++; $Root = [string]$args[$k] }
    'templates' { if ($k + 1 -ge $args.Count) { Fail '--templates needs a value' }; $k++; $Tpl = [string]$args[$k] }
    'today' { if ($k + 1 -ge $args.Count) { Fail '--today needs a value' }; $k++; $Today = [string]$args[$k] }
    'json' { $Json = $true }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: audit-agile [--root DIR] [--json] [--templates DIR] [--today YYYY-MM-DD]'; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
if ($Tpl -ne '') { if (-not (Test-Path -LiteralPath $Tpl -PathType Container)) { Fail "templates folder not found: $Tpl" } }
else { $Tpl = Join-Path (Split-Path -Parent $PSScriptRoot) 'templates' }
if ($Today -eq '') { $Today = (Get-Date).ToString('yyyy-MM-dd') }
if ($Today -notmatch '^\d{4}-\d{2}-\d{2}$') { Fail '--today must be YYYY-MM-DD' }
$Label = $Root.Replace('\', '/'); while ($Label.Length -gt 1 -and $Label.EndsWith('/')) { $Label = $Label.Substring(0, $Label.Length - 1) }
$RootFull = (Resolve-Path -LiteralPath $Root).Path
function P([string]$rel) { return (Join-Path $RootFull $rel) }

$Findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($file, $line, $rule, $msg) { $Findings.Add([pscustomobject]@{ File = $file; Line = [int]$line; Rule = $rule; Msg = $msg }) }

$I = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$ReFence = [regex]'^\s*(```|~~~)'
$ReHead = [regex]'^#{1,6}[ \t]+(.*)$'
$ReSub = [regex]'^#{2,6}[ \t]+(.*)$'
$ReDate = [regex]'[0-9]{4}-[0-9]{2}-[0-9]{2}'
$ReLink = [regex]'\]\(([^)\s]+)[^)]*\)'
$ReReview = New-Object regex('^#{1,6}[ \t]+(review on|revisar el|revisi(\u00f3|o)n)', $I)
$ReState = New-Object regex('(state|estado)[*]*\s*:[*]*\s*([^\u00b7|]*)', $I)
$ReDone = New-Object regex('^(done|hecho|hecha|terminado|terminada|completed|complete|cerrado|cerrada)([^a-z]|$)', $I)
$ReInactive = New-Object regex('(superseded|revoked|reemplazad|revocad)', $I)
$ReVWord = New-Object regex('(verdict|veredicto)', $I)
$ReDates = New-Object regex('(dates|fechas)', $I)

function Read-Prose([string]$path) { # prose lines (fenced code skipped) as { No, Text }
  $out = New-Object System.Collections.Generic.List[object]
  $n = 0; $fence = $false
  foreach ($l in [System.IO.File]::ReadAllLines($path, (New-Object System.Text.UTF8Encoding($false)))) {
    $n++; $l = $l.TrimEnd("`r")
    if ($ReFence.IsMatch($l)) { $fence = -not $fence; continue }
    if ($fence) { continue }
    $out.Add([pscustomobject]@{ No = $n; Text = $l })
  }
  return , $out
}
function Get-Sorted([string]$rel, [string]$kind, [string]$filter, [bool]$recurse) { # relative paths with '/', ordinal sort
  $dir = P $rel
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return @() }
  if ($kind -eq 'dir') { $items = Get-ChildItem -LiteralPath $dir -Directory }
  elseif ($recurse) { $items = Get-ChildItem -LiteralPath $dir -File -Recurse -Filter $filter }
  else { $items = Get-ChildItem -LiteralPath $dir -File -Filter $filter }
  $list = [string[]]@($items | ForEach-Object { $_.FullName.Substring($RootFull.TrimEnd('\', '/').Length + 1).Replace('\', '/') })
  [Array]::Sort($list, [StringComparer]::Ordinal)
  return , $list
}
function Remove-Spans([string]$text) { $rest = $text; while ($rest -match '^(.*)`[^`]*`(.*)$') { $rest = $Matches[1] + ' ' + $Matches[2] }; return $rest }
function Test-Before([string]$a, [string]$b) { return ([string]::CompareOrdinal($a, $b) -lt 0) }

# ── 1. Decision records due for review ───────────────────────────────────────
foreach ($f in (Get-Sorted 'plans/decisions' 'file' '*.md' $false)) {
  $skip = $false; $inrev = $false; $d = ''; $dl = 0
  foreach ($l in (Read-Prose (P $f))) {
    $m = $ReState.Match($l.Text)
    if ($m.Success -and $ReInactive.IsMatch($m.Groups[2].Value)) { $skip = $true }
    if ($ReReview.IsMatch($l.Text)) { $inrev = $true; continue }
    if ($inrev) {
      if ($ReHead.IsMatch($l.Text)) { $inrev = $false; continue }
      if ($d -eq '') { $dm = $ReDate.Match($l.Text); if ($dm.Success) { $d = $dm.Value; $dl = $l.No } }
    }
  }
  if (-not $skip -and $d -ne '' -and (Test-Before $d $Today)) { Add-Finding $f $dl 'review-overdue' "decision review date $d has passed (today $Today)" }
}

# ── 2. Drift between skill templates and plans/agile/ copies ─────────────────
if (Test-Path -LiteralPath $Tpl -PathType Container) {
  # constitution.md is excluded on purpose: its articles are team content that amendments
  # rename or replace, so template section names must not be enforced there.
  foreach ($t in @('methodology', 'definition-of-ready', 'definition-of-done', 'ceremonies', 'team', 'capabilities', 'kpi-directives', 'language', 'autonomy', 'hooks')) {
    $tf = Join-Path $Tpl "$t.md"; $cf = P "plans/agile/$t.md"
    if (-not ((Test-Path -LiteralPath $tf -PathType Leaf) -and (Test-Path -LiteralPath $cf -PathType Leaf))) { continue }
    $have = New-Object System.Collections.Generic.HashSet[string]
    foreach ($l in (Read-Prose $cf)) { $m = $ReSub.Match($l.Text); if ($m.Success) { [void]$have.Add($m.Groups[1].Value.Trim()) } }
    foreach ($l in (Read-Prose (Resolve-Path -LiteralPath $tf).Path)) {
      $m = $ReSub.Match($l.Text); if (-not $m.Success) { continue }
      $h = $m.Groups[1].Value.Trim()
      if ($h.Contains('<')) { continue }
      if (-not $have.Contains($h)) { Add-Finding "plans/agile/$t.md" 0 'template-drift' "section '$h' from the skill template is missing" }
    }
  }
}

# ── 3. Broken relative links ─────────────────────────────────────────────────
$docs = @((Get-Sorted 'plans' 'file' '*.md' $true)) + @((Get-Sorted 'specs' 'file' '*.md' $true))
foreach ($f in $docs) {
  $base = $f.Substring(0, $f.LastIndexOf('/'))
  foreach ($l in (Read-Prose (P $f))) {
    foreach ($m in $ReLink.Matches((Remove-Spans $l.Text))) {
      $t = $m.Groups[1].Value
      if ($t.Contains('://') -or $t.StartsWith('mailto:') -or $t.StartsWith('#') -or $t.StartsWith('/') -or $t.Contains('<')) { continue }
      $p = $t.Split('#')[0]
      if ($p -eq '') { continue }
      if (-not (Test-Path -LiteralPath (Join-Path (P $base) $p))) { Add-Finding $f $l.No 'broken-link' "broken link: $t" }
    }
  }
}

# ── 4. Sprints past their end date without a report ──────────────────────────
foreach ($s in (Get-Sorted 'plans/sprints' 'dir' '' $false)) {
  if (-not (Test-Path -LiteralPath (P "$s/planning.md") -PathType Leaf)) { continue }
  if (Test-Path -LiteralPath (P "$s/report.md") -PathType Leaf) { continue }
  $end = ''
  foreach ($l in (Read-Prose (P "$s/planning.md"))) {
    if (-not $ReDates.IsMatch($l.Text)) { continue }
    foreach ($dm in $ReDate.Matches($l.Text)) { $end = $dm.Value }
    break
  }
  if ($end -ne '' -and (Test-Before $end $Today)) { Add-Finding "$s/" 0 'sprint-report' "sprint ended $end without report.md" }
}

# ── 5. Initiatives marked Done without a passing verification ────────────────
foreach ($d in (Get-Sorted 'plans/initiatives' 'dir' '' $false)) {
  $o = "$d/overview.md"
  if (-not (Test-Path -LiteralPath (P $o) -PathType Leaf)) { continue }
  $isDone = $false
  foreach ($l in (Read-Prose (P $o))) { $m = $ReState.Match($l.Text); if ($m.Success) { $isDone = $ReDone.IsMatch($m.Groups[2].Value.Trim()); break } }
  if (-not $isDone) { continue }
  $slug = $d.Substring($d.LastIndexOf('/') + 1)
  $v = "specs/$slug/verification.md"
  if (-not (Test-Path -LiteralPath (P $v) -PathType Leaf)) { Add-Finding $o 0 'done-unverified' "initiative is Done but $v is missing"; continue }
  $verdict = 'none'
  foreach ($l in (Read-Prose (P $v))) {
    if (-not $ReVWord.IsMatch($l.Text)) { continue }
    $ok = $l.Text.Contains([string][char]0x2705) -or $l.Text.Contains([string][char]0x26a0)
    $bad = $l.Text.Contains([string][char]0x274c)
    if ($ok -and -not $bad) { $verdict = 'pass'; break }
    if ($bad -and -not $ok) { $verdict = 'fail'; break }
  }
  if ($verdict -eq 'fail') { Add-Finding $o 0 'done-unverified' "initiative is Done but $v verdict is $([string][char]0x274c)" }
  elseif ($verdict -eq 'none') { Add-Finding $o 0 'done-unverified' "initiative is Done but $v has no filled verdict" }
}

# ── Report ───────────────────────────────────────────────────────────────────
$N = $Findings.Count
$Exit = 0; if ($N -gt 0) { $Exit = 1 }
function Get-JsonEsc([string]$s) { $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t'); return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '') }
if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"root":"' + (Get-JsonEsc $Label) + '","today":"' + $Today + '","findings":[')
  for ($k = 0; $k -lt $N; $k++) {
    $x = $Findings[$k]; if ($k -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"n":' + ($k + 1) + ',"file":"' + (Get-JsonEsc $x.File) + '","line":' + $x.Line + ',"rule":"' + $x.Rule + '","message":"' + (Get-JsonEsc $x.Msg) + '"}')
  }
  [void]$sb.Append('],"count":' + $N + ',"exit":' + $Exit + '}')
  Write-Output $sb.ToString()
} else {
  Write-Output "audit-agile $EM $Label (today $Today)"
  if ($N -eq 0) { Write-Output 'No findings.' }
  for ($k = 0; $k -lt $N; $k++) {
    $x = $Findings[$k]; $loc = $x.File; if ($x.Line -gt 0) { $loc += ":$($x.Line)" }
    Write-Output ("$($k + 1). $loc [$($x.Rule)] $($x.Msg)")
  }
  if ($N -eq 0) { Write-Output "Result: 0 finding(s) $EM CLEAN" } else { Write-Output "Result: $N finding(s) $EM ATTENTION" }
}
exit $Exit
