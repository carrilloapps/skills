// Test helper: run an adapter script the way an agent does (stdin in, stdout/stderr/exit out).
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export const scriptPath = (url, rel) => fileURLToPath(new URL(rel, url));

export function run(script, { args = [], stdin = '', env = {} } = {}) {
  const r = spawnSync(process.execPath, [script, ...args], {
    input: typeof stdin === 'string' ? stdin : JSON.stringify(stdin),
    encoding: 'utf8',
    env: { ...process.env, DA_GUARD_MODE: '', ...env },
  });
  return { exit: r.status, stdout: r.stdout, stderr: r.stderr };
}
