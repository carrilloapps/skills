# Security Policy

## Supported Skills and Versions

This repository publishes three AI agent skills — all are pure Markdown instruction files with no compiled code, binaries, or runtime. Security concerns relate primarily to:

- **Instruction integrity** — guidance should not be misleading, exploitable, or harmful
- **Content accuracy** — risk analysis, security assessment, and behavioral frameworks should reflect current best practices

| Skill | Latest version | Supported |
|-------|---------------|-----------|
| devils-advocate | `main` branch | ✅ Active |
| sar-cybersecurity | `main` branch | ✅ Active |
| ai-rules | `main` branch | ✅ Active |
| Tagged releases (any skill) | Stated version scope | ✅ For their stated version |

---

## Reporting a Vulnerability

If you find a security issue in any skill in this repository — including harmful, misleading, or exploitable guidance — please **do not open a public issue**.

Report it privately by:

1. **GitHub Security Advisories** (preferred): [Report a vulnerability](https://github.com/carrilloapps/skills/security/advisories/new)
2. **Email**: [m@carrillo.app](mailto:m@carrillo.app)

### What to include

- The affected skill and file(s)
- A description of the issue
- Why this is a security concern (e.g., guidance that could lead a user to introduce a vulnerability, or AI instruction that could be exploited via prompt injection)
- A suggested correction if you have one

### Response timeline

| Step | Target |
|------|--------|
| Acknowledgment | Within 72 hours |
| Initial assessment | Within 7 days |
| Resolution or mitigation | Within 30 days |

### Out of scope

- Opinions about whether a given risk rating is too high or too low → use a regular issue
- Suggestions to add new analysis domains, frameworks, or rules → use a feature request
- Markdown rendering issues → use a regular issue

---

Thank you for helping keep these skills accurate and trustworthy.
