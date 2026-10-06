# init.ps1 — idempotent scaffold of the agentic-agile workspace inside the current project.
#
# PowerShell twin of init.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS): same
# actions, same output, same exit codes. Never overwrites an existing file; never writes
# outside the project root.
#
# --preset NAME overrides the templates with presets/NAME/<file>.md when present.
#
# Usage: init.ps1 [--root DIR] [--preset scrum|kanban|regulated] [--dry-run]     (-Root DIR, -DryRun also accepted)
# Exit:  0 ok · 3 configuration error (missing templates, unknown preset, bad root)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$Root = '.'; $Dry = $false; $Preset = 'scrum'
$Templates = 'methodology', 'definition-of-ready', 'definition-of-done', 'ceremonies', 'team', 'capabilities', 'kpi-directives', 'language', 'autonomy', 'constitution', 'hooks'
function Fail([string]$msg) { [Console]::Error.WriteLine("init: $msg"); exit 3 }

$i = 0
while ($i -lt $args.Count) {
  $a = [string]$args[$i]
  switch (($a -replace '^-+', '').ToLowerInvariant().Replace('-', '')) {
    'root' { if ($i + 1 -ge $args.Count) { Fail '--root needs a value' }; $Root = [string]$args[$i + 1]; $i += 2 }
    'dryrun' { $Dry = $true; $i += 1 }
    'preset' { if ($i + 1 -ge $args.Count) { Fail '--preset needs a value' }; $Preset = [string]$args[$i + 1]; $i += 2 }
    { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: init.ps1 [--root DIR] [--preset scrum|kanban|regulated] [--dry-run]'; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RootFull = (Resolve-Path -LiteralPath $Root).Path

$SkillDir = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$TplDir = Join-Path $SkillDir 'templates'
$PreDir = Join-Path (Join-Path $SkillDir 'presets') $Preset
$avail = @('scrum')
$pd = Join-Path $SkillDir 'presets'
if (Test-Path -LiteralPath $pd -PathType Container) { foreach ($d in Get-ChildItem -LiteralPath $pd -Directory) { if ($avail -cnotcontains $d.Name) { $avail += $d.Name } } }
$avail = [string[]]$avail; [Array]::Sort($avail, [StringComparer]::Ordinal)
if ($avail -cnotcontains $Preset) { Fail "unknown preset: $Preset (available: $($avail -join ', '))" }
function Get-Src([string]$t) { $p = Join-Path $PreDir "$t.md"; if (Test-Path -LiteralPath $p -PathType Leaf) { return $p }; return (Join-Path $TplDir "$t.md") }
$missing = ''
foreach ($t in $Templates) { if (-not (Test-Path -LiteralPath (Get-Src $t) -PathType Leaf)) { $missing += " $t.md" } }
if ($missing -ne '') { Fail "missing templates in $(($TplDir -replace '\\', '/')):$missing" }

$Utf8 = New-Object System.Text.UTF8Encoding($false)
$script:N = 0
function Write-Step([string]$text) { $script:N++; if ($Dry) { Write-Output "$($script:N). (dry-run) $text" } else { Write-Output "$($script:N). $text" } }
function P([string]$rel) { return Join-Path $RootFull $rel }
function New-Dir([string]$rel) { if (-not $Dry) { [void][System.IO.Directory]::CreateDirectory((P $rel)) } }

foreach ($t in $Templates) {
  $f = "plans/agile/$t.md"
  if (Test-Path -LiteralPath (P $f)) { Write-Step "skip $f (exists)" }
  else {
    $s = Get-Src $t; $note = ''; if ($s -ne (Join-Path $TplDir "$t.md")) { $note = " (preset $Preset)" }
    Write-Step "create $f$note"; if (-not $Dry) { New-Dir 'plans/agile'; [System.IO.File]::Copy($s, (P $f)) }
  }
}
foreach ($d in 'plans/sprints', 'plans/initiatives', 'plans/decisions', 'plans/drafts', 'specs') {
  $f = "$d/.gitkeep"
  if (Test-Path -LiteralPath (P $f)) { Write-Step "skip $f (exists)" }
  else { Write-Step "create $f"; if (-not $Dry) { New-Dir $d; [System.IO.File]::WriteAllText((P $f), '', $Utf8) } }
}
$f = 'plans/agile/metrics/events.jsonl'
if (Test-Path -LiteralPath (P $f)) { Write-Step "skip $f (exists)" }
else { Write-Step "create $f"; if (-not $Dry) { New-Dir 'plans/agile/metrics'; [System.IO.File]::WriteAllText((P $f), '', $Utf8) } }

$Block = @(
  ('# Managed by carrilloapps/skills ' + [char]0x2014 + ' ignores agent-private paths only.'),
  '# Shared team state under .memory/<skill>/ stays versioned.',
  'local/', '*.local.*', '*.recovered.json'
)
$f = '.memory/.gitignore'
$existing = @()
if (Test-Path -LiteralPath (P $f) -PathType Leaf) { $existing = [System.IO.File]::ReadAllLines((P $f), $Utf8) | ForEach-Object { $_.TrimEnd("`r") } }
$add = @(); foreach ($l in $Block) { if ($existing -cnotcontains $l) { $add += $l } }
if ($add.Count -eq 0) { Write-Step "skip $f (block present)" }
else {
  Write-Step "append $($add.Count) line(s) to $f"
  if (-not $Dry) {
    New-Dir '.memory'
    $prefix = ''
    if (Test-Path -LiteralPath (P $f) -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes((P $f))
      if ($bytes.Length -gt 0 -and $bytes[$bytes.Length - 1] -ne 10) { $prefix = "`n" }
    }
    [System.IO.File]::AppendAllText((P $f), $prefix + (($add -join "`n") + "`n"), $Utf8)
  }
}

$d = '.memory/local/agentic-agile/transcripts'
if (Test-Path -LiteralPath (P $d) -PathType Container) { Write-Step "skip $d/ (exists)" }
else { Write-Step "create $d/"; New-Dir $d }
Write-Output 'Next: complete plans/agile/ with the team, then run scripts/check-structure (Phase 0 gate) before any spec, plan, draft, ticket or decision record.'
exit 0
