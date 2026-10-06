// Run: node --test integrations/windsurf/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const ev = (agent_action_name, tool_info) => ({
  agent_action_name, trajectory_id: 't1', execution_id: 'e1', timestamp: '2026-10-05T10:00:00Z', model_name: 'm', tool_info,
});

test('read-only command → exit 0 silent', () => {
  const r = run(guard, { stdin: ev('pre_run_command', { command_line: 'cat README.md', cwd: '/w' }) });
  assert.deepEqual([r.exit, r.stdout, r.stderr], [0, '', '']);
});
test('Tier 2 command → exit 2', () => {
  const r = run(guard, { stdin: ev('pre_run_command', { command_line: 'git push origin main', cwd: '/w' }) });
  assert.equal(r.exit, 2);
  assert.match(r.stderr, /Tier 2 — git push/);
});
test('Tier 1 write → exit 0 notice', () => {
  const r = run(guard, { stdin: ev('pre_write_code', { file_path: '/w/src/a.ts', edits: [{ old_string: 'a', new_string: 'b' }] }) });
  assert.equal(r.exit, 0);
  assert.match(r.stdout, /Tier 1/);
});
test('sensitive write → exit 2', () => assert.equal(run(guard, { stdin: ev('pre_write_code', { file_path: '/w/.env', edits: [] }) }).exit, 2));
test('MCP read-only → exit 0', () =>
  assert.equal(run(guard, { stdin: ev('pre_mcp_tool_use', { mcp_server_name: 'gh', mcp_tool_name: 'get_issue', mcp_tool_arguments: {} }) }).exit, 0));
test('pre_read_code → exit 0', () => assert.equal(run(guard, { stdin: ev('pre_read_code', { file_path: '/w/.env' }) }).exit, 0));
test('strict blocks Tier 1', () =>
  assert.equal(run(guard, { stdin: ev('pre_write_code', { file_path: 'a.ts' }), env: { DA_GUARD_MODE: 'strict' } }).exit, 2));
test('unknown action / invalid JSON → exit 2', () => {
  assert.equal(run(guard, { stdin: ev('pre_something_new', {}) }).exit, 2);
  assert.equal(run(guard, { stdin: 'nope' }).exit, 2);
});
