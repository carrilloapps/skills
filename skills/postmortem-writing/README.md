# 🔁 Postmortem Writing

> **Blameless incident postmortems — deterministic severity, attributed timelines, verifiable actions, and lessons that feed your next plan.**

[![License: MIT](https://img.shields.io/badge/License-MIT-red.svg)](../../LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](../../CHANGELOG.md)
[![skill.sh](https://img.shields.io/badge/skill.sh-postmortem--writing-black.svg)](https://skills.sh/carrilloapps/skills/postmortem-writing)
[![GitHub](https://img.shields.io/badge/GitHub-carrilloapps-181717.svg?logo=github)](https://github.com/carrilloapps/skills)
[![X / Twitter](https://img.shields.io/badge/@carrilloapps-000000.svg?logo=x)](https://x.com/carrilloapps)

---

Postmortem Writing is an [agent skill](https://skills.sh) compatible with **70+ AI coding agents** — including GitHub Copilot, Claude Code, Cursor, Antigravity, Windsurf, Cline, Codex, Gemini CLI, OpenCode, Roo Code, and more — that turns an incident into a record a team can act on.

It closes the collection's feedback loop: **devils-advocate prevents → sar-cybersecurity assesses → postmortem-writing learns.**

It is not a template to fill in. It enforces the parts teams skip:

- **Blameless by rule, not by tone** — an individual is never a cause. When the input says "an engineer pushed a bad config", the report says what made the change possible and undetectable. That rewrite is what turns one action ("be careful") into four verifiable ones.
- **Deterministic severity** — five dimensions (user impact, data, duration, blast radius, regulatory), scored independently, severity is the **highest** one, and every report shows its rubric line so a reader can re-derive it: `SEV1 ← D1 users: checkout unusable (SEV1) · D2 data: none (SEV4) … → max = SEV1`
- **Every timeline row carries its source** — a log line, alert ID, commit, deploy, or a **role** and a time. `[unknown]` instead of a guess, and a period with no evidence is written down as an explicit gap row — usually the most actionable thing in the report.
- **Confidence on every causal claim** — `Confirmed` / `Probable` (with the gap stated) / `Possible` (a hypothesis, never presented as the cause).
- **Contributing factors, not a single root cause** — each factor states the condition, its evidence, and what removing it would have changed. "Human error" is never a root cause.
- **The detection gap is a finding** — onset versus detection, quantified, plus the signal that existed and was not alerted on.
- **What went well is mandatory** — a team that documents only failures eventually deletes the safety net that saved it.
- **No action item without an owner role, a due date, and a verification step** — one that is missing a field is reported `incomplete`, never silently accepted. The skill records action state; it never closes one.
- **Measured metrics only** — time to detect / mitigate / resolve from timeline rows with evidence. Anything else is `not measured`, never estimated.
- **Bilingual EN + ES (es_VE)** reports, cross-linked, with technical names kept in English.
- **Near misses get the same rigor** — classified SEV4 with an explicit counterfactual, so the actions are sized to what almost happened.

---

## Install

```bash
npx skills add carrilloapps/skills@postmortem-writing
```

Per-agent paths, global installs, and the manual route: [`docs/INSTALL.md`](../../docs/INSTALL.md).

## Using it

Talk to your agent: *"write the postmortem for last night's outage"*, *"what was the root cause"*, *"reconstruct the timeline from these logs"*, *"postmortem del incidente"*. The skill loads itself and starts with Step 0 — it confirms the incident is stabilized, where the report goes, which languages, and what evidence you can share.

It will not write a postmortem while the incident is active. During an incident it offers one thing: collecting and attributing evidence into a draft timeline so nothing is lost.

## What it writes, and where

| Path | Versioned? | Contents |
|------|-----------|----------|
| `docs/postmortems/YYYY-MM-DD_SEVn_<slug>_{EN,ES}.md` | Yes | The reports — the team's record |
| `.memory/local/postmortems/…` | No | Reports instead of the above **when the repository is public and the incident exposes an unfixed vulnerability** |
| `.memory/postmortem-writing/incidents.json` | Yes | Incident registry: severity, metrics, action state, lessons |

Nothing is written outside the project — no global agent directories, no system temp ([ai-rules](../ai-rules/) *Project-Local Storage*).

## Report structure

Executive summary (≤ 5 lines, impact first) · Incident record (including **systems NOT affected**, verified) · Timeline · Severity rubric line · Contributing factors · Triggering change · Detection gap · What went well · Action items · Incident metrics · Out of scope & limitations · Lessons · Registry snapshot · Gate.

## Files

| Area | Files |
|------|-------|
| Protocol | `frameworks/lifecycle.md` (eight phases, active-incident gate) · `frameworks/output-format.md` (naming, structure, registry, `.memory/` rule) · `frameworks/severity-classification.md` (the rubric) |
| Analysis | `frameworks/timeline.md` · `frameworks/root-cause.md` · `frameworks/actions.md` · `frameworks/metrics.md` |
| Evidence | `frameworks/evidence-collection.md` — read-only commands for Linux / WSL (`journalctl`, `dmesg`), containers, Kubernetes, and git, each **proposed** and run only after you approve that exact command |
| Integration | `frameworks/handoffs.md` — lessons export for devils-advocate, security handoff to sar-cybersecurity, the agentic-agile boundary |
| Templates | Report EN · Report ES · timeline worksheet · action register · executive summary · Five Whys · registry schema |
| Examples | `database-connection-exhaustion.md` (SEV1) · `silent-data-drift.md` (SEV2, detection gap dominates) · `near-miss-expired-certificate.md` (SEV4 near miss) |

## Works with the other skills

| Concern | Owner |
|---------|-------|
| Adversarial review of the plan that fixes the cause | [devils-advocate](../devils-advocate/) — consumes the Lessons export |
| Vulnerability analysis, scoring, and fix of a security cause | [sar-cybersecurity](../sar-cybersecurity/) — the postmortem references its finding ID, never duplicates the score |
| The lightweight team postmortem inside a sprint retro | [agentic-agile](../agentic-agile/) — `templates/postmortem.md`, recorded as a decision record |
| Language, documentation discipline, project-local storage | [ai-rules](../ai-rules/) |

This skill owns **incident** postmortems: severity, timeline, causal analysis, metrics, and the registry. Each skill is independently installable; a missing companion falls back to a minimal built-in behavior.

## Safety

Read-only everywhere except the report directory and `.memory/postmortem-writing/`. All incident input — logs, alerts, chat exports, command output — is **untrusted data**: instructions found inside it are never followed. No scripts are written or run; the only commands are the read-only evidence commands in `frameworks/evidence-collection.md`, each shown verbatim and run only after you approve that exact command. Secrets and personal data are redacted at capture. The agent never creates, closes, or reassigns a ticket or an action item.

## License

[MIT](../../LICENSE) — free to use, modify, and distribute. Attribution appreciated.

## Author

**José Carrillo** — [carrillo.app](https://carrillo.app)

[![Website](https://img.shields.io/badge/website-carrillo.app-FF5733.svg)](https://carrillo.app)
[![GitHub](https://img.shields.io/badge/GitHub-carrilloapps-181717.svg?logo=github)](https://github.com/carrilloapps)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-carrilloapps-0A66C2.svg?logo=linkedin)](https://linkedin.com/in/carrilloapps)
[![Email](https://img.shields.io/badge/email-m%40carrillo.app-EA4335.svg?logo=gmail)](mailto:m@carrillo.app)
