# lab-probe.ps1 — read-only capacity probe for the optional Docker labs of carrilloapps/skills.
#
# PowerShell twin of lab-probe.sh (Windows PowerShell 5.1 and PowerShell 7+, any OS).
# Same options, same output, same exit codes. Never uses the network, never installs,
# never writes files. Canonical copy: shared/scripts/lab-probe.ps1 (vendored into
# skills/*/scripts/ by shared/sync.ps1).
#
# Usage: lab-probe.ps1 [--root DIR] [--catalog FILE]... [--budget-ram MB]
#                      [--include-dashboards] [--json]      (-Root, -Json, ... also accepted)
# Exit:  0 ok · 3 configuration error · 4 Docker unavailable
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$EM = [string][char]0x2014
$DOT = [string][char]0x00B7

$Root = '.'; $Json = $false; $BudgetRam = ''; $IncludeDash = $false; $Fake = ''
$Catalogs = New-Object System.Collections.Generic.List[string]
$ReserveRam = 1024; $ReserveDisk = 1024; $UnknownRamBudget = 2048; $MaxDepth = 6
$SkillDirs = '.claude/skills', '.agents/skills', '.cursor/skills', '.github/skills', '.windsurf/skills', '.devin/skills', '.kiro/skills', '.roo/skills', '.codex/skills', '.gemini/skills', 'skills'

function Fail([string]$msg) { [Console]::Error.WriteLine("lab-probe: $msg"); exit 3 }
function Show-Usage {
  @(
    "lab-probe $EM suggest the Docker lab tools this machine can run, most critical first.",
    '',
    'Options:',
    '  1. --root DIR             project root (default: current directory)',
    '  2. --catalog FILE         extra lab-catalog.tsv (repeatable; installed skills are auto-discovered)',
    '  3. --budget-ram MB        RAM budget instead of (available RAM - 1024 MB)',
    '  4. --include-dashboards   also consider dashboards (SonarQube, DefectDojo, PgHero)',
    '  5. --json                 machine-readable output',
    'Exit codes: 0 ok, 3 configuration error, 4 Docker unavailable.'
  ) | ForEach-Object { Write-Output $_ }
}

$i = 0
while ($i -lt $args.Count) {
  $a = [string]$args[$i]
  $key = ($a -replace '^-+', '').ToLowerInvariant().Replace('-', '')
  $hasVal = ($i + 1) -lt $args.Count
  switch ($key) {
    'root' { if (-not $hasVal) { Fail '--root needs a value' }; $Root = [string]$args[$i + 1]; $i += 2 }
    'catalog' { if (-not $hasVal) { Fail '--catalog needs a value' }; $Catalogs.Add([string]$args[$i + 1]); $i += 2 }
    'budgetram' { if (-not $hasVal) { Fail '--budget-ram needs a value' }; $BudgetRam = [string]$args[$i + 1]; $i += 2 }
    'includedashboards' { $IncludeDash = $true; $i += 1 }
    'json' { $Json = $true; $i += 1 }
    'fakeresources' { if (-not $hasVal) { Fail '--fake-resources needs a value' }; $Fake = [string]$args[$i + 1]; $i += 2 } # test hook
    'fakeresourcesfile' { # test hook
      if (-not $hasVal) { Fail '--fake-resources-file needs a value' }
      $fp = [string]$args[$i + 1]
      if (-not (Test-Path -LiteralPath $fp -PathType Leaf)) { Fail "fake resources file not found: $fp" }
      $Fake = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $fp).Path); $i += 2
    }
    { $_ -eq 'h' -or $_ -eq 'help' } { Show-Usage; exit 0 }
    default { Fail "unknown option: $a" }
  }
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Fail "project root not found: $Root" }
$RootFull = (Resolve-Path -LiteralPath $Root).Path
if ($BudgetRam -ne '' -and $BudgetRam -notmatch '^[0-9]+$') { Fail '--budget-ram must be an integer (MB)' }

function Test-Int($v) { return ($null -ne $v) -and ([string]$v -match '^[0-9]+$') }
function Get-OrNull($v) { if (Test-Int $v) { return [string]$v } return 'null' }
function Get-JsonEsc([string]$s) { return $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t') }

# ── Resources ────────────────────────────────────────────────────────────────
$OS = 'unknown'; $Arch = 'unknown'; $DCli = 'false'; $DDaemon = 'false'; $DCompose = 'false'; $DVersion = ''
$RamTotal = ''; $RamAvail = ''; $Cpus = ''; $DiskFree = ''; $Mmc = ''; $DockerWhy = ''

function Get-FakeValue([string]$name) {
  $m = [regex]::Match($Fake, '"' + $name + '"[ \t\r\n]*:[ \t\r\n]*("([^"]*)"|[^,}\s]+)')
  if (-not $m.Success) { return '' }
  if ($m.Groups[1].Value.StartsWith('"')) { return $m.Groups[2].Value }
  if ($m.Groups[1].Value -eq 'null') { return '' }
  return $m.Groups[1].Value
}

function Invoke-Timed([string]$exe, [string]$argLine) {
  try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe; $psi.Arguments = $argLine
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEndAsync(); $null = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit(15000)) { try { $p.Kill() } catch { }; return $null }
    if ($p.ExitCode -ne 0) { return $null }
    return $out.Result.Trim()
  } catch { return $null }
}

if ($Fake -ne '') {
  $OS = Get-FakeValue 'os'; $Arch = Get-FakeValue 'arch'
  if ((Get-FakeValue 'docker_cli') -eq 'true') { $DCli = 'true' }
  if ((Get-FakeValue 'docker_daemon') -eq 'true') { $DDaemon = 'true' }
  if ((Get-FakeValue 'compose') -eq 'true') { $DCompose = 'true' }
  $DVersion = Get-FakeValue 'docker_version'
  $RamTotal = Get-FakeValue 'ram_total_mb'; $RamAvail = Get-FakeValue 'ram_available_mb'
  $Cpus = Get-FakeValue 'cpus'; $DiskFree = Get-FakeValue 'disk_free_mb'; $Mmc = Get-FakeValue 'max_map_count'
  if ($OS -eq '') { $OS = 'unknown' }; if ($Arch -eq '') { $Arch = 'unknown' }
} else {
  $isWin = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows
  if ($isWin) { $OS = 'windows' } elseif ($IsMacOS) { $OS = 'macos' } elseif ($IsLinux) { $OS = 'linux' }
  $Arch = [string]$env:PROCESSOR_ARCHITECTURE
  if ($Arch -eq '') { try { $Arch = (& uname -m 2>$null) } catch { } }
  switch -regex ($Arch) { '^(x86_64|amd64|AMD64)$' { $Arch = 'amd64' } '^(aarch64|arm64|ARM64)$' { $Arch = 'arm64' } '^$' { $Arch = 'unknown' } }
  $Cpus = [string][Environment]::ProcessorCount
  if ($isWin) {
    try {
      $o = Get-CimInstance -ClassName Win32_OperatingSystem
      $RamTotal = [string][long][Math]::Floor($o.TotalVisibleMemorySize / 1024); $RamAvail = [string][long][Math]::Floor($o.FreePhysicalMemory / 1024)
    } catch { }
    try {
      $drive = New-Object System.IO.DriveInfo([System.IO.Path]::GetPathRoot($RootFull))
      $DiskFree = [string][long][Math]::Floor($drive.AvailableFreeSpace / 1048576)
    } catch { }
  } else {
    if (Test-Path '/proc/meminfo') {
      foreach ($l in [System.IO.File]::ReadAllLines('/proc/meminfo')) {
        if ($l -match '^MemTotal:\s+([0-9]+)') { $RamTotal = [string][long][Math]::Floor([long]$Matches[1] / 1024) }
        if ($l -match '^MemAvailable:\s+([0-9]+)') { $RamAvail = [string][long][Math]::Floor([long]$Matches[1] / 1024) }
      }
    } elseif ($OS -eq 'macos') {
      try { $RamTotal = [string][long][Math]::Floor([long](& sysctl -n hw.memsize) / 1048576) } catch { }
    }
    try { $df = (& df -Pk $RootFull 2>$null) | Select-Object -Skip 1 -First 1; $DiskFree = [string][long][Math]::Floor([long](($df -split '\s+')[3]) / 1024) } catch { }
  }
  $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
  if ($dockerCmd) {
    $DCli = 'true'
    $info = Invoke-Timed $dockerCmd.Source 'info --format "{{.ServerVersion}}|{{.MemTotal}}|{{.OperatingSystem}}"'
    if ($info) {
      $DDaemon = 'true'
      $parts = $info.Split('|')
      $DVersion = $parts[0]
      $memMb = 0; if ($parts.Count -gt 1 -and $parts[1] -match '^[0-9]+$') { $memMb = [long][Math]::Floor([long]$parts[1] / 1048576) }
      # Docker Desktop runs containers in a VM: its MemTotal is the real ceiling.
      if ($memMb -gt 0 -and (-not (Test-Int $RamAvail) -or $memMb -lt [long]$RamAvail)) { $RamAvail = [string]$memMb }
      if ($parts.Count -gt 2 -and $parts[2] -like '*Docker Desktop*') { $Mmc = 'desktop' }
    }
    if ($null -ne (Invoke-Timed $dockerCmd.Source 'compose version --short')) { $DCompose = 'true' }
  }
  # The VM behind Docker Desktop has its own kernel: the host value would be misleading.
  if ($Mmc -ne 'desktop' -and $OS -eq 'linux' -and (Test-Path '/proc/sys/vm/max_map_count')) { $Mmc = ([System.IO.File]::ReadAllText('/proc/sys/vm/max_map_count')).Trim() }
  if ($Mmc -eq 'desktop') { $Mmc = '' }
}
if (-not (Test-Int $RamTotal)) { $RamTotal = '' }; if (-not (Test-Int $RamAvail)) { $RamAvail = '' }
if (-not (Test-Int $Cpus)) { $Cpus = '' }; if (-not (Test-Int $DiskFree)) { $DiskFree = '' }; if (-not (Test-Int $Mmc)) { $Mmc = '' }

if ($DCli -ne 'true') { $DockerWhy = 'docker CLI not found' }
elseif ($DDaemon -ne 'true') { $DockerWhy = 'Docker daemon not reachable' }
elseif ($DCompose -ne 'true') { $DockerWhy = 'docker compose v2 not available' }

if ($BudgetRam -ne '') { $Budget = [long]$BudgetRam }
elseif (Test-Int $RamAvail) { $Budget = [long]$RamAvail - $ReserveRam; if ($Budget -lt 0) { $Budget = 0 } }
else { $Budget = $UnknownRamBudget }
if (Test-Int $DiskFree) { $DiskBudget = [long]$DiskFree - $ReserveDisk; if ($DiskBudget -lt 0) { $DiskBudget = 0 } } else { $DiskBudget = 999999999 }

# ── Catalogs ─────────────────────────────────────────────────────────────────
foreach ($d in $SkillDirs) {
  $base = Join-Path $Root $d
  if (Test-Path -LiteralPath $base -PathType Container) {
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($s in [System.IO.Directory]::GetDirectories($base)) {
      $f = Join-Path (Join-Path $s 'frameworks') 'lab-catalog.tsv'
      if (Test-Path -LiteralPath $f -PathType Leaf) { $found.Add($f) }
    }
    $arr = $found.ToArray(); [Array]::Sort($arr, [StringComparer]::Ordinal)
    foreach ($f in $arr) { $Catalogs.Add($f) }
  }
}
if ($Catalogs.Count -eq 0) { Fail 'no lab-catalog.tsv found (install a skill or pass --catalog)' }

$Tools = New-Object System.Collections.Generic.List[object]
$seen = @{}
foreach ($cat in $Catalogs) {
  if (-not (Test-Path -LiteralPath $cat -PathType Leaf)) { Fail "catalog not found: $cat" }
  $ln = 0
  foreach ($line in [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $cat).Path, (New-Object System.Text.UTF8Encoding($false)))) {
    $ln++; $line = $line.TrimEnd("`r")
    if ($line -eq '' -or $line.StartsWith('#') -or $line.StartsWith("id`t")) { continue }
    $c = $line.Split("`t")
    if ($c.Count -ne 11) { Fail "${cat}:${ln}: expected 11 tab-separated columns" }
    if (-not ((Test-Int $c[2]) -and (Test-Int $c[3]) -and (Test-Int $c[4]))) { Fail "${cat}:${ln}: criticality, ram_mb and disk_mb must be integers" }
    if ($c[5] -ne 'scanner' -and $c[5] -ne 'dashboard') { Fail "${cat}:${ln}: kind must be scanner or dashboard" }
    if ($seen.ContainsKey($c[0])) { continue }
    $seen[$c[0]] = $true
    $Tools.Add([pscustomobject]@{ Id = $c[0]; Skill = $c[1]; Crit = [int]$c[2]; Ram = [long]$c[3]; Disk = [long]$c[4]; Kind = $c[5]
        Profile = $c[6]; Compose = $c[7]; Signals = $c[8]; Req = $c[9]; Notes = $c[10]; Reason = '' })
  }
}

# ── Stack detection ──────────────────────────────────────────────────────────
$Files = New-Object System.Collections.Generic.List[string]
# Skipped: VCS/dependency dirs, agent-private state, and test data or templates that would
# fake a stack signal (fixtures, testdata, __fixtures__, .work, templates).
$Skip = @{ '.git' = 1; 'node_modules' = 1; 'vendor' = 1; 'fixtures' = 1; 'testdata' = 1; '__fixtures__' = 1; '.work' = 1; 'templates' = 1 }
function Add-Files([string]$dir, [string]$rel, [int]$depth) {
  foreach ($f in [System.IO.Directory]::GetFiles($dir)) {
    $name = [System.IO.Path]::GetFileName($f)
    if ($Skip.ContainsKey($name)) { continue }
    if (([System.IO.File]::GetAttributes($f) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
    $Files.Add($rel + $name)
  }
  if ($depth -ge $MaxDepth) { return }
  foreach ($s in [System.IO.Directory]::GetDirectories($dir)) {
    $name = [System.IO.Path]::GetFileName($s)
    if ($Skip.ContainsKey($name) -or ($rel + $name) -eq '.memory/local') { continue }
    if (([System.IO.File]::GetAttributes($s) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
    Add-Files $s ($rel + $name + '/') ($depth + 1)
  }
}
try { Add-Files $RootFull '' 1 } catch { }

function Convert-GlobToRegex([string]$g) { # same translation as the bash twin
  $out = New-Object System.Text.StringBuilder
  for ($k = 0; $k -lt $g.Length; $k++) {
    $ch = $g[$k]
    if ($ch -eq '*' -and $k + 1 -lt $g.Length -and $g[$k + 1] -eq '*') {
      if ($k + 2 -lt $g.Length -and $g[$k + 2] -eq '/') { [void]$out.Append('(.*/)?'); $k += 2 } else { [void]$out.Append('.*'); $k += 1 }
    } elseif ($ch -eq '*') { [void]$out.Append('[^/]*') }
    elseif ($ch -eq '?') { [void]$out.Append('[^/]') }
    elseif ('.+()$'.IndexOf($ch) -ge 0) { [void]$out.Append('[' + $ch + ']') }
    else { [void]$out.Append($ch) }
  }
  return '^' + $out.ToString() + '$'
}

# .labprobeignore at the project root: one glob or directory per line (# comments); a match
# excludes the path and everything under it.
$IgnFile = Join-Path $RootFull '.labprobeignore'
if (Test-Path -LiteralPath $IgnFile -PathType Leaf) {
  $ign = @()
  foreach ($g in [System.IO.File]::ReadAllLines($IgnFile)) {
    $g = $g.TrimEnd("`r"); if ($g.StartsWith('./')) { $g = $g.Substring(2) }; $g = $g.TrimEnd('/')
    if ($g -eq '' -or $g.StartsWith('#')) { continue }
    $r = Convert-GlobToRegex $g; $ign += $r.Substring(1, $r.Length - 2)
  }
  if ($ign.Count -gt 0) {
    $re = [regex]('^(' + ($ign -join '|') + ')(/.*)?$')
    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($f in $Files) { if (-not $re.IsMatch($f)) { $kept.Add($f) } }
    $Files = $kept
  }
}
$Bases = New-Object System.Collections.Generic.List[string]
foreach ($f in $Files) { $Bases.Add(($f -replace '.*/', '')) }

function Test-Applicable([string]$signals) {
  if ($signals -eq '*') { return $true }
  $baseRe = @(); $pathRe = @()
  foreach ($g in $signals.Split(',')) {
    if ($g -eq '') { continue }
    if ($g.Contains('/')) { $pathRe += (Convert-GlobToRegex $g) } else { $baseRe += (Convert-GlobToRegex $g) }
  }
  if ($baseRe.Count -gt 0) { $re = [regex]($baseRe -join '|'); foreach ($b in $Bases) { if ($re.IsMatch($b)) { return $true } } }
  if ($pathRe.Count -gt 0) { $re = [regex]($pathRe -join '|'); foreach ($p in $Files) { if ($re.IsMatch($p)) { return $true } } }
  return $false
}

function Get-ReqFailure([string]$req) {
  foreach ($r in $req.Split(';')) {
    if ($r -eq '') { continue }
    $m = [regex]::Match($r, '^([a-z_]+)>=([0-9]+)$')
    if (-not $m.Success) { return "invalid requirement: $r" }
    $k = $m.Groups[1].Value; $min = [long]$m.Groups[2].Value
    switch ($k) { 'max_map_count' { $v = $Mmc } 'cpus' { $v = $Cpus } 'ram_total_mb' { $v = $RamTotal } default { $v = '' } }
    if (-not (Test-Int $v)) { return "requires $k>=$min (unknown on this machine)" }
    if ([long]$v -lt $min) { return "requires $k>=$min (current $v)" }
  }
  return ''
}

# ── Selection ────────────────────────────────────────────────────────────────
$keys = New-Object System.Collections.Generic.List[string]
for ($n = 0; $n -lt $Tools.Count; $n++) { $keys.Add(('{0:D3}|{1:D7}|{2}|{3}' -f (999 - $Tools[$n].Crit), $Tools[$n].Ram, $Tools[$n].Id, $n)) }
$ka = $keys.ToArray(); [Array]::Sort($ka, [StringComparer]::Ordinal)
$Order = @(); foreach ($k in $ka) { $Order += [int]($k.Split('|')[3]) }

$Sel = New-Object System.Collections.Generic.List[int]
$script:Used = [long]0; $script:DUsed = [long]0
function Get-FitFailure([int]$n) {
  $t = $Tools[$n]
  if ($script:Used + $t.Ram -gt $Budget) { return "exceeds RAM budget (needs $($t.Ram) MB, $($Budget - $script:Used) MB left)" }
  if ($script:DUsed + $t.Disk -gt $DiskBudget) { return "exceeds free disk (needs $($t.Disk) MB, $($DiskBudget - $script:DUsed) MB left)" }
  return ''
}
function Add-Selected([int]$n) { $Sel.Add($n); $script:Used += $Tools[$n].Ram; $script:DUsed += $Tools[$n].Disk }

$Dash = @()
foreach ($n in $Order) {
  $t = $Tools[$n]
  if (-not (Test-Applicable $t.Signals)) { $t.Reason = 'no matching files in the project'; continue }
  $why = Get-ReqFailure $t.Req
  if ($why -ne '') { $t.Reason = $why; continue }
  if ($DockerWhy -ne '') { $t.Reason = "Docker unavailable: $DockerWhy"; if ($t.Notes -ne '') { $t.Reason += " $EM " + $t.Notes }; continue }
  if ($t.Kind -eq 'dashboard') { $Dash += $n; continue }
  $why = Get-FitFailure $n
  if ($why -ne '') { $t.Reason = $why } else { Add-Selected $n }
}
foreach ($n in $Dash) {
  $t = $Tools[$n]
  if (-not $IncludeDash) { $t.Reason = "dashboard: add --include-dashboards to consider it (~$($t.Ram) MB)"; continue }
  $why = Get-FitFailure $n
  if ($why -ne '') { $t.Reason = $why } else { Add-Selected $n }
}

function Get-RunCmd($t) {
  if ($t.Kind -eq 'dashboard') { return "docker compose -f $($t.Compose) --profile $($t.Profile) up -d" }
  return "docker compose -f $($t.Compose) --profile $($t.Profile) run --rm $($t.Id)"
}
function Get-Letter([int]$n) { $s = ''; while ($true) { $s = [string][char](97 + $n % 26) + $s; $n = [Math]::Floor($n / 26) - 1; if ($n -lt 0) { break } }; return $s }

$Exit = 0; if ($DockerWhy -ne '') { $Exit = 4 }

if ($Json) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('{"os":"' + (Get-JsonEsc $OS) + '","arch":"' + (Get-JsonEsc $Arch) + '","docker":{"cli":' + $DCli + ',"daemon":' + $DDaemon + ',"compose":' + $DCompose + ',"version":')
  if ($DVersion -ne '') { [void]$sb.Append('"' + (Get-JsonEsc $DVersion) + '"') } else { [void]$sb.Append('null') }
  [void]$sb.Append(',"unavailable_reason":'); if ($DockerWhy -ne '') { [void]$sb.Append('"' + $DockerWhy + '"') } else { [void]$sb.Append('null') }
  [void]$sb.Append('},"resources":{"ram_total_mb":' + (Get-OrNull $RamTotal) + ',"ram_available_mb":' + (Get-OrNull $RamAvail) + ',"ram_budget_mb":' + $Budget + ',"cpus":' + (Get-OrNull $Cpus) + ',"disk_free_mb":' + (Get-OrNull $DiskFree) + ',"max_map_count":' + (Get-OrNull $Mmc) + '},"selected":[')
  $r = 0
  foreach ($n in $Sel) {
    $t = $Tools[$n]; $r++; if ($r -gt 1) { [void]$sb.Append(',') }
    [void]$sb.Append('{"rank":' + $r + ',"id":"' + (Get-JsonEsc $t.Id) + '","skill":"' + (Get-JsonEsc $t.Skill) + '","criticality":' + $t.Crit + ',"ram_mb":' + $t.Ram + ',"disk_mb":' + $t.Disk + ',"kind":"' + $t.Kind + '","profile":"' + (Get-JsonEsc $t.Profile) + '","compose":"' + (Get-JsonEsc $t.Compose) + '","run":"' + (Get-JsonEsc (Get-RunCmd $t)) + '","notes":"' + (Get-JsonEsc $t.Notes) + '"}')
  }
  [void]$sb.Append('],"skipped":[')
  $s = 0
  foreach ($n in $Order) {
    $t = $Tools[$n]; if ($t.Reason -eq '') { continue }
    if ($s -gt 0) { [void]$sb.Append(',') }
    [void]$sb.Append('{"label":"' + (Get-Letter $s) + '","id":"' + (Get-JsonEsc $t.Id) + '","skill":"' + (Get-JsonEsc $t.Skill) + '","reason":"' + (Get-JsonEsc $t.Reason) + '"}')
    $s++
  }
  [void]$sb.Append('],"exit":' + $Exit + '}')
  Write-Output $sb.ToString()
} else {
  $dockerState = $DockerWhy; if ($dockerState -eq '') { $dockerState = $DVersion }; if ($dockerState -eq '') { $dockerState = 'available' }
  Write-Output ("Lab probe $EM $OS/$Arch $DOT Docker: $dockerState")
  $u = { param($v) if ($v -eq '') { 'unknown' } else { $v } }
  Write-Output ("Resources: RAM available $(& $u $RamAvail) MB (budget $Budget MB) $DOT CPUs $(& $u $Cpus) $DOT disk free $(& $u $DiskFree) MB $DOT vm.max_map_count $(& $u $Mmc)")
  Write-Output ''
  if ($Sel.Count -eq 0) { Write-Output 'Suggested: none fits right now.' }
  else {
    Write-Output 'Suggested, most critical first (approve each run individually):'
    $r = 0
    foreach ($n in $Sel) {
      $t = $Tools[$n]; $r++
      Write-Output ("$r. $($t.Id) ($($t.Skill)) $EM criticality $($t.Crit), ~$($t.Ram) MB $EM run: $(Get-RunCmd $t)")
      if ($t.Notes -ne '') { Write-Output ("   note: $($t.Notes)") }
    }
  }
  $s = 0
  foreach ($n in $Order) {
    $t = $Tools[$n]; if ($t.Reason -eq '') { continue }
    if ($s -eq 0) { Write-Output ''; Write-Output 'Skipped:' }
    Write-Output ("$(Get-Letter $s). $($t.Id) ($($t.Skill)) $EM $($t.Reason)")
    $s++
  }
}
exit $Exit
