#!/usr/bin/env shellspec
# Unit tests for the example-value fixup in _tools/fix-generated-readme.py.
#
# Every input without a metadata default gets the canonical example for its
# validation type, unless the tool names a value for that input: a version input
# whose example would otherwise name no published release. Runs the tool against
# throwaway README fixtures so the real repository is never modified.

Describe "fix-generated-readme.py example values"
TOOL="${PROJECT_ROOT}/_tools/fix-generated-readme.py"

# Write a README fixture for <action> whose quick start holds the theme's
# placeholder for the given inputs.
write_readme() {
  local action="$1"
  shift
  mkdir -p "$FIX_ROOT/$action"
  {
    printf '# %s\n\n## Quick Start\n\n```yaml\n' "$action"
    printf 'jobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - name: Run\n'
    printf '        uses: ivuorinen/actions/%s@main\n        with:\n' "$action"
    for input in "$@"; do
      printf '          %s: "value"\n' "$input"
    done
    printf '```\n'
  } >"$FIX_ROOT/$action/README.md"
}

setup_fixture() { FIX_ROOT="$(mktemp -d)"; }
cleanup_fixture() { rm -rf "$FIX_ROOT"; }
BeforeEach 'setup_fixture'
AfterEach 'cleanup_fixture'

Describe "a version input names a published release"
Parameters
"docker-build" "buildx-version" "v0.38.2"
"docker-build" "buildkit-version" "v0.34.2"
"go-build" "go-version" "1.27"
"language-version-detect" "default-version" "3.13"
End

It "writes $2: $3 for $1"
write_readme "$1" "$2"
When run python3 "$TOOL" "$FIX_ROOT/$1/README.md"
The status should be success
The contents of file "$FIX_ROOT/$1/README.md" should include "$2: '$3'"
End

It "uses a value $1's own validator accepts for $2"
When call validate_input_python "$1" "$2" "$3"
The status should be success
End
End

It "keeps the validation type's example for other inputs"
write_readme docker-build cache-mode
When run python3 "$TOOL" "$FIX_ROOT/docker-build/README.md"
The status should be success
The contents of file "$FIX_ROOT/docker-build/README.md" should include "cache-mode: 'max'"
End
End
