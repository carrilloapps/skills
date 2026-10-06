#!/bin/sh
# Runs INSIDE the pinned Python container started by scripts/audit-skills.sh / audit-skills.ps1.
# /src = repository (read-only), /out = results folder. Offline analyzers only.
set -eu
# Exit 3 = the audit could not run (install or scanner crash); 1 is reserved for real findings.
pip install -q --root-user-action=ignore --disable-pip-version-check "$SKILLS_REF" "$SKILL_SCANNER" >/dev/null || { echo "audit-skills: pip install failed" >&2; exit 3; }
rm -rf /tmp/skills && cp -r /src/skills /tmp/skills

: >/out/agentskills-validate.txt
for d in /tmp/skills/*/; do
  n=$(basename "$d")
  if agentskills validate "$d" >>/out/agentskills-validate.txt 2>&1; then echo "ok $n" >>/out/agentskills-validate.txt
  else echo "FAIL $n" >>/out/agentskills-validate.txt; fi
done

skill-scanner scan-all /tmp/skills --recursive --use-behavioral --format json --output /out/skill-scanner.json >/dev/null || { echo "audit-skills: skill-scanner crashed (json)" >&2; exit 3; }
skill-scanner scan-all /tmp/skills --recursive --use-behavioral --format sarif --output /out/skill-scanner.sarif >/dev/null || { echo "audit-skills: skill-scanner crashed (sarif)" >&2; exit 3; }
[ -s /out/skill-scanner.json ] || { echo "audit-skills: scanner produced no report" >&2; exit 3; }

python - <<'PY'
import json, sys
issues = []
for line in open("/out/agentskills-validate.txt", encoding="utf-8"):
    line = line.rstrip()
    if line.startswith("FAIL "):
        issues.append("agentskills validate failed: " + line[5:])
    elif line.startswith("  - "):
        issues.append("  " + line.strip())
data = json.load(open("/out/skill-scanner.json", encoding="utf-8"))
for r in data.get("results", []):
    for f in r.get("findings", []):
        where = "%s/%s:%s" % (r.get("skill_name"), f.get("file_path"), f.get("line_number"))
        issues.append("%s %s %s — %s" % (f.get("severity"), f.get("rule_id"), where, f.get("title")))
if not issues:
    print("Skills audit clean: agentskills validate ok, skill-scanner 0 findings.")
    sys.exit(0)
for i, msg in enumerate(issues, 1):
    print("%d. %s" % (i, msg))
sys.exit(1)
PY
