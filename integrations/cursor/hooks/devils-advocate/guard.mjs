#!/usr/bin/env node
// Devil's Advocate guard — Cursor agent hooks adapter.
//   node guard.mjs shell  (beforeShellExecution) stdin: { command, cwd, ... }
//   node guard.mjs mcp    (beforeMCPExecution)   stdin: { tool_name, tool_input (JSON string), mcp_server_name, ... }
//   node guard.mjs tool   (preToolUse)           stdin: { tool_name, tool_input, ... }
// stdout: { permission: "ask" | "deny", user_message, agent_message } for Tier 1–2, {} for Tier 0.
// DA_GUARD_MODE=strict → deny Tier 1–2; DA_GUARD_MODE=warn → never interfere.

import { pathToFileURL } from 'node:url';
import { classifyCommand, classifyMcp, classifyTool, guardMode, reasonOf, safeClassify } from './classifier.mjs';

function classify(mode, event) {
  if (mode === 'shell') return classifyCommand(event?.command);
  if (mode === 'mcp') {
    if (typeof event?.tool_name !== 'string') throw new Error('missing tool_name');
    return classifyMcp(event.tool_name);
  }
  if (mode === 'tool') {
    const input = typeof event?.tool_input === 'string' ? JSON.parse(event.tool_input) : event?.tool_input ?? {};
    return classifyTool(event?.tool_name, input);
  }
  throw new Error(`unknown mode ${mode}`);
}

export function decide(mode, event, env = process.env) {
  const r = safeClassify(() => classify(mode, event));
  const m = guardMode(env);
  if (r.tier === 0 || m === 'warn') return {};
  const reason = reasonOf(r);
  return { permission: m === 'strict' ? 'deny' : 'ask', user_message: reason, agent_message: reason };
}

async function main() {
  const mode = process.argv[2];
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // decide(…, null) asks
  }
  process.stdout.write(JSON.stringify(decide(mode, event)));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => process.stdout.write(JSON.stringify(decide('tool', null))));
}
