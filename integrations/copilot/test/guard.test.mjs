// Run: node --test integrations/copilot/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const cli = (toolName, args) => ({ timestamp: 1704614600000, cwd: '/w', toolName, toolArgs: JSON.stringify(args) });
const exec = (stdin, env) => {
  const r = run(guard, { stdin, env });
  assert.equal(r.exit, 0);
  return r.stdout ? JSON.parse(r.stdout) : null;
};

test('CLI read-only bash → no output', () => assert.equal(exec(cli('bash', { command: 'git status' })), null));
test('CLI view → no output', () => assert.equal(exec(cli('view', { path: '.env' })), null));
test('CLI git push → ask, top-level and hookSpecificOutput', () => {
  const o = exec(cli('bash', { command: 'git push', description: 'publish' }));
  assert.equal(o.permissionDecision, 'ask');
  assert.match(o.permissionDecisionReason, /Tier 2/);
  assert.equal(o.hookSpecificOutput.permissionDecision, 'ask');
});
test('CLI edit → ask Tier 1', () => assert.match(exec(cli('edit', { path: 'src/a.ts' })).permissionDecisionReason, /Tier 1/));
test('CLI create on workflow → ask Tier 2', () =>
  assert.match(exec(cli('create', { path: '.github/workflows/ci.yml' })).permissionDecisionReason, /Tier 2/));
test('toolArgs as object is accepted', () =>
  assert.equal(exec({ toolName: 'bash', toolArgs: { command: 'rm -rf dist' } }).permissionDecision, 'ask'));
test('VS Code format (tool_name/tool_input)', () =>
  assert.equal(exec({ tool_name: 'run_in_terminal', tool_input: { command: 'npm publish' } }).hookSpecificOutput.permissionDecision, 'ask'));
test('strict mode → deny', () =>
  assert.equal(exec(cli('edit', { path: 'a.ts' }), { DA_GUARD_MODE: 'strict' }).permissionDecision, 'deny'));
test('warn mode → no output', () => assert.equal(exec(cli('bash', { command: 'git push' }), { DA_GUARD_MODE: 'warn' }), null));
test('malformed toolArgs → ask', () => assert.equal(exec({ toolName: 'bash', toolArgs: '{bad' }).permissionDecision, 'ask'));
test('invalid JSON → ask', () => assert.equal(exec('nope').permissionDecision, 'ask'));
