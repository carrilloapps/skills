#!/usr/bin/env node
// Devil's Advocate guard — Kiro PreToolUse command hook adapter (EXPERIMENTAL).
// stdin: { hook_event_name, cwd, tool_name, tool_input }  (fs_write, str_replace, execute_bash, @server/tool …)
// Kiro blocks a tool call when a PreToolUse command exits with code 2 (stderr goes to the agent).
// There is no "ask", so Tier 2 is blocked and Tier 1 passes with a notice on stdout
// (DA_GUARD_MODE=strict blocks Tier 1 too; DA_GUARD_MODE=warn never blocks).
// Empty stdin is passed through with a notice: some Kiro IDE builds don't send the event (kirodotdev/Kiro#7500),
// and blocking every call there would make the IDE unusable.

import { pathToFileURL } from 'node:url';
import { BLOCK_HINT, classifyMcp, classifyTool, reasonOf, safeClassify, shouldBlock } from './classifier.mjs';

function classify(event) {
  const tool = event?.tool_name;
  if (typeof tool === 'string' && tool.startsWith('@')) return classifyMcp(tool.split('/').pop());
  return classifyTool(tool, event?.tool_input ?? {});
}

// → { exit, stdout, stderr }
export function decide(raw, env = process.env) {
  if (!String(raw ?? '').trim()) {
    return { exit: 0, stdout: "Devil's Advocate guard: no tool event received; not enforced for this call.", stderr: '' };
  }
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // classify(null) throws → fails closed
  }
  const r = safeClassify(() => classify(event));
  if (r.tier === 0) return { exit: 0, stdout: '', stderr: '' };
  if (shouldBlock(r.tier, env)) return { exit: 2, stdout: '', stderr: `${reasonOf(r)}. ${BLOCK_HINT}` };
  return { exit: 0, stdout: reasonOf(r), stderr: '' };
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  const d = decide(raw);
  if (d.stdout) process.stdout.write(d.stdout);
  if (d.stderr) process.stderr.write(d.stderr);
  process.exitCode = d.exit;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => {
    process.stderr.write("Devil's Advocate guard crashed; blocking to be safe.");
    process.exitCode = 2;
  });
}
