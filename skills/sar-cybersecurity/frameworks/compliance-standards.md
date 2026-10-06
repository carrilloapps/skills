# Compliance Standards Reference

> *Domain framework — load when relevant.*
>
> Load this framework when the assessment requires the **full expanded reference** or lesser-known standards (ISA/IEC 62443, FedRAMP, FIPS 140-3, etc.). The agent can map findings to well-known standards (OWASP, CWE, NIST, ISO 27001, PCI-DSS, GDPR, MITRE ATT&CK) from training knowledge without loading this file. Load it when the target operates under specific regulatory requirements or when the Standard Selection Guide is needed for precise mapping.

## Minimum Required Baseline

The following standards represent the **minimum required baseline** for every SAR — they are explicitly not exhaustive. The agent must also apply any additional standards, frameworks, regulations, or industry-specific best practices that its cybersecurity expertise identifies as relevant to the specific assessment context.

Map every finding to all applicable standards and justify each selection.

| Standard          | Domain                                                                       |
|-------------------|------------------------------------------------------------------------------|
| ISO/IEC 27001:2022 | ISMS establishment, implementation, certification (Annex A: 93 controls)    |
| ISO/IEC 27002:2022 | Security controls catalog and implementation guidance                       |
| NIST CSF 2.0      | Govern · Identify · Protect · Detect · Respond · Recover                      |
| NIST SP 800-53    | Comprehensive security & privacy controls                                    |
| CIS Controls v8.1 (formerly SANS Top 20) | Prioritized defensive actions — software inventory, vulnerability management, application security (18 controls) |
| COBIT             | IT governance aligned with business objectives                               |
| OWASP Top 10:2025 | Critical web application security risks                                     |
| SOC 2             | Service provider data security (Trust Services Criteria)                    |
| ISO/IEC 27017     | Cloud-specific information security controls                                 |
| CSA STAR          | Cloud provider security posture assessment and certification                 |
| FedRAMP           | US government cloud authorization standard                                   |
| PCI-DSS           | Payment card data protection                                                 |
| HIPAA             | Healthcare data confidentiality and integrity                                |
| SOX               | Financial IT controls and electronic records integrity                       |
| ISA/IEC 62443     | OT/ICS cybersecurity for industrial automation and critical infrastructure   |
| GDPR              | EU personal data privacy and security by design                              |
| ISO/IEC 27701     | Privacy Information Management System (PIMS), extends ISO 27001             |
| FIPS 140-3        | Cryptographic module security validation                                     |
| MITRE ATT&CK      | Threat modeling via real-world adversary tactics and techniques              |
| NIST SP 800-171   | Protecting Controlled Unclassified Information (CUI)                        |
| CWE Top 25 (2025) | Most dangerous software weaknesses — mandatory CWE mapping for every finding |

## Expanded Standards Reference

These descriptions provide the full context for when and why each standard applies. They are the minimum expected knowledge base for the agent:

- **ISO/IEC 27001**: Used to establish, implement, and certify an Information Security Management System (ISMS) at the organizational level.
- **ISO/IEC 27002**: Serves as a detailed catalog of security controls and best practices to implement the requirements of ISO 27001.
- **NIST CSF (Cybersecurity Framework)**: Used to understand, manage, and reduce cybersecurity risks based on six core functions in version 2.0 (February 2024): Govern, Identify, Protect, Detect, Respond, and Recover. Govern covers cybersecurity strategy, roles, policy, and supply-chain risk management.
- **NIST SP 800-53**: Provides an exhaustive catalog of security and privacy controls, originally used by the US government but adopted globally for its rigor.
- **CIS Controls (SANS Top 20)**: A prioritized guide of defensive actions (formerly known as SANS Top 20, now CIS Controls v8.1 with 18 controls) to protect against the most common cyberattacks. For dependency and supply chain security, the most relevant controls are: CIS 2 (Inventory and Control of Software Assets), CIS 7 (Continuous Vulnerability Management), CIS 16 (Application Software Security), and CIS 18 (Penetration Testing).
- **COBIT**: Used for corporate IT governance, aligning security and technology objectives with business objectives.
- **OWASP Top 10**: The de facto standard used by development teams to identify and mitigate the 10 most critical security risks in web applications and APIs.
- **SOC 2 (Type 2)**: Used to audit and demonstrate that a service provider (e.g., SaaS) securely manages customer data based on the Trust Services Criteria: security, availability, processing integrity, confidentiality, and privacy.
- **ISO/IEC 27017**: Provides information security controls specific to the use and provision of cloud computing services.
- **CSA STAR**: Used to evaluate and certify the security posture of cloud service providers.
- **FedRAMP**: The mandatory standard for evaluating and authorizing cloud products and services intended for use by US government agencies.
- **PCI-DSS**: Strictly mandatory for protecting cardholder data during processing, storage, and transmission in payment gateways and merchants.
- **HIPAA**: Used in the healthcare sector (primarily in the US, but as a global reference) to protect the confidentiality and integrity of patient medical information.
- **SOX (Sarbanes-Oxley)**: A financial law whose IT provisions enforce strict controls over electronic records and prevent corporate fraud.
- **ISA/IEC 62443**: Used to ensure cybersecurity in industrial automation and control systems (OT/ICS), protecting critical infrastructure such as power plants and factories.
- **GDPR**: The European regulation (and global gold standard) used to guarantee the privacy and protection of citizens' personal data, requiring security by design.
- **ISO/IEC 27701**: An extension of ISO 27001 used to establish a Privacy Information Management System (PIMS).
- **FIPS 140-3**: Used to validate and certify the security level of cryptographic modules (hardware or software) that protect sensitive information.
- **MITRE ATT&CK**: A technical knowledge base used for threat modeling, simulating the real tactics and techniques used by cybercriminals to attack networks.
- **NIST SP 800-171**: Used to protect Controlled Unclassified Information (CUI) residing in contractor and non-governmental institution networks.
- **CWE Top 25 (2025)**: The 25 most dangerous software weaknesses published by MITRE (full ranked list in [dependency-supply-chain.md](dependency-supply-chain.md)). Every finding in the SAR must include its CWE identifier(s) — including CWEs outside the Top 25, such as CWE-798 (hard-coded credentials), CWE-287 (improper authentication), or CWE-943 (NoSQL injection). Dependency CVEs use the CWE on their advisory record.

## Standard Selection Guide

When mapping findings to standards, use this decision flow:

| If the finding involves... | Always map to... | Also consider... |
|---------------------------|-----------------|-----------------|
| Web application vulnerability | OWASP Top 10, CIS Controls | NIST SP 800-53 |
| Cloud misconfiguration | ISO 27017, CSA STAR | FedRAMP (if US gov) |
| Personal data exposure | GDPR, ISO 27701 | HIPAA (if healthcare) |
| Payment data | PCI-DSS | SOX (if financial) |
| Access control failure | ISO 27001, NIST CSF | SOC 2 |
| Cryptographic weakness | FIPS 140-3 | NIST SP 800-53 |
| Industrial control system | ISA/IEC 62443 | NIST CSF |
| Threat modeling needed | MITRE ATT&CK | NIST SP 800-53 |
| Government / CUI data | NIST SP 800-171, FedRAMP | ISO 27001 |
| Vulnerable dependency / outdated package | OWASP Top 10:2025 (A03), CWE Top 25, CIS Controls (2, 7) | NIST SP 800-53 |
| Supply chain integrity (unsigned, unpinned, unverified) | OWASP Top 10:2025 (A03, A08), CIS Controls (2, 16) | NIST CSF 2.0 (GV.SC) |
| Integrated skill/plugin with excessive permissions | CWE-269, CWE-862, OWASP Top 10:2025 (A01) | ISO 27001:2022 A.8.2 |
| Any code-level finding | CWE ID (Top 25 when applicable) | OWASP Top 10:2025 |

## Control ID Reference — use current editions

Cite **current edition** control IDs. ISO/IEC 27001:2013 Annex A numbering (`A.9`, `A.10`, `A.12`, `A.14`…) was withdrawn with the 2022 revision and must not be used in new reports.

| Finding type | ISO/IEC 27001:2022 Annex A | Replaces 2013 |
|--------------|----------------------------|---------------|
| Access control policy, missing authorization, IDOR | A.5.15 Access control · A.8.3 Information access restriction | A.9.1, A.9.4 |
| Access rights, over-privileged accounts | A.5.18 Access rights · A.8.2 Privileged access rights | A.9.2 |
| Weak or exposed authentication information, hard-coded secrets | A.5.17 Authentication information · A.8.5 Secure authentication | A.9.2.4, A.9.4.2 |
| Missing or weak encryption | A.8.24 Use of cryptography | A.10.1 |
| Injection, insecure code | A.8.28 Secure coding · A.8.26 Application security requirements | A.14.2 |
| Insecure SDLC, missing security testing | A.8.25 Secure development life cycle · A.8.29 Security testing in development and acceptance | A.14.2 |
| Misconfiguration, insecure defaults | A.8.9 Configuration management | — (new in 2022) |
| Data exposure to unauthorized parties, public storage | A.8.12 Data leakage prevention · A.5.12 Classification of information | — (new) / A.8.2 |
| PII in logs or non-production data | A.8.11 Data masking · A.8.15 Logging | — (new) / A.12.4 |
| Vulnerable dependency, unpatched component | A.8.8 Management of technical vulnerabilities | A.12.6 |
| Resource exhaustion, missing capacity limits | A.8.6 Capacity management | A.12.1.3 |
| Cloud service misconfiguration | A.5.23 Information security for use of cloud services | — (new) |

Other editions to cite: **OWASP Top 10:2025**, **CWE Top 25 (2025)**, **NIST CSF 2.0**, **NIST SP 800-53 Rev. 5**, **CIS Controls v8.1**, **PCI DSS v4.0.1**. If a newer edition is published, the agent may use it after verifying it on the issuer's official site, and states the edition in the Appendix.

---

## CWE Lookup Table (verified)

Official names from the MITRE CWE Research View (CWE-1000) CSV, downloaded from cwe.mitre.org on 2026-10-05. Use these names verbatim. A CWE not listed here is verified on cwe.mitre.org during the assessment, or cited by number only (`CWE-1234`) — never named from memory.

| CWE | Official name |
|-----|---------------|
| CWE-20 | Improper Input Validation |
| CWE-22 | Improper Limitation of a Pathname to a Restricted Directory ('Path Traversal') |
| CWE-77 | Improper Neutralization of Special Elements used in a Command ('Command Injection') |
| CWE-78 | Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection') |
| CWE-79 | Improper Neutralization of Input During Web Page Generation ('Cross-site Scripting') |
| CWE-89 | Improper Neutralization of Special Elements used in an SQL Command ('SQL Injection') |
| CWE-90 | Improper Neutralization of Special Elements used in an LDAP Query ('LDAP Injection') |
| CWE-94 | Improper Control of Generation of Code ('Code Injection') |
| CWE-95 | Improper Neutralization of Directives in Dynamically Evaluated Code ('Eval Injection') |
| CWE-113 | Improper Neutralization of CRLF Sequences in HTTP Headers ('HTTP Request/Response Splitting') |
| CWE-116 | Improper Encoding or Escaping of Output |
| CWE-117 | Improper Output Neutralization for Logs |
| CWE-183 | Permissive List of Allowed Inputs |
| CWE-200 | Exposure of Sensitive Information to an Unauthorized Actor |
| CWE-209 | Generation of Error Message Containing Sensitive Information |
| CWE-250 | Execution with Unnecessary Privileges |
| CWE-256 | Plaintext Storage of a Password |
| CWE-259 | Use of Hard-coded Password |
| CWE-260 | Password in Configuration File |
| CWE-269 | Improper Privilege Management |
| CWE-276 | Incorrect Default Permissions |
| CWE-284 | Improper Access Control |
| CWE-285 | Improper Authorization |
| CWE-287 | Improper Authentication |
| CWE-288 | Authentication Bypass Using an Alternate Path or Channel |
| CWE-295 | Improper Certificate Validation |
| CWE-306 | Missing Authentication for Critical Function |
| CWE-307 | Improper Restriction of Excessive Authentication Attempts |
| CWE-311 | Missing Encryption of Sensitive Data |
| CWE-312 | Cleartext Storage of Sensitive Information |
| CWE-319 | Cleartext Transmission of Sensitive Information |
| CWE-321 | Use of Hard-coded Cryptographic Key |
| CWE-326 | Inadequate Encryption Strength |
| CWE-327 | Use of a Broken or Risky Cryptographic Algorithm |
| CWE-328 | Use of Weak Hash |
| CWE-330 | Use of Insufficiently Random Values |
| CWE-345 | Insufficient Verification of Data Authenticity |
| CWE-346 | Origin Validation Error |
| CWE-347 | Improper Verification of Cryptographic Signature |
| CWE-352 | Cross-Site Request Forgery (CSRF) |
| CWE-359 | Exposure of Private Personal Information to an Unauthorized Actor |
| CWE-362 | Concurrent Execution using Shared Resource with Improper Synchronization ('Race Condition') |
| CWE-377 | Insecure Temporary File |
| CWE-400 | Uncontrolled Resource Consumption |
| CWE-427 | Uncontrolled Search Path Element |
| CWE-434 | Unrestricted Upload of File with Dangerous Type |
| CWE-441 | Unintended Proxy or Intermediary ('Confused Deputy') |
| CWE-494 | Download of Code Without Integrity Check |
| CWE-502 | Deserialization of Untrusted Data |
| CWE-522 | Insufficiently Protected Credentials |
| CWE-523 | Unprotected Transport of Credentials |
| CWE-532 | Insertion of Sensitive Information into Log File |
| CWE-538 | Insertion of Sensitive Information into Externally-Accessible File or Directory |
| CWE-539 | Use of Persistent Cookies Containing Sensitive Information |
| CWE-552 | Files or Directories Accessible to External Parties |
| CWE-565 | Reliance on Cookies without Validation and Integrity Checking |
| CWE-601 | URL Redirection to Untrusted Site ('Open Redirect') |
| CWE-611 | Improper Restriction of XML External Entity Reference |
| CWE-614 | Sensitive Cookie in HTTPS Session Without 'Secure' Attribute |
| CWE-639 | Authorization Bypass Through User-Controlled Key |
| CWE-640 | Weak Password Recovery Mechanism for Forgotten Password |
| CWE-668 | Exposure of Resource to Wrong Sphere |
| CWE-693 | Protection Mechanism Failure |
| CWE-732 | Incorrect Permission Assignment for Critical Resource |
| CWE-749 | Exposed Dangerous Method or Function |
| CWE-759 | Use of a One-Way Hash without a Salt |
| CWE-770 | Allocation of Resources Without Limits or Throttling |
| CWE-776 | Improper Restriction of Recursive Entity References in DTDs ('XML Entity Expansion') |
| CWE-778 | Insufficient Logging |
| CWE-798 | Use of Hard-coded Credentials |
| CWE-829 | Inclusion of Functionality from Untrusted Control Sphere |
| CWE-862 | Missing Authorization |
| CWE-863 | Incorrect Authorization |
| CWE-915 | Improperly Controlled Modification of Dynamically-Determined Object Attributes |
| CWE-918 | Server-Side Request Forgery (SSRF) |
| CWE-922 | Insecure Storage of Sensitive Information |
| CWE-943 | Improper Neutralization of Special Elements in Data Query Logic |
| CWE-1004 | Sensitive Cookie Without 'HttpOnly' Flag |
| CWE-1021 | Improper Restriction of Rendered UI Layers or Frames |
| CWE-1104 | Use of Unmaintained Third Party Components |
| CWE-1188 | Initialization of a Resource with an Insecure Default |
| CWE-1236 | Improper Neutralization of Formula Elements in a CSV File |
| CWE-1275 | Sensitive Cookie with Improper SameSite Attribute |
| CWE-1321 | Improperly Controlled Modification of Object Prototype Attributes ('Prototype Pollution') |
| CWE-1333 | Inefficient Regular Expression Complexity |
| CWE-1336 | Improper Neutralization of Special Elements Used in a Template Engine |
| CWE-1357 | Reliance on Insufficiently Trustworthy Component |
| CWE-1392 | Use of Default Credentials |
| CWE-1393 | Use of Default Password |
| CWE-1395 | Dependency on Vulnerable Third-Party Component |

## MITRE ATT&CK Lookup Table (verified)

Enterprise technique names verified on attack.mitre.org on 2026-10-05. Cite a technique only when the attack scenario actually uses it; a technique not listed here is verified on attack.mitre.org during the assessment or omitted.

| Technique | Name | Typical SAR use |
|-----------|------|-----------------|
| T1190 | Exploit Public-Facing Application | Injection, auth bypass, SSRF on an internet-facing service |
| T1078 | Valid Accounts | Abuse of legitimate or default credentials |
| T1098 | Account Manipulation | Privilege escalation via mass assignment / role change |
| T1136 | Create Account | Unauthorized account creation |
| T1110 | Brute Force | Missing rate limiting on authentication |
| T1212 | Exploitation for Credential Access | Flaw that discloses credentials |
| T1528 | Application access token theft — official name at [attack.mitre.org/techniques/T1528](https://attack.mitre.org/techniques/T1528/) | Token leakage (logs, URLs, storage) |
| T1539 | Steal Web Session Cookie | Missing `HttpOnly`/`Secure`, XSS-driven cookie theft |
| T1550.001 | Use Alternate Authentication Material: Application Access Token | Replay of leaked API/OAuth tokens |
| T1552.001 | Unsecured Credentials: Credentials In Files | Secrets in source, configs, images |
| T1552.004 | Unsecured Credentials: Private Keys | Committed or world-readable private keys |
| T1059 | Command and Scripting Interpreter | Command / code injection |
| T1059.004 | Command and Scripting Interpreter: Unix Shell | Shell injection in scripts and hooks |
| T1068 | Exploitation for Privilege Escalation | Local privilege escalation via a flaw |
| T1195.001 | Supply Chain Compromise: Compromise Software Dependencies and Development Tools | Malicious dependency, action, image, or plugin |
| T1195.002 | Supply Chain Compromise: Compromise Software Supply Chain | Tampered release / build pipeline |
| T1525 | Implant Internal Image | Poisoned container image in a registry |
| T1609 | Container Administration Command | Abuse of exposed container runtime / exec |
| T1610 | Deploy Container | Abuse of an exposed Docker/Kubernetes API |
| T1611 | Escape to Host | Privileged containers, host mounts |
| T1530 | Data from Cloud Storage | Public or over-permissive buckets |
| T1213 | Data from Information Repositories | Wikis, trackers, document stores exposed |
| T1005 | Data from Local System | File read via path traversal / LFI |
| T1083 | File and Directory Discovery | Directory listing, path enumeration |
| T1119 | Automated Collection | Bulk enumeration through an API flaw |
| T1567 | Exfiltration Over Web Service | Data exfiltrated through a legitimate web service |
| T1565.001 | Data Manipulation: Stored Data Manipulation | Integrity violations (write/modify findings) |
| T1557 | Adversary-in-the-Middle | Missing TLS / certificate validation |
| T1185 | Browser Session Hijacking | Session fixation / hijacking |
| T1499 | Endpoint Denial of Service | Availability-only findings (capped at 49) |
