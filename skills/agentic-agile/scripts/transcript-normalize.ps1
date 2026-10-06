# transcript-normalize.ps1 — convert a meeting transcript (WebVTT, SRT or "Speaker: text"
# lines) into normalized JSON Lines, redacting personal data and secrets on the way.
#
# PowerShell twin of transcript-normalize.sh (Windows PowerShell 5.1 and PowerShell 7+,
# any OS): same parsing, same redactions, same output file. Never uses the network;
# writes only inside the project.
#
# Usage: transcript-normalize.ps1 <file> [--out DIR]   (-Out DIR also accepted; DIR relative, no "..")
# Exit:  0 ok · 3 configuration error
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$In = ''; $Out = '.memory/local/agentic-agile/transcripts'
function Fail([string]$msg) { [Console]::Error.WriteLine("transcript-normalize: $msg"); exit 3 }
$i = 0
while ($i -lt $args.Count) {
  $a = [string]$args[$i]
  if ($a.StartsWith('-')) {
    switch (($a -replace '^-+', '').ToLowerInvariant()) {
      'out' { if ($i + 1 -ge $args.Count) { Fail '--out needs a value' }; $Out = [string]$args[$i + 1]; $i += 2 }
      { $_ -eq 'h' -or $_ -eq 'help' } { Write-Output 'Usage: transcript-normalize <file> [--out DIR]'; exit 0 }
      default { Fail "unknown option: $a" }
    }
  } else { if ($In -ne '') { Fail 'only one input file is allowed' }; $In = $a; $i += 1 }
}
if ($In -eq '') { Fail 'missing input file' }
if (-not (Test-Path -LiteralPath $In -PathType Leaf)) { Fail "input file not found: $In" }
$Out = $Out.Replace('\', '/')
if ($Out.StartsWith('/') -or $Out -match '^[A-Za-z]:') { Fail '--out must be a path relative to the project' }
if (('/' + $Out + '/').Contains('/../')) { Fail "--out must not contain '..'" }

$Src = $In.Replace('\', '/'); $Src = $Src.Substring($Src.LastIndexOf('/') + 1)
$Base = $Src; $dot = $Src.LastIndexOf('.'); if ($dot -gt 0) { $Base = $Src.Substring(0, $dot) }

$TS = '(([0-9]{1,2}):)?([0-9]{1,2}):([0-9]{2})[.,]([0-9]{3})'
$ReTime = [regex]('^' + $TS + '\s+-->\s+' + $TS)
$ReVoice = [regex]'^<v(\.[^ >]*)?\s+([^>]+)>'
$ReTag = [regex]'<[^>]*>'
$ReSpeaker = [regex]'^([^:<> ]{1,40}( [^:<> ]{1,40}){0,3}):\s+(.*)$' # 1-4 words before ':'
$SecretRes = @(
  '([Aa][Pp][Ii][_-]?[Kk][Ee][Yy]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd])[ ]*[:=][ ]*[^ ]+',
  '(sk|pk|rk)_(live|test)_[A-Za-z0-9]{8,}',
  'AKIA[0-9A-Z]{16}',
  'gh[pousr]_[A-Za-z0-9]{20,}',
  'xox[baprs]-[A-Za-z0-9-]{10,}',
  'eyJ[A-Za-z0-9_-]{10,}[.][A-Za-z0-9_-]{10,}[.][A-Za-z0-9_-]{5,}'
)
$Counts = [ordered]@{ secret = 0; email = 0; iban = 0; card = 0; phone = 0 }
$Redactions = @(
  @('email', '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}', '[REDACTED_EMAIL]'),
  @('iban', '[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}', '[REDACTED_IBAN]'),
  @('card', '[0-9]([ -]?[0-9]){12,18}', '[REDACTED_CARD]'),
  @('phone', '[+]?[0-9][0-9 ().-]{6,}[0-9]', '[REDACTED_PHONE]')
)

function Get-JsonEsc([string]$s) {
  $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t')
  return [regex]::Replace($s, '[\x00-\x08\x0b-\x1f]', '')
}
function Format-Ts($m, [int]$o) {
  $h = 0; if ($m.Groups[$o + 1].Success) { $h = [int]$m.Groups[$o + 1].Value }
  return ('{0:D2}:{1:D2}:{2:D2}.{3}' -f $h, [int]$m.Groups[$o + 2].Value, [int]$m.Groups[$o + 3].Value, $m.Groups[$o + 4].Value)
}
function Invoke-Redact([string]$text, [string]$re, [string]$label, [string]$key) {
  $Counts[$key] += ([regex]::Matches($text, $re)).Count
  return [regex]::Replace($text, $re, $label.Replace('$', '$$'))
}

$Body = New-Object System.Text.StringBuilder
$script:Cues = 0
function Add-Cue([string]$start, [string]$end, [string]$raw) {
  $speaker = ''
  $m = $ReVoice.Match($raw); if ($m.Success) { $speaker = $m.Groups[2].Value }
  $raw = $ReTag.Replace($raw, '')
  if ($speaker -eq '') { $m = $ReSpeaker.Match($raw); if ($m.Success) { $speaker = $m.Groups[1].Value; $raw = $m.Groups[3].Value } }
  $speaker = $speaker.Trim(); $text = $raw.Trim()
  if ($text -eq '') { return }
  foreach ($r in $SecretRes) { $text = Invoke-Redact $text $r '[REDACTED_SECRET]' 'secret' }
  foreach ($r in $Redactions) { $text = Invoke-Redact $text $r[1] $r[2] $r[0] }
  $js = 'null'; if ($start -ne '') { $js = '"' + $start + '"' }
  $je = 'null'; if ($end -ne '') { $je = '"' + $end + '"' }
  $jsp = 'null'; if ($speaker -ne '') { $jsp = '"' + (Get-JsonEsc $speaker) + '"' }
  [void]$Body.Append('{"speaker":' + $jsp + ',"start":' + $js + ',"end":' + $je + ',"text":"' + (Get-JsonEsc $text) + '","source":"' + (Get-JsonEsc $Src) + '"}' + "`n")
  $script:Cues++
}

$Lines = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $In).Path, (New-Object System.Text.UTF8Encoding($false))) | ForEach-Object { $_.TrimEnd("`r") }
if ($null -eq $Lines) { $Lines = @() }
$Lines = @($Lines)

$Format = 'plain'
foreach ($l in $Lines) { if ($l -eq '') { continue }; if ($l.StartsWith('WEBVTT')) { $Format = 'vtt' }; break }
if ($Format -eq 'plain') { foreach ($l in $Lines) { if ($ReTime.IsMatch($l)) { $Format = 'srt'; break } } }

if ($Format -eq 'plain') {
  foreach ($l in $Lines) { if ($l -ne '') { Add-Cue '' '' $l } }
} else {
  $inCue = $false; $start = ''; $end = ''; $text = ''
  foreach ($l in $Lines) {
    $m = $ReTime.Match($l)
    if ($m.Success) {
      if ($inCue) { Add-Cue $start $end $text }
      $start = Format-Ts $m 1; $end = Format-Ts $m 6
      $inCue = $true; $text = ''
    } elseif ($inCue) {
      if ($l -eq '') { Add-Cue $start $end $text; $inCue = $false }
      elseif ($text -eq '') { $text = $l } else { $text += ' ' + $l }
    }
  }
  if ($inCue) { Add-Cue $start $end $text }
}

$total = 0; foreach ($v in $Counts.Values) { $total += $v }
[void]$Body.Append('{"summary":{"source":"' + (Get-JsonEsc $Src) + '","format":"' + $Format + '","cues":' + $script:Cues + ',"redactions":{"secret":' + $Counts['secret'] + ',"email":' + $Counts['email'] + ',"iban":' + $Counts['iban'] + ',"card":' + $Counts['card'] + ',"phone":' + $Counts['phone'] + '}}}' + "`n")
$outDir = Join-Path (Get-Location).Path $Out
[void][System.IO.Directory]::CreateDirectory($outDir)
$dest = $Out.TrimEnd('/') + '/' + $Base + '.jsonl'
[System.IO.File]::WriteAllText((Join-Path $outDir ($Base + '.jsonl')), $Body.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dest ($($script:Cues) cue(s), $total redaction(s))"
exit 0
