#!/usr/bin/env node
// Copies the canonical classifier (integrations/core/classifier.mjs) into every adapter.
// Agents load hook scripts from the adapter's own directory (Claude Code plugins cannot
// reference files outside the plugin root), so each adapter ships its own copy.
//   node integrations/sync-core.mjs          → write copies
//   node integrations/sync-core.mjs --check  → exit 1 if any copy differs (used by the drift test)

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const TARGETS = [
  'claude-code/hooks/classifier.mjs',
  'gemini-cli/hooks/devils-advocate/classifier.mjs',
  'copilot/hooks/devils-advocate/classifier.mjs',
  'codex/hooks/devils-advocate/classifier.mjs',
  'cursor/hooks/devils-advocate/classifier.mjs',
  'kiro/hooks/devils-advocate/classifier.mjs',
  'windsurf/hooks/devils-advocate/classifier.mjs',
  'cline/hooks/devils-advocate/classifier.mjs',
  'antigravity/hooks/devils-advocate/classifier.mjs',
  'opencode/devils-advocate/classifier.mjs',
];

const here = (p) => fileURLToPath(new URL(p, import.meta.url));

export function drifted() {
  const core = readFileSync(here('core/classifier.mjs'), 'utf8');
  return TARGETS.filter((t) => {
    try {
      return readFileSync(here(t), 'utf8') !== core;
    } catch {
      return true;
    }
  });
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const args = process.argv.slice(2);
  const unknown = args.filter((a) => !['--check', '--help', '-h'].includes(a));
  if (args.includes('--help') || args.includes('-h') || unknown.length) {
    if (unknown.length) console.error(`Unknown option(s): ${unknown.join(' ')}`);
    console.log('Usage: node integrations/sync-core.mjs [--check]\n  (no flag)  copy core/classifier.mjs into every adapter\n  --check    exit 1 if any adapter copy differs');
    process.exit(unknown.length ? 2 : 0);
  }
  if (args.includes('--check')) {
    const bad = drifted();
    if (bad.length) {
      console.error(`Out of sync with core/classifier.mjs:\n  ${bad.join('\n  ')}\nRun: node integrations/sync-core.mjs`);
      process.exit(1);
    }
  } else {
    const core = readFileSync(here('core/classifier.mjs'), 'utf8');
    for (const t of TARGETS) {
      mkdirSync(dirname(here(t)), { recursive: true });
      writeFileSync(here(t), core);
    }
    console.log(`Synced ${TARGETS.length} copies.`);
  }
}
