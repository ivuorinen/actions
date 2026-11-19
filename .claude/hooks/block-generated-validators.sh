#!/bin/sh
set -eu

# Block direct edits to generated per-action validate.py files.
#
# Each <action>/validate.py is produced by _validation/generate.py from the canonical
# _validation/kit.py (check implementations) + _validation/spec.py (input -> check map).
# Hand-editing one would drift from the generator. To change what an action validates,
# edit _validation/spec.py (or kit.py) and run `make update-validators`.

# shellcheck source=SCRIPTDIR/lib.sh
. "$(dirname -- "$0")/lib.sh"

read_tool_call
FILE_PATH=$(input_field '.tool_input.file_path // .tool_input.filePath')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
*/validate.py)
  deny 'validate.py is auto-generated. Edit _validation/spec.py or _validation/kit.py and run make update-validators instead.'
  ;;
esac
