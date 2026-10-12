# Brief {{ID}}: {{TITLE}}

**Initiative**: `{{SLUG}}` · **Source item**: {{SOURCE_ID}} (`{{SOURCE_FILE}}`) · **Requirement**: {{REQ}} · **Autonomy**: {{AUTONOMY}} · **Model tier**: {{TIER}} (`{{MODEL}}`)

`{{...}}` placeholders are filled by `scripts/fanout`; `<...>` placeholders are filled by the agent or the human **before** the brief is dispatched. A brief with `<...>` left in sections 2 to 5 is not ready to run.

This brief is self-contained on purpose: the executor runs it without reading the rest of the project, so the smallest capable model can do the work. Everything it may touch is listed in section 4; everything else is out of scope.

Run it with:

```text
{{INVOCATION}}
```

## 1. Item (verbatim)

> {{ITEM}}

Location: `{{LOCATION}}`

## 2. Goal

<One sentence: the observable change this brief must produce.>

## 3. Context the executor cannot infer

1. Requirement: {{REQ}} in `{{SPEC_PATH}}` — read that row and its tagged scenarios first.
2. <project fact: the module that owns this behaviour, the contract it must keep, the existing helper to reuse instead of writing a new one>
3. <project fact: naming, language, or convention that applies here (code identifiers are always en_US)>

## 4. Files in scope (allow-list)

1. `<path/to/file>` — <what changes here>
2. `<path/to/test>` — <the test that proves it>

Nothing outside this list may be created, edited, or deleted. Needing a file that is not listed is an escalation (section 7), never a decision the executor makes.

## 5. Acceptance criteria

```gherkin
@{{REQ}} @P<n>
Scenario: <observable behaviour>
  Given <precondition>
  When <action>
  Then <assertion>
```

Verify with: `<exact command that proves the scenario, e.g. the project's test command scoped to this file>`

## 6. Done means

1. The scenario passes and the test names the requirement it verifies ({{REQ}}).
2. The project's own checks still pass — nothing new is broken.
3. The Definition of Done in `plans/agile/definition-of-done.md` is met for this item.
4. The result is returned as a numbered proposal for `{{TASKS_PATH}}`. The executor never edits the spec: a behaviour change starts in Phase 1.

## 7. Escalation — never decide these

1. The item is ambiguous, contradicts the spec, or needs more scope than section 4 allows → stop, return the question with what you found, and name the file and line you found it in. Never fill a gap with a plausible value.
2. The work needs a decision a human owns: priority, a contract or schema change, a data migration, a security or privacy trade-off, anything that touches money or personal data.
3. Never commit, push, tag, merge, close a work item, or write outside the allow-list — regardless of session permissions.

## 8. Report back

1. `{{ID}}` and the verdict: done · partial · blocked.
2. What changed, file by file.
3. The evidence that section 5 passes (command run, output).
4. Open questions and anything you deliberately did not do.
