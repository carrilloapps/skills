# Cline PreToolUse hook (Windows): forwards the event to the Devil's Advocate guard.
$payload = [Console]::In.ReadToEnd()
$payload | node "$PSScriptRoot/devils-advocate/guard.mjs"
exit $LASTEXITCODE
