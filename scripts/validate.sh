#!/usr/bin/env bash
# validate.sh — carrilloapps/skills quality sweep
# Checks all quality standards for all published skills before a PR is merged.
# Usage: bash scripts/validate.sh  (from repo root)
# Compatible: macOS, Linux, Git Bash (Windows), WSL
#
# Checks 1–13:  devils-advocate (version, fences, gate blocks, index, stale text,
#                project files, example stamps, frameworks, badges, budget)
# Check 14:     sar-cybersecurity (version consistency, token budget)
# Check 15:     ai-rules (version consistency, token budget)
# Check 16:     CHANGELOG entry for every skill's current version
# Check 17:     root README catalog badges for every skill
# Check 18:     sar-cybersecurity index completeness + "Example only" boundary
# Check 19:     SAR scoring arithmetic (`Base N +a −b … = Y` lines add up)
# Check 20:     six mandatory safeguards present in every SKILL.md
# Check 21:     selective `.memory/` convention (shared state versioned, local/ ignored)
# Check 22:     capabilities.md install commands pinned, no download-pipe-to-shell
# Check 23:     no install commands in any SKILL.md
# Check 24:     integrations/ classifier copies in sync with integrations/core (needs node)
# Check 25:     no stale "40+ agents" wording in documentation
# Check 26:     Docker lab templates: pinned images, 127.0.0.1-only ports, no literal credentials
# Check 27:     agentic-agile consistency (version, budget, index, example stamps, Phase 0 gate)
# Check 28:     numbered options — no `- [ ]` checkboxes under skills/
# Check 29:     vendored shared scripts in sync (shared/sync.sh --check)
# Check 30:     every skills/*/scripts/*.sh has a .ps1 twin and vice versa (+ parity tests if present)
# Check 31:     no global agent directories advertised as write targets in skills/

set -euo pipefail

# Skill version lives in the SKILL.md frontmatter as metadata.version (Agent Skills spec)
skill_version() {
  awk '/^---[[:space:]]*$/{n++; if (n==2) exit; next}
       n==1 && /^metadata:/ {m=1; next}
       n==1 && m && /^[^[:space:]]/ {m=0}
       n==1 && m && /^[[:space:]]+version:/ {v=$2; gsub(/["\r]/, "", v); print v; exit}' "$1/SKILL.md"
}

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
VERSION=$(skill_version "$ROOT")
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
  count=$(grep -cE '^[[:space:]]*```' "$file" 2>/dev/null || true)
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
  # Gate labels are a guide, not a password: require the gate plus the natural-language note
  echo "$content" | grep -q "✅ Proceed"  || missing+=("✅ Proceed")
  echo "$content" | grep -q "own words"   || missing+=("'reply in your own words' note")
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
  grep -q "own words" "$canonical" || { fail "Natural-language gate note missing in $(basename "$canonical")"; ((++CONTINUE_ISSUES)); }
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
    # Migration notes that name removed files on purpose are not stale
    if grep -iE "with implementation|14-dimension|carrilloapps/devils-advocate|immediate-report|handbrake-checklist|IMMEDIATE REPORT|full adversarial analysis" "$file" \
         | grep -viqE "removed|merged into|migrat"; then
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
SKILL_VER=$(skill_version "$ROOT")
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
SKILL_VER2=$(skill_version "$ROOT")
if [ "$README_VER" = "$SKILL_VER2" ]; then
  ok "README.md version badge ($README_VER) matches SKILL.md version"
else
  fail "README.md version badge ($README_VER) does not match SKILL.md ($SKILL_VER2)"
fi

# ─── Check 12: metadata.json version matches SKILL.md ────────────────────────
section "metadata.json version"
META_VER=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$ROOT/metadata.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
SKILL_VER3=$(skill_version "$ROOT")
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
SAR_SKILL_VER=$(skill_version "$SAR_ROOT")
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
AIRULES_SKILL_VER=$(skill_version "$AIRULES_ROOT")
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

# ─── Check 16: CHANGELOG entry for every skill's current version ─────────────
section "CHANGELOG entries"
SAR_ROOT="$REPO_ROOT/skills/sar-cybersecurity"
AIRULES_ROOT="$REPO_ROOT/skills/ai-rules"
DA_VER=$(skill_version "$ROOT")
SAR_VER=$(skill_version "$SAR_ROOT")
AIRULES_VER=$(skill_version "$AIRULES_ROOT")
AA_ROOT="$REPO_ROOT/skills/agentic-agile"
AA_VER=""; [ -f "$AA_ROOT/SKILL.md" ] && AA_VER=$(skill_version "$AA_ROOT")
EXTRA_ENTRIES=(); [ -n "$AA_VER" ] && EXTRA_ENTRIES+=("agentic-agile:$AA_VER")
for entry in "sar-cybersecurity:$SAR_VER" "ai-rules:$AIRULES_VER" "${EXTRA_ENTRIES[@]}"; do
  name="${entry%%:*}"; ver="${entry#*:}"
  if grep -qF "## $name [$ver]" "$REPO_ROOT/CHANGELOG.md"; then
    ok "CHANGELOG has '## $name [$ver]'"
  else
    fail "CHANGELOG missing entry '## $name [$ver]'"
  fi
done

# ─── Check 17: Root README catalog badges ────────────────────────────────────
section "Root README catalog badges"
for entry in "devils-advocate:$DA_VER" "sar-cybersecurity:$SAR_VER" "ai-rules:$AIRULES_VER" "${EXTRA_ENTRIES[@]}"; do
  name="${entry%%:*}"; ver="${entry#*:}"
  badge_lines=$(grep -F "skills/$name/" "$REPO_ROOT/README.md" | grep -cF "v$ver-blue" || true)
  stale_lines=$(grep -F "skills/$name/" "$REPO_ROOT/README.md" | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+-blue' | grep -vcF "v$ver-blue" || true)
  if (( badge_lines >= 1 && stale_lines == 0 )); then
    ok "Root README badges for $name match v$ver"
  else
    fail "Root README badges for $name do not all match v$ver ($badge_lines current, $stale_lines stale)"
  fi
done

# ─── Check 18: SAR index completeness + example boundary ─────────────────────
section "SAR index completeness"
SAR_INDEX_ISSUES=0
for file in "$SAR_ROOT/frameworks/"*.md "$SAR_ROOT/examples/"*.md; do
  rel="${file#$SAR_ROOT/}"
  if ! grep -qF "$rel" "$SAR_ROOT/SKILL.md"; then
    fail "Not in SAR SKILL.md index: $rel"
    ((++SAR_INDEX_ISSUES))
  fi
done
while IFS= read -r f; do
  if [ ! -f "$SAR_ROOT/$f" ]; then
    fail "Referenced in SAR SKILL.md but missing: $f"
    ((++SAR_INDEX_ISSUES))
  fi
done < <(grep -oE '(frameworks|examples)/[a-zA-Z0-9_-]+\.md' "$SAR_ROOT/SKILL.md" | sort -u)
for file in "$SAR_ROOT/examples/"*.md; do
  if ! grep -q "Example only" "$file"; then
    fail "Missing '⚠️ Example only' boundary in SAR ${file#$SAR_ROOT/}"
    ((++SAR_INDEX_ISSUES))
  fi
done
(( SAR_INDEX_ISSUES == 0 )) && ok "SAR frameworks/examples indexed, resolvable, and bounded"

# ─── Check 19: SAR scoring arithmetic ────────────────────────────────────────
section "SAR scoring arithmetic"
# Parses lines such as: Base 80 +5 (enumeration) −10 (auth) = 75 (cap: none) → Final 75
# Parenthesized labels are dropped; lines with non-numeric terms (templates) are skipped.
ARITH_OUT=$(grep -rn "Base [0-9]" "$SAR_ROOT" --include="*.md" 2>/dev/null \
  | sed 's/−/-/g' \
  | awk '{
      line = $0
      i = index(line, "Base ")
      rest = substr(line, i + 5)
      e = index(rest, "=")
      if (!e) next
      lhs = substr(rest, 1, e - 1); rhs = substr(rest, e + 1)
      gsub(/\([^)]*\)/, "", lhs)
      if (lhs ~ /[A-Za-z]/) next
      n = split(lhs, t, " "); sum = 0; terms = 0
      for (k = 1; k <= n; k++) {
        if (t[k] !~ /^[+-]?[0-9]+$/) next
        sum += t[k]; terms++
      }
      if (terms == 0 || !match(rhs, /[0-9]+/)) next
      y = substr(rhs, RSTART, RLENGTH) + 0
      checked++
      if (sum != y) { print "BAD " sum " " line }
    }
    END { print "CHECKED " checked + 0 }')
ARITH_CHECKED=$(echo "$ARITH_OUT" | grep '^CHECKED' | awk '{print $2}')
ARITH_BAD=0
while IFS= read -r bad; do
  [ -z "$bad" ] && continue
  computed=$(echo "$bad" | awk '{print $2}')
  where=$(echo "$bad" | cut -d' ' -f3- | cut -d: -f1-2)
  fail "Score arithmetic does not add up (computed $computed): ${where#$REPO_ROOT/}"
  ((++ARITH_BAD))
done < <(echo "$ARITH_OUT" | grep '^BAD' || true)
(( ARITH_BAD == 0 )) && ok "All $ARITH_CHECKED SAR score arithmetic lines add up"

# ─── Check 20: Mandatory safeguards in every SKILL.md ────────────────────────
section "Mandatory safeguards"
for skill_dir in "$REPO_ROOT/skills/"*/; do
  skill_md="$skill_dir/SKILL.md"
  [ -f "$skill_md" ] || continue
  sname=$(basename "$skill_dir")
  missing=()
  grep -qi "untrusted"          "$skill_md" || missing+=("untrusted input boundary")
  grep -qi "code execution"     "$skill_md" || missing+=("no arbitrary code execution")
  grep -qi "bounded autonomy"   "$skill_md" || missing+=("bounded autonomy")
  grep -qi "web search"         "$skill_md" || missing+=("web search scoping")
  grep -qi "example code"       "$skill_md" || missing+=("example code boundaries")
  grep -qi "report-only"        "$skill_md" || missing+=("report-only output")
  if (( ${#missing[@]} > 0 )); then
    fail "$sname SKILL.md missing safeguard(s): ${missing[*]}"
  else
    ok "$sname SKILL.md declares all six safeguards"
  fi
done

# ─── Check 21: Selective .memory/ convention ─────────────────────────────────
section ".memory/ selective convention"
if grep -qxF ".memory/" "$REPO_ROOT/.gitignore"; then
  fail "Root .gitignore ignores all of .memory/ — shared state under .memory/<skill>/ must stay versioned"
elif grep -qF ".memory/local/" "$REPO_ROOT/.gitignore"; then
  ok "Root .gitignore ignores only .memory/local/ (selective)"
else
  fail "Root .gitignore does not ignore .memory/local/"
fi
for skill_md in "$REPO_ROOT/skills/"*/SKILL.md; do
  sname=$(basename "$(dirname "$skill_md")")
  grep -qF ".memory/" "$skill_md" || continue
  if grep -qF ".memory/.gitignore" "$skill_md" && grep -qF "local/" "$skill_md" \
     && ! grep -qiE "\.memory/.*(never (be )?gitignored|never add it to .?\.gitignore)" "$skill_md"; then
    ok "$sname documents .memory/.gitignore with local/"
  else
    fail "$sname SKILL.md mentions .memory/ without documenting .memory/.gitignore and local/"
  fi
done

# Print only the lines inside fenced code blocks of a Markdown file
fenced_lines() { awk '/^[[:space:]]*```/ { inside = !inside; next } inside { print }' "$1"; }

# ─── Check 22: capabilities.md install hygiene ────────────────────────────────
section "capabilities.md install hygiene"
CAP_ISSUES=0
for cap in "$REPO_ROOT/skills/"*/frameworks/capabilities.md; do
  [ -f "$cap" ] || continue
  rel="${cap#$REPO_ROOT/}"
  code=$(fenced_lines "$cap")
  if echo "$code" | grep -qiE "(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh"; then
    fail "$rel pipes a download into a shell"; ((++CAP_ISSUES))
  fi
  if echo "$code" | grep -qiE "(irm|iwr|invoke-restmethod|invoke-webrequest)[^|]*\|[[:space:]]*(iex|invoke-expression)"; then
    fail "$rel pipes a download into iex"; ((++CAP_ISSUES))
  fi
  if echo "$code" | grep -qF "@latest"; then
    fail "$rel uses @latest"; ((++CAP_ISSUES))
  fi
  # npx -y / --yes <pkg> must pin <pkg>@<version>; same for JSON args ["-y", "<pkg>"]
  unpinned=$(echo "$code" | grep -oE "npx[[:space:]]+(-y|--yes)[[:space:]]+[^[:space:]]+|\"(-y|--yes)\",[[:space:]]*\"[^\"]+\"" \
             | grep -vE "@[0-9]" || true)
  if [ -n "$unpinned" ]; then
    fail "$rel has an unpinned npx -y package: $(echo "$unpinned" | head -1)"; ((++CAP_ISSUES))
  fi
done
(( CAP_ISSUES == 0 )) && ok "capabilities.md files pin every install and never pipe downloads into a shell"

# ─── Check 23: No install commands in SKILL.md ────────────────────────────────
section "No install commands in SKILL.md"
INSTALL_ISSUES=0
for skill_md in "$REPO_ROOT/skills/"*/SKILL.md; do
  sname=$(basename "$(dirname "$skill_md")")
  if grep -qE "(npm (i|install)|pnpm add|yarn add|pip3? install|pipx install|brew install|winget install|scoop install|go install|cargo install)[[:space:]]" "$skill_md"; then
    fail "$sname SKILL.md contains an install command — move it to frameworks/capabilities.md"
    ((++INSTALL_ISSUES))
  fi
done
(( INSTALL_ISSUES == 0 )) && ok "No SKILL.md contains install commands"

# ─── Check 24: integrations/ classifier copies in sync ────────────────────────
section "integrations/ classifier sync"
if [ -f "$REPO_ROOT/integrations/sync-core.mjs" ]; then
  if command -v node >/dev/null 2>&1; then
    if node "$REPO_ROOT/integrations/sync-core.mjs" --check >/dev/null 2>&1; then
      ok "Every adapter's classifier copy matches integrations/core/classifier.mjs"
    else
      fail "Classifier copies drifted from integrations/core — run: node integrations/sync-core.mjs"
    fi
  else
    echo "  ⏭️  node not found — skipping classifier sync check"
  fi
fi

# ─── Check 25: No stale agent-count wording ──────────────────────────────────
section "Agent-count wording"
COUNT_ISSUES=0
while IFS= read -r -d '' file; do
  if grep -qiE "40\+ (ai coding )?agents|over \*\*40 agents" "$file"; then
    fail "Stale '40+ agents' wording in ${file#$REPO_ROOT/} (use 70+)"
    ((++COUNT_ISSUES))
  fi
done < <(find "$REPO_ROOT" \( -name "README.md" -o -name "AGENTS.md" -o -name ".ai-context.md" -o -path "*/docs/*.md" -o -path "*/.github/*.md" \) -not -path "*/.git/*" -print0)
(( COUNT_ISSUES == 0 )) && ok "No stale agent-count wording in documentation"

# ─── Check 26: Docker lab hygiene (pinned images, localhost ports, no literal passwords) ─
section "Docker lab hygiene"
LAB_ISSUES=0
while IFS= read -r -d '' lab; do
  rel=${lab#$REPO_ROOT/}
  if grep -nE '^[[:space:]]*image:[[:space:]]*[^[:space:]]+:latest([[:space:]@]|$)|^[[:space:]]*image:[[:space:]]*[a-z0-9./_-]+[[:space:]]*$' "$lab" >/dev/null; then
    fail "Unpinned image (:latest or no tag) in $rel"; ((++LAB_ISSUES))
  fi
  # Every image: and Dockerfile FROM line must carry a digest (tag@sha256:...)
  if grep -nE '^[[:space:]]*(image:|FROM )' "$lab" | grep -v '@sha256:[0-9a-f]\{64\}' >/dev/null; then
    fail "Image or FROM line without @sha256 digest in $rel"; ((++LAB_ISSUES))
  fi
  # Published ports must bind to 127.0.0.1: flag "- "8080:8080"" / "- 0.0.0.0:..." forms
  if grep -nE '^[[:space:]]*-[[:space:]]*"?(0\.0\.0\.0:)?[0-9]+:[0-9]+"?[[:space:]]*$' "$lab" >/dev/null; then
    fail "Port not bound to 127.0.0.1 in $rel"; ((++LAB_ISSUES))
  fi
  # Literal secrets: KEY: value / KEY=value for *PASSWORD*/*SECRET*/*TOKEN* not using ${...}, $VAR, or a file
  if grep -nE '(PASSWORD|SECRET|TOKEN)[A-Z_]*[[:space:]]*[:=][[:space:]]*"?[A-Za-z0-9!@#%^&*_+-]{6,}"?[[:space:]]*$' "$lab" \
      | grep -vE '\$\{|\$[A-Z_]|_FILE|<[^>]+>|changeme|example' >/dev/null; then
    fail "Possible literal credential in $rel"; ((++LAB_ISSUES))
  fi
done < <(find "$REPO_ROOT/skills" -path '*/frameworks/docker-lab.md' -print0)
(( LAB_ISSUES == 0 )) && ok "Docker lab templates: digest-pinned images, 127.0.0.1-only ports, no literal credentials"

# ─── Check 27: agentic-agile consistency ─────────────────────────────────────
section "agentic-agile consistency"
if [ ! -f "$AA_ROOT/SKILL.md" ]; then
  fail "skills/agentic-agile/SKILL.md missing"
else
  AA_README_VER=$(grep -oE 'version-[0-9]+\.[0-9]+\.[0-9]+-blue' "$AA_ROOT/README.md" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  AA_META_VER=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$AA_ROOT/metadata.json" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  [ "$AA_README_VER" = "$AA_VER" ] && ok "agentic-agile README badge ($AA_README_VER) matches SKILL.md" || fail "agentic-agile README badge ($AA_README_VER) != SKILL.md ($AA_VER)"
  [ "$AA_META_VER" = "$AA_VER" ] && ok "agentic-agile metadata.json ($AA_META_VER) matches SKILL.md" || fail "agentic-agile metadata.json ($AA_META_VER) != SKILL.md ($AA_VER)"
  AA_BYTES=$(wc -c < "$AA_ROOT/SKILL.md")
  (( AA_BYTES < 32000 )) && ok "agentic-agile SKILL.md ${AA_BYTES} chars — within 8K-token budget" || fail "agentic-agile SKILL.md ${AA_BYTES} chars — exceeds 32,000"
  AA_ISSUES=0
  for file in "$AA_ROOT/frameworks/"*.md "$AA_ROOT/examples/"*.md; do
    [ -f "$file" ] || continue
    rel="${file#$AA_ROOT/}"
    grep -qF "$rel" "$AA_ROOT/SKILL.md" || { fail "Not in agentic-agile SKILL.md index: $rel"; ((++AA_ISSUES)); }
  done
  while IFS= read -r f; do
    [ -f "$AA_ROOT/$f" ] || { fail "Referenced in agentic-agile SKILL.md but missing: $f"; ((++AA_ISSUES)); }
  done < <(grep -oE '(frameworks|examples|templates|scripts)/[a-zA-Z0-9_.-]+\.(md|sh|ps1|tsv)' "$AA_ROOT/SKILL.md" | sort -u)
  for file in "$AA_ROOT/examples/"*.md; do
    [ -f "$file" ] || continue
    ex_ver=$(grep -m1 "Skill version" "$file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    [ "$ex_ver" = "$AA_VER" ] || { fail "agentic-agile ${file#$AA_ROOT/}: Skill version '$ex_ver' != $AA_VER"; ((++AA_ISSUES)); }
  done
  (( AA_ISSUES == 0 )) && ok "agentic-agile frameworks/examples indexed, resolvable, and stamped"
  for aa_tool in audit-agile doctor; do
    grep -q "$aa_tool" "$AA_ROOT/SKILL.md" || fail "agentic-agile SKILL.md does not index scripts/$aa_tool"
  done
  if grep -q 'check-structure' "$AA_ROOT/SKILL.md"; then
    ok "agentic-agile SKILL.md enforces the Phase 0 structure gate (check-structure)"
  else
    fail "agentic-agile SKILL.md does not mention check-structure (Phase 0 gate)"
  fi
fi

# ─── Check 28: numbered options, no checkboxes ───────────────────────────────
section "Numbered options (no checkboxes)"
CB=$(grep -rnE '^[[:space:]>]*[-*] \[[ xX]\] ' "$REPO_ROOT/skills" --include='*.md' || true)
if [ -z "$CB" ]; then
  ok "No '- [ ]' checkboxes under skills/ — options are numbered or lettered"
else
  while IFS= read -r l; do fail "Checkbox in ${l#$REPO_ROOT/}"; done <<< "$(echo "$CB" | head -20)"
fi

# ─── Check 29: vendored shared scripts in sync ───────────────────────────────
section "Shared scripts sync"
if [ -f "$REPO_ROOT/shared/sync.sh" ]; then
  if bash "$REPO_ROOT/shared/sync.sh" --check >/dev/null 2>&1; then
    ok "shared/sync.sh --check: vendored copies identical in every skill"
  else
    fail "shared/sync.sh --check failed — run: bash shared/sync.sh"
  fi
else
  fail "shared/sync.sh missing"
fi

# ─── Check 30: .sh / .ps1 twins + parity tests ───────────────────────────────
section "Multi-OS script twins"
TWIN_ISSUES=0
for f in "$REPO_ROOT"/skills/*/scripts/*.sh "$REPO_ROOT"/skills/*/scripts/*.ps1; do
  [ -f "$f" ] || continue
  case "$f" in *.sh) twin="${f%.sh}.ps1" ;; *) twin="${f%.ps1}.sh" ;; esac
  [ -f "$twin" ] || { fail "No twin for ${f#$REPO_ROOT/} (expected ${twin#$REPO_ROOT/})"; ((++TWIN_ISSUES)); }
done
(( TWIN_ISSUES == 0 )) && ok "Every skill script has a .sh and a .ps1 implementation"
if [ -f "$REPO_ROOT/tests/scripts/run-parity.sh" ]; then
  if bash "$REPO_ROOT/tests/scripts/run-parity.sh" >/dev/null 2>&1; then
    ok "tests/scripts/run-parity.sh passed"
  else
    fail "tests/scripts/run-parity.sh failed — run it for details"
  fi
fi

# ─── Check 31: no global agent dirs as write targets ─────────────────────────
section "Project-local storage"
GLOBAL_HITS=$(grep -rnE '(~|\$HOME|%USERPROFILE%)/\.(claude|gemini|codex|cursor|copilot)\b' "$REPO_ROOT/skills" --include='*.md' \
  | grep -viE "never|not |n't|avoid|forbid|without|ask|approv|unless|global|instead|outside" || true)
if [ -z "$GLOBAL_HITS" ]; then
  ok "skills/ never advertise global agent directories as write targets"
else
  while IFS= read -r l; do fail "Global path without approval wording: ${l#$REPO_ROOT/}"; done <<< "$(echo "$GLOBAL_HITS" | head -20)"
fi

# ─── Check 32: PowerShell scripts are ASCII outside comments (PS 5.1 reads BOM-less files as ANSI) ─
section "PowerShell ASCII-safe code"
PS_ISSUES=0
while IFS= read -r -d '' ps; do
  if LC_ALL=C grep -n $'[^\t -~]' "$ps" | LC_ALL=C grep -vE '^[0-9]+:[[:space:]]*#' >/dev/null; then
    fail "Non-ASCII character outside comments in ${ps#$REPO_ROOT/} (use \uXXXX escapes)"; ((++PS_ISSUES))
  fi
done < <(find "$REPO_ROOT/skills" "$REPO_ROOT/shared" "$REPO_ROOT/scripts" "$REPO_ROOT/tests/scripts" "$REPO_ROOT/integrations" -name '*.ps1' -not -path '*/.work/*' -print0 2>/dev/null)
(( PS_ISSUES == 0 )) && ok "All .ps1 files are ASCII outside comments (Windows PowerShell 5.1 safe)"

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