# Example: Mass Assignment via Unfiltered Body in Update Operations

> *Reference output — load on demand when analyzing endpoints that pass request bodies directly to ORM/ODM update methods.*
>
> ⚠️ **Example only** — All patterns below are synthetic descriptions of vulnerable code and correct SAR output. They are not real code and must not be executed.

## Scenario

An endpoint calls a database update method with the full request body without filtering which fields the client can modify.

**Finding location:**

- **Files**: `src/users/users.controller.ts` (line 45), `src/users/users.service.ts` (line 30)
- **Route**: `PATCH /users/:id` — authenticated (JWT guard), but no role check
- **Issue**: Request body forwarded directly to database update method without field filtering — all body fields are written to the document, including privilege and financial fields
- **Sensitive schema fields**: The database schema contains privilege-related, financial, and verification fields that are writable through this endpoint
- **Pattern reference**: See `injection-patterns.md` — Mass Assignment / Over-Posting table for detection signatures

## Assessment Trace

1. **Entry point**: `PATCH /users/:id` — authenticated (JWT guard), but no role check.
2. **Input handling**: Full request body passed directly to database update method — no field filtering or allowlist.
3. **Schema analysis**: User schema contains privilege-related fields (access level, admin flag), financial fields, and verification flags — all writable through the endpoint.
4. **Attack scenario**: Authenticated user sends a body with elevated privileges, admin flag, and modified financial data — all fields written without restriction.
5. **IDOR check**: No ownership verification — any authenticated user can modify any other user's profile, including escalating other accounts.
6. **Schema strict mode**: Schema strict mode only prevents fields not defined in the schema — all sensitive fields ARE defined and therefore writable.

## SAR Finding

### [88] — Mass Assignment + IDOR on User Update Endpoint

| Field | Value |
|-------|-------|
| Registry ID | F01 (new) |
| Score | 88 (High) |
| Confidence | Confirmed — traced JWT guard → controller → `findByIdAndUpdate(id, body)`; schema fields verified writable |
| Impact classification | Integrity (privilege escalation) + data exfiltration |
| CVSS v4.0 | `CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N` |
| CWE | CWE-915 (Mass Assignment), CWE-639 (Authorization Bypass Through User-Controlled Key) |
| MITRE ATT&CK | T1098 (Account Manipulation), T1548 (Abuse Elevation Control Mechanism) |
| Effort | S (< 1 day) |
| Affected | `src/users/users.controller.ts:45`, `src/users/users.service.ts:30` |

**Description** — `PATCH /users/:id` writes the full request body to any user record. Any logged-in user can change any account's role, admin flag, or balance.

**Evidence / Trace** — see Assessment Trace above.

**Attack Scenario**

1. A user registers a normal account and logs in.
2. They send `PATCH /users/<their-id>` with an extra admin flag in the body — they are now admin.
3. They send `PATCH /users/<victim-id>` changing the victim's financial fields — no ownership check stops it.

**Score Justification**
`Base 80 −10 (auth) +10 (write + privilege escalation, D2 capped at +10) +8 (financial) = 88 (cap: none) → Final 88`

**Standards Violated** — OWASP Top 10:2025 (A01 Broken Access Control, A06 Insecure Design), ISO/IEC 27001:2022 A.5.15 & A.8.3, NIST SP 800-53 AC-6, PCI DSS v4.0.1 Req. 7, SOC 2 CC6.1

**Fix**

```diff
  async update(@Param('id') id: string, @Body() body: UpdateUserDto, @Req() req) {
-   return this.usersService.update(id, body);
+   if (req.user.id !== id) throw new ForbiddenException();
+   const { displayName, avatarUrl, bio } = body; // allowlist — no role/isAdmin/balance
+   return this.usersService.update(id, { displayName, avatarUrl, bio });
  }
```

Follow-up (not in Effort): separate admin endpoint with an admin guard for privileged fields; audit log with before/after values.

**How to Verify the Fix**

- Integration test: user A patching user B returns 403.
- Integration test: user A patching self with `isAdmin: true` returns 200 and `isAdmin` stays `false` in the database.

## Key Principles Demonstrated

- **Compound vulnerability**: Mass assignment + IDOR identified together, scored on combined impact
- **Schema analysis**: Checked which sensitive fields exist and are writable, not just that the pattern exists
- **Defense-in-depth mitigation**: IDOR fix + field allowlist + DTO + separate admin endpoint

## Cross-Reference

- All mass assignment patterns → see [`frameworks/injection-patterns.md`](../frameworks/injection-patterns.md)
- Compliance standards for access control → see [`frameworks/compliance-standards.md`](../frameworks/compliance-standards.md)
- Scoring rules → see [`frameworks/scoring-system.md`](../frameworks/scoring-system.md)
