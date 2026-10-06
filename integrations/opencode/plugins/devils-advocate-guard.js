// Devil's Advocate guard — OpenCode plugin adapter.
// Hook: "tool.execute.before"(input: { tool, sessionID, callID }, output: { args }).
// Throwing blocks the tool call. OpenCode plugins cannot "ask", so Tier 2 is blocked and Tier 1 passes
// (DA_GUARD_MODE=strict blocks Tier 1; warn never blocks). For a real confirmation prompt on Tier 1,
// also set OpenCode's own permissions (see the README).
// Only the plugin is exported: OpenCode treats every export of a plugin file as a plugin.
import { BLOCK_HINT, classifyTool, reasonOf, safeClassify, shouldBlock } from '../devils-advocate/classifier.mjs';

export const DevilsAdvocateGuard = async () => ({
  'tool.execute.before': async (input, output) => {
    const r = safeClassify(() => classifyTool(input?.tool, output?.args ?? {}));
    if (shouldBlock(r.tier, process.env)) throw new Error(`${reasonOf(r)}. ${BLOCK_HINT}`);
  },
});
