// Run: node --test integrations/core/core.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { classifyTool, classifyEdit, patchPaths, shouldBlock, guardMode, safeClassify } from './classifier.mjs';
import { drifted } from '../sync-core.mjs';

test('every adapter copy matches core/classifier.mjs (run node integrations/sync-core.mjs)', () =>
  assert.deepEqual(drifted(), []));

// Tool-name normalization across agents: [agent, tool, input, tier]
const cases = [
  ['claude', 'Bash', { command: 'git push' }, 2],
  ['copilot', 'bash', { command: 'git status' }, 0],
  ['copilot', 'powershell', { command: 'Remove-Item -Recurse -Force dist' }, 2],
  ['copilot', 'create', { path: 'src/new.ts' }, 1],
  ['copilot', 'edit', { path: '.env' }, 2],
  ['gemini', 'run_shell_command', { command: 'npm publish' }, 2],
  ['gemini', 'write_file', { file_path: 'README.md' }, 1],
  ['gemini', 'replace', { file_path: 'src/payments/charge.ts' }, 2],
  ['gemini', 'read_file', { file_path: '.env' }, 0],
  ['codex', 'apply_patch', { command: '*** Begin Patch\n*** Update File: db/migrations/0001.sql\n@@' }, 2],
  ['codex', 'apply_patch', { command: '*** Begin Patch\n*** Add File: src/util.ts\n+x' }, 1],
  ['antigravity', 'run_command', { CommandLine: 'rm -rf build' }, 2],
  ['antigravity', 'write_to_file', { TargetFile: '/w/src/app.ts' }, 1],
  ['antigravity', 'view_file', { AbsolutePath: '/w/.env' }, 0],
  ['cline', 'execute_command', { command: 'ls -la' }, 0],
  ['cline', 'replace_in_file', { path: 'infra/main.tf' }, 2],
  ['kiro', 'fs_write', { path: 'src/a.ts' }, 1],
  ['kiro', 'execute_bash', { command: 'kubectl delete pod x' }, 2],
  ['cursor', 'StrReplace', { path: 'src/auth/login.ts' }, 2],
  ['cursor', 'Delete', { path: 'notes.md' }, 1],
  ['opencode', 'edit', { filePath: 'src/a.ts' }, 1],
  ['any', 'TodoWrite', {}, 0],
  ['any', 'web_fetch', { url: 'https://example.com' }, 0],
];
for (const [agent, tool, input, tier] of cases) {
  test(`${agent}: ${tool} ${JSON.stringify(input).slice(0, 60)} → Tier ${tier}`, () =>
    assert.equal(classifyTool(tool, input).tier, tier));
}

test('editing an agent hook config is Tier 2 (it could disable the guard)', () => {
  for (const p of ['.gemini/settings.json', '.codex/hooks.json', '.cursor/hooks.json', '.github/hooks/devils-advocate.json',
    '.agents/hooks.json', '.clinerules/hooks/PreToolUse', '.devin/hooks.json', '.kiro/hooks/x.json', 'opencode.json']) {
    assert.equal(classifyEdit(p).tier, 2, p);
  }
});

test('patchPaths reads every file in an apply_patch body', () =>
  assert.deepEqual(patchPaths('*** Update File: a.ts\n*** Delete File: b.ts\n*** Add File: c.ts'), ['a.ts', 'b.ts', 'c.ts']));

test('shell tool without a command throws (adapters fail safe)', () =>
  assert.throws(() => classifyTool('run_shell_command', {})));

test('safeClassify turns errors into Tier 2', () =>
  assert.equal(safeClassify(() => { throw new Error('x'); }).tier, 2));

test('block policy per DA_GUARD_MODE', () => {
  assert.equal(guardMode({}), 'default');
  assert.equal(guardMode({ DA_GUARD_MODE: 'nonsense' }), 'default');
  assert.deepEqual([0, 1, 2].map((t) => shouldBlock(t, {})), [false, false, true]);
  assert.deepEqual([0, 1, 2].map((t) => shouldBlock(t, { DA_GUARD_MODE: 'strict' })), [false, true, true]);
  assert.deepEqual([0, 1, 2].map((t) => shouldBlock(t, { DA_GUARD_MODE: 'warn' })), [false, false, false]);
});

// SAR 2026-10-05 F01: shapes that run commands or write files must never be Tier 0.
const bypasses = [
  'ls & rm notes.md', 'ls &rm notes.md', 'sed "1e touch x" f', 'sed -n 1p f', "awk 'BEGIN{system(1)}'",
  'gawk 1 f', 'perl -e 1', 'python -c 1', 'python3 x.py', 'node -e 1', 'ruby -e 1', 'sort -o t in', 'sort --output=t in',
  'tree -o out.txt', 'uniq in out', 'yq -i .a=1 f', 'xxd in out', 'tee out.txt', 'ls | tee out.txt', 'ls | xargs rm',
  'git -c core.pager=x log', 'git -c core.sshCommand=x fetch', 'git -c alias.st=!sh status', 'git --config-env=core.pager=X log',
  'git --exec-path=/tmp status', 'git diff --output=/x', 'git log --output=x', 'git grep --open-files-in-pager=sh x',
  'git fetch --upload-pack=x origin', 'find . -exec rm {} ;', 'find . -delete', 'find . -fprint out', 'find . -fls out',
  'echo hi > f', 'echo hi>>f', 'ls 2>err.log', 'ls &>all.log', 'cat <(rm x)', 'PAGER=sh git log', 'GIT_SSH_COMMAND=x git fetch',
  'LD_PRELOAD=x ls', 'ls --output=x',
];
for (const c of bypasses) {
  test(`F01 bypass closed: ${c} → Tier ≥ 1`, () => assert.ok(classifyTool('Bash', { command: c }).tier >= 1, c));
}
const stillReadOnly = ['ls 2>&1', 'ls >/dev/null 2>&1', 'ls > /dev/null', 'git status', 'cat a | grep b', 'grep -o x f',
  'git grep -c foo', 'git -C repo log --oneline', 'sort a', 'uniq a', 'git log --format="%h %s"', 'tree -L 2', 'Get-ChildItem > $null'];
for (const c of stillReadOnly) {
  test(`read-only stays Tier 0: ${c}`, () => assert.equal(classifyTool('Bash', { command: c }).tier, 0, c));
}
test('F01: MCP query/search/execute tools ask; get/list/read/describe do not', () => {
  for (const t of ['query', 'search_code', 'execute_sql', 'check_x', 'fetch_x']) assert.equal(classifyTool(`mcp__s__${t}`, {}).tier, 1, t);
  for (const t of ['get_issue', 'list_files', 'read_page', 'describe_table']) assert.equal(classifyTool(`mcp__s__${t}`, {}).tier, 0, t);
});
test('F01: destructive part still wins after & split', () => assert.equal(classifyTool('Bash', { command: 'ls & rm -rf build' }).tier, 2));
