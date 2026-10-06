# run-parity.ps1 — PowerShell twin of run-parity.sh: run every case in cases.tsv with the
# PowerShell implementation (current host) and, when Git Bash or a Linux/macOS bash is
# available, with the bash implementation; compare stdout, exit code and produced files
# with expected/.
#
# Usage: tests/scripts/run-parity.ps1
# Exit:  0 all match · 1 at least one mismatch
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$Here = $PSScriptRoot
$Repo = (Resolve-Path -LiteralPath (Join-Path $Here '../..')).Path
$Fix = Join-Path $Here 'fixtures'; $Exp = Join-Path $Here 'expected'; $Work = Join-Path $Here '.work'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$OnWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows

$HostExe = (Get-Process -Id $PID).Path
$Runners = New-Object System.Collections.Generic.List[string]
$Runners.Add('ps')
$BashExe = $null
if ($OnWindows) {
  foreach ($c in @((Join-Path $env:ProgramFiles 'Git\bin\bash.exe'), (Join-Path ${env:ProgramFiles(x86)} 'Git\bin\bash.exe'))) { if ($c -and (Test-Path -LiteralPath $c)) { $BashExe = $c; break } }
} else {
  $b = Get-Command bash -ErrorAction SilentlyContinue; if ($b) { $BashExe = $b.Source }
}
if ($BashExe) { $Runners.Add('bash') } else { Write-Output 'note: no Git Bash / bash found; running the PowerShell implementation only' }

function Get-Script([string]$impl, [string]$runner) {
  $ext = 'ps1'; if ($runner -eq 'bash') { $ext = 'sh' }
  $dir = Join-Path $Repo 'skills/agentic-agile/scripts'
  if ($impl -eq 'lab-probe') { $dir = Join-Path $Repo 'shared/scripts' }
  return (Join-Path $dir "$impl.$ext")
}
function Invoke-Impl([string]$runner, [string]$script, [string[]]$argv) {
  $ErrorActionPreference = 'Continue' # native stderr must not throw (Windows PowerShell 5.1)
  if ($runner -eq 'bash') { $out = & $BashExe ($script.Replace('\', '/')) @argv 2>$null }
  elseif ($HostExe -like '*powershell.exe') { $out = & $HostExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script @argv 2>$null }
  else { $out = & $HostExe -NoProfile -NonInteractive -File $script @argv 2>$null }
  $code = $LASTEXITCODE
  $text = (@($out) | ForEach-Object { ([string]$_).TrimEnd("`r") }) -join "`n"
  return @($text, $code)
}
function Read-Text([string]$path) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
  return $Utf8.GetString([System.IO.File]::ReadAllBytes($path)).Replace("`r", '').TrimEnd("`n")
}
function Get-Tree([string]$dir) {
  $files = New-Object System.Collections.Generic.List[string]
  foreach ($f in [System.IO.Directory]::GetFiles($dir, '*', [System.IO.SearchOption]::AllDirectories)) {
    $files.Add($f.Substring($dir.Length + 1).Replace('\', '/'))
  }
  $arr = $files.ToArray(); [Array]::Sort($arr, [StringComparer]::Ordinal)
  $sb = New-Object System.Text.StringBuilder
  foreach ($rel in $arr) {
    [void]$sb.Append("== $rel`n")
    [void]$sb.Append($Utf8.GetString([System.IO.File]::ReadAllBytes((Join-Path $dir $rel))).Replace("`r", ''))
    [void]$sb.Append("`n")
  }
  return $sb.ToString().TrimEnd("`n")
}
function Copy-Contents([string]$from, [string]$to) {
  foreach ($item in Get-ChildItem -LiteralPath $from -Force) { Copy-Item -LiteralPath $item.FullName -Destination $to -Recurse -Force }
}

$pass = 0; $fail = 0; $n = 0
foreach ($runner in $Runners) {
  foreach ($row in [System.IO.File]::ReadAllLines((Join-Path $Here 'cases.tsv'), $Utf8)) {
    if ($row -eq '' -or $row.StartsWith('#')) { continue }
    $c = $row.Split("`t")
    $name = $c[0]; $mode = $c[1]; $impl = $c[2]; $seed = $c[3]; $want = [int]$c[5]
    $argv = @(); if ($c[4] -ne '') { $argv = $c[4].Split(' ') }
    $w = Join-Path (Join-Path $Work $runner) $name
    if (Test-Path -LiteralPath $w) { Remove-Item -LiteralPath $w -Recurse -Force }
    [void][System.IO.Directory]::CreateDirectory($w)
    $script = Get-Script $impl $runner
    $cwd = $Fix
    if ($mode -eq 'transcript') {
      $cwd = Join-Path $w 'project'; [void][System.IO.Directory]::CreateDirectory((Join-Path $cwd 'input'))
      Copy-Contents (Join-Path $Fix 'transcripts') (Join-Path $cwd 'input')
    } elseif ($mode -eq 'init' -or $mode -eq 'init2') {
      $cwd = Join-Path $w 'project'
      foreach ($d in @($cwd, (Join-Path $w 'skill/scripts'), (Join-Path $w 'skill/templates'))) { [void][System.IO.Directory]::CreateDirectory($d) }
      Copy-Item -LiteralPath $script -Destination (Join-Path $w 'skill/scripts')
      Copy-Contents (Join-Path $Fix 'init-templates') (Join-Path $w 'skill/templates')
      $script = Join-Path (Join-Path $w 'skill/scripts') ([System.IO.Path]::GetFileName($script))
      $pre = Join-Path $Fix 'aa-preset/presets'
      if (Test-Path -LiteralPath $pre -PathType Container) { Copy-Item -LiteralPath $pre -Destination (Join-Path $w 'skill') -Recurse -Force }
      if ($seed -ne '-') { Copy-Contents (Join-Path $Fix $seed) $cwd }
      if ($mode -eq 'init2') { Push-Location $cwd; try { $null = Invoke-Impl $runner $script $argv } finally { Pop-Location } }
    } elseif ($mode -eq 'skill') { # every script of the runner's kind + fixture templates/presets + trace/analyze stubs
      $cwd = Join-Path $w 'project'
      $sk = Join-Path $w 'skill'
      foreach ($d in @($cwd, (Join-Path $sk 'scripts'), (Join-Path $sk 'templates'))) { [void][System.IO.Directory]::CreateDirectory($d) }
      $ext = [System.IO.Path]::GetExtension($script)
      foreach ($f in Get-ChildItem -LiteralPath (Join-Path $Repo 'skills/agentic-agile/scripts') -File -Filter "*$ext") { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $sk 'scripts') -Force }
      foreach ($f in Get-ChildItem -LiteralPath (Join-Path $Fix 'aa-entry/stubs') -File -Filter "*$ext") { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $sk 'scripts') -Force }
      Copy-Contents (Join-Path $Fix 'init-templates') (Join-Path $sk 'templates')
      Copy-Contents (Join-Path $Fix 'aa-entry/templates') (Join-Path $sk 'templates')
      Copy-Item -LiteralPath (Join-Path $Fix 'aa-preset/presets') -Destination $sk -Recurse -Force
      $script = Join-Path (Join-Path $sk 'scripts') ([System.IO.Path]::GetFileName($script))
      if ($seed -ne '-') { Copy-Contents (Join-Path $Fix $seed) $cwd }
    }
    Push-Location $cwd
    try { $res = Invoke-Impl $runner $script $argv } finally { Pop-Location }
    $n++
    $why = ''
    if ([int]$res[1] -ne $want) { $why = "exit $($res[1]), expected $want" }
    elseif ($res[0].TrimEnd("`n") -cne (Read-Text (Join-Path $Exp "$name.out"))) { $why = "stdout differs from expected/$name.out" }
    elseif ($mode -ne 'repo' -and (Get-Tree $cwd) -cne (Read-Text (Join-Path $Exp "$name.tree"))) { $why = "files differ from expected/$name.tree" }
    $label = $runner; if ($runner -eq 'ps') { $label = [System.IO.Path]::GetFileNameWithoutExtension($HostExe) }
    if ($why -eq '') { $pass++; Write-Output "$n. pass $label - $name" }
    else { $fail++; Write-Output "$n. FAIL $label - $name - $why" }
  }
}
Write-Output "Runners: $($Runners -join ' ') - $pass passed - $fail failed"
if ($fail -gt 0) { exit 1 }
exit 0
