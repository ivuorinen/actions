#!/bin/sh
# Route all Bash through context-mode: permit only `git commit` and `git push`.
#
# Every other command — reads (ls, cat, grep, git status/diff/log, make, gh
# queries) AND mutations (git add, mkdir, rm, mv, make targets, gh writes) — must
# go through the context-mode MCP tools (ctx_execute / ctx_batch_execute), which
# persist filesystem and git-index changes to the real repo; file content goes
# through Edit/Write. This keeps terminal output out of the context window.
# See .claude/rules/context-mode-always.md.
set -eu

# shellcheck source=SCRIPTDIR/lib.sh
. "$(dirname -- "$0")/lib.sh"

read_tool_call
CMD=$(input_field '.tool_input.command')

# Valid input with no command -> nothing to inspect.
if [ -z "$CMD" ]; then
  exit 0
fi

NL='
'
TAB=$(printf '\t')
# Drop the blanks the shell skips before the first word; later lines keep theirs.
TRIMMED=$CMD
while :; do
  case "$TRIMMED" in
  " "* | "$TAB"* | "$NL"*) TRIMMED=${TRIMMED#?} ;;
  *) break ;;
  esac
done
FIRST=${TRIMMED%%"$NL"*}

# The first line is allowed only when it is one of the forms below, word for word.
# V is a value: characters sh, bash and zsh treat as text, not starting with = (zsh would
# replace =name with a command's path). The one quoted form is -m '...', inside which nothing
# expands. Options are listed rather than refused, since git accepts any unambiguous
# abbreviation of one (--rec for --receive-pack, which runs a program). This assumes no zsh
# global alias is defined for a plain word, since one would expand in argument position.
V='[A-Za-z0-9_./:@+,%-][A-Za-z0-9_./:@+,%=-]*'
# A commit needs a message source, or git would open an editor.
CFLAG='--amend|-s|--signoff|-q|--quiet'
MSG="-F $V|-m $V|-m '[^']*'|--no-edit"
COMMIT="git commit( ($CFLAG))*( ($MSG))( ($CFLAG|$MSG))*"
# A push names a remote (no / or :, so not a path or URL) and refs that start with neither
# + (a force push without a lease) nor : (deleting the remote branch).
REF='[A-Za-z0-9_@][A-Za-z0-9_./@-]*'
PFLAG="-u|--set-upstream|--tags|--follow-tags|--dry-run|--force-with-lease(=$REF(:$REF)?)?"
PUSH="git push( ($PFLAG))*( [A-Za-z0-9_][A-Za-z0-9_.-]*( $REF(:$REF)?)*)?"
# A quoted heredoc delimiter keeps the shell from expanding anything in the body.
HEREDOC="git commit( ($CFLAG|--no-edit))* -F - <<'[A-Za-z_][A-Za-z0-9_]*'"

first_line_matches() {
  printf '%s\n' "$FIRST" | grep -E -x -q -- "$1"
}

allowed() {
  if [ "$FIRST" = "$TRIMMED" ]; then
    first_line_matches "($COMMIT)|($PUSH)"
    return
  fi
  # Further lines are a commit message: the body of the heredoc the first line opens, closed
  # by its delimiter on the last line and on no line before it.
  first_line_matches "$HEREDOC" || return 1
  delim=${FIRST##*<<\'}
  delim=${delim%\'}
  [ "${TRIMMED##*"$NL"}" = "$delim" ] || return 1
  [ "$(printf '%s\n' "$TRIMMED" | grep -c -x -F -- "$delim")" -eq 1 ]
}

if allowed; then
  exit 0
fi

REASON="Bash is restricted to one 'git commit' or 'git push' in this repo, in the forms that"
REASON="$REASON .claude/rules/context-mode-always.md lists: a commit message goes in -m '...' or a"
REASON="$REASON -F - <<'EOF' heredoc. Route everything else through context-mode: reads AND mutations"
REASON="$REASON (git add, mkdir, rm, mv, make, gh, ...) via ctx_execute or ctx_batch_execute (these persist"
REASON="$REASON filesystem and git-index changes to the real repo), and file content via Edit/Write."
REASON="$REASON This keeps terminal output out of the context window."
deny "$REASON"
