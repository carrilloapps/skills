# Requirements checklist: <Initiative title>

**Initiative**: `<initiative-kebab>` · **Spec**: [`spec.md`](spec.md)

Unit tests for the spec's English: each item asks whether the **requirement** is well written — never whether the code works. Status: ✅ satisfied · ❌ gap (fix the spec or add an open question) · ⚠️ partial. At least 80% of items reference a spec section or ID in `Ref`. Required before Phase 2 under `check-spec --strict`.

Dimensions: completeness · clarity · consistency · measurability · coverage · edge cases · non-functional · dependencies/assumptions · ambiguities/conflicts.

| ID | Question | Dimension | Ref | Status |
|----|----------|-----------|-----|--------|
| CHK001 | Is every functional requirement stated as observable behavior? | completeness | <FR-###> | <✅ / ❌ / ⚠️> |
| CHK002 | Does every vague adjective ("fast", "secure", "simple") have a number or criterion? | clarity | <section> | <✅ / ❌ / ⚠️> |
| CHK003 | Do requirements and scenarios use the same terms for the same things? | consistency | <FR-###> | <✅ / ❌ / ⚠️> |
| CHK004 | Is every success criterion measurable and mapped to a scenario? | measurability | <SC-###> | <✅ / ❌ / ⚠️> |
| CHK005 | Does every FR have at least one scenario tagged `@FR-###`? | coverage | <FR-###> | <✅ / ❌ / ⚠️> |
| CHK006 | Are the applicable edge-case categories answered or marked N/A with a reason? | edge cases | 1.2 | <✅ / ❌ / ⚠️> |
| CHK007 | Are performance, security, accessibility, and observability needs stated or explicitly out of scope? | non-functional | 1.5 | <✅ / ❌ / ⚠️> |
| CHK008 | Is every assumption labelled Verified / Documented / Proposed? | dependencies/assumptions | 1.5 | <✅ / ❌ / ⚠️> |
| CHK009 | Are contradictions between stakeholders shown as open questions, not resolved silently? | ambiguities/conflicts | Open questions | <✅ / ❌ / ⚠️> |

Add items per initiative; IDs are never reused.
