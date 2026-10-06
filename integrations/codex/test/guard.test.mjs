// Run: node --test integrations/codex/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const ev = (tool_name, tool_input) => ({ hook_event_name: 'PreToolUse', tool_use_id: 'call_1', cwd: '/w', tool_name, tool_input });
const exec = (stdin, env) => {
  const r = run(guard, { stdin, env });
  assert.equal(r.exit, 0);
  return r.stdout ? JSON.parse(r.stdout).hookSpecificOutput : null;
};

test('read-only Bash → no output', () => assert.equal(exec(ev('Bash', { command: 'rg TODO src' })), null));
test('Tier 1 Bash → no output (Codex has no ask)', () => assert.equal(exec(ev('Bash', { command: 'npm test' })), null));
test('Tier 2 Bash → deny', () => {
  const o = exec(ev('Bash', { command: 'git reset --hard HEAD~2' }));
  assert.equal(o.hookEventName, 'PreToolUse');
  assert.equal(o.permissionDecision, 'deny');
  assert.match(o.permissionDecisionReason, /Tier 2 — git reset --hard/);
});
test('apply_patch on a migration → deny', () =>
  assert.equal(exec(ev('apply_patch', { command: '*** Begin Patch\n*** Update File: db/migrations/0002_users.sql\n@@\n-a\n+b\n*** End Patch' })).permissionDecision, 'deny'));
test('apply_patch on a normal file → no output', () =>
  assert.equal(exec(ev('apply_patch', { command: '*** Begin Patch\n*** Update File: src/util.ts\n@@\n*** End Patch' })), null));
test('MCP write → no output by default, deny in strict', () => {
  assert.equal(exec(ev('mcp__github__create_issue', {})), null);
  assert.equal(exec(ev('mcp__github__create_issue', {}), { DA_GUARD_MODE: 'strict' }).permissionDecision, 'deny');
});
test('warn mode never denies', () => assert.equal(exec(ev('Bash', { command: 'git push' }), { DA_GUARD_MODE: 'warn' }), null));
test('invalid JSON → deny', () => assert.equal(exec('{x').permissionDecision, 'deny'));
