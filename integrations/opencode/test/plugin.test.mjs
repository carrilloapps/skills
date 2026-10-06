// Run: node --test integrations/opencode/test/plugin.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as plugin from '../plugins/devils-advocate-guard.js';

const hooks = await plugin.DevilsAdvocateGuard({ project: {}, client: {}, $: () => {}, directory: '/w', worktree: '/w' });
const before = hooks['tool.execute.before'];
const call = (tool, args) => before({ tool, sessionID: 's', callID: 'c' }, { args });

test('plugin file exports only the plugin', () => assert.deepEqual(Object.keys(plugin), ['DevilsAdvocateGuard']));
test('read-only bash passes', () => assert.doesNotReject(call('bash', { command: 'git diff' })));
test('Tier 1 edit passes', () => assert.doesNotReject(call('edit', { filePath: 'src/a.ts', oldString: 'a', newString: 'b' })));
test('Tier 2 bash throws with reason', () => assert.rejects(call('bash', { command: 'git push' }), /Tier 2 — git push/));
test('Tier 2 write on lockfile throws', () => assert.rejects(call('write', { filePath: 'package-lock.json', content: '{}' }), /Tier 2/));
test('strict blocks Tier 1', async () => {
  process.env.DA_GUARD_MODE = 'strict';
  try {
    await assert.rejects(call('edit', { filePath: 'a.ts' }), /Tier 1/);
  } finally {
    delete process.env.DA_GUARD_MODE;
  }
});
test('malformed call blocks', () => assert.rejects(call(undefined, {}), /could not read/));
