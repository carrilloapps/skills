#!/usr/bin/env node
// Devil's Advocate guard — Cline PreToolUse hook adapter.
// stdin: { hookName: "PreToolUse", preToolUse: { tool | toolName, parameters }, ... }
//   execute_command → parameters.command; write_to_file / replace_in_file → parameters.path;
//   use_mcp_tool → parameters.tool_name. Parameter values may arrive JSON-stringified.
// stdout: { cancel, errorMessage?, contextModification? }. Cline has no "ask", so Tier 2 is cancelled and
// Tier 1 continues with a context note (DA_GUARD_MODE=strict cancels Tier 1; warn never cancels).

import { pathToFileURL } from 'node:url';
import { BLOCK_HINT, classifyMcp, classifyTool, reasonOf, safeClassify, shouldBlock } from './classifier.mjs';

function classify(event) {
  const call = event?.preToolUse ?? {};
  const tool = call.tool ?? call.toolName;
  const params = call.parameters ?? {};
  if (tool === 'use_mcp_tool') {
    if (typeof params.tool_name !== 'string') throw new Error('missing tool_name');
    return classifyMcp(params.tool_name);
  }
  if (tool === 'access_mcp_resource') return { tier: 0 };
  return classifyTool(tool, params);
}

export function decide(event, env = process.env) {
  const r = safeClassify(() => classify(event));
  if (r.tier === 0) return { cancel: false };
  if (shouldBlock(r.tier, env)) return { cancel: true, errorMessage: `${reasonOf(r)}. ${BLOCK_HINT}` };
  return { cancel: false, contextModification: reasonOf(r) };
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // decide(null) cancels
  }
  process.stdout.write(JSON.stringify(decide(event)));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => process.stdout.write(JSON.stringify(decide(null))));
}
