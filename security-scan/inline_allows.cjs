'use strict';
// Lists the inline gitleaks:allow comments a pull request adds, in one pull request comment
// that each run of security-scan updates. Gitleaks skips the line such a comment is on. When
// the base branch keeps a Gitleaks config or ignore file, that is where an allowance can be
// reviewed in one place, so the comment names each new inline one until it is gone, and then
// says none remain. A pull request that never added one gets no comment.
//
// actions/github-script runs it: run({ github, context, core }). check-configs supplies
// BASE_SHA and HEAD_SHA, commits it has checked exist in the clone, and GITLEAKS_CONFIG is
// the gitleaks-config input. The comment names a file and a line, never the line's text,
// which holds the secret the comment allows.

const { execFileSync } = require('node:child_process');

const ALLOW = 'gitleaks:allow';
const MARKER = '<!-- ivuorinen/actions security-scan: inline gitleaks:allow -->';

// git ARGS, with attributes read from the base commit like the Gitleaks scan: a -diff the
// pull request adds would otherwise hide a file's changes.
function git(args, base) {
  return execFileSync('git', args, {
    encoding: 'utf8',
    env: { ...process.env, GIT_ATTR_SOURCE: base },
    maxBuffer: 1024 * 1024 * 1024,
  });
}

function inCommit(commit, file) {
  try {
    execFileSync('git', ['cat-file', '-e', `${commit}:${file}`], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

// The path a "+++ b/PATH" header names. With core.quotePath=false git quotes only a path
// holding a quote, a backslash or a control character, much as JSON would.
function headerPath(name) {
  if (name.startsWith('"')) {
    try {
      return JSON.parse(name).slice('b/'.length);
    } catch {
      return name.slice('"b/'.length, -1);
    }
  }
  return name.slice('b/'.length);
}

// The file and new line number of each added line in DIFF, a git diff -U0, that holds
// gitleaks:allow. A "+++ " line is a file name only in a file's header, before its first
// hunk: inside a hunk it is an added line that starts with "++".
function addedAllows(diff) {
  const found = [];
  let file = null;
  let inHeader = false;
  let line = 0;
  for (const text of diff.split('\n')) {
    if (text.startsWith('diff --git ')) {
      inHeader = true;
      file = null;
    } else if (inHeader && text.startsWith('+++ ')) {
      file = text === '+++ /dev/null' ? null : headerPath(text.slice('+++ '.length));
    } else if (text.startsWith('@@ ')) {
      inHeader = false;
      const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/.exec(text);
      line = hunk ? Number(hunk[1]) : 0;
    } else if (!inHeader && file !== null && text.startsWith('+')) {
      if (text.includes(ALLOW)) {
        found.push({ file, line });
      }
      line += 1;
    }
  }
  return found;
}

function render(allows, link) {
  if (allows.length === 0) {
    return `${MARKER}\n### ✅ Inline \`${ALLOW}\` comments\n\nNo inline \`${ALLOW}\` found anymore.\n`;
  }
  // The name is shown escaped: a line break in it would end the code span and let the rest of
  // the name render as markdown.
  const shown = file => JSON.stringify(file).slice(1, -1).replaceAll('`', "'");
  const items = allows.map(({ file, line }) => `- [\`${shown(file)}:${line}\`](${link(file, line)})`);
  return [
    MARKER,
    `### ⚠️ Inline \`${ALLOW}\` comments`,
    '',
    `This pull request adds ${allows.length} inline \`${ALLOW}\` comment${allows.length === 1 ? '' : 's'}. ` +
      'Gitleaks skips the line each one is on. The base branch keeps a Gitleaks config or ignore file, ' +
      'where an allowance can be reviewed in one place:',
    '',
    ...items,
    '',
  ].join('\n');
}

// The comment an earlier run posted: one that starts with the marker and was written by the
// identity posting now, so another user's comment with the marker is never taken for it. The
// workflow token cannot ask who it is, and writes as a bot, which no user can post as.
async function ownComment(github, comments) {
  let login = null;
  try {
    login = (await github.rest.users.getAuthenticated()).data.login;
  } catch {
    login = null;
  }
  return comments.find(comment => (comment.body || '').startsWith(MARKER) && comment.user && (login ? comment.user.login === login : comment.user.type === 'Bot'));
}

module.exports = async function run({ github, context, core }) {
  const base = process.env.BASE_SHA;
  const head = process.env.HEAD_SHA;
  const configs = [process.env.GITLEAKS_CONFIG, '.gitleaks.toml', '.gitleaksignore'].filter(Boolean);
  if (!configs.some(file => inCommit(base, file))) {
    core.info('The base branch keeps no Gitleaks config or ignore file, so inline gitleaks:allow comments are not listed');
    return;
  }

  const allows = addedAllows(git(['-c', 'core.quotePath=false', 'diff', '--no-color', '--no-ext-diff', '-U0', `${base}...${head}`], base));
  const { owner, repo } = context.repo;
  const issue_number = context.payload.pull_request.number;
  const link = (file, line) => `${context.serverUrl}/${owner}/${repo}/blob/${head}/${file.split('/').map(encodeURIComponent).join('/')}#L${line}`;

  try {
    const comments = await github.paginate(github.rest.issues.listComments, { owner, repo, issue_number, per_page: 100 });
    const existing = await ownComment(github, comments);
    if (allows.length === 0 && !existing) {
      return;
    }
    const body = render(allows, link);
    if (existing) {
      await github.rest.issues.updateComment({ owner, repo, comment_id: existing.id, body });
    } else {
      await github.rest.issues.createComment({ owner, repo, issue_number, body });
    }
  } catch (error) {
    for (const { file, line } of allows) {
      core.warning(`Inline ${ALLOW} added: Gitleaks skips this line`, { file, startLine: line });
    }
    core.warning(`Could not post the inline ${ALLOW} comment, which needs pull-requests: write, a scope a fork's pull request does not get: ${error.message}`);
  }
};

module.exports.addedAllows = addedAllows;
module.exports.render = render;
module.exports.MARKER = MARKER;
