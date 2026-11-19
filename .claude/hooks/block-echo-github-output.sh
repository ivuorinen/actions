#!/bin/sh
set -eu

# shellcheck source=SCRIPTDIR/lib.sh
. "$(dirname -- "$0")/lib.sh"

read_tool_call
FILE_PATH=$(input_field '.tool_input.file_path // .tool_input.filePath')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check action.yml files
case "$FILE_PATH" in
*/action.yml | */.github/workflows/*.yml | */.github/workflows/*.yaml) ;;
*) exit 0 ;;
esac

# Check new_string (Edit) or content (Write) for echo→GITHUB_OUTPUT pattern
NEW_CONTENT=$(input_field '.tool_input.new_string // .tool_input.content')

if [ -z "$NEW_CONTENT" ]; then
  exit 0
fi

if printf '%s' "$NEW_CONTENT" | grep -q 'echo.*>>.*GITHUB_OUTPUT'; then
  # shellcheck disable=SC2016
  deny 'Use printf with format-string separation for GITHUB_OUTPUT, as in printf '\''key=%s\n'\'' "$value" >> "$GITHUB_OUTPUT", not echo.'
fi
