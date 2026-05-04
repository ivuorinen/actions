# POSIX Shell Compliance

All shell scripts must be POSIX sh, not bash — never use `[[ ]]`, `local`, `declare`, or the `function` keyword.
Always use `set -eu` at the top of every shell script.
Always quote shell variables: `"$var"`, `basename -- "$path"`.
Always check tool availability with `command -v <tool> >/dev/null 2>&1` before using jq, bc, terraform, or other optional tools.
Always provide fallbacks for tools unavailable on macOS or Windows runners.
