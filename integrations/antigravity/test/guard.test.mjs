// Run: node --test integrations/antigravity/test/guard.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { run, scriptPath } from '../../core/test-util.mjs';

const guard = scriptPath(import.meta.url, '../hooks/devils-advocate/guard.mjs');
const ev = (name, args) => ({
  toolCall: { name, args }, stepIdx: 19, conversationId: 'c1', workspacePaths: ['/w'], transcriptPath: '/t', modelName: 'gemini',
});
const exec = (stdin, env) => {
  const r = run(guard, { stdin, env });
  assert.equal(r.exit, 0);
  return JSON.parse(r.stdout);
};

const raw = (stdin, env) => run(guard, { stdin, env });
test('git status → no decision (never "allow"; agy permissions decide)', () => {
  const r = raw(ev('run_command', { CommandLine: 'git status' }));
  assert.equal(r.exit, 0);
  assert.equal(r.stdout.trim(), '');
});
test('warn mode → no decision even for Tier 2, notice on stderr (SAR W01)', () => {
  const r = raw(ev('run_command', { CommandLine: 'git push --force' }), { DA_GUARD_MODE: 'warn' });
  assert.equal(r.exit, 0);
  assert.equal(r.stdout.trim(), '');
  assert.match(r.stderr, /Tier 2/);
});
test('the adapter never emits allow', () => {
  for (const c of ['git status', 'ls', 'npm test', 'git push']) {
    for (const env of [{}, { DA_GUARD_MODE: 'warn' }, { DA_GUARD_MODE: 'strict' }]) {
      assert.doesNotMatch(raw(ev('run_command', { CommandLine: c }), env).stdout, /"allow"/);
    }
  }
});
test('command not known to be read-only → ask', () => assert.equal(exec(ev('run_command', { CommandLine: 'npm test' })).decision, 'ask'));
test('Tier 1 write_to_file → ask', () => {
  const o = exec(ev('write_to_file', { TargetFile: '/w/src/a.ts', CodeContent: 'x' }));
  assert.equal(o.decision, 'ask');
  assert.match(o.reason, /Tier 1/);
});
test('Tier 2 run_command → force_ask', () =>
  assert.equal(exec(ev('run_command', { CommandLine: 'git push --force' })).decision, 'force_ask'));
test('Tier 2 replace_file_content on .env → force_ask', () =>
  assert.equal(exec(ev('replace_file_content', { TargetFile: '/w/.env' })).decision, 'force_ask'));
test('strict → deny', () =>
  assert.equal(exec(ev('write_to_file', { TargetFile: 'a.ts' }), { DA_GUARD_MODE: 'strict' }).decision, 'deny'));
test('invalid JSON → force_ask', () => assert.equal(exec('{').decision, 'force_ask'));
