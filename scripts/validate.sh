#!/usr/bin/env bash
# validate.sh — carrilloapps/skills quality sweep
# Checks all quality standards for all published skills before a PR is merged.
# Usage: bash scripts/validate.sh  (from repo root)
# Compatible: macOS, Linux, Git Bash (Windows), WSL
#
# Checks 1–13: devils-advocate (version, examples, frameworks, gate blocks, budget)
# Check 14:    sar-cybersecurity (version consistency, token budget)
# Check 15:    ai-rules (version consistency, token budget)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/devils-advocate" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUES=()
PASS=0
FAIL=0

ok()   { echo "  ✅ $1"; ((++PASS)); }
fail() { echo "  ❌ $1"; ISSUES+=("$1"); ((++FAIL)); }
section() { echo; echo "── $1 ──────────────────────────────────────"; }

# ─── Check 1: Version consistency ────────────────────────────────────────────
section "Version"
VERSION=$(grep -m1 '^version:' "$ROOT/SKILL.md" | awk '{print $2}')
CHANGELOG_VER=$(grep -m1 '^## \[[0-9]' "$REPO_ROOT/CHANGELOG.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
if [ "$VERSION" = "$CHANGELOG_VER" ]; then
  ok "SKILL.md version ($VERSION) matches latest CHANGELOG entry"
else
  fail "Version mismatch: SKILL.md=$VERSION, CHANGELOG latest=$CHANGELOG_VER"
fi

# ─── Check 2: Fence balance (even number of ``` per file) ────────────────────
section "Fence balance"
FENCE_ISSUES=0
while IFS= read -r -d '' file; do
  count=$(grep -c '^```' "$file" 2>/dev/null || true)
  if (( count % 2 != 0 )); then
    fail "Odd fence count ($count) in: ${file#$REPO_ROOT/}"
    ((++FENCE_ISSUES))
  fi
done < <(find "$REPO_ROOT" -name "*.md" -not -path "*/.git/*" -print0)
(( FENCE_ISSUES == 0 )) && ok "All .md files have balanced fences"

# ─── Check 3: Gate blocks in all examples ────────────────────────────────────
section "Gate blocks (examples)"
EXAMPLE_ISSUES=0
for file in "$ROOT/examples/"*.md; do
  name=$(basename "$file")
  content=$(cat "$file")
  missing=()
  echo "$content" | grep -q "✅ Proceed"  || missing+=("✅ Proceed")
  echo "$content" | grep -q "🔁 Revise"   || missing+=("🔁 Revise")
  echo "$content" | grep -q "❌ Cancel"   || missing+=("❌ Cancel")
  echo "$content" | grep -q '`continue`'  || missing+=("\`continue\`")
  if (( ${#missing[@]} > 0 )); then
    fail "Gate incomplete in $name — missing: ${missing[*]}"
    ((++EXAMPLE_ISSUES))
  fi
done
(( EXAMPLE_ISSUES == 0 )) && ok "All examples have complete Gate blocks"

# ─── Check 4: `continue` wording ─────────────────────────────────────────────
section "Continue wording"
CONTINUE_ISSUES=0
for file in "$ROOT/examples/"*.md; do
  name=$(basename "$file")
  # Verify the FULL correct phrase exists (positive check)
  if ! grep -q "risks remain active and unmitigated" "$file"; then
    fail "Incorrect or missing 'continue' wording in $name — expected: 'proceed without addressing remaining issues (risks remain active and unmitigated)'"
    ((++CONTINUE_ISSUES))
  fi
done
# Check canonical sources too
for canonical in "$ROOT/SKILL.md" "$ROOT/frameworks/output-format.md"; do
  cname=$(basename "$canonical")
  if ! grep -q "risks remain active and unmitigated" "$canonical"; then
    fail "Canonical 'continue' wording missing or incorrect in $cname"
    ((++CONTINUE_ISSUES))
  fi
done
(( CONTINUE_ISSUES == 0 )) && ok "'continue' wording correct in all examples and canonical sources"

# ─── Check 5: All examples referenced in SKILL.md index ─────────────────────
section "SKILL.md index completeness"
INDEX_ISSUES=0
for file in "$ROOT/examples/"*.md; do
  name=$(basename "$file")
  if ! grep -q "$name" "$ROOT/SKILL.md"; then
    fail "Not in SKILL.md index: $name"
    ((++INDEX_ISSUES))
  fi
done
(( INDEX_ISSUES == 0 )) && ok "All examples are indexed in SKILL.md"

# ─── Check 6: No stale legacy text ───────────────────────────────────────────
section "Stale text"
STALE_EXCLUDE="CONTRIBUTING.md PULL_REQUEST_TEMPLATE.md CHANGELOG.md validate.sh"
STALE_ISSUES=0
while IFS= read -r -d '' file; do
  name=$(basename "$file")
  skip=false
  for ex in $STALE_EXCLUDE; do [[ "$name" == "$ex" ]] && skip=true; done
  if ! $skip; then
    if grep -qE "with implementation|14-dimension|carrilloapps/devils-advocate" "$file"; then
      fail "Stale text in: ${file#$REPO_ROOT/}"
      ((++STALE_ISSUES))
    fi
  fi
done < <(find "$REPO_ROOT" -name "*.md" -not -path "*/.git/*" -print0)
(( STALE_ISSUES == 0 )) && ok "No stale text found"

# ─── Check 7: Required GitHub project files ──────────────────────────────────
section "GitHub project files"
for f in README.md metadata.json; do
  if [ -f "$ROOT/$f" ]; then
    ok "$f present"
  else
    fail "Missing: $f"
  fi
done
for f in AGENTS.md \
          .github/copilot-instructions.md \
          LICENSE .gitignore .gitattributes \
          CHANGELOG.md \
          scripts/validate.sh \
          .github/CODEOWNERS \
          .github/CONTRIBUTING.md .github/CODE_OF_CONDUCT.md .github/SECURITY.md \
          .github/ISSUE_TEMPLATE/bug_report.yml .github/ISSUE_TEMPLATE/feature_request.yml \
          .github/PULL_REQUEST_TEMPLATE.md .github/workflows/validate.yml; do
  if [ -f "$REPO_ROOT/$f" ]; then
    ok "$f present"
  else
    fail "Missing: $f"
  fi
done

# ─── Check 8: Example version stamps match SKILL.md ─────────────────────────
section "Example version stamps"
SKILL_VER=$(grep -m1 '^version:' "$ROOT/SKILL.md" | sed 's/version: *//')
VERSION_ISSUES=0
while IFS= read -r -d '' file; do
  if grep -q "Skill version" "$file"; then
    ex_ver=$(grep -m1 "Skill version" "$file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [ "$ex_ver" != "$SKILL_VER" ]; then
      fail "Version mismatch in ${file#$ROOT/}: example=$ex_ver, skill=$SKILL_VER"
      ((++VERSION_ISSUES))
    fi
  else
    fail "Missing 'Skill version' stamp in ${file#$ROOT/}"
    ((++VERSION_ISSUES))
  fi
done < <(find "$ROOT/examples" -name "*.md" -print0)
(( VERSION_ISSUES == 0 )) && ok "All example version stamps match v$SKILL_VER"

# ─── Check 9: Framework files referenced in SKILL.md Index exist on disk ─────
section "Framework files on disk"
MISSING_ISSUES=0
while IFS= read -r f; do
  if [ -f "$ROOT/$f" ]; then
    ok "$f"
  else
    fail "Referenced in SKILL.md but missing: $f"
    ((++MISSING_ISSUES))
  fi
done < <(grep -oE '(frameworks|checklists)/[a-zA-Z0-9_-]+\.md' "$ROOT/SKILL.md" | sort -u)
(( MISSING_ISSUES == 0 )) && ok "All SKILL.md framework references resolve to files on disk"

# ─── Check 10: Frameworks on disk are indexed in SKILL.md ─────────────────────
section "Framework and checklist index coverage"
UNINDEXED_ISSUES=0
for file in "$ROOT/frameworks/"*.md "$ROOT/checklists/"*.md; do
  name=$(basename "$file")
  if ! grep -q "$name" "$ROOT/SKILL.md"; then
    fail "File not indexed in SKILL.md: $name"
    ((++UNINDEXED_ISSUES))
  fi
done
(( UNINDEXED_ISSUES == 0 )) && ok "All framework and checklist files on disk are indexed in SKILL.md"

# ─── Check 11: README.md version badge matches SKILL.md ────────────────────────
section "README version badge"
README_VER=$(grep -oE 'version-[0-9]+\.[0-9]+\.[0-9]+-blue' "$ROOT/README.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
SKILL_VER2=$(grep -m1 '^version:' "$ROOT/SKILL.md" | sed 's/version: *//')
if [ "$README_VER" = "$SKILL_VER2" ]; then
  ok "README.md version badge ($README_VER) matches SKILL.md version"
else
  fail "README.md version badge ($README_VER) does not match SKILL.md ($SKILL_VER2)"
fi

# ─── Check 12: metadata.json version matches SKILL.md ────────────────────────
section "metadata.json version"
META_VER=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$ROOT/metadata.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
SKILL_VER3=$(grep -m1 '^version:' "$ROOT/SKILL.md" | sed 's/version: *//')
if [ "$META_VER" = "$SKILL_VER3" ]; then
  ok "metadata.json version ($META_VER) matches SKILL.md version"
else
  fail "metadata.json version ($META_VER) does not match SKILL.md ($SKILL_VER3)"
fi

# ─── Check 13: SKILL.md token budget ─────────────────────────────────────────
section "SKILL.md token budget"
SKILL_BYTES=$(wc -c < "$ROOT/SKILL.md")
SKILL_TOKEN_EST=$(( SKILL_BYTES / 4 ))
# 8,000-token budget ≈ 32,000 chars (conservative 4 chars/token estimate)
if (( SKILL_BYTES < 32000 )); then
  ok "SKILL.md ${SKILL_BYTES} chars (~${SKILL_TOKEN_EST} tokens) — within 8K-token budget"
else
  fail "SKILL.md ${SKILL_BYTES} chars (~${SKILL_TOKEN_EST} tokens) — exceeds 8K-token budget (32,000 char threshold)"
fi

# ─── Check 14: SAR Cybersecurity version consistency ─────────────────────────
section "SAR Cybersecurity version consistency"
SAR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/sar-cybersecurity" && pwd)"
SAR_SKILL_VER=$(grep -m1 '^version:' "$SAR_ROOT/SKILL.md" | sed 's/version: *//')
SAR_README_VER=$(grep -oE 'version-[0-9]+\.[0-9]+\.[0-9]+-blue' "$SAR_ROOT/README.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
SAR_META_VER=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$SAR_ROOT/metadata.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
SAR_SKILL_BYTES=$(wc -c < "$SAR_ROOT/SKILL.md")
SAR_SKILL_TOKENS=$(( SAR_SKILL_BYTES / 4 ))
if [ "$SAR_README_VER" = "$SAR_SKILL_VER" ]; then
  ok "SAR README.md badge ($SAR_README_VER) matches SKILL.md version"
else
  fail "SAR README.md badge ($SAR_README_VER) does not match SKILL.md ($SAR_SKILL_VER)"
fi
if [ "$SAR_META_VER" = "$SAR_SKILL_VER" ]; then
  ok "SAR metadata.json version ($SAR_META_VER) matches SKILL.md version"
else
  fail "SAR metadata.json version ($SAR_META_VER) does not match SKILL.md ($SAR_SKILL_VER)"
fi
if (( SAR_SKILL_BYTES < 32000 )); then
  ok "SAR SKILL.md ${SAR_SKILL_BYTES} chars (~${SAR_SKILL_TOKENS} tokens) — within 8K-token budget"
else
  fail "SAR SKILL.md ${SAR_SKILL_BYTES} chars (~${SAR_SKILL_TOKENS} tokens) — exceeds 8K-token budget (32,000 char threshold)"
fi

# ─── Check 15: ai-rules version consistency ───────────────────────────────────
section "ai-rules version consistency"
AIRULES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/ai-rules" && pwd)"
AIRULES_SKILL_VER=$(grep -m1 '^version:' "$AIRULES_ROOT/SKILL.md" | sed 's/version: *//')
AIRULES_README_VER=$(grep -oE 'version-[0-9]+\.[0-9]+\.[0-9]+-blue' "$AIRULES_ROOT/README.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
AIRULES_META_VER=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$AIRULES_ROOT/metadata.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
AIRULES_SKILL_BYTES=$(wc -c < "$AIRULES_ROOT/SKILL.md")
AIRULES_SKILL_TOKENS=$(( AIRULES_SKILL_BYTES / 4 ))
if [ "$AIRULES_README_VER" = "$AIRULES_SKILL_VER" ]; then
  ok "ai-rules README.md badge ($AIRULES_README_VER) matches SKILL.md version"
else
  fail "ai-rules README.md badge ($AIRULES_README_VER) does not match SKILL.md ($AIRULES_SKILL_VER)"
fi
if [ "$AIRULES_META_VER" = "$AIRULES_SKILL_VER" ]; then
  ok "ai-rules metadata.json version ($AIRULES_META_VER) matches SKILL.md version"
else
  fail "ai-rules metadata.json version ($AIRULES_META_VER) does not match SKILL.md ($AIRULES_SKILL_VER)"
fi
if (( AIRULES_SKILL_BYTES < 32000 )); then
  ok "ai-rules SKILL.md ${AIRULES_SKILL_BYTES} chars (~${AIRULES_SKILL_TOKENS} tokens) — within 8K-token budget"
else
  fail "ai-rules SKILL.md ${AIRULES_SKILL_BYTES} chars (~${AIRULES_SKILL_TOKENS} tokens) — exceeds 8K-token budget (32,000 char threshold)"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════════════"
echo "  Results: $PASS passed · $FAIL failed"
echo "════════════════════════════════════════════"

if (( FAIL > 0 )); then
  echo
  echo "Findings:"
  for issue in "${ISSUES[@]}"; do echo "  • $issue"; done
  echo
  exit 1
else
  echo "  ✅ All checks passed — ready to merge"
  echo
  exit 0
fi