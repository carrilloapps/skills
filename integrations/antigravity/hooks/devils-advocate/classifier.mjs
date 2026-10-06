// Devil's Advocate guard — shared deterministic classifier.
// CANONICAL COPY. Every adapter ships a byte-identical copy as `classifier.mjs`
// (agents load hooks from the adapter's own directory). Edit this file, then run
//   node integrations/sync-core.mjs
// The drift test (integrations/core/drift.test.mjs) fails if a copy differs.
//
// Pure functions: no I/O, no network, no dependencies. Same input → same output.
// Tier 0 = read-only, Tier 1 = contained side effect, Tier 2 = hard to reverse / wide blast radius.

export const REMINDER =
  "Devil's Advocate gate active: classify every action by risk tier before side effects. " +
  'Tier 1+ needs the user\'s go-ahead in their own words (a bare "ok" is acknowledgement, not approval). ' +
  'Approved plans are not re-gated; same plan, same verdict.';

export const reasonOf = (r) => `Devil's Advocate · Tier ${r.tier} — ${r.why}`;

// ── Shell commands (Bash, PowerShell, any agent's shell tool) ───────────────

const READ_ONLY = new Set([
  'ls', 'dir', 'cat', 'head', 'tail', 'less', 'more', 'wc', 'grep', 'egrep', 'fgrep', 'rg', 'ag',
  'find', 'fd', 'echo', 'printf', 'pwd', 'which', 'where', 'type', 'whoami', 'date', 'file', 'stat',
  // Not here on purpose: awk/sed (programs can run commands or write files), yq (-i), xxd (in out),
  // tee, xargs, interpreters — they fall through to Tier 1.
  'du', 'df', 'tree', 'diff', 'cmp', 'sort', 'uniq', 'cut', 'tr', 'jq',
  'basename', 'dirname', 'realpath', 'readlink', 'test', 'true', 'false', 'cd', 'uname', 'hostname',
  'ps', 'printenv', 'id', 'nl', 'column', 'od', 'md5sum', 'sha256sum', 'shasum',
  // PowerShell read-only cmdlets
  'get-childitem', 'get-content', 'get-item', 'get-location', 'select-string', 'test-path',
  'get-command', 'get-process', 'measure-object', 'select-object', 'where-object', 'format-table',
  'format-list', 'out-string', 'resolve-path', 'get-filehash', 'write-output', 'write-host',
]);

const GIT_READ_ONLY = new Set([
  'status', 'log', 'diff', 'show', 'rev-parse', 'ls-files', 'ls-tree', 'blame', 'describe',
  'shortlog', 'reflog', 'cat-file', 'grep', 'fetch', 'remote', 'branch', 'tag', 'config', 'stash',
  'help', 'version', 'whatchanged', 'merge-base', 'name-rev', 'for-each-ref', 'count-objects',
]);

const GIT_PUBLISH = new Set(['push', 'merge', 'rebase', 'filter-repo', 'filter-branch', 'cherry-pick', 'revert', 'am', 'pull']);

const DESTRUCTIVE = [
  [/\b(drop\s+(table|database|schema)|truncate\s+table|delete\s+from)\b/i, 'destructive SQL'],
  [/\bterraform\s+(apply|destroy|import|state)\b/, 'infrastructure change'],
  [/\b(kubectl|oc)\s+(delete|apply|replace|scale|drain|patch|rollout)\b/, 'cluster change'],
  [/\bhelm\s+(install|upgrade|uninstall|rollback)\b/, 'cluster change'],
  [/\bdocker\s+(rm|rmi|push|system\s+prune|volume\s+rm)\b/, 'container/registry change'],
  [/\b(npm|pnpm|yarn|cargo|gem|dotnet\s+nuget)\s+publish\b|\btwine\s+upload\b/, 'package publish'],
  [/\bgh\s+(release\s+(create|delete)|pr\s+merge|repo\s+delete)\b/, 'GitHub publish/delete'],
  [/\b(aws|gcloud|az)\s.*\b(delete|remove|rm|destroy|terminate)\b/, 'cloud resource deletion'],
  [/\bvercel\b.*(--prod\b|\bdeploy\b)|\bfirebase\s+deploy\b|\bfly\s+deploy\b/, 'deployment'],
  [/\b(curl|wget|invoke-webrequest|invoke-restmethod)\b.*(-X\s*(POST|PUT|PATCH|DELETE)|--request\s+(POST|PUT|PATCH|DELETE)|-Method\s+(Post|Put|Patch|Delete))/i, 'remote write request'],
  [/\brm\s+(-[a-z]*[rf]|--recursive|--force)/i, 'recursive/forced delete'],
  [/\b(remove-item|rd|rmdir)\b.*(-recurse|\/s)\b/i, 'recursive delete'],
];

// ponytail: segments are split without honoring quotes; a quoted ";" or "|" over-splits,
// which only yields an unknown fragment → Tier 1. The error direction is always toward asking.
function segments(command) {
  const parts = [];
  // $(…), `…`, and process substitution <(…) / >(…) run their own commands.
  const nested = /\$\(([^()]*)\)|`([^`]*)`|[<>]\(([^()]*)\)/g;
  let m;
  while ((m = nested.exec(command))) parts.push(m[1] ?? m[2] ?? m[3]);
  // A single `&` (background job, PowerShell call operator) also separates commands;
  // `&&`, `2>&1`, `>&2` and `&>file` do not.
  return parts
    .concat(command.split(/&&|\|\||[;|\n]|(?<![<>&])&(?![&>])/))
    .map((s) => s.trim())
    .filter(Boolean);
}

function words(segment) {
  const w = segment.split(/\s+/);
  let env = false;
  while (w.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(w[0])) { w.shift(); env = true; } // FOO=bar cmd
  return { w, env };
}

// Flags that make an otherwise read-only command write a file.
const WRITE_FLAGS = { sort: /^(-o|--output)/, tree: /^-o$/ };

const worse = (a, b) => (b.tier > a.tier ? b : a);

function classifySegment(segment) {
  for (const [re, why] of DESTRUCTIVE) if (re.test(segment)) return { tier: 2, why };
  const { w, env } = words(segment);
  if (!w.length) return env ? { tier: 1, why: 'sets environment variables' } : { tier: 0 };
  // PAGER=, GIT_SSH_COMMAND=, LD_PRELOAD=… can turn a read-only command into execution.
  const r = classifyWords(segment, w);
  return env ? worse({ tier: 1, why: 'environment override before the command' }, r) : r;
}

function classifyWords(segment, w) {
  if (w[0] === 'sudo' || w[0] === 'doas') return { tier: 2, why: 'elevated privileges' };
  const cmd = w[0].replace(/^.*[\\/]/, '').toLowerCase();
  const args = w.slice(1);
  const has = (re) => args.some((a) => re.test(a));

  if (['dd', 'mkfs', 'shred', 'format', 'diskpart'].includes(cmd) || cmd.startsWith('mkfs.')) {
    return { tier: 2, why: 'disk-level write' };
  }
  // >file, >>file, 2>file, &>file — but not 2>&1, >&2, or the null devices.
  if (/(?:^|[^<>=-])(?:\d+|&)?>{1,2}(?![&>])\s*(?!(?:\/dev\/null|nul|\$null)(?:\s|$))\S/i.test(segment)) {
    return { tier: 1, why: 'redirects output into a file' };
  }
  if (cmd === 'git') return classifyGit(args);
  if (cmd === 'rm' || cmd === 'del' || cmd === 'remove-item') {
    return has(/^-[a-z]*[rf]|^--(recursive|force)$|^-recurse$|^-force$/i)
      ? { tier: 2, why: 'recursive/forced delete' }
      : { tier: 1, why: 'deletes files' };
  }
  if (cmd === 'find') {
    return has(/^-(delete|exec|execdir|ok|okdir|fprint|fls)/) ? { tier: 1, why: 'find with side effects' } : { tier: 0 };
  }
  if (['sed', 'awk', 'gawk', 'mawk', 'nawk'].includes(cmd)) return { tier: 1, why: `${cmd} programs can run commands or write files` };
  if (READ_ONLY.has(cmd)) {
    if (has(/^--output(-file)?(=|$)/) || (WRITE_FLAGS[cmd] && has(WRITE_FLAGS[cmd]))) {
      return { tier: 1, why: `${cmd} writes its output to a file` };
    }
    if (cmd === 'uniq' && args.filter((a) => !a.startsWith('-')).length > 1) return { tier: 1, why: 'uniq writes its output to a file' };
    return { tier: 0 };
  }
  return { tier: 1, why: `command not known to be read-only: ${cmd}` };
}

function classifyGit(allArgs) {
  // Config overrides (core.pager, core.sshCommand, alias.*) and these options run programs or write files.
  const firstSub = allArgs.findIndex((a, i) => !a.startsWith('-') && !['-C', '--git-dir', '--work-tree', '--namespace'].includes(allArgs[i - 1]));
  const globals = firstSub < 0 ? allArgs : allArgs.slice(0, firstSub);
  if (globals.some((a) => /^(-c|--config-env|--exec-path)/.test(a)) ||
      allArgs.some((a) => /^(--output|--open-files-in-pager|-O|--upload-pack|--receive-pack|--exec=|--ext-diff$)/.test(a))) {
    return { tier: 1, why: 'git option that can run commands or write files' };
  }
  // Drop global options that take a value (git -C dir …).
  const args = [];
  for (let i = 0; i < allArgs.length; i++) {
    if (['-C', '--git-dir', '--work-tree', '--namespace'].includes(allArgs[i])) i++;
    else args.push(allArgs[i]);
  }
  const sub = args.find((a) => !a.startsWith('-')) ?? '';
  const flags = args.filter((a) => a.startsWith('-'));
  const flag = (re) => flags.some((f) => re.test(f));

  if (sub === 'push') {
    return flag(/^(-f|--force|--force-with-lease|--delete|--mirror|--prune)/) || args.some((a) => a.startsWith('+') || a.startsWith(':'))
      ? { tier: 2, why: 'git push rewriting or deleting remote history' }
      : { tier: 2, why: 'git push publishes history' };
  }
  if (sub === 'reset' && flag(/^--hard$/)) return { tier: 2, why: 'git reset --hard discards work' };
  if (sub === 'clean' && flag(/^-[a-z]*f|^--force$/)) return { tier: 2, why: 'git clean deletes untracked files' };
  if (GIT_PUBLISH.has(sub)) return { tier: 2, why: `git ${sub} rewrites or integrates history` };

  if (GIT_READ_ONLY.has(sub)) {
    const rest = args.slice(args.indexOf(sub) + 1);
    const positional = rest.filter((a) => !a.startsWith('-'));
    if (sub === 'branch' && (flag(/^-[dDmMcC]$|^--(delete|move|copy|force|set-upstream-to|unset-upstream)/) || positional.length)) {
      return { tier: 2, why: 'git branch create/delete/rename' };
    }
    if (sub === 'tag' && !flag(/^(-l|--list|-n\d*|--contains|--points-at|-v|--verify)/) && positional.length) {
      return { tier: 2, why: 'git tag creates or deletes a tag' };
    }
    if (sub === 'remote' && positional.length && !['show', 'get-url'].includes(positional[0])) {
      return { tier: 1, why: `git remote ${positional[0]}` };
    }
    if (sub === 'config' && !flag(/^--(get|get-all|get-regexp|list|show-origin)$|^-l$/) && positional.length > 1) {
      return { tier: 1, why: 'git config writes a setting' };
    }
    if (sub === 'stash' && positional.length && !['list', 'show'].includes(positional[0])) {
      return { tier: 1, why: `git stash ${positional[0]}` };
    }
    if (sub === 'stash' && !positional.length) return { tier: 1, why: 'git stash modifies the working tree' };
    return { tier: 0 };
  }
  return { tier: 1, why: `git ${sub || '(no subcommand)'} modifies the repository` };
}

export function classifyCommand(command) {
  if (typeof command !== 'string') throw new Error('missing command');
  let worst = { tier: 0 };
  for (const s of segments(command)) {
    const r = classifySegment(s);
    if (r.tier > worst.tier) worst = r;
  }
  return worst;
}

// ── File edits ───────────────────────────────────────────────────────────────

const SENSITIVE_PATH = [
  [/(^|[\\/])migrations?[\\/]|\.sql$/i, 'database migration/SQL'],
  [/(^|[\\/])\.env(\.|$)|secret|credential|\.pem$|\.key$/i, 'secrets/credentials'],
  [/auth|login|session|token|password|permission|rbac/i, 'authentication/authorization code'],
  [/payment|billing|checkout|invoice|stripe/i, 'payments/billing code'],
  [/\.tf$|\.tfvars$|terraform|(^|[\\/])(infra|k8s|helm|deploy)[\\/]/i, 'infrastructure'],
  [/\.github[\\/]workflows[\\/]|\.gitlab-ci\.yml$|Jenkinsfile$/i, 'CI/CD pipeline'],
  [/Dockerfile|docker-compose/i, 'container definition'],
  [/package-lock\.json$|yarn\.lock$|pnpm-lock\.yaml$|poetry\.lock$|Cargo\.lock$|go\.sum$|composer\.lock$/i, 'dependency lockfile'],
  // Agent hook/permission config: editing it could switch this guard off.
  [/(^|[\\/])(\.claude[\\/]settings|\.gemini[\\/]|\.codex[\\/]|\.cursor[\\/]hooks|\.kiro[\\/]hooks|\.devin[\\/]|\.windsurf[\\/]|\.clinerules[\\/]hooks|\.agents[\\/]hooks|\.opencode[\\/]|\.github[\\/]hooks|opencode\.json$)/i, 'agent hook/permission configuration'],
];

export function classifyEdit(paths) {
  const list = (Array.isArray(paths) ? paths : [paths]).map((p) => String(p ?? ''));
  for (const path of list) {
    for (const [re, why] of SENSITIVE_PATH) if (re.test(path)) return { tier: 2, why: `edits ${why}` };
  }
  return { tier: 1, why: 'edits a file' };
}

// Paths named in an apply_patch / unified patch body ("*** Update File: src/x.ts").
export function patchPaths(text) {
  const out = [];
  const re = /^\*\*\* (?:Add|Update|Delete) File: (.+)$|^\*\*\* Move to: (.+)$|^\+\+\+ b\/(.+)$/gm;
  let m;
  while ((m = re.exec(String(text ?? '')))) out.push((m[1] ?? m[2] ?? m[3]).trim());
  return out;
}

// ── MCP tools ────────────────────────────────────────────────────────────────

// Only verbs that cannot mutate by contract; query/search/execute tools (SQL, GraphQL) can write → ask.
const MCP_READ_ONLY = /^(get|list|read|describe)([_-]|$)/i;

// `tool` is the bare MCP tool name (without server prefix).
export function classifyMcp(tool) {
  return MCP_READ_ONLY.test(String(tool ?? ''))
    ? { tier: 0 }
    : { tier: 1, why: 'MCP tool that may have side effects' };
}

// ── Generic tool dispatch (used by adapters whose tool names vary) ───────────

const SHELL_TOOL = /^(bash|powershell|shell|run_shell_command|run_command|execute_command|execute_bash|run_in_terminal|terminal|exec|local_shell)$/i;
const EDIT_TOOL = /(write|edit|create|replace|patch|insert|delete|remove|rename|move|notebook)/i;
const NOT_EDIT = /todo|read|view|search|list|get/i;
const COMMAND_KEYS = ['command', 'CommandLine', 'command_line', 'commandLine', 'cmd'];
const PATH_KEYS = ['file_path', 'filePath', 'path', 'notebook_path', 'TargetFile', 'target_file', 'targetFile', 'AbsolutePath', 'absolute_path', 'file', 'filename'];

const pick = (obj, keys) => keys.map((k) => obj?.[k]).find((v) => typeof v === 'string');

// tool: tool name as the agent reports it; input: its arguments object.
// Throws on malformed input so adapters can fail safe.
export function classifyTool(tool, input = {}) {
  if (typeof tool !== 'string' || !tool) throw new Error('missing tool name');
  if (input === null || typeof input !== 'object') throw new Error('missing tool input');

  if (/^mcp__/.test(tool)) return classifyMcp(tool.split('__').slice(2).join('__'));
  if (SHELL_TOOL.test(tool)) return classifyCommand(pick(input, COMMAND_KEYS));
  if (/^apply_patch$/i.test(tool)) {
    const body = pick(input, ['command', 'patch', 'input']);
    return classifyEdit(patchPaths(body));
  }
  if (EDIT_TOOL.test(tool) && !NOT_EDIT.test(tool)) {
    const paths = PATH_KEYS.map((k) => input[k]).filter((v) => typeof v === 'string');
    return classifyEdit(paths);
  }
  return { tier: 0 };
}

// ── Policy for agents whose hooks can only allow or block (no "ask") ─────────
// DA_GUARD_MODE (read from the agent's environment, not from tool commands):
//   default → block Tier 2, let Tier 1 through with a notice
//   strict  → block Tier 1 and Tier 2
//   warn    → never block, notice only
export function guardMode(env = {}) {
  const m = String(env.DA_GUARD_MODE ?? '').toLowerCase();
  return m === 'strict' || m === 'warn' ? m : 'default';
}

export function shouldBlock(tier, env = {}) {
  const m = guardMode(env);
  if (tier === 0 || m === 'warn') return false;
  return m === 'strict' ? tier >= 1 : tier >= 2;
}

export const BLOCK_HINT =
  "Blocked by the Devil's Advocate guard. Show the user the plan and its risks and ask for approval; " +
  'after approval the user runs it, or relaxes the guard for this session.';

// Classify, never throw: malformed events become a Tier 2 "could not read" result so
// block-only agents fail closed and ask-capable agents ask.
export function safeClassify(fn) {
  try {
    return fn();
  } catch {
    return { tier: 2, why: 'guard could not read the request (adapter/agent version mismatch?)' };
  }
}
