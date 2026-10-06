// Run: node --test integrations/cline/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const ev = (tool, parameters) => ({
  taskId: 'abc123', hookName: 'PreToolUse', clineVersion: '3.36.0', timestamp: '1736654400000',
  workspaceRoots: ['/w'], preToolUse: { tool, parameters },
});
const exec = (stdin, env) => {
  const r = run(guard, { stdin, env });
  assert.equal(r.exit, 0);
  return JSON.parse(r.stdout);
};

test('read-only command → cancel false', () =>
  assert.deepEqual(exec(ev('execute_command', { command: 'ls', requires_approval: 'false' })), { cancel: false }));
test('Tier 1 write → continue with context note', () => {
  const o = exec(ev('write_to_file', { path: 'src/config.ts', content: '...' }));
  assert.equal(o.cancel, false);
  assert.match(o.contextModification, /Tier 1/);
});
test('Tier 2 command → cancel with errorMessage', () => {
  const o = exec(ev('execute_command', { command: 'npm publish' }));
  assert.equal(o.cancel, true);
  assert.match(o.errorMessage, /Tier 2 — package publish/);
});
test('toolName key variant is accepted', () =>
  assert.equal(exec({ preToolUse: { toolName: 'replace_in_file', parameters: { path: 'Dockerfile' } } }).cancel, true));
test('use_mcp_tool read-only → cancel false', () =>
  assert.deepEqual(exec(ev('use_mcp_tool', { server_name: 'gh', tool_name: 'list_issues', arguments: '{}' })), { cancel: false }));
test('strict cancels Tier 1', () => assert.equal(exec(ev('write_to_file', { path: 'a.ts' }), { DA_GUARD_MODE: 'strict' }).cancel, true));
test('invalid JSON → cancel', () => assert.equal(exec('{').cancel, true));
