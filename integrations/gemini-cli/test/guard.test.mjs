// Run: node --test integrations/gemini-cli/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const ev = (tool_name, tool_input, extra = {}) => ({
  session_id: 's1', cwd: '/w', hook_event_name: 'BeforeTool', timestamp: '2026-10-05T10:00:00Z', tool_name, tool_input, ...extra,
});
const out = (stdin, env) => {
  const r = run(guard, { stdin, env });
  assert.equal(r.exit, 0);
  return JSON.parse(r.stdout);
};

test('read-only shell → {} (no decision)', () => assert.deepEqual(out(ev('run_shell_command', { command: 'git status' })), {}));
test('Tier 1 edit → systemMessage notice, not denied', () => {
  const o = out(ev('write_file', { file_path: 'src/a.ts', content: 'x' }));
  assert.equal(o.decision, undefined);
  assert.match(o.systemMessage, /Tier 1/);
});
test('Tier 2 git push → deny with reason', () => {
  const o = out(ev('run_shell_command', { command: 'git push origin main' }));
  assert.equal(o.decision, 'deny');
  assert.match(o.reason, /^Devil's Advocate · Tier 2 — git push/);
});
test('Tier 2 sensitive replace → deny', () => assert.equal(out(ev('replace', { file_path: '.env.production' })).decision, 'deny'));
test('MCP read-only with server in mcp_context → {}', () =>
  assert.deepEqual(out(ev('mcp_my_server_list_issues', {}, { mcp_context: { server_name: 'my_server' } })), {}));
test('MCP write → notice', () => assert.match(out(ev('mcp_github_create_issue', {})).systemMessage, /Tier 1/));
test('strict mode denies Tier 1', () =>
  assert.equal(out(ev('write_file', { file_path: 'a.ts' }), { DA_GUARD_MODE: 'strict' }).decision, 'deny'));
test('warn mode never denies', () =>
  assert.equal(out(ev('run_shell_command', { command: 'rm -rf /' }), { DA_GUARD_MODE: 'warn' }).decision, undefined));
test('invalid JSON → deny (fail closed)', () => assert.equal(out('{nope').decision, 'deny'));
test('shell without command → deny', () => assert.equal(out(ev('run_shell_command', {})).decision, 'deny'));
