# Changelog

All notable changes to Devil's Advocate are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- `postmortem-writing` companion skill for post-incident analysis

---

## [2.7.0] — 2026-02-20

### Added
- `frameworks/handbrake-checklist.md` — new 8-question rapid-sweep checklist to determine if Handbrake should activate; includes minimum steps and bypass disclosure template
- `.gitattributes` — enforces LF line endings on `scripts/validate.sh` and GitHub Actions workflows for cross-platform compatibility
- `.github/workflows/validate.yml` — GitHub Actions CI: runs `bash scripts/validate.sh` on every push and PR to `main`

### Fixed
- **Critical — IR `continue` vs Handbrake conflict**: `continue` at the IR stage now explicitly documented to skip IR context collection only, NOT bypass the Handbrake; if finding is 🔴 Critical the Handbrake still activates as the next mandatory step (`immediate-report.md`, `SKILL.md`)
- **High — validate.sh CRLF line endings**: re-saved with LF only; Windows contributors can now run `bash scripts/validate.sh` in Git Bash without `$'\r': command not found` errors
- **High — example version stamps stale**: all 12 examples updated from `v2.4.1` to current `v2.6.9`; new validate.sh check 8 enforces version stamp consistency going forward
- **High — premortem.md budget conflict**: reclassified from Domain Framework (counted against 2-framework budget) to Protocol File (free); Handbrake Step 6 mandates it, so it was self-defeating to count it; domain count updated 13 → 12 in `SKILL.md`, `CONTRIBUTING.md`
- **High — "bypass is recorded" wording**: replaced with "visible in the conversation history" in `SKILL.md` Gate Protocol and `handbrake-protocol.md` — the previous wording implied non-existent persistence
- **Medium — duplicate scope guard**: removed shorter/incomplete scope guard from `Rule Precedence` section; single authoritative definition remains in `Automatic Trigger Detection` with full Disambiguation rule
- **Medium — IR+Handbrake merge cross-reference missing**: added merge note to `handbrake-protocol.md` Output Block section pointing to `immediate-report.md` for combined format
- **Medium — `handbrake-checklist.md` referenced but missing**: created the file; added to SKILL.md Index under Protocol Files

### Changed
- **SKILL.md slimmed** (~25% size reduction): removed duplicated Handbrake flow diagram, role escalation table, IR flash format template, and Building Protocol tables — these are all defined authoritatively in their dedicated framework files; SKILL.md now contains minimal summaries with explicit load references
- `premortem.md` moved from Domain Frameworks section to Protocol Files section in SKILL.md Index
- `CONTRIBUTING.md`: domain count updated to 12; `premortem.md` added to protocol files exclusion list
- validate.sh check 7: added `.gitattributes` and `.github/workflows/validate.yml` to required files list
- validate.sh: added check 8 — example version stamps must match `SKILL.md` version

---

## [2.6.9] — 2026-02-20

### Added
- 6 new examples covering all remaining major domains: Product/PM, Data Pipeline, CI/CD Pipeline, Vendor/Strategy, UX/Checkout, Performance
- `README.md` — public project documentation for GitHub and skill.sh
- `LICENSE` — MIT license
- `CONTRIBUTING.md` — contributor guide with quality standards and PR process
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1
- `CHANGELOG.md` — version history (this file)
- `SECURITY.md` — vulnerability reporting policy
- `.gitignore` — standard ignores for OS, editor, and Node tooling
- `.github/ISSUE_TEMPLATE/` — bug report and feature request YAML templates
- `.github/PULL_REQUEST_TEMPLATE.md` — structured PR checklist

---

## [2.6.8] — 2026-02-20

### Added
- `frameworks/version-control.md` — new domain framework: platform detection (GitHub/GitLab/generic), branching strategy, force push & history rewriting, secrets-in-repo remediation, PR/MR workflow, branch protection rules, GitHub Actions security, GitLab CI/CD variables, access control, tag & release management, monorepo/polyrepo trade-offs
- `examples/version-control-review.md` — full protocol stack: leaked DB credentials + force push to main → ⚡ IR + 🛑 Multi-role Handbrake + git filter-repo remediation plan
- Version Control domain added to `handbrake-protocol.md` (Role→Escalation Map + Context Question Template)
- Version Control Context Request Template added to `immediate-report.md`
- Version Control added to IR domain list, Handbrake escalation table, trigger table, and "When to Use" in `SKILL.md`
- Developer/DevOps row added to "When to Use This Skill" table

---

## [2.6.7] — 2026-02-20

### Fixed
- Missing `---` separator before `## Handbrake Bypass` section in `handbrake-protocol.md` (accidentally removed during v2.6.6 restructuring)

---

## [2.6.6] — 2026-02-20

### Added
- `examples/security-review.md` — JWT authentication audit: STRIDE analysis, AppSec Handbrake, Building Protocol Critical violation (hardcoded secret in git)
- `examples/ai-context-review.md` — AI Optimization example: AGENTS.md + copilot-instructions.md conflict review, context starvation, hallucination root cause analysis
- SKILL.md Index updated with both new examples

### Fixed
- IR flash format domain list updated from 7 → 10 domains (Finance, Legal, AI Optimization added)
- `handbrake-protocol.md`: Legal and AI Optimization templates repositioned into `## Context Question Templates` section (were misplaced after `## Pre-mortem Integration`)
- `continue` reply in all 3 original examples: `(risks remain active)` → `(risks remain active and unmitigated)`

---

## [2.6.5] — 2026-02-19

### Added
- Finance/Billing Context Question Template in `handbrake-protocol.md` and `immediate-report.md`
- Legal/Compliance Context Question Template in `handbrake-protocol.md` and `immediate-report.md`
- AI Optimization Context Question Template in `handbrake-protocol.md` and `immediate-report.md`
- Finance, Legal, AI Optimization rows added to Role→Escalation Map in `handbrake-protocol.md`
- `frameworks/ai-optimization.md` — AI context file analysis: context window budget, cross-reference integrity, feature overlap, context starvation, instruction conflicts, hallucination risk

---

## [2.6.0] — 2026-02-18

### Changed
- Orchestration Priority section restructured: explicit Execution Hierarchy diagram, User Authority Preservation table, per-action-category blocking table
- Rule Precedence section added: this skill's rules override all other tools, skills, agents, and MCPs
- Context Before Calling Resources section added
- Read-only exception documented

---

## [2.5.0] — 2026-02-17

> Internal iteration — not externally released. Changes incorporated into v2.6.0.

---

## [2.4.1] — 2026-02-15

### Added
- `frameworks/building-protocol.md` — Three Languages rule, Conventional Commits, SOLID enforcement, Definition of Done checklist, reference implementation, violation severity table
- Building Protocol Activation rules documented
- Role Detection prompt standardized across SKILL.md and building-protocol.md

---


## [2.4.0] — 2026-02-14

### Added
- `checklists/risk-checklist.md` — 8-category structured risk sweep with percentage-based scoring
- `checklists/questioning-checklist.md` — 15-dimension interrogation checklist
- AI Optimization category added to both checklists
- Building Protocol category added to both checklists

---

## [2.3.0] — 2026-02-12

> Internal iteration — not externally released. Changes incorporated into v2.4.0.

---

## [2.2.0] — 2026-02-11

> Internal iteration — not externally released. Changes incorporated into v2.4.0.

---

## [2.1.0] — 2026-02-10

### Added
- `frameworks/immediate-report.md` — flash alert protocol for first High/Critical finding
- `frameworks/handbrake-protocol.md` — full stop + specialist escalation on Critical findings
- Multi-role Handbrake protocol
- Pre-mortem Integration step in Handbrake flow
- Handbrake Bypass behavior documented

---


## [2.0.0] — 2026-02-05

### Added
- `frameworks/output-format.md` — standard report template with PRECONDITIONS A/B/C
- `examples/architecture-critique.md` — microservices with distributed transaction gap
- `examples/plan-critique.md` — database migration with zero-downtime risk
- `examples/handbrake-example.md` — data pipeline PII multi-role Handbrake

### Changed
- Gate Protocol formalized: 4-step INTERCEPT → ANALYSE → REPORT → GATE flow
- Verification Prompt standardized with exact ✅ / 🔁 / ❌ / `continue` wording

---

## [1.0.0] — 2026-01-28

### Added
- Initial release
- Core adversarial analysis framework
- `frameworks/analysis-framework.md` — 5-step analysis: attack surfaces, assumption challenges, pros/cons, FMEA, edge cases
- `frameworks/security-stride.md` — STRIDE threat model + extended threats
- `frameworks/performance.md` — bottleneck identification and scalability limits
- `frameworks/premortem.md` — forward-looking failure analysis
- `frameworks/vulnerability-patterns.md` — known failure patterns
- `frameworks/product-risks.md` — feature assumptions, launch risks, metrics
- `frameworks/design-ux-risks.md` — dark patterns, WCAG, cognitive load
- `frameworks/leadership-strategy-risks.md` — build vs buy, vendor risk, Type 1/2 decisions
- `frameworks/architecture-risks.md` — distributed systems, coupling, CAP theorem
- `frameworks/data-analytics-risks.md` — pipeline reliability, PII governance, schema drift
- `frameworks/developer-risks.md` — testing gaps, CI/CD risks, dependency management
- Proactive Prevention Mode and automatic trigger detection
