#!/usr/bin/env node
// Devil's Advocate guard — Gemini CLI BeforeTool hook adapter.
// stdin: { tool_name, tool_input, mcp_context?, ... }  stdout: { decision, reason } | { systemMessage } | {}
// Gemini CLI hooks can allow or deny but not ask, so Tier 2 is denied and Tier 1 passes with a notice
// (DA_GUARD_MODE=strict denies Tier 1 too; DA_GUARD_MODE=warn never denies).

import { pathToFileURL } from 'node:url';
import { BLOCK_HINT, classifyMcp, classifyTool, reasonOf, safeClassify, shouldBlock } from './classifier.mjs';

function classify(event) {
  const tool = event?.tool_name;
  // MCP tools are named mcp_<server>_<tool>. Strip the server when Gemini tells us its name;
  // otherwise assume a one-word server (a longer one only makes the check stricter).
  if (typeof tool === 'string' && tool.startsWith('mcp_')) {
    const server = event?.mcp_context?.server_name;
    const bare = server && tool.startsWith(`mcp_${server}_`)
      ? tool.slice(`mcp_${server}_`.length)
      : tool.split('_').slice(2).join('_');
    return classifyMcp(bare);
  }
  return classifyTool(tool, event?.tool_input ?? {});
}

export function decide(event, env = process.env) {
  const r = safeClassify(() => classify(event));
  if (r.tier === 0) return {};
  if (shouldBlock(r.tier, env)) return { decision: 'deny', reason: `${reasonOf(r)}. ${BLOCK_HINT}` };
  return { systemMessage: reasonOf(r) };
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // decide(null) fails closed
  }
  process.stdout.write(JSON.stringify(decide(event)));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => process.stdout.write(JSON.stringify(decide(null))));
}
