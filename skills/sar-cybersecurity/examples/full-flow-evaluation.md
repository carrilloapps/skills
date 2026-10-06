# Example: Full Flow Evaluation — Apparently Insecure Endpoint

> *Reference output — load on demand when an endpoint appears unprotected at code level but may be secured upstream.*
>
> ⚠️ **Example only** — All code snippets below are synthetic illustrations of vulnerable patterns and correct SAR output. They are not real code and must not be executed.

## Scenario

A route appears to lack authentication upon direct code inspection, and takes the target `userId` from the query string.

```typescript
// src/payments/payments.controller.ts — line 15
@Controller('payments')
export class PaymentsController {
  // No @UseGuards, no AuthMiddleware visible

  @Get('history')
  async getPaymentHistory(@Query('userId') userId: string) {
    return this.paymentsService.getHistory(userId);
  }
}
```

No guard, middleware, or decorator is visible on the controller or route.

## Assessment Trace

1. **Code-level check**: No `@UseGuards()`, no `AuthMiddleware`, no JWT decorator. Appears unprotected.
2. **Module-level check**: `payments.module.ts` does not apply middleware in `configure()`.
3. **Global middleware check**: `main.ts` applies `helmet()` and `cors()`, but no global auth guard.
4. **Infrastructure check**: Kubernetes ingress manifest (`k8s/ingress.yaml`) routes `/payments/*` through an **OAuth2 proxy** sidecar that validates JWT tokens before traffic reaches the pod.
5. **API gateway check**: AWS API Gateway configuration requires a Lambda authorizer on all `/payments/*` routes.
6. **Conclusion**: Authentication is enforced at infrastructure layer (OAuth2 proxy + API Gateway authorizer). The endpoint is protected end-to-end.

## SAR Findings

The trace produces **two** findings. Infrastructure authentication answers *who is calling*; it does not answer *whose data they may read*. Treating the endpoint as "fully mitigated" would hide an IDOR on financial data.

### [83] — IDOR on Payment History: Any Authenticated User Can Read Any User's Payments

| Field | Value |
|-------|-------|
| Registry ID | F04 (new) |
| Score | 83 (High) |
| Confidence | Confirmed — `userId` flows from the query string to the query; the authorizer in `infra/api-gateway.tf` validates the JWT signature only and passes no identity check to the service |
| Impact classification | Data exfiltration |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N` |
| CWE | CWE-639 (Authorization Bypass Through User-Controlled Key), CWE-862 |
| MITRE ATT&CK | T1078 (Valid Accounts) |
| Effort | S (< 1 day) |
| Affected | `src/payments/payments.controller.ts:18`, `src/payments/payments.service.ts` |

**Description** — `GET /payments/history?userId=…` returns the payment history of whatever `userId` the caller supplies. The gateway authorizer guarantees the caller is logged in, but nothing compares the caller's identity with `userId`.

**Evidence / Trace** — steps 1–5 of the Assessment Trace, plus: `getHistory(userId)` filters only by the supplied `userId`; the authorizer policy grants `/payments/*` to any valid token.

**Attack Scenario**

1. An attacker registers a normal account and obtains a valid token.
2. They request their own history, then repeat the request changing `userId` to other values (user IDs are sequential).
3. They collect payment histories of other customers — amounts, dates, merchants, and masked card data.

**Score Justification**
`Base 80 −10 (auth) +5 (full enumeration) +8 (financial) = 83 (cap: none) → Final 83`

- Base 80: broken access control (IDOR) — classified by the sink (missing ownership check).
- D1 −10: a valid account is required (any self-registered user qualifies).
- D2 +5: sequential IDs allow enumeration of every user's history.
- D3 +8: financial data.

**Standards Violated** — OWASP Top 10:2025 (A01 Broken Access Control), ISO/IEC 27001:2022 A.5.15 & A.8.3, NIST SP 800-53 AC-3, PCI DSS v4.0.1 Req. 7, GDPR Art. 32

**Fix**

```diff
  @Get('history')
- async getPaymentHistory(@Query('userId') userId: string) {
-   return this.paymentsService.getHistory(userId);
+ async getPaymentHistory(@Req() req: AuthenticatedRequest) {
+   return this.paymentsService.getHistory(req.user.id);
  }
```

**How to Verify the Fix**

- Integration test: user A's token with `?userId=<B>` returns only A's history (the parameter is ignored), or HTTP 403 if the parameter is kept for admins.
- Integration test: user A's token never returns a row whose `userId` differs from A's.

### [30] — Missing Application-Layer Authentication on Payment History Endpoint

| Field | Value |
|-------|-------|
| Registry ID | W03 (new) |
| Score | 30 (Low — Warning) |
| Confidence | Probable — gap: the live API Gateway configuration was read from IaC, not from the deployed account |
| Impact classification | Data exfiltration (mitigated upstream) |
| CVSS v4.0 | N/A — fully mitigated |
| CWE | CWE-306 (Missing Authentication for Critical Function — defense-in-depth) |
| MITRE ATT&CK | T1078 (Valid Accounts) — relevant only if infrastructure auth is bypassed |
| Effort | S (< 1 day) |
| Affected | `src/payments/payments.controller.ts:15`, `k8s/ingress.yaml`, `infra/api-gateway.tf` |

**Description** — `GET /payments/history` has no application guard. Authentication is enforced only by the OAuth2 proxy sidecar and the API Gateway Lambda authorizer. If the service is ever exposed another way (new ingress, local port-forward, migration), payment data is open to anonymous callers.

**Evidence / Trace** — see Assessment Trace above (code → module → global → ingress → gateway).

**Score Justification**
`Base 80 (gate: fully mitigated by formal centralized control — OAuth2 proxy + gateway authorizer, fixed 30) → Final 30`

**Standards Violated** — OWASP Top 10:2025 (A01 — defense-in-depth gap), ISO/IEC 27001:2022 A.8.5, NIST SP 800-53 AC-3

**Fix**

```diff
+ @UseGuards(JwtAuthGuard)
  @Controller('payments')
  export class PaymentsController {
```

**How to Verify the Fix**

- Integration test calling the pod directly (bypassing ingress) without a token returns 401.

### Alternate Outcome — If Truly Unprotected

If the trace had found **no** infrastructure protection, the two findings collapse into one anonymous IDOR:

`Base 80 +5 (full enumeration) +8 (financial) = 93 (cap: none) → Final 93` — Critical, Confidence Confirmed, CVSS `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N`, standards OWASP Top 10:2025 A01, PCI DSS v4.0.1 Req. 7 & 8, GDPR Art. 32. Roadmap: **This week**.

## Key Principles Demonstrated

- **Full flow evaluation**: Traced from code → module → global → infrastructure → API gateway
- **Net effective security**: Score reflects actual posture, not isolated code appearance
- **Authentication ≠ authorization**: Upstream authentication fully mitigates the anonymous-access risk (W03 = 30) but not the ownership check (F04 = 83) — a gate applies to a finding only for the risk the control actually covers
- **Defense-in-depth recommendation**: Even when protected, recommends an application-layer guard

## Cross-Reference

- Compliance standards for access control → see [`frameworks/compliance-standards.md`](../frameworks/compliance-standards.md)
- Scoring decision flow → see [`frameworks/scoring-system.md`](../frameworks/scoring-system.md)
