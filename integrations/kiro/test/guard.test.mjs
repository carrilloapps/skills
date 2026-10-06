// Run: node --test integrations/kiro/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const ev = (tool_name, tool_input) => ({ hook_event_name: 'preToolUse', cwd: '/w', tool_name, tool_input });

test('read-only shell → exit 0, silent', () => {
  const r = run(guard, { stdin: ev('execute_bash', { command: 'git log -5' }) });
  assert.deepEqual([r.exit, r.stdout, r.stderr], [0, '', '']);
});
test('Tier 1 write → exit 0 with notice', () => {
  const r = run(guard, { stdin: ev('fs_write', { command: 'create', path: 'src/a.ts' }) });
  assert.equal(r.exit, 0);
  assert.match(r.stdout, /Tier 1/);
});
test('Tier 2 shell → exit 2, reason on stderr', () => {
  const r = run(guard, { stdin: ev('execute_bash', { command: 'terraform destroy' }) });
  assert.equal(r.exit, 2);
  assert.match(r.stderr, /Tier 2 — infrastructure change/);
});
test('MCP (@server/tool) read-only → exit 0', () => assert.equal(run(guard, { stdin: ev('@github/list_issues', {}) }).exit, 0));
test('strict blocks Tier 1', () =>
  assert.equal(run(guard, { stdin: ev('str_replace', { path: 'a.ts' }), env: { DA_GUARD_MODE: 'strict' } }).exit, 2));
test('empty stdin (IDE without event) → exit 0 with notice', () => {
  const r = run(guard, { stdin: '' });
  assert.equal(r.exit, 0);
  assert.match(r.stdout, /no tool event/);
});
test('invalid JSON → exit 2', () => assert.equal(run(guard, { stdin: '{x' }).exit, 2));
