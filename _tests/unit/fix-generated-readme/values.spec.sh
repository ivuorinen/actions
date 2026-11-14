#!/usr/bin/env shellspec
# Unit tests for the example-value fixup in _tools/fix-generated-readme.py.
#
# Every input without a metadata default gets the canonical example for its
# validation type, unless the tool names a value for that input: a version input
# whose example would otherwise name no published release. Runs the tool against
# throwaway README fixtures so the real repository is never modified.

Describe "fix-generated-readme.py example values"
TOOL="${PROJECT_ROOT}/_tools/fix-generated-readme.py"

# Write a docker-build README fixture whose quick start holds the theme's
# placeholder for the given inputs.
write_readme() {
  mkdir -p "$FIX_ROOT/docker-build"
  {
    printf '# docker-build\n\n## Quick Start\n\n```yaml\n'
    printf 'jobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - name: Run\n'
    printf '        uses: ivuorinen/actions/docker-build@main\n        with:\n'
    for input in "$@"; do
      printf '          %s: "value"\n' "$input"
    done
    printf '```\n'
  } >"$FIX_ROOT/docker-build/README.md"
}

setup_fixture() { FIX_ROOT="$(mktemp -d)"; }
cleanup_fixture() { rm -rf "$FIX_ROOT"; }
BeforeEach 'setup_fixture'
AfterEach 'cleanup_fixture'

It "names a published Buildx and BuildKit release for the version examples"
write_readme buildx-version buildkit-version
When run python3 "$TOOL" "$FIX_ROOT/docker-build/README.md"
The status should be success
The contents of file "$FIX_ROOT/docker-build/README.md" should include "buildx-version: 'v0.38.2'"
The contents of file "$FIX_ROOT/docker-build/README.md" should include "buildkit-version: 'v0.34.2'"
End

It "keeps the validation type's example for other inputs"
write_readme cache-mode
When run python3 "$TOOL" "$FIX_ROOT/docker-build/README.md"
The status should be success
The contents of file "$FIX_ROOT/docker-build/README.md" should include "cache-mode: 'max'"
End

Describe "the named versions pass the action's own validator"
Parameters
"buildx-version" "v0.38.2"
"buildkit-version" "v0.34.2"
End

It "accepts $1 $2"
When call validate_input_python "docker-build" "$1" "$2"
The status should be success
End
End
End
