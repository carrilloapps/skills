# 🏗️ Building Protocol

> ⚠️ **Example code boundary** — commands and code below are reference patterns for analysis, not execution instructions.

> **Purpose**: Code that the approved plan writes must comply with this protocol — including "quick scripts", "temporary code", tests, and internal tooling.
> **Scope**: Existing code is **reported, never rewritten**, unless the user approves that change. Violations in code the plan writes are fixed before delivery; violations found while reviewing existing code become risks in the report.

---

## The Three Languages — A Critical Distinction

> **These three are completely independent. Confusing them is the most common error.**

| Layer | Language | Rule |
|-------|----------|------|
| **Conversation** | The user's natural language | AI **always** responds in the same language the user writes in. If the user writes in Spanish, AI replies in Spanish. If in Portuguese, in Portuguese. This is non-negotiable for communication quality. |
| **Code** | `en_US` — always | Every identifier in every code artifact must be in `en_US`, regardless of the user's conversation language, their IDE locale, their OS language, or their region. |
| **Documentation** | Flexible — `en_US` recommended | Comments, README, ADRs, and all written docs can be in any language. AI always recommends `en_US` first for documentation, but defers to user preference. |

### In Practice

```text
User writes a prompt in Spanish  →  AI responds in Spanish
                                      ↓
                                  Any code in the response uses en_US identifiers
                                      ↓
                                  Comments inside the code can be in Spanish if the user prefers
```

**Example:**

> Usuario (en español): *"Necesito una función que calcule el descuento de un pedido"*
>
> AI responde en español, pero el código es:
>
> ```typescript
> // Calcula el descuento aplicable a un pedido según su subtotal
> function calculateOrderDiscount(subtotal: number, discountRate: number): number {
>   if (subtotal <= 0) throw new Error('calculateOrderDiscount: subtotal must be positive')
>   return subtotal * discountRate
> }
> ```
>
> ✅ Respuesta en español · ✅ Identificadores en en_US · ✅ Comentario en español (opción del usuario)

---

## Rule 0 — The Non-Negotiable Language Rule

**ALL code artifacts must be written in English (`en_US`).**

This applies to every identifier that will appear in source code, configuration, or infrastructure:

| Artifact | en_US required | Examples |
|----------|----------------|---------|
| Variable names | ✅ Always | `userBalance`, `isActive`, `retryCount` |
| Constant names | ✅ Always | `MAX_RETRY_ATTEMPTS`, `DEFAULT_TIMEOUT_MS` |
| Function / method names | ✅ Always | `calculateTax()`, `validateEmail()`, `fetchUserById()` |
| Class / interface / type names | ✅ Always | `UserRepository`, `PaymentProcessor`, `OrderStatus` |
| Enum values | ✅ Always | `PENDING`, `PROCESSING`, `COMPLETED`, `FAILED` |
| File names | ✅ Always | `user-service.ts`, `payment_processor.py`, `OrderRepository.java` |
| Directory names | ✅ Always | `src/`, `services/`, `repositories/`, `utils/` |
| Database column names | ✅ Always | `created_at`, `user_id`, `is_deleted` |
| Database table names | ✅ Always | `users`, `order_items`, `audit_logs` |
| API endpoint paths | ✅ Always | `/api/v1/users`, `/orders/{orderId}/cancel` |
| Environment variable names | ✅ Always | `DATABASE_URL`, `JWT_SECRET`, `MAX_POOL_SIZE` |
| Configuration keys | ✅ Always | `server.port`, `logging.level`, `cache.ttl` |
| Git branch names | ✅ Always | `feat/user-authentication`, `fix/payment-timeout` |
| Commit messages | ✅ Always | `feat: add retry logic to payment processor` |
| Script names | ✅ Always | `migrate-database.sh`, `seed-users.py`, `deploy.ps1` |
| CLI flags / arguments | ✅ Always | `--dry-run`, `--verbose`, `--output-format` |
| Log messages | ✅ Always | `"User {userId} authenticated successfully"` |
| Error messages (code-level) | ✅ Always | `throw new Error("Payment amount must be positive")` |
| Test names / describe blocks | ✅ Always | `"should return 404 when user not found"` |
| SQL queries | ✅ Always | `SELECT id, created_at FROM users WHERE is_active = true` |
| Infrastructure / IaC identifiers | ✅ Always | `aws_s3_bucket.user_uploads`, `kubernetes_deployment.api_server` |
| Docker image tags | ✅ Always | `payment-service:1.2.0`, `api-gateway:latest` |

**Documentation is the only exception.** See [Documentation Language Strategy](#documentation-language-strategy) below.

---

## Documentation Language Strategy

### Default Recommendation: Start in en_US

> When AI generates documentation, it will **always first recommend en_US** as the primary documentation language.
> Rationale: en_US maximizes reach, enables global collaboration, and is the universal technical standard.

When the user requests documentation in another language, AI will:

1. Acknowledge and comply with the user's choice
2. Generate documentation in the requested language
3. Append a note: *"💡 Recommendation: Consider maintaining an `en_US` version as the canonical reference for international contributors."*

### Documentation artifacts where language is flexible

| Documentation type | Recommendation | User override |
|-------------------|----------------|---------------|
| README.md | en_US | ✅ Any language |
| Inline code comments | en_US | ✅ Any language |
| API documentation (OpenAPI, JSDoc, etc.) | en_US | ✅ Any language |
| Architecture Decision Records (ADRs) | en_US | ✅ Any language |
| CHANGELOG.md | en_US | ✅ Any language |
| Error messages shown to end users (UI) | User's locale | ✅ Required per locale |
| User-facing strings | i18n key in en_US, value in locale | ✅ Required per locale |

### i18n Code Pattern (always en_US keys, locale values)

```typescript
// ✅ Correct — key in en_US, value in user's language
const messages = {
  'error.payment.insufficient_funds': 'Fondos insuficientes',
  'error.payment.card_expired': 'Tarjeta vencida',
  'success.order.placed': 'Pedido realizado con éxito',
}

// ❌ Wrong — key in Spanish, breaks tooling and searchability
const messages = {
  'error.pago.fondos_insuficientes': 'Fondos insuficientes',
}
```

---

## Naming Conventions

Apply the following conventions consistently based on language and context:

### Universal (language-agnostic)

| Identifier type | Convention | Example |
|----------------|-----------|---------|
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_CONNECTIONS`, `API_BASE_URL` |
| Environment variables | `SCREAMING_SNAKE_CASE` | `DATABASE_URL`, `JWT_SECRET` |
| File names (kebab) | `kebab-case` | `user-service.ts`, `order-repository.py` |
| File names (snake) | `snake_case` | `payment_processor.py` (Python convention) |
| Database tables | `snake_case` plural | `users`, `order_items`, `audit_logs` |
| Database columns | `snake_case` | `created_at`, `user_id`, `is_deleted` |
| URL paths / endpoints | `kebab-case` | `/api/v1/order-items`, `/user-profiles` |
| Git branches | `kebab-case` with prefix | `feat/`, `fix/`, `chore/`, `hotfix/` |

### By Language

| Language | Variables & functions | Classes & types | Interfaces |
|----------|-----------------------|-----------------|------------|
| TypeScript / JavaScript | `camelCase` | `PascalCase` | `PascalCase` (no `I` prefix) |
| Python | `snake_case` | `PascalCase` | `PascalCase` |
| Java / Kotlin | `camelCase` | `PascalCase` | `PascalCase` |
| Go | `camelCase` (unexported), `PascalCase` (exported) | `PascalCase` | `PascalCase` |
| C# | `camelCase` (private), `PascalCase` (public) | `PascalCase` | `IPascalCase` |
| Rust | `snake_case` | `PascalCase` | `PascalCase` |
| SQL | `snake_case` | N/A | N/A |
| Shell / Bash | `snake_case` (local), `SCREAMING_SNAKE_CASE` (env) | N/A | N/A |

### Naming Quality Rules

```text
✅ Names must be intention-revealing
   userAge        ← clear
   d              ← unclear (days? data? distance?)

✅ Names must be pronounceable
   customerRecord ← pronounceable
   cstmrRcrd      ← not pronounceable, never abbreviate arbitrarily

✅ Names must be searchable
   MAX_CLASSES_PER_STUDENT  ← searchable
   7                        ← magic number, not searchable

✅ Boolean names must read as questions
   isActive, hasPermission, canRetry, shouldNotify

✅ Function names must describe what they DO
   calculateInterest()   ← verb + noun
   interest()            ← unclear — gets? calculates? formats?

✅ Avoid encodings and noise words
   userList → users
   theUser  → user
   userData → user (or userProfile if disambiguation needed)
```

---

## Code Quality Standards

### SOLID Principles (enforced on every class/module generated)

| Principle | Rule | Violation example |
|-----------|------|------------------|
| **S** — Single Responsibility | One class / function does one thing | `UserService` handles auth + email + billing |
| **O** — Open/Closed | Extend behavior without modifying existing code | `if type == 'visa' ... if type == 'amex'` — add `if` for every card type |
| **L** — Liskov Substitution | Subtypes must be substitutable for their base type | Overriding method to throw `NotImplemented` |
| **I** — Interface Segregation | Don't force clients to depend on methods they don't use | `IAnimal` with `swim()` forced on `Dog` |
| **D** — Dependency Inversion | Depend on abstractions, not concretions | `new MySQLDatabase()` inside business logic |

### DRY / KISS / YAGNI

```text
✅ DRY  — Don't Repeat Yourself
   Extract duplicated logic into a shared function/module.
   Never copy-paste logic that may need to change in sync.

✅ KISS — Keep It Simple, Stupid
   Prefer the simplest solution that correctly handles the requirements.
   Complexity must be justified by a real requirement, not anticipated ones.

✅ YAGNI — You Aren't Gonna Need It
   Do not add functionality until it is actually required.
   Never generate speculative abstractions or extension points "just in case".
```

### Function / Method Rules

```text
✅ Functions must:
   - Do ONE thing (single responsibility at function level)
   - Be ≤ 20 lines (if longer, extract)
   - Have ≤ 3 parameters (use a config object/DTO if more needed)
   - Return a value OR have a side effect — never both implicitly
   - Be pure where possible (same input → same output, no hidden state)

❌ Functions must NOT:
   - Accept boolean flags that alter the function's behavior (split into two functions)
   - Have a different behavior based on the type of input (use polymorphism or overloading)
   - Mix business logic with I/O (separate concerns)
```

### Error Handling Standards

```typescript
// ✅ Always handle errors explicitly
async function fetchUser(userId: string): Promise<User> {
  if (!userId) {
    throw new Error('fetchUser: userId is required')
  }
  try {
    return await userRepository.findById(userId)
  } catch (error) {
    logger.error('fetchUser: failed to fetch user', { userId, error })
    throw new UserNotFoundError(userId)
  }
}

// ❌ Never swallow errors silently
async function fetchUser(userId: string) {
  try {
    return await userRepository.findById(userId)
  } catch (e) {
    // silently swallowed — the worst pattern
  }
}
```

---

## Security-by-Default Rules

These rules are **mandatory** on every code generation, not optional:

### Secrets & Credentials

```text
❌ NEVER hardcode secrets, API keys, passwords, or tokens in source code
❌ NEVER commit .env files containing real values
❌ NEVER log secrets, tokens, or passwords — even partially
❌ NEVER include secrets in error messages returned to clients

✅ ALWAYS load secrets from environment variables or a secrets manager
✅ ALWAYS provide a .env.example with placeholder values and comments
✅ ALWAYS document which environment variables are required in README
```

### Input Validation

```text
✅ Validate ALL external input at the boundary (API, CLI, file, event)
✅ Use allowlists, not denylists, for input validation
✅ Validate type, format, range, and length
✅ Sanitize before storing or rendering
✅ Use parameterized queries — NEVER string-concatenate SQL
```

### Authentication & Authorization

```text
✅ Authenticate before serving any non-public resource
✅ Authorize after authentication — check permissions per operation
✅ Apply principle of least privilege to service accounts and roles
✅ Set expiry on all tokens and sessions
✅ Use secure, httpOnly, sameSite cookies for web session tokens
```

### Dependencies

```text
✅ Pin dependency versions in lockfiles (package-lock.json, poetry.lock, go.sum)
✅ Scan dependencies for CVEs before use (npm audit, pip-audit, Dependabot)
✅ Prefer well-maintained packages with active security response
✅ Document the reason for every direct dependency added
```

---

## Definition of Done — Code Block Checklist

Before any code block is considered complete and deliverable:

```markdown
### Code
1. All identifiers are in en_US
2. Naming follows conventions for the target language (table above)
3. No magic numbers — all literals extracted to named constants
4. No dead code, commented-out code blocks, or TODO stubs left in
5. Functions are ≤ 20 lines; if not, extraction is justified
6. No function has > 3 parameters without a config object
7. Error handling is explicit — no empty catch blocks

### Security
1. No secrets, tokens, or credentials in source
2. All external input is validated at the boundary
3. No string-concatenated SQL, shell commands, or filesystem paths
4. Dependencies used are pinned and have no known critical CVEs

### Documentation
1. Public functions / classes have a docstring or JSDoc comment (en_US recommended)
2. Complex logic has an inline comment explaining WHY, not WHAT
3. Any non-obvious architectural decision has a comment referencing the ADR or reason

### Tests
1. The happy path is tested
2. At least one error/edge case is tested
3. Test names describe the expected behavior in plain language (en_US)

### Maintainability
1. No hardcoded configuration — values are externalized to env or config
2. No circular imports
3. New code does not duplicate existing logic
```

---

## Reference Implementation

The following TypeScript function satisfies **all Definition of Done criteria simultaneously**. Use it as a model when reviewing generated code.

```typescript
// ✅ Full DoD compliance — annotated reference
import { logger } from '../shared/logger'
import { UserNotFoundError, ValidationError } from '../shared/errors'
import { userRepository } from './user-repository'
import type { User } from './user.types'

// Named constants — no magic numbers
const MAX_USER_ID_LENGTH = 36
const USER_ID_FORMAT = /^[0-9a-f-]{36}$/

/**
 * Retrieves a user by their unique identifier.
 * Returns the user if found; throws UserNotFoundError if not.
 *
 * @param userId - UUID of the user to retrieve (must match UUID v4 format)
 * @throws {ValidationError} if userId is missing or malformed
 * @throws {UserNotFoundError} if no user exists with the given id
 */
export async function fetchUserById(userId: string): Promise<User> {
  // Input validated at the boundary — not assumed valid
  if (!userId || userId.length > MAX_USER_ID_LENGTH) {
    throw new ValidationError('fetchUserById: userId is required and must be a valid UUID')
  }
  if (!USER_ID_FORMAT.test(userId)) {
    throw new ValidationError(`fetchUserById: userId format invalid — expected UUID v4, received "${userId}"`)
  }

  try {
    const user = await userRepository.findById(userId)

    if (!user) {
      // Explicit not-found — never return null silently
      throw new UserNotFoundError(userId)
    }

    return user
  } catch (error) {
    if (error instanceof UserNotFoundError || error instanceof ValidationError) {
      throw error  // Re-throw domain errors as-is
    }
    // Infrastructure error — log context before re-throwing
    logger.error('fetchUserById: unexpected repository error', { userId, error })
    throw new Error(`fetchUserById: failed to retrieve user ${userId}`)
  }
}
```

**DoD satisfied:**

- ✅ All identifiers in en_US (`fetchUserById`, `userId`, `MAX_USER_ID_LENGTH`, `USER_ID_FORMAT`)
- ✅ No magic numbers (constants `MAX_USER_ID_LENGTH = 36`, `USER_ID_FORMAT`)
- ✅ Input validated at boundary (null, length, format checks)
- ✅ No empty catch — errors logged with context and re-thrown
- ✅ No string-concatenated SQL — uses repository abstraction
- ✅ Single responsibility — only fetches by ID, no side effects
- ✅ ≤ 20 lines of logic
- ✅ 1 parameter — rule is ≤ 3 (consolidate to config object if more needed)
- ✅ Public function has JSDoc comment
- ✅ Returns typed value or throws typed exception (no null return)

```typescript
// ✅ Corresponding test — DoD for test dimension
import { fetchUserById } from './fetch-user-by-id'
import { userRepository } from './user-repository'
import { UserNotFoundError, ValidationError } from '../shared/errors'

describe('fetchUserById', () => {
  it('should return the user when a valid userId is provided', async () => {
    const mockUser = { id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', name: 'Alice' }
    jest.spyOn(userRepository, 'findById').mockResolvedValue(mockUser)

    const result = await fetchUserById('a1b2c3d4-e5f6-7890-abcd-ef1234567890')
    expect(result).toEqual(mockUser)
  })

  it('should throw ValidationError when userId is empty', async () => {
    await expect(fetchUserById('')).rejects.toThrow(ValidationError)
  })

  it('should throw ValidationError when userId format is invalid', async () => {
    await expect(fetchUserById('not-a-uuid')).rejects.toThrow(ValidationError)
  })

  it('should throw UserNotFoundError when repository returns null', async () => {
    jest.spyOn(userRepository, 'findById').mockResolvedValue(null)
    await expect(fetchUserById('a1b2c3d4-e5f6-7890-abcd-ef1234567890')).rejects.toThrow(UserNotFoundError)
  })
})
```

---

## Anti-Patterns — Never Generate

The following patterns are prohibited in any AI-generated code:

```text
❌ Magic numbers
   if status == 3          ← What is 3?
   if status == OrderStatus.PROCESSING  ← ✅

❌ Commented-out code
   // const oldCalculation = price * 0.9
   Delete dead code — version control preserves history.

❌ TODO stubs in deliverable code
   // TODO: handle this edge case
   Either handle it now or create a tracked issue. Not in deliverable code.

❌ God objects / God functions
   A class or function that does everything.
   Split into focused, single-responsibility units.

❌ Primitive obsession
   Money as float        → use a Money value object or integer cents
   Status as raw string  → use an enum
   User as a plain dict  → use a typed class/interface

❌ Boolean parameters that change behavior
   sendEmail(user, true)   ← What does true mean?
   sendWelcomeEmail(user)  ← ✅ (separate function)
   sendPasswordResetEmail(user) ← ✅

❌ Returning null / undefined for "not found" in typed languages
   Use Option<T>, Result<T, E>, or throw a typed exception.
   Document and handle the "not found" case explicitly.

❌ Catch-all exception handlers without re-throw or logging
   catch (e) {}  ← The worst pattern in existence.

❌ Non-English identifiers
   const nombreUsuario = ...  ← ❌
   const userName = ...       ← ✅
```

---

## Building Protocol Violation Severity

When a Building Protocol violation is found during code review or analysis, use this table to assign a consistent severity rating:

| Violation | Severity | Rationale |
|-----------|----------|-----------|
| Hardcoded secret, token, or credential in source code | 🔴 Critical | Immediate security incident risk; may already be in git history |
| Empty catch block (`catch (e) {}`) on a data, money, or security path | 🔴 Critical | Silently swallows failures where they cause data loss, wrong charges, or bypassed checks |
| Empty catch block elsewhere in production code | 🟠 High | Hides errors; makes incidents hard to diagnose |
| SQL string concatenation / unparameterized query | 🔴 Critical | SQL injection vector |
| No input validation on public API / external boundary | 🔴 Critical | Injection, overflow, and type confusion attack surface |
| Non-English identifiers in production code | 🟡 Medium | Breaks global collaboration, tooling searchability, and AI analysis accuracy |
| Magic number used in business logic | 🟡 Medium | Incorrect value is invisible to reviewers; breaks future changes |
| Boolean parameter that changes function behavior | 🟢 Low | Caller has no way to know what `true` means without reading the implementation |
| Function > 20 lines without justification | 🟢 Low | Single responsibility violation; harder to test |
| God object / function doing more than one thing | 🟡 Medium | Violates SOLID S; changes cascade unpredictably |
| `TODO` stub left in deliverable code | 🟡 Medium | Untracked work; silently becomes permanent |
| Commented-out code blocks | 🟡 Medium | Dead code; confuses reviewers; version control preserves history |
| Missing docstring/JSDoc on public function | 🟡 Medium | Integration friction; invisible contract |
| Non-English identifiers in test code only | 🟡 Medium | Lower production risk but breaks consistency and searchability |
| Magic number in test data (not business logic) | 🟢 Low | No runtime risk; minor readability issue |
| Non-standard commit message format | 🟢 Low | Reduces changelog quality; does not affect functionality |

> **Rule**: Violations are reported with the severity above, under the same 5-risk limit as every other risk. **Style violations (🟡/🟢) never displace correctness or security risks** — when the list is full, they go to *Also considered, not material*. A 🔴 violation moves to Tier 3 only if its severity depends on facts only the user has.

---

## Commit Message Convention (Conventional Commits)

All commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <short description in en_US, imperative mood>

[optional body — explain WHY, not WHAT]

[optional footer — BREAKING CHANGE, closes #issue]
```

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `perf` | Performance improvement |
| `refactor` | Code change that is neither a fix nor a feature |
| `test` | Adding or modifying tests |
| `docs` | Documentation only |
| `chore` | Build process, dependency updates, tooling |
| `ci` | CI/CD pipeline changes |
| `hotfix` | Critical production fix |

```text
✅ feat(auth): add JWT refresh token rotation
✅ fix(payment): prevent double charge on network retry
✅ refactor(user-service): extract email validation to shared utility
✅ docs(api): add OpenAPI spec for orders endpoint

❌ fixed stuff
❌ cambios en el servicio de pagos
❌ WIP
```

---

## Building Protocol Activation

The Building Protocol activates **whenever code is generated or reviewed** — it is not a switch to turn on. It does not apply to pure analysis conversations where no code artifact is produced or examined.

It applies to:

- Every code snippet generated in chat
- Every file the approved plan creates or modifies (existing code outside the plan is reported, not rewritten)
- Every script, migration, configuration, or infrastructure definition
- Every test generated
- Every example code in documentation

When a user writes in a non-English language (e.g., Spanish) and requests code, AI will:

1. **Respond in the user's language** — the explanation, analysis, and conversation are always in the user's language
2. **Write all new identifiers in en_US** — variable names, function names, constants, file names, etc.
3. **Keep comments in the user's preferred language** — if the user writes in Spanish, inline comments may be in Spanish
4. **State the rule once if not obvious**: *"Los identificadores del código están en en_US según el Building Protocol. Los comentarios pueden estar en el idioma que prefieras."*
