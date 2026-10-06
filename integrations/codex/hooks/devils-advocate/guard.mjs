#!/usr/bin/env node
// Devil's Advocate guard — OpenAI Codex CLI PreToolUse hook adapter.
// stdin: { tool_name: "Bash" | "apply_patch" | "Edit" | "Write" | "mcp__server__tool", tool_input, ... }
// Codex parses permissionDecision "ask" but does not support it yet, so Tier 2 is denied and
// Tier 1 passes (DA_GUARD_MODE=strict denies Tier 1 too; DA_GUARD_MODE=warn never denies).

import { pathToFileURL } from 'node:url';
import { BLOCK_HINT, classifyTool, reasonOf, safeClassify, shouldBlock } from './classifier.mjs';

export function decide(event, env = process.env) {
  const r = safeClassify(() => classifyTool(event?.tool_name, event?.tool_input ?? {}));
  if (!shouldBlock(r.tier, env)) return null;
  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: `${reasonOf(r)}. ${BLOCK_HINT}`,
    },
  };
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // decide(null) denies
  }
  const d = decide(event);
  if (d) process.stdout.write(JSON.stringify(d));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => process.stdout.write(JSON.stringify(decide(null))));
}
