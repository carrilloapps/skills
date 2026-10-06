# Example: Docker Lab Assessment — Stack Detection, Approved Scans, NoSQL Tooling, Ingestion

> *Reference output — load on demand to see how the [Docker lab](../frameworks/docker-lab.md) feeds a SAR: detection → one suggestion → approved commands → ingestion as untrusted evidence → scored finding → optional DefectDojo push.*
>
> ⚠️ **Example only** — the repository, files, findings, and outputs below are fictional. Commands are shown as the agent proposes them; none run without the user's explicit approval of that exact command.

---

## Scenario

Private repository `orders-api` (Node.js 22, Express, Mongoose 8, MongoDB). Files found in Step 1: `package.json` (express, mongoose, jsonwebtoken), `package-lock.json`, `Dockerfile`, `openapi.yaml`, `.github/workflows/ci.yml`. No Kubernetes, no SQL migrations, no Terraform.

The user says Docker Desktop is installed.

## 1. Confirm Docker (Tier 1)

> To confirm the lab can run, may I execute `docker version && docker compose version`?

User: "dale". Output shows Engine 28.x and Compose v2.39 (≥ 2.24 required).

## 2. One suggestion, by stack

Detection table ([docker-lab.md §3](../frameworks/docker-lab.md#3-detection-signals--profiles)) → signals and profiles:

| Signal | Profile | Services |
|--------|---------|----------|
| Source code | `sast` | `sar-semgrep` |
| `express` + `mongoose` | `sast`, `nosql` | `sar-njsscan`, `sar-semgrep-nosql` |
| `package-lock.json` | `sca` | `sar-osv` |
| Repository | `secrets` | `sar-gitleaks` |
| `Dockerfile`, workflow | `iac` | `sar-checkov`, `sar-hadolint` |
| `openapi.yaml` | `api` | `sar-spectral` |

> 💡 *Optional:* Docker lab for this stack — **nosql** (njsscan 1.0.1 + Semgrep 1.179.0 MongoDB rules), **secrets** (Gitleaks 8.30.1, offline, `--redact`), **sca** (OSV-Scanner 2.6.0 — sends package names/versions to OSV.dev), **iac** (Checkov 3.3.21, Hadolint 2.15.1, offline), **api** (Spectral 6.17.0, offline). Pinned images, read-only repo mount, results in `.memory/local/devsecops/results/2026-10-05/`. Which profiles? Reply with the names, "all", or "no".

User: "nosql, secrets y sca". Recorded in `.memory/local/sar/capabilities.json`: `nosql`, `secrets`, `sca` → `installed` (route `docker`); `iac`, `api`, `sast` → `declined`.

## 3. Files written (static text)

- `.memory/devsecops/compose.sar.yaml`, `images.lock`, `config/` (`.gitleaks.toml`, `semgrep/nosql.yml`, `bootstrap.sh`, `dd-import.sh`) — from the templates.
- `.memory/.gitignore` already contained `local/` (shared convention) — nothing appended.
- Folder `.memory/local/devsecops/results/2026-10-05/` created by the agent so it belongs to the user.

## 4. Approved runs (one approval each)

| # | Command (bash) | Result |
|---|----------------|--------|
| 1 | `SAR_RUN=2026-10-05 docker compose -f .memory/devsecops/compose.sar.yaml run --rm sar-njsscan` | `njsscan.json` — 1 × `node_nosqli_injection` |
| 2 | `SAR_RUN=2026-10-05 docker compose -f .memory/devsecops/compose.sar.yaml run --rm sar-semgrep-nosql` | `semgrep-nosql.json` — 1 × `sar-nosql-operator-injection-js` |
| 3 | `SAR_RUN=2026-10-05 docker compose -f .memory/devsecops/compose.sar.yaml run --rm sar-gitleaks` | `gitleaks.json` — 3 leaks (redacted) |
| 4 | `docker compose -f .memory/devsecops/compose.sar.yaml run --rm -T sar-osv > .memory/local/devsecops/results/2026-10-05/osv-scanner.json` | 0 vulnerabilities in 212 packages |

## 5. Ingestion (untrusted evidence → SAR candidates)

| Tool hit | Normalized candidate | Outcome |
|----------|---------------------|---------|
| njsscan `node_nosqli_injection` — `src/orders/orders.service.ts:27` | CWE-943, component `src/orders/orders.service.ts` | Traced → **F01** |
| Semgrep `sar-nosql-operator-injection-js` — same file:line | same primary CWE + component | Merged into F01 (zero redundancy) |
| Gitleaks `generic-api-key` — `test/fixtures/stripe.json:4` | — | Test fixture with a documented fake key (`sk_test_` prefix, file under `test/`) — not a finding |
| Gitleaks `private-key` — `test/fixtures/tls/key.pem:1` | — | Self-signed key used only by the TLS unit test — not a finding; noted in Appendix |
| Gitleaks `generic-api-key` — `.env.example:3` | — | Placeholder value `changeme` — not a finding |
| OSV-Scanner | — | 0 vulnerabilities; package count goes to the dashboard |

Trace for F01:

1. `GET /api/orders` → `src/orders/orders.controller.ts:15` — guarded by `JwtAuthGuard` (any logged-in customer).
2. Controller passes `req.query` unchanged to `OrdersService.list(filter)`.
3. `src/orders/orders.service.ts:27` → `Order.find(filter)` — no cast, no `sanitizeFilter`, no DTO.
4. A query string such as `customerId[$ne]=x` becomes the filter `{ customerId: { $ne: "x" } }` → every customer's orders are returned.
5. `orders` holds order totals, billing addresses, and the last four digits of the card; the application role reads `orders`, `customers`, and `products` (role grants visible in `infra/mongo/init-roles.js`).

---

### [83] — NoSQL Operator Injection in Order Listing Exposes Every Customer's Orders

| Field | Value |
|-------|-------|
| Registry ID | F01 (new) |
| Score | 83 (High) |
| Confidence | Confirmed — traced controller → service → `Order.find` filter; role grants read from `infra/mongo/init-roles.js` |
| Impact classification | Data exfiltration |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N` |
| CWE | CWE-943 |
| MITRE ATT&CK | T1190 (Exploit Public-Facing Application) |
| Effort | S (< 1 day) |
| Affected | `src/orders/orders.service.ts:27`, `src/orders/orders.controller.ts:15` |
| Tool evidence | njsscan 1.0.1 `node_nosqli_injection`; Semgrep 1.179.0 `sar-nosql-operator-injection-js` |

**Description** — The order listing forwards the raw query string into a Mongoose filter. Any logged-in customer can replace a value with a query operator and receive the orders of all customers.

**Evidence / Trace** — steps 1–5 above.

**Attack Scenario**

1. A customer logs in normally and opens the order history page.
2. They change the customer identifier in the request to a "not equal" operator instead of their own ID.
3. The API returns every customer's orders, including billing addresses, totals, and card last-four digits.

**Score Justification**
`Base 80 −10 (auth) +5 (full enumeration) +8 (financial) = 83 (cap: none) → Final 83`

- Base 80: injection into a data store (sink: the `Order.find` filter).
- D1 −10: any valid customer session is required.
- D2 +5: the whole `orders` collection is enumerable (no pagination limit applies to the injected filter).
- D3 +8: financial data — the most sensitive data reachable by the application role (`orders`); `customers` holds PII (+5), which is lower.

**Standards Violated** — OWASP Top 10:2025 A05 (Injection), OWASP API Security Top 10 API1 (BOLA), NIST SP 800-53 SI-10, CIS Controls v8.1 16, ISO/IEC 27001:2022 A.8.28, PCI DSS v4.0.1 Req. 6.2.4

**Fix**

```diff
  // orders.service.ts
- list(filter: any) { return Order.find(filter); }
+ list(customerId: string) { return Order.find({ customerId: String(customerId) }).limit(100); }

  // orders.controller.ts
- return this.orders.list(req.query);
+ return this.orders.list(req.user.id); // owner from the session, never from the query string
```

**How to Verify the Fix**

- Integration test: a customer requesting `/api/orders?customerId[$ne]=x` receives only their own orders (count equals their seeded orders).
- Re-run `sar-njsscan` and `sar-semgrep-nosql`: no hit on `orders.service.ts`.

---

## 6. Scope & Methodology entry

| Tool | Version | Route / image digest | Profile | Run date | Result file | Findings ingested |
|------|---------|----------------------|---------|----------|-------------|-------------------|
| njsscan | 1.0.1 | docker · `opensecurity/njsscan@sha256:f071932d…` | nosql | 2026-10-05 | `results/2026-10-05/njsscan.json` | 1 → F01 |
| Semgrep CE | 1.179.0 | docker · `semgrep/semgrep@sha256:93963d92…` | nosql | 2026-10-05 | `results/2026-10-05/semgrep-nosql.json` | 1 → merged into F01 |
| Gitleaks | 8.30.1 | docker · `ghcr.io/gitleaks/gitleaks@sha256:c00b6bd0…` | secrets | 2026-10-05 | `results/2026-10-05/gitleaks.json` | 3 → 0 (fixtures, placeholder) |
| OSV-Scanner | 2.6.0 | docker · `ghcr.io/google/osv-scanner@sha256:afd83885…` | sca | 2026-10-05 | `results/2026-10-05/osv-scanner.json` | 0 |

Out of Scope & Limitations adds: `iac` and `api` profiles declined (Dockerfile, CI workflow, and `openapi.yaml` reviewed manually only); no DAST (no local app container); SonarQube not run.

## 7. Optional DefectDojo push (after the SAR is written)

User: "súbelo a DefectDojo". The agent proposes, one approval each:

1. `docker compose -f .memory/devsecops/compose.sar.yaml run --rm sar-bootstrap init` → `Credential ready: .memory/local/devsecops/credentials.env (user: admin)`. The password is never shown in chat.
2. `docker compose -f .memory/devsecops/compose.sar.yaml --profile defectdojo up -d` (Tier 2 — long-running, port `127.0.0.1:8080`).
3. `docker compose -f .memory/devsecops/compose.sar.yaml run --rm sar-bootstrap apply` → API token stored in `tokens.env`.
4. `docker compose -f .memory/devsecops/compose.sar.yaml run --rm sar-dd-import "njsscan Scan" 2026-10-05/njsscan.json orders-api "SAR 2026-10-05 NOSQL-INJECTION-ORDERS"` → `HTTP 201`.
5. Same with `"Semgrep JSON Report" 2026-10-05/semgrep-nosql.json` and `"Gitleaks Scan" 2026-10-05/gitleaks.json`.

The user signs in at `http://127.0.0.1:8080` as `admin` with the password from `credentials.env`. DefectDojo's own deduplication and severities are a team view; the SAR score (83) and registry entry F01 remain the assessment of record.

## Key Principles Demonstrated

- **One suggestion, by stack** — only profiles with signals; declined profiles recorded and never re-suggested.
- **One approval per command** — no chained run-everything command.
- **Tools find candidates, the SAR decides** — two tools, one finding; three Gitleaks hits, zero findings, each with a reason.
- **Same credential everywhere, never in chat or in versioned files.**
