#!/usr/bin/env shellspec
# Unit tests for the permission fixup in _tools/fix-generated-readme.py.
#
# The generated Quick Start must declare a permission contract that matches what
# the example actually does: the mode it demonstrates, and the checkout step the
# theme always emits. Verifies the tool against throwaway README fixtures so the
# real repository is never modified.

Describe "fix-generated-readme.py permissions"
TOOL="${PROJECT_ROOT}/_tools/fix-generated-readme.py"

# Write a README fixture for <action> with the given Permissions table rows and
# quick-start body, mirroring the shape gh-action-readme emits.
write_readme() {
  local action="$1" rows="$2" quickstart="$3"
  mkdir -p "$FIX_ROOT/$action"
  {
    printf '# %s\n\n## Quick Start\n\n```yaml\n%s\n```\n\n' "$action" "$quickstart"
    if [ -n "$rows" ]; then
      printf '## Permissions\n\n| Permission | Access Level |\n| --- | --- |\n%s\n\n' "$rows"
      printf '**Usage in workflow:**\n\n```yaml\npermissions:\n  contents: write\n```\n'
    fi
  } >"$FIX_ROOT/$action/README.md"
}

JOB_WITH_CHECKOUT='name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Run'

# Number of job-level `permissions:` blocks the tool injected into the README.
count_permission_blocks() {
  grep -c '^    permissions:$' "$FIX_ROOT/pre-commit/README.md"
}

setup_fixture() { FIX_ROOT="$(mktemp -d)"; }
cleanup_fixture() { rm -rf "$FIX_ROOT"; }
BeforeEach 'setup_fixture'
AfterEach 'cleanup_fixture'

Describe "mode-gated scopes"
It "downgrades contents to read for the check-mode quick start"
write_readme eslint-lint '| `contents` | `write` |
| `security-events` | `write` |' "$JOB_WITH_CHECKOUT"
When run python3 "$TOOL" "$FIX_ROOT/eslint-lint/README.md"
The status should be success
# The example runs `mode: check`; write is fix-mode only, and the comment
# says so rather than leaving the reader to reconcile it with the table.
The contents of file "$FIX_ROOT/eslint-lint/README.md" should include "contents: read # \`mode: 'fix'\` needs write to push"
The contents of file "$FIX_ROOT/eslint-lint/README.md" should include "security-events: write"
End

It "leaves the Permissions table itself stating the full contract"
write_readme prettier-lint '| `contents` | `write` |' "$JOB_WITH_CHECKOUT"
When run python3 "$TOOL" "$FIX_ROOT/prettier-lint/README.md"
The status should be success
The contents of file "$FIX_ROOT/prettier-lint/README.md" should include "| \`contents\` | \`write\` |"
End

It "keeps the documented level for an action with no mode override"
write_readme python-lint-fix '| `contents` | `write` |' "$JOB_WITH_CHECKOUT"
When run python3 "$TOOL" "$FIX_ROOT/python-lint-fix/README.md"
The status should be success
The contents of file "$FIX_ROOT/python-lint-fix/README.md" should include "      contents: write"
End
End

Describe "checkout coverage"
It "grants contents: read when the contract omits contents but checkout runs"
write_readme stale '| `issues` | `write` |
| `pull-requests` | `write` |' "$JOB_WITH_CHECKOUT"
When run python3 "$TOOL" "$FIX_ROOT/stale/README.md"
The status should be success
The contents of file "$FIX_ROOT/stale/README.md" should include "      contents: read"
The contents of file "$FIX_ROOT/stale/README.md" should include "      issues: write"
End

It "grants contents: read when the action documents no permissions at all"
write_readme docker-build '' "$JOB_WITH_CHECKOUT"
When run python3 "$TOOL" "$FIX_ROOT/docker-build/README.md"
The status should be success
The contents of file "$FIX_ROOT/docker-build/README.md" should include "    permissions:
      contents: read"
End

It "adds no block when there is neither a contract nor a checkout step"
write_readme go-build '' 'name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Run'
When run python3 "$TOOL" "$FIX_ROOT/go-build/README.md"
The status should be success
The contents of file "$FIX_ROOT/go-build/README.md" should not include "permissions:"
End
End

Describe "blocks left alone"
It "does not inject into a snippet that declares no job"
write_readme codeql-analysis '| `contents` | `read` |' '- name: Run
  uses: ivuorinen/actions/codeql-analysis@vYYYY.MM.DD'
When run python3 "$TOOL" "$FIX_ROOT/codeql-analysis/README.md"
The status should be success
# The only `permissions:` left is the table's own usage snippet.
The contents of file "$FIX_ROOT/codeql-analysis/README.md" should not include "    permissions:"
End

It "leaves a second runnable workflow outside the Quick Start untouched"
mkdir -p "$FIX_ROOT/pre-commit"
{
  printf '# pre-commit\n\n## Quick Start\n\n```yaml\n%s\n```\n\n' "$JOB_WITH_CHECKOUT"
  printf '## Permissions\n\n| Permission | Access Level |\n| --- | --- |\n| `contents` | `write` |\n\n'
  # A development workflow that never invokes this action must not inherit its
  # permission contract just because it is a runnable job.
  printf '## Development\n\n```yaml\nname: Setup\non: [push]\n\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - run: npm ci\n```\n'
} >"$FIX_ROOT/pre-commit/README.md"
When run python3 "$TOOL" "$FIX_ROOT/pre-commit/README.md"
The status should be success
# Exactly one injected block, and it is the Quick Start's.
The result of function count_permission_blocks should equal 1
The contents of file "$FIX_ROOT/pre-commit/README.md" should include "    runs-on: ubuntu-latest
    steps:
      - run: npm ci"
End

It "does not override a job that already declares permissions"
write_readme go-lint '| `contents` | `write` |' 'name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4'
When run python3 "$TOOL" "$FIX_ROOT/go-lint/README.md"
The status should be success
The contents of file "$FIX_ROOT/go-lint/README.md" should not include "      contents: write"
End
End
End
