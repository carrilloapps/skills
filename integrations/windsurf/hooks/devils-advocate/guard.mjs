#!/usr/bin/env node
// Devil's Advocate guard — Windsurf / Devin Desktop Cascade pre-hook adapter.
// stdin: { agent_action_name: "pre_run_command" | "pre_write_code" | "pre_mcp_tool_use", tool_info, ... }
//   pre_run_command  → tool_info.command_line
//   pre_write_code   → tool_info.file_path
//   pre_mcp_tool_use → tool_info.mcp_tool_name
// Cascade blocks a pre-hook action on exit code 2 (stderr shown). There is no "ask", so Tier 2 is
// blocked and Tier 1 passes with a notice (DA_GUARD_MODE=strict blocks Tier 1; warn never blocks).

import { pathToFileURL } from 'node:url';
import { BLOCK_HINT, classifyCommand, classifyEdit, classifyMcp, reasonOf, safeClassify, shouldBlock } from './classifier.mjs';

function classify(event) {
  const info = event?.tool_info ?? {};
  switch (event?.agent_action_name) {
    case 'pre_run_command':
      return classifyCommand(info.command_line);
    case 'pre_write_code':
      if (typeof info.file_path !== 'string') throw new Error('missing file_path');
      return classifyEdit(info.file_path);
    case 'pre_mcp_tool_use':
      if (typeof info.mcp_tool_name !== 'string') throw new Error('missing mcp_tool_name');
      return classifyMcp(info.mcp_tool_name);
    case 'pre_read_code':
      return { tier: 0 };
    default:
      throw new Error('unknown agent_action_name');
  }
}

// → { exit, stdout, stderr }
export function decide(event, env = process.env) {
  const r = safeClassify(() => classify(event));
  if (r.tier === 0) return { exit: 0, stdout: '', stderr: '' };
  if (shouldBlock(r.tier, env)) return { exit: 2, stdout: '', stderr: `${reasonOf(r)}. ${BLOCK_HINT}` };
  return { exit: 0, stdout: reasonOf(r), stderr: '' };
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // decide(null) blocks
  }
  const d = decide(event);
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
