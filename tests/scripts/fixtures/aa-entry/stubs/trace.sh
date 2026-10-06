#!/usr/bin/env bash
# Test stub: fixed trace output for the aa converge parity tests (copied over scripts/trace.sh).
cat <<'EOF'
{"spec":"stub","findings":[{"n":1,"severity":"error","rule":"uncovered-requirement","message":"FR-002 has no scenario"},{"n":2,"severity":"warning","rule":"orphan-test","message":"test references FR-099"},{"n":3,"category":"partial","severity":"warning","rule":"no-evidence","message":"FR-001 verified without evidence"}],"exit":1}
EOF
exit 1
