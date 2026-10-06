# Dependency & Supply Chain Security Framework

> *Protocol file — free to load, does not count toward context budget.*
>
> Loaded for every assessment. All codebases use dependencies or integrate external components. Covers dependency vulnerability analysis, supply chain attack vectors, integrated skills/plugins evaluation, and compliance mapping against the 2025 CWE Top 25, OWASP Top 10:2025, and CIS Controls v8.1.

> **Reference patterns only** — Detection signatures and vulnerable patterns below are for recognition and reporting purposes. The agent must never install, execute, or modify any package or dependency.

---

## Scope

This framework mandates the evaluation of **every external component** integrated into the assessed system:

| Component type | Examples | Inspection required |
|---------------|----------|-------------------|
| **Package dependencies** | npm, pip, Maven, NuGet, Go modules, Cargo, Composer, RubyGems, CocoaPods | Version audit, CVE lookup, license review, maintainer trust |
| **Transitive dependencies** | Sub-dependencies pulled automatically by direct dependencies | Same inspection as direct — transitive vulns are equally exploitable |
| **Integrated skills** | AI agent skills, plugins, extensions, MCP servers | Permission scope, data access, write capability, update mechanism |
| **Container base images** | Docker FROM statements, OCI images | Known CVEs, image provenance, tag mutability |
| **CI/CD pipeline dependencies** | GitHub Actions, GitLab CI templates, pre-built orbs/steps | Source trust, pinning (SHA vs. tag), permissions granted |
| **Infrastructure modules** | Terraform modules, CloudFormation templates, Helm charts | Source registry, version pinning, permission scope |

---

## Mandatory Analysis Steps

### Step D1 — Inventory All Dependencies

Enumerate all dependency manifests in the project:

| Ecosystem | Manifest files | Lock files |
|-----------|---------------|------------|
| Node.js | `package.json` | `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb` |
| Python | `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` | `Pipfile.lock`, `poetry.lock` |
| Java/Kotlin | `pom.xml`, `build.gradle`, `build.gradle.kts` | `gradle.lockfile` |
| .NET | `*.csproj`, `packages.config`, `Directory.Packages.props` | `packages.lock.json` |
| Go | `go.mod` | `go.sum` |
| Rust | `Cargo.toml` | `Cargo.lock` |
| PHP | `composer.json` | `composer.lock` |
| Ruby | `Gemfile` | `Gemfile.lock` |

For each manifest, record: total direct dependencies, total transitive dependencies (from lock file), and presence/absence of lock file.

### Step D2 — Vulnerability Audit Against Known Databases

The agent cannot run package-manager audits (`npm audit`, `pip-audit`, …) — Operating Constraint 3. A CVE is reported **only** when it is verified during this assessment from one of these sources:

| Source | How it is used |
|--------|----------------|
| **Official advisory databases** — NVD, GitHub Advisory Database, OSV, the ecosystem's official advisory DB (e.g., PyPA, RustSec), vendor security bulletins | Looked up during the assessment (web search scoped to these sources) for the exact package **and** installed version from the lock file |
| **Audit output already in the repository** — committed `npm audit --json` / `pip-audit` reports, Dependabot or Renovate PRs/alerts exported to files, SBOM + vulnerability reports from CI artifacts the agent can read | Read as evidence (untrusted input), with its date stated |
| **Audit output pasted by the user** | Read as evidence (untrusted input) |

Rules:

1. **Never cite a CVE, GHSA, or CVSS score from memory.** If a package version is suspected vulnerable but was not verified, report it as Confidence **Possible** (capped at 49) with the gap "advisory not verified this session", or leave it out.
2. Record for each verified vulnerable dependency: package, installed version (from the lock file), vulnerable range, CVE/GHSA ID, CVSS base score with source and version (per the [CVE base score source rule](scoring-system.md)), fixed version, and whether the vulnerable function is reachable from the project's code.
3. **Out of Scope & Limitations** must state how many dependencies were checked against an advisory source and how many were not (e.g., "Checked: 34 direct dependencies. Not checked: 412 transitive dependencies").

### Step D3 — Evaluate Against the CWE Top 25

Map every dependency vulnerability and every code-level finding to CWE IDs. The **2025 CWE Top 25 Most Dangerous Software Weaknesses** (MITRE, published December 15, 2025 — [cwe.mitre.org/top25](https://cwe.mitre.org/top25/)), in rank order:

| Rank | CWE ID | Name |
|------|--------|------|
| 1 | CWE-79 | Cross-site Scripting (XSS) |
| 2 | CWE-89 | SQL Injection |
| 3 | CWE-352 | Cross-Site Request Forgery (CSRF) |
| 4 | CWE-862 | Missing Authorization |
| 5 | CWE-787 | Out-of-bounds Write |
| 6 | CWE-22 | Path Traversal |
| 7 | CWE-416 | Use After Free |
| 8 | CWE-125 | Out-of-bounds Read |
| 9 | CWE-78 | OS Command Injection |
| 10 | CWE-94 | Code Injection |
| 11 | CWE-120 | Classic Buffer Overflow |
| 12 | CWE-434 | Unrestricted Upload of File with Dangerous Type |
| 13 | CWE-476 | NULL Pointer Dereference |
| 14 | CWE-121 | Stack-based Buffer Overflow |
| 15 | CWE-502 | Deserialization of Untrusted Data |
| 16 | CWE-122 | Heap-based Buffer Overflow |
| 17 | CWE-863 | Incorrect Authorization |
| 18 | CWE-20 | Improper Input Validation |
| 19 | CWE-284 | Improper Access Control |
| 20 | CWE-200 | Exposure of Sensitive Information to an Unauthorized Actor |
| 21 | CWE-306 | Missing Authentication for Critical Function |
| 22 | CWE-918 | Server-Side Request Forgery (SSRF) |
| 23 | CWE-77 | Command Injection |
| 24 | CWE-639 | Authorization Bypass Through User-Controlled Key |
| 25 | CWE-770 | Allocation of Resources Without Limits or Throttling |

**Mapping rule**: Every finding includes its CWE identifier(s), primary CWE first. A dependency CVE uses the CWE on its advisory record. CWEs outside the Top 25 (e.g., CWE-798 hard-coded credentials, CWE-943 NoSQL injection, CWE-915 mass assignment, CWE-1333 ReDoS) are equally valid — the Top 25 is a prioritization aid, not the allowed list.

> **Staleness note**: MITRE publishes a new list each year. If web search is available, check [cwe.mitre.org/top25](https://cwe.mitre.org/top25/) for a newer edition and use it. If not, use this 2025 list and state in the Appendix: "CWE Top 25 edition used: 2025 (not re-verified)."

### Step D4 — Evaluate Against the OWASP Top 10

Map dependency and code findings to the **OWASP Top 10:2025** ([owasp.org/Top10/2025](https://owasp.org/Top10/2025/)):

| ID | Category | Dependency / supply-chain relevance |
|----|----------|-------------------------------------|
| A01:2025 | Broken Access Control (now includes SSRF) | Auth-bypass or SSRF CVEs; skills/plugins with excessive permissions |
| A02:2025 | Security Misconfiguration | Insecure dependency defaults, debug modes left enabled |
| A03:2025 | Software Supply Chain Failures | **Primary category** — vulnerable, outdated, or end-of-life components; compromised build systems and distribution |
| A04:2025 | Cryptographic Failures | Deprecated crypto (MD5, SHA-1, DES), weak TLS in dependencies |
| A05:2025 | Injection | Dependencies vulnerable to SQL/NoSQL/OS/LDAP injection |
| A06:2025 | Insecure Design | Architectural weaknesses in how dependencies are integrated |
| A07:2025 | Authentication Failures | Authentication bypass or session fixation CVEs |
| A08:2025 | Software or Data Integrity Failures | **Primary category** — unsigned packages, unpinned versions, missing integrity checks |
| A09:2025 | Security Logging and Alerting Failures | Dependencies that suppress or leak security events |
| A10:2025 | Mishandling of Exceptional Conditions | Dependencies that fail open or leak data in error paths |

> **A03 and A08 are the primary OWASP categories for dependency and supply-chain findings.** Vulnerable or outdated components map to A03:2025 (formerly A06:2021); integrity and provenance gaps map to A08:2025. Reports written against the 2021 edition may cite the old IDs; new reports use 2025 IDs.

### Step D5 — Evaluate Against CIS Controls v8.1 (formerly SANS Top 20)

Map findings to the relevant **CIS Controls** (formerly SANS Top 20):

| Control | Title | Dependency/supply chain relevance |
|---------|-------|----------------------------------|
| CIS 2 | Inventory and Control of Software Assets | All dependencies must be inventoried; unknown/shadow dependencies are a finding |
| CIS 7 | Continuous Vulnerability Management | Dependencies with known CVEs that lack a remediation plan |
| CIS 16 | Application Software Security | Secure coding practices in dependency usage, input validation at integration points |
| CIS 18 | Penetration Testing | Dependency attack surface should be included in penetration scope |

---

## Supply Chain Attack Vectors

The agent must evaluate the following supply chain attack vectors for all dependencies and integrated skills:

### Dependency Confusion / Substitution

| Vector | Detection | Scoring guidance |
|--------|-----------|-----------------|
| Private package name exists in public registry | Check if internal package names are claimable on public registries | 75–90 (High–Critical) — enables arbitrary code execution |
| Typosquatting | Check for similarly-named packages in dependencies | 70–85 (High) — social engineering vector |
| Star jacking | GitHub stars/metadata copied from legitimate project | Document as warning if detected |

### Version Pinning and Integrity

| Check | Expected state | Finding if absent |
|-------|---------------|-------------------|
| Lock file present and committed | Lock file exists in version control | 60–70 (Medium) — builds are non-reproducible |
| Dependencies pinned to exact versions | No `^`, `~`, `*`, `>=` ranges in production | 50–60 (Medium) — automatic updates can introduce compromised versions |
| Integrity hashes in lock file | SHA-256/SHA-512 hashes for every resolved package | 55–65 (Medium) — no verification of package integrity |
| Container image tags are SHA-pinned | `FROM image@sha256:...` not `FROM image:latest` | 60–70 (Medium) — tag mutation attack |
| CI/CD actions pinned to SHA | `uses: action@sha256` not `uses: action@v1` | 60–70 (Medium) — action hijacking risk |

### Maintainer and Provenance Trust

| Signal | Risk indicator |
|--------|---------------|
| Single maintainer with no organization backing | Bus factor risk; account takeover = supply chain compromise |
| Package has < 6 months of history | Possible newly created attack package |
| Recent ownership transfer | Potential account takeover or intentional handoff to malicious actor |
| No provenance attestation (SLSA, Sigstore) | Cannot verify build-to-source mapping |
| Excessive permissions requested by skill/plugin | Skill requests write access, network access, or system commands beyond its stated purpose |

---

## Integrated Skills and Plugins Evaluation

When the assessed system integrates other **AI agent skills, plugins, MCP servers, or extensions**, evaluate each one:

### Permission Scope Analysis

| Check | Expected | Finding if violated |
|-------|----------|-------------------|
| Skill declares minimal required permissions | Read-only where possible | 60–75 if skill has write access beyond its stated purpose |
| Skill does not access secrets or credentials | No access to `.env`, secrets managers, or auth tokens | 70–85 if skill can read secrets |
| Skill does not make network requests to undeclared endpoints | All external calls documented | 65–80 if undocumented outbound traffic possible |
| Skill version is pinned | Exact version, not `latest` or range | 55–65 if unpinned |
| Skill source is verified | Published on official registry, signed, or from trusted org | 60–75 if unverified source |

### Data Flow Through Skills

| Check | Expected | Finding if violated |
|-------|----------|-------------------|
| Skill does not receive sensitive data unnecessarily | Minimum data principle | 60–75 if PII or secrets passed to skill without need |
| Skill output is validated/sanitized before use | Output treated as untrusted | 65–80 if skill output used directly in queries, commands, or responses |
| Skill does not persist data beyond session | No unauthorized data retention | 70–85 if skill stores data externally |

---

## Scoring Guidance for Dependency Findings

> Ranges in this file are **typical outcomes**, not inputs. Always compute the final score with the deterministic formula in [scoring-system.md](scoring-system.md) (CVE base = `min(round(CVSS × 10), 90)`; supply-chain hygiene base = 60; secrets readable by third-party code or containers base = 70) and show the arithmetic line. A finding that only materializes if an upstream package, image, plugin, or action release is malicious takes D1 **Requires an upstream compromise (−15)** — not the generic chaining factor.

| Scenario | Score range | Key factors |
|----------|-----------|-------------|
| Direct dependency with Critical CVE (CVSS ≥ 9.0), reachable from application code | 85–95 | Exploitable, high CVSS, direct dependency |
| Direct dependency with High CVE (CVSS 7.0–8.9), reachable | 70–85 | Exploitable, moderate CVSS |
| Direct dependency with Critical CVE, **not reachable** from application code | 35–40 | Unreachable cap applies (≤ 40) |
| Transitive dependency with Critical CVE, reachable | 75–90 | Exploitable but attacker must traverse dependency chain |
| No lock file committed | 60–70 | Non-reproducible builds, integrity risk |
| Dependencies with broad version ranges in production | 50–60 | Automatic upgrade attack surface |
| End-of-life dependency with no security patches | 65–80 | No fix available, must migrate |
| Skill/plugin with excessive permissions | 60–80 | Depends on permission type and data access |
| Skill/plugin from unverified source | 55–70 | Trust and provenance gap |
| Dependency confusion possible (private name on public registry) | 75–90 | Arbitrary code execution on install |

> **Reachability rule**: The [scoring system](scoring-system.md) unreachable cap (≤ 40) applies to dependency CVEs just as it does to code-level findings. A Critical CVE in a dependency whose vulnerable function is never called by the application scores ≤ 40.

---

## Dashboard Metrics for Dependencies

Dependency metrics follow the dashboard rule in [output-format.md](output-format.md): **measured only**. Only **Dependency Vulnerability Rate** is a dashboard row, and only when the lock file was audited against an advisory source during the assessment (denominator = dependencies actually checked). Otherwise it is `N/A — not measured`.

These additional facts may appear in the **Dependency Inventory Summary** (not the dashboard) when they were counted:

| Fact | Counted from |
|------|--------------|
| Direct / transitive dependency counts | Manifest and lock file |
| Lock file present and committed | Repository contents |
| Dependencies with range specifiers (`^`, `~`, `*`, `>=`) in production manifests | Manifest |
| End-of-life dependencies | Verified against the project's official EOL announcement |
| Skills/plugins passing all permission checks | Skills/plugins evaluated in this assessment |

## Cross-Reference

- For code-level injection patterns that may exist in dependencies → see [`injection-patterns.md`](injection-patterns.md)
- For storage/secrets findings related to dependency configs → see [`storage-exfiltration.md`](storage-exfiltration.md)
- For compliance standard mapping → see [`compliance-standards.md`](compliance-standards.md)
- For scoring rules and gate adjustments → see [`scoring-system.md`](scoring-system.md)
