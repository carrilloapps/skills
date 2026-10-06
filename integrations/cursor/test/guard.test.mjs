// Run: node --test integrations/cursor/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const base = { conversation_id: 'c1', generation_id: 'g1', workspace_roots: ['/w'] };
const exec = (mode, stdin, env) => {
  const r = run(guard, { args: [mode], stdin, env });
  assert.equal(r.exit, 0);
  return JSON.parse(r.stdout);
};

test('shell read-only → {}', () =>
  assert.deepEqual(exec('shell', { ...base, hook_event_name: 'beforeShellExecution', command: 'ls -la', cwd: '/w' }), {}));
test('shell git push → ask with messages', () => {
  const o = exec('shell', { ...base, command: 'git push --force', cwd: '/w' });
  assert.equal(o.permission, 'ask');
  assert.match(o.user_message, /Tier 2/);
  assert.equal(o.agent_message, o.user_message);
});
test('mcp read-only → {}', () =>
  assert.deepEqual(exec('mcp', { ...base, tool_name: 'list_issues', tool_input: '{}', mcp_server_name: 'github' }), {}));
test('mcp write → ask', () =>
  assert.equal(exec('mcp', { ...base, tool_name: 'merge_pull_request', tool_input: '{"n":1}', mcp_server_name: 'github' }).permission, 'ask'));
test('preToolUse Write (path key) → ask', () =>
  assert.equal(exec('tool', { ...base, tool_name: 'Write', tool_input: { path: 'src/a.ts' } }).permission, 'ask'));
test('preToolUse StrReplace on auth → ask Tier 2', () =>
  assert.match(exec('tool', { ...base, tool_name: 'StrReplace', tool_input: { path: 'src/auth/session.ts' } }).user_message, /Tier 2/));
test('preToolUse tool_input as JSON string', () =>
  assert.equal(exec('tool', { ...base, tool_name: 'Delete', tool_input: '{"path":"notes.md"}' }).permission, 'ask'));
test('strict → deny', () => assert.equal(exec('shell', { ...base, command: 'npm i' }, { DA_GUARD_MODE: 'strict' }).permission, 'deny'));
test('warn → {}', () => assert.deepEqual(exec('shell', { ...base, command: 'git push' }, { DA_GUARD_MODE: 'warn' }), {}));
test('invalid JSON → ask', () => assert.equal(exec('shell', '{oops').permission, 'ask'));
