# POSIX Shell Compliance

All shell scripts must be POSIX sh, not bash, with one explicit carve-out: the
`_tests/` tree (`_tests/run-tests.sh`, `_tests/framework/*`, `_tests/unit/*`,
`_tests/integration/*`) is deliberately bash because those scripts run only on
Linux CI runners and depend on ShellSpec idioms (`local`, `export -f`, arrays).
The PostToolUse `block-bashisms.sh` hook enforces this by exempting
`_tests/* | */_tests/*`. Any shell file outside `_tests/` must be strict POSIX sh.

Never use `[[ ]]`, `local`, `declare`, the `function` keyword, arrays
(`arr=()`, `${arr[@]}`), process substitution (`<(cmd)`, `>(cmd)`), `$'...'` ANSI-C
quoting, brace expansion (`{a,b,c}`), or any other bash-only construct.

Always use `set -eu` at the top of every POSIX sh script.
`set -euo pipefail` is bash-only and forbidden in POSIX sh.
The `_tests/` carve-out also covers `set -euo pipefail` in those scripts only.

Always quote shell variables: `"$var"`, `basename -- "$path"`,
`printf '%s\n' "$value"`.
Legitimate unquoted contexts are limited to deliberate word-splitting patterns
(`set -- $var`, iteration over `$@`) where `set -f` is used to disable pathname
expansion first.

Always check tool availability with `command -v <tool> >/dev/null 2>&1` before using
any tool not in POSIX base.
The full external-tool list this repo uses is:
`jq`, `bc`, `yq`, `terraform`, `tflint`, `actionlint`, `action-validator`,
`shellcheck`, `shfmt`, `shellspec`, `gh`, `docker`, `kubectl`,
`node`, `npm`, `npx`, `pnpm`, `yarn`, `bun`, `bunx`,
`python`, `python3`, `uv`, `ruff`, `pyright`, `mypy`, `pytest`,
`prettier`, `markdownlint-cli2`, `markdown-table-formatter`, `yaml-lint`,
`pre-commit`, `tar`, `gzip`, `unzip`, `curl`, `wget`, `rsync`,
`find`, `xargs`, `tr`, `sort`, `uniq`, `head`, `tail`, `cut`, `tee`, `wc`,
`mktemp`, `touch`, `chmod`, `chown`.
The list is not "tools like these" — it is the explicit set.
Add a new entry to this rule before introducing a new external tool.
Replacing an existing tool with a different external tool counts as introducing —
ask the user before swapping.

Always provide a fallback or hard-fail path when a tool is unavailable:
`command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }`.
Never silently degrade behavior or skip the check.

Never rely on a tool being present on macOS or Windows runners.
macOS ships BSD `sed`/`awk`/`date`/`find`/`grep`; Windows `bash` is git-bash without
GNU coreutils, gawk, gsed, or `date -d`.

When parsing dates, always use `date -u +"%Y-%m-%dT%H:%M:%SZ"`.
Never use `date -d`, `date --iso-8601`, `date -I`, or any GNU-only flag.

When using `sed`, always use `sed -E` (BSD+GNU compatible).
Never use `sed -i` without an extension argument
(`sed -i.bak '...' file && rm -f file.bak`).

When using `awk`, never rely on GAWK-only functions: `gensub`, `strftime`, `mktime`,
`systime`, length-with-string-arg, `asort`, `asorti`, `genmatch`, `patsplit`, or
`delete a` to clear arrays.

When using `grep`, always use `grep -E` for extended regex.
Never use `grep -P` (PCRE — GNU-only).
