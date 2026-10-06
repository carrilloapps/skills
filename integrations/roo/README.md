# Devil's Advocate — Roo Code (advisory)

No blocking pre-tool hook was found in Roo Code's documentation, so this integration is a **rule file only**: it is always in the model's context but cannot stop a tool call.

## Install

```bash
mkdir -p .roo/rules
cp integrations/roo/rules/devils-advocate.md .roo/rules/
```

For an actual stop, keep Roo's auto-approve settings **off** for write, execute, and MCP actions — Roo then asks you before each one.

## Uninstall

Delete `.roo/rules/devils-advocate.md`.

## Sources

- Roo custom instructions / rules: <https://docs.roocode.com/features/custom-instructions>
