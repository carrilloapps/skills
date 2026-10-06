#!/usr/bin/env node
// Devil's Advocate guard — deterministic pre-execution classifier for Claude Code hooks.
// Reads one hook event as JSON on stdin and writes at most one JSON decision on stdout.
// No network, no file writes, no dependencies. Same input → same output.
//
//   node guard.mjs pre-tool-use   (PreToolUse)       → "ask" (or "deny" in strict mode) / no decision
//   node guard.mjs remind         (UserPromptSubmit) → short reminder added to Claude's context

import { pathToFileURL } from 'node:url';
import { REMINDER, classifyTool, reasonOf } from './classifier.mjs';

// Claude Code event → tier. Throws on malformed events so decide() fails safe.
export function classify(event) {
  return classifyTool(event?.tool_name, event?.tool_input ?? {});
}

const UNATTENDED_MODES = new Set(['auto', 'bypassPermissions']);

export function decide(event, env = process.env) {
  let result;
  try {
    result = classify(event);
  } catch {
    result = { tier: 1, why: 'guard could not read the request, asking to be safe' };
  }
  if (result.tier === 0) return null; // no decision: normal permission flow applies
  const strict = /^(true|1)$/i.test(env.CLAUDE_PLUGIN_OPTION_STRICT ?? '');
  const unattended = UNATTENDED_MODES.has(event?.permission_mode);
  const reason = reasonOf(result);
  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: strict && unattended ? 'deny' : 'ask',
      permissionDecisionReason: strict && unattended
        ? `${reason}. Blocked: strict mode does not allow unattended Tier ${result.tier} actions.`
        : reason,
    },
  };
}

async function main() {
  const mode = process.argv[2];
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;

  if (mode === 'remind') {
    process.stdout.write(REMINDER);
    return;
  }
  if (mode !== 'pre-tool-use') return;

  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // fall through: decide(null) asks
  }
  const decision = decide(event);
  if (decision) process.stdout.write(JSON.stringify(decision));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => {
    // Last-resort fail-safe: never let a crash turn into a silent allow.
    process.stdout.write(JSON.stringify(decide(null)));
  });
}
