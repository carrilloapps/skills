# Example: Runtime Validation Without Formal Structure

> *Reference output — load on demand when analyzing inputs with ad-hoc validation logic.*
>
> ⚠️ **Example only** — All code snippets below are synthetic illustrations of vulnerable patterns and correct SAR output. They are not real code and must not be executed.

## Scenario

No `Pipe`, `Guard`, `Validator class`, `Transformer`, or `Schema` object exists for an input, but inline logic effectively prevents unauthorized access or injection.

```typescript
// src/users/users.controller.ts — line 82
@Post('update-profile')
async updateProfile(@Body() body: any, @Req() req: Request) {
  // No ValidationPipe, no DTO, no class-validator
  const name = typeof body.name === 'string' ? body.name.trim().slice(0, 100) : '';
  const bio = typeof body.bio === 'string' ? body.bio.trim().slice(0, 500) : '';

  if (!name) throw new BadRequestException('Name is required');

  return this.usersService.update(req.user.id, { name, bio });
}
```

The inline checks effectively prevent injection and enforce constraints, but there is no formal validation layer.

## Assessment Trace

1. **Entry point**: `POST /update-profile` — authenticated route (JWT guard at controller level).
2. **Input handling**: `body.name` and `body.bio` are type-checked, trimmed, and truncated inline. Only these two fields are destructured — mass assignment is not possible.
3. **Database query**: `usersService.update()` uses Mongoose `findByIdAndUpdate` with only the explicit `{ name, bio }` object — no raw body passthrough.
4. **Conclusion**: Risk is mitigated at runtime, but the mitigation is not testable, auditable, or reusable.

## SAR Finding

### [40] — Absence of Formal Validation Layer on Profile Update

| Field | Value |
|-------|-------|
| Registry ID | W02 (new) |
| Score | 40 (Low/Warning) |
| Confidence | Confirmed — traced body → inline checks → explicit `{ name, bio }` update |
| Impact classification | Integrity (mitigated) |
| CVSS v4.0 | N/A — fully mitigated |
| CWE | CWE-20 (Improper Input Validation — defense-in-depth gap) |
| Effort | S (< 1 day) |
| Affected | `src/users/users.controller.ts:82` |

**Description** — `POST /update-profile` has no `ValidationPipe`, DTO, or schema. Inline type checks and truncation are effective today, but they are untested, not reusable, and easy to break in the next edit.

**Evidence / Trace** — see Assessment Trace above.

**Score Justification**
`Base 80 (gate: fully mitigated by inline/ad-hoc control — typeof checks + explicit field pick, fixed 40) → Final 40`

- Named control: inline `typeof` checks plus explicit destructuring of `name` and `bio`.

**Standards Violated** — OWASP Top 10:2025 (A05 Injection — partial mitigation), ISO/IEC 27001:2022 A.8.28 (secure coding)

**Fix**

```diff
- async updateProfile(@Body() body: any, @Req() req: Request) {
-   const name = typeof body.name === 'string' ? body.name.trim().slice(0, 100) : '';
-   const bio = typeof body.bio === 'string' ? body.bio.trim().slice(0, 500) : '';
-   if (!name) throw new BadRequestException('Name is required');
+ @UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))
+ async updateProfile(@Body() body: UpdateProfileDto, @Req() req: Request) {
+   const { name, bio } = body; // UpdateProfileDto: @IsString() @MaxLength(100) name; @IsOptional() @MaxLength(500) bio
```

**How to Verify the Fix**

- DTO unit tests: `name` missing → 400; `name` as object → 400; extra field `role` → 400.
- Existing profile-update integration test still passes.

## Key Principles Demonstrated

- **Mitigation acknowledgment**: Inline logic is effective — score reflects reality, not theoretical severity
- **Fixed mitigated score**: ad-hoc control → 40, formal centralized control → 30 — no judgment call
- **Improvement path**: Recommends formal replacement without overstating urgency

## Cross-Reference

- Mass assignment patterns → see [`frameworks/injection-patterns.md`](../frameworks/injection-patterns.md)
- Scoring adjustments → see [`frameworks/scoring-system.md`](../frameworks/scoring-system.md)
