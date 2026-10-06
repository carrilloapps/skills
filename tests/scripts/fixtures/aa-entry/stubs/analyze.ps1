# Test stub: fixed analyze output for the aa converge parity tests (copied over scripts/analyze.ps1).
Write-Output '{"findings":[{"n":1,"severity":"high","rule":"terminology-drift","message":"\"invoice\" conflicts with \"bill\""},{"n":2,"severity":"low","rule":"ambiguous-term","message":"vague word fast in FR-001"}],"exit":1}'
exit 1
