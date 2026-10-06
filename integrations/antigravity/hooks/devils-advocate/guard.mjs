#!/usr/bin/env node
// Devil's Advocate guard — Google Antigravity CLI (agy) PreToolUse hook adapter (EXPERIMENTAL).
// stdin (camelCase): { toolCall: { name, args }, stepIdx, conversationId, workspacePaths, ... }
//   run_command → args.CommandLine; write_to_file / replace_file_content / multi_replace_file_content → args.TargetFile
// stdout: { decision, reason }. Tier 1 → "ask", Tier 2 → "force_ask" (no cached "Always Allow" can skip it),
// DA_GUARD_MODE=strict → "deny". Tier 0 → no output (no decision): the guard never emits "allow", because an
// "allow" that agy starts honoring (google-antigravity/antigravity-cli#1053) would override the user's own rules.
// DA_GUARD_MODE=warn → no decision either; the reason goes to stderr as a notice.

import { pathToFileURL } from 'node:url';
import { classifyMcp, classifyTool, guardMode, reasonOf, safeClassify } from './classifier.mjs';

function classify(event) {
  const name = event?.toolCall?.name;
  // ponytail: agy's MCP tool naming is not documented; treat "mcp_<server>_<tool>" like Gemini CLI.
  if (typeof name === 'string' && /^mcp[_:]/.test(name)) return classifyMcp(name.split(/[_:]/).slice(2).join('_'));
  return classifyTool(name, event?.toolCall?.args ?? {});
}

// Returns null for "no decision" (Tier 0, or warn mode). Never returns "allow".
export function decide(event, env = process.env) {
  const r = safeClassify(() => classify(event));
  const m = guardMode(env);
  if (r.tier === 0 || m === 'warn') return null;
  if (m === 'strict') return { decision: 'deny', reason: reasonOf(r) };
  return { decision: r.tier >= 2 ? 'force_ask' : 'ask', reason: reasonOf(r) };
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  let event = null;
  try {
    event = JSON.parse(raw);
  } catch {
    // decide(null) → force_ask
  }
  const d = decide(event);
  if (d) process.stdout.write(JSON.stringify(d));
  else if (guardMode(process.env) === 'warn') {
    const r = safeClassify(() => classify(event));
    if (r.tier > 0) process.stderr.write(`${reasonOf(r)} (warn mode: not blocked)
`);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch(() => process.stdout.write(JSON.stringify(decide(null))));
}
