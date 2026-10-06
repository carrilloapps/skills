// Run: node --test integrations/claude-code/test/classifier.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { classify, decide } from '../hooks/guard.mjs';

const bash = (command) => ({ tool_name: 'Bash', tool_input: { command } });
const tierOf = (event) => classify(event).tier;

const cases = [
  // read-only → Tier 0 (no decision)
  ['ls -la', 0],
  ['cat README.md | grep version', 0],
  ['rg "TODO" src | head -20', 0],
  ['find . -name "*.md"', 0],
  ['git status', 0],
  ['git log --oneline -10', 0],
  ['git log --format="%h %s"', 0],
  ['git diff HEAD~1', 0],
  ['git branch --list', 0],
  ['git -C repo status', 0],
  ['git tag -l "v*"', 0],
  ['git stash list', 0],
  ['git config --get user.name', 0],
  ['grep -r foo . 2>/dev/null', 0],
  ['sed -n 1,20p file.txt', 1], // sed programs can run commands (e) or write files (w)
  ['Get-ChildItem | Select-Object Name', 0],
  // ordinary writes → Tier 1
  ['git commit -m "fix: typo"', 1],
  ['git add .', 1],
  ['git checkout -- src/app.ts', 1],
  ['npm test', 1],
  ['echo hello > notes.txt', 1],
  ['sed -i s/a/b/ file.txt', 1],
  ['find . -name "*.tmp" -delete', 1],
  ['rm file.txt', 1],
  ['env FOO=1 node script.js', 1],
  ['Set-Content -Path a.txt -Value x', 1],
  // publish / destructive / history → Tier 2
  ['git push origin main', 2],
  ['git push --force origin main', 2],
  ['git reset --hard HEAD~3', 2],
  ['git clean -fdx', 2],
  ['git rebase -i main', 2],
  ['git filter-repo --path secrets.txt --invert-paths', 2],
  ['git branch -D feature/x', 2],
  ['git tag v1.0.0', 2],
  ['rm -rf build', 2],
  ['sudo apt install x', 2],
  ['psql -c "DROP TABLE users"', 2],
  ['terraform apply -auto-approve', 2],
  ['kubectl delete pod web-1', 2],
  ['npm publish', 2],
  ['curl -X DELETE https://api.example.com/users/1', 2],
  ['Remove-Item -Recurse -Force dist', 2],
  // compound → riskiest part
  ['git status && git push', 2],
  ['ls; rm -rf /tmp/x', 2],
  ['echo $(git push)', 2],
  ['FOO=bar git push', 2],
  ['bash -c "rm -rf node_modules"', 2],
];

for (const [command, tier] of cases) {
  test(`Bash: ${command} → Tier ${tier}`, () => assert.equal(tierOf(bash(command)), tier));
}

test('Edit on a normal file → Tier 1', () =>
  assert.equal(tierOf({ tool_name: 'Edit', tool_input: { file_path: 'src/utils/format.ts' } }), 1));

for (const path of ['db/migrations/0007_orders.sql', '.env.production', 'src/auth/jwt.ts',
  'src/payments/charge.ts', 'infra/main.tf', '.github/workflows/ci.yml', 'Dockerfile', 'package-lock.json']) {
  test(`Write on sensitive path ${path} → Tier 2`, () =>
    assert.equal(tierOf({ tool_name: 'Write', tool_input: { file_path: path } }), 2));
}

test('Read-only tools are not classified', () => {
  for (const tool_name of ['Read', 'Grep', 'Glob', 'WebFetch', 'TodoWrite']) {
    assert.equal(tierOf({ tool_name, tool_input: {} }), 0);
  }
});

test('MCP read-only vs write tools', () => {
  assert.equal(tierOf({ tool_name: 'mcp__github__list_issues', tool_input: {} }), 0);
  assert.equal(tierOf({ tool_name: 'mcp__db__query', tool_input: {} }), 1); // query can write (SQL)
  assert.equal(tierOf({ tool_name: 'mcp__github__create_pull_request', tool_input: {} }), 1);
  assert.equal(tierOf({ tool_name: 'mcp__slack__send_message', tool_input: {} }), 1);
});

test('Deterministic: same input, same decision', () => {
  const e = bash('git push --force origin main');
  assert.deepEqual(decide(e, {}), decide(e, {}));
});

test('Tier 0 yields no decision (normal permission flow applies)', () =>
  assert.equal(decide(bash('git status'), {}), null));

test('Tier 1+ yields ask with a tiered reason', () => {
  const d = decide(bash('git push origin main'), {}).hookSpecificOutput;
  assert.equal(d.hookEventName, 'PreToolUse');
  assert.equal(d.permissionDecision, 'ask');
  assert.match(d.permissionDecisionReason, /^Devil's Advocate · Tier 2 — /);
});

test('Strict mode denies only in unattended modes', () => {
  const env = { CLAUDE_PLUGIN_OPTION_STRICT: 'true' };
  const e = { ...bash('git push'), permission_mode: 'bypassPermissions' };
  assert.equal(decide(e, env).hookSpecificOutput.permissionDecision, 'deny');
  assert.equal(decide({ ...e, permission_mode: 'default' }, env).hookSpecificOutput.permissionDecision, 'ask');
  assert.equal(decide(e, {}).hookSpecificOutput.permissionDecision, 'ask');
});

test('Malformed events fail safe to ask', () => {
  for (const e of [null, {}, { tool_name: 'Bash' }, { tool_name: 'Bash', tool_input: { command: 42 } }]) {
    assert.equal(decide(e, {}).hookSpecificOutput.permissionDecision, 'ask');
  }
});

const script = fileURLToPath(new URL('../hooks/guard.mjs', import.meta.url));
const run = (mode, stdin) => spawnSync(process.execPath, [script, mode], { input: stdin, encoding: 'utf8' });

test('CLI: invalid JSON on stdin → ask, exit 0', () => {
  const r = run('pre-tool-use', '{not json');
  assert.equal(r.status, 0);
  assert.equal(JSON.parse(r.stdout).hookSpecificOutput.permissionDecision, 'ask');
});

test('CLI: read-only command → empty stdout, exit 0', () => {
  const r = run('pre-tool-use', JSON.stringify(bash('git status')));
  assert.equal(r.status, 0);
  assert.equal(r.stdout, '');
});

test('CLI: remind prints a short reminder', () => {
  const r = run('remind', JSON.stringify({ hook_event_name: 'UserPromptSubmit', prompt_text: 'hi' }));
  assert.equal(r.status, 0);
  assert.ok(r.stdout.length > 0 && r.stdout.length <= 300, `length ${r.stdout.length}`);
});
