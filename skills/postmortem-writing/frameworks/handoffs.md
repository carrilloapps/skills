# Handoffs and Integrations

This skill owns **incident** postmortems. Everything adjacent belongs to another skill, and the handoff is a reference, never a copy.

## devils-advocate — the Lessons export

The Lessons section is written so devils-advocate can cite it as evidence when a later plan touches the same component. Each lesson is a risk with a trigger condition.

```markdown
## Lessons

| # | Lesson | Triggers on a plan that… | Evidence |
|---|--------|--------------------------|----------|
| L-1 | A per-instance resource limit must be validated against the shared backend maximum, because instance count multiplies it | changes a pool size, replica count, or any per-instance limit on a service sharing a database | INC-003 CF-1 |
| L-2 | An alert on a downstream symptom detects later than one on the saturating resource | adds or changes alerting for a resource-constrained service | INC-003 detection gap, 7 min |
| L-3 | A staging environment with a looser limit than production cannot reach the production failure mode | relies on staging to validate a capacity or limit change | INC-003 CF-4 |
```

Rules:

1. A lesson is **generalized** — it must apply beyond this incident, or it is a contributing factor, not a lesson.
2. It names the **trigger condition**, so devils-advocate knows when to raise it.
3. It cites the incident and factor, so the claim is checkable.
4. No lesson contradicts another report's lesson without saying so.

When devils-advocate is not installed, the Lessons section still exists — it is the input to whoever reviews the next change.

## sar-cybersecurity — security causes

When the cause is a security defect (an exposed credential, an injection, a missing authorization check, a vulnerable dependency that was exploited), the postmortem **records and references**; it does not analyze.

| The postmortem does | sar-cybersecurity does |
|---------------------|------------------------|
| Records the incident, timeline, severity, impact, actions | Scores the vulnerability, traces reachability, writes the fix diff and verification |
| References the finding ID (`F03`) and the SAR report file | Owns the finding registry entry and its status |
| States in Out of scope that the vulnerability analysis is SAR's | Produces the remediation roadmap for the defect |

```markdown
**Security cause** — the credential was readable in the repository since 2026-07-02. The
vulnerability analysis, scoring, and fix belong to the SAR assessment: finding `F03` in
`docs/security/2026-10-06_SECRETS-IN-SOURCE-CONTROL_EN.md`. This postmortem covers the
incident (exposure window, detection, rotation) and the process actions.
```

If no SAR exists yet, say so and make it an action: `A-0n | prevent | Run a security assessment of the credential-handling path | Owner: security role | Verification: SAR finding registry contains an entry for this path`.

Never duplicate a CVSS score, a CVE claim, or a vulnerability score in a postmortem. Two numbers for the same defect will diverge.

## agentic-agile — the boundary

| This skill | agentic-agile |
|------------|---------------|
| **Incident** postmortems: production or near-miss events, severity rubric, metrics, registry | The **team retro** postmortem inside a sprint: `templates/postmortem.md`, recorded as a decision record |
| Writes to `docs/postmortems/` and `.memory/postmortem-writing/` | Writes to `plans/decisions/` |
| Triggered by an incident | Triggered by a ceremony |

They do not overlap: a sprint retro note about a process friction is not an incident report, and an incident report is not a retro item. When an incident produces a process change the team must adopt, the action item points at agentic-agile's capture flow so it lands in `plans/agile/`.

When agentic-agile is installed, action items that become tickets go through its delivery flow (plan → tickets, with the exact payload approved) — this skill drafts, it never writes to a tracker.

## ai-rules — language and storage

Documentation language, project-local storage, and the `.memory/` convention follow ai-rules (`frameworks/memory-convention.md` owns the convention). Standalone, the same rules apply, stated in this skill's constraints 4, 6, and 15.

## Capability slots

This skill needs no tooling of its own. Evidence comes from what the team already has, and the agent asks rather than assumes:

| Slot | Used for | If absent |
|------|----------|-----------|
| Log platform | Timeline rows, error counts | Ask for excerpts; record the gap in Out of scope |
| Metrics / dashboards | Onset, saturation, retention limits | TTD may be `not measured` |
| Alerting | Detection time, alert IDs | Detection attributed to a role instead |
| Chat / incident channel | Decisions and their times | Attributed statements are unavailable; say so |
| Tracker | Action item publication | Draft the items in the report only |
| Version control | Change analysis | Ask which change shipped and when |

No slot is required to produce a postmortem. Every missing slot becomes an honest limitation and, where it hurt the analysis, a `detect` action.
