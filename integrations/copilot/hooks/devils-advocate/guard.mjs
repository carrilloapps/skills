#!/usr/bin/env node
// Devil's Advocate guard — GitHub Copilot preToolUse hook adapter (Copilot CLI, cloud agent, VS Code).
// Copilot CLI stdin: { toolName, toolArgs (JSON string or object), cwd, ... }
// VS Code stdin:     { tool_name, tool_input, ... }
// stdout: permissionDecision "ask" (Tier 1–2) or "deny" (DA_GUARD_MODE=strict), written both top-level
// (Copilot CLI format) and under hookSpecificOutput (VS Code / Claude-compatible format).
// Tier 0 prints nothing: Copilot's normal permission flow applies.

import { pathToFileURL } from 'node:url';
import { classifyTool, guardMode, reasonOf, safeClassify } from './classifier.mjs';

function parseArgs(args) {
  if (typeof args === 'string') return args.trim() ? JSON.parse(args) : {};
  return args ?? {};
}

export function decide(event, env = process.env) {
  const r = safeClassify(() =>
    'toolName' in (event ?? {})
      ? classifyTool(event.toolName, parseArgs(event.toolArgs))
      : classifyTool(event?.tool_name, event?.tool_input ?? {}),
  );
  if (r.tier === 0) return null;
  const permissionDecision = guardMode(env) === 'strict' ? 'deny' : guardMode(env) === 'warn' ? 'allow' : 'ask';
  const permissionDecisionReason = reasonOf(r);
  if (permissionDecision === 'allow') return null; // warn mode: never interfere
  return {
    permissionDecision,
    permissionDecisionReason,
    hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision, permissionDecisionReason },
  };
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // decide(null) asks
  }
  const d = decide(event);
  if (d) process.stdout.write(JSON.stringify(d));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => process.stdout.write(JSON.stringify(decide(null))));
}
