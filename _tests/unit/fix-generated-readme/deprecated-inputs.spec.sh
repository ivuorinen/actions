#!/usr/bin/env shellspec
# Unit tests for the deprecated-input fixup in _tools/fix-generated-readme.py.
#
# Examples are meant to be copied, so they must not set an input the action
# ignores. The tool reads deprecationMessage from the real action.yml named by the
# fixture's directory, and only the throwaway README fixture is modified.

Describe "fix-generated-readme.py deprecated inputs"
TOOL="${PROJECT_ROOT}/_tools/fix-generated-readme.py"
FIX_ROOT="${SHELLSPEC_TMPBASE}/deprecated-inputs"

write_readme() {
  mkdir -p "$FIX_ROOT/$1"
  cat >"$FIX_ROOT/$1/README.md" <<'EOF'
| `autopep8-version` | Deprecated and ignored |

```yaml
- uses: ivuorinen/actions/example@vYYYY.MM.DD
  with:
    autopep8-version: '1.2.3'
    flake8-version: '1.2.3'
    max-retries: '3'
```
EOF
}

It "removes deprecated inputs from the examples and keeps the rest"
write_readme python-lint-fix
When run python3 "$TOOL" "$FIX_ROOT/python-lint-fix/README.md"
The status should be success
The contents of file "$FIX_ROOT/python-lint-fix/README.md" should not include "autopep8-version: "
The contents of file "$FIX_ROOT/python-lint-fix/README.md" should not include "flake8-version: "
The contents of file "$FIX_ROOT/python-lint-fix/README.md" should include "max-retries: '3'"
End

It "keeps the deprecated input in the inputs table"
write_readme python-lint-fix
When run python3 "$TOOL" "$FIX_ROOT/python-lint-fix/README.md"
The status should be success
The contents of file "$FIX_ROOT/python-lint-fix/README.md" should include '| `autopep8-version` |'
End

It "leaves an input alone in an action that has not deprecated it"
write_readme go-lint
When run python3 "$TOOL" "$FIX_ROOT/go-lint/README.md"
The status should be success
The contents of file "$FIX_ROOT/go-lint/README.md" should include "autopep8-version: "
End
End
