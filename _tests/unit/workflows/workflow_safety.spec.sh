#!/usr/bin/env shellspec
# Static checks for the workflows, the local composite actions, the published actions and
# the integration-test workflows: no ${{ }} expression inside a run: block, every run: block
# begun with set -eu, actions/checkout pinned by full SHA, and a pr-lint job that reads
# contents and only writes where MegaLinter reports. The checks read the YAML as text so they
# need nothing beyond python3.

# Scans the given files, or the workflows, the local composite actions, the published actions
# and the integration-test workflows when no file is given, each as .yml or .yaml. A location
# that matches no file fails the scan instead of dropping out of it. The mode picks what is
# printed:
#   expressions  "<file>:<line>: <text>" for every ${{ }} inside a run: block
#   set-eu       "<file>:<line>: <command>" for every run: block whose first command, past
#                comments and blank lines, is not set -eu (or bash's set -euo pipefail)
#   checkout     "<file>:<line>: <ref>" for every actions/checkout ref a uses: key
#                names that is not a full commit SHA; finding no ref at all fails
workflow_scan() {
  command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required" >&2
    return 1
  }
  python3 -I - "$@" <<'PY'
import glob
import re
import sys

mode, files = sys.argv[1], sys.argv[2:]
if mode not in ("expressions", "set-eu", "checkout"):
    sys.exit("unknown mode: %s" % mode)
if not files:
    for patterns in (
        (".github/workflows/*.yml", ".github/workflows/*.yaml"),
        (".github/actions/*/action.yml", ".github/actions/*/action.yaml"),
        ("*/action.yml", "*/action.yaml"),
        ("_tests/integration/workflows/*.yml", "_tests/integration/workflows/*.yaml"),
    ):
        matched = sorted(path for pattern in patterns for path in glob.glob(pattern))
        if not matched:
            sys.exit("no file matches %s" % " or ".join(patterns))
        files += matched

key = re.compile(r"^(\s*)(?:- )?run:\s*(.*)$")
# A block scalar header: | or >, an optional indentation indicator and chomping
# indicator in either order, then an optional comment.
block = re.compile(r"^[|>](?:[1-9][-+]?|[-+][1-9]?)?(?:\s+#.*)?\s*$")
# Every uses: value on its own, quoted or not, up to whitespace, a quote or a comment,
# so a pinned ref elsewhere on the line does not cover a floating one.
uses = re.compile(r"""uses:\s*["']?(actions/checkout@[^\s"'#]*)""")
pinned = re.compile(r"actions/checkout@[0-9a-f]{40}")
# A YAML comment: a # at the line start or after whitespace, to the end of the line.
# Only the checkout scan drops it; GitHub expands ${{ }} even inside a shell comment.
comment = re.compile(r"(?:^|\s)#.*")


# set -eu, or bash's set -euo pipefail, which the integration-test workflows may use, ended by
# whitespace, the line's end or a ; before the next command.
guard = re.compile(r"set -eu(?:o pipefail)?(?:\s|;|$)")


def run_blocks(lines):
    """Yield each run: block's lines as (line number, text): one for a value on the key's line,
    without the quotes around it when it is a quoted scalar."""
    index = 0
    while index < len(lines):
        match = key.match(lines[index])
        index += 1
        if not match:
            continue
        indent = len(match.group(1)) + (2 if lines[index - 1].lstrip().startswith("- ") else 0)
        value = match.group(2).rstrip()
        if len(value) >= 2 and value[0] in "'\"" and value[-1] == value[0]:
            value = value[1:-1]
        body = [(index, value)]
        if block.match(match.group(2)):
            body = []
            while index < len(lines):
                text = lines[index]
                if text.strip() and len(text) - len(text.lstrip()) <= indent:
                    break
                body.append((index + 1, text))
                index += 1
        yield body


def report_expressions(path, lines):
    for body in run_blocks(lines):
        for number, text in body:
            if "${{" in text:
                print("%s:%d: %s" % (path, number, text.strip()))


def report_unguarded(path, lines):
    for body in run_blocks(lines):
        commands = [(number, text.strip()) for number, text in body if text.strip() and not text.strip().startswith("#")]
        if commands and not guard.match(commands[0][1]):
            print("%s:%d: %s" % (path, commands[0][0], commands[0][1]))


def report_checkout_refs(path, lines):
    found = 0
    for number, text in enumerate(lines, 1):
        for ref in uses.findall(comment.sub("", text, count=1)):
            found += 1
            if not pinned.fullmatch(ref):
                print("%s:%d: %s" % (path, number, ref))
    return found


found = 0
for path in files:
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    if mode == "expressions":
        report_expressions(path, lines)
    elif mode == "set-eu":
        report_unguarded(path, lines)
    else:
        found += report_checkout_refs(path, lines)
if mode == "checkout" and not found:
    sys.exit("no actions/checkout reference found")
PY
}

# Prints every scope the pr-lint job is granted as "scope=level", sorted. The block runs
# from the job's `permissions:` key to the next line indented as deep as that key or
# less; blank lines and comments inside it do not end it.
pr_lint_permissions() {
  command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required" >&2
    return 1
  }
  python3 -I - "${1:-.github/workflows/pr-lint.yml}" <<'PY'
import re
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    lines = handle.read().splitlines()
scopes = []
inside = False
for text in lines:
    if re.match(r"^    permissions:\s*$", text):
        inside = True
        continue
    if not inside:
        continue
    content = text.split("#", 1)[0].rstrip()
    if not content:
        continue
    if len(content) - len(content.lstrip()) <= 4:
        break
    scope, _, level = content.strip().partition(":")
    scopes.append("%s=%s" % (scope.strip(), level.strip()))
print(" ".join(sorted(scopes)))
PY
}

# Prints the paths filters on a workflow's pull_request trigger, pr-lint.yml when no file
# is given, as a sorted list. PyYAML reads the `on:` key as True.
pull_request_path_filters() {
  _harness_python - "${1:-.github/workflows/pr-lint.yml}" <<'PY'
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as handle:
    doc = yaml.safe_load(handle)
trigger = (doc.get("on", doc.get(True)) or {}).get("pull_request") or {}
print(sorted(key for key in trigger if key.startswith("paths")))
PY
}

# Runs pr-lint.yml's Cleanup step in a scratch directory that holds a temporary MegaLinter
# file and a report, and prints the files left.
megalinter_cleanup_leaves() {
  cleanup_script=$(
    _harness_python - .github/workflows/pr-lint.yml <<'PY'
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as handle:
    doc = yaml.safe_load(handle)
for job in doc["jobs"].values():
    for step in job.get("steps", []):
        if step.get("name") == "Cleanup":
            print(step["run"])
PY
  )
  cleanup_dir="${SHELLSPEC_TMPBASE}/megalinter-cleanup"
  mkdir -p "$cleanup_dir/megalinter-reports"
  : >"$cleanup_dir/megalinter.log"
  : >"$cleanup_dir/megalinter-reports/megalinter.log"
  (cd "$cleanup_dir" && sh -c "$cleanup_script" && find . -type f | sort)
}

Describe "GitHub workflows and actions"
It "contain no \${{ }} expression inside a run: block"
When call workflow_scan expressions
The status should be success
The output should equal ""
End

# GitHub's sh and bash wrappers add -e but not -u, and a one-line run: is a script too.
It "begin every run: block with set -eu"
When call workflow_scan set-eu
The status should be success
The output should equal ""
End

It "name actions/checkout only by full commit SHA"
When call workflow_scan checkout
The status should be success
The output should equal ""
End

# A job's permissions replace the workflow's, so a grant at the top reaches only a job that names
# none; each job names what it needs instead. grep -L's exit status differs between versions, so
# only the files it lists count.
It "grant nothing at the top of a workflow"
When call grep -L -x 'permissions: {}' .github/workflows/*.yml
The output should equal ""
End

It "give the pr-lint job read on contents and write only where MegaLinter reports"
When call pr_lint_permissions
The status should be success
The output should equal "contents=read pull-requests=write security-events=write statuses=write"
End

It "remove temporary MegaLinter files after linting but keep the reports"
When call megalinter_cleanup_leaves
The status should be success
The output should equal "./megalinter-reports/megalinter.log"
End

# The branch ruleset requires the MegaLinter check. A workflow that a paths filter skips
# reports no check, so a pull request it skips can never merge.
It "run MegaLinter on every pull request, since the ruleset requires its check"
When call pull_request_path_filters
The status should be success
The output should equal "[]"
End

# Any process in the job can read a command's arguments, so a URL must not carry a
# credential; git takes one from a credential helper instead. The pattern takes a variable or
# an expression before the @ of the host part, as the user or the password, quoted or not.
CREDENTIAL_IN_URL='://[^/[:space:]"]*"?[$][^/[:space:]@]*([[:space:]][^/@]*)?@'

It "keep credentials out of URLs on the command line"
When call grep -E -n -- "$CREDENTIAL_IN_URL" .github/workflows/*.yml .github/actions/*/action.yml ./*/action.yml _tests/integration/workflows/*.yml
The status should be failure
The output should equal ""
End

# The check above passes when nothing matches, so the pattern must match the forms it is for.
urls_with_credentials() {
  printf '%s\n' \
    'https://x-access-token:${GH_TOKEN}@github.com/o/r' \
    'https://$TOKEN@github.com/o/r' \
    'https://u:${{ secrets.T }}@github.com/o/r' \
    'https://"$TOKEN"@github.com/o/r' \
    'https://github.com/${REPO}' \
    'https://${HOST}/path' \
    'https://example.com/$VAR' |
    grep -E -- "$CREDENTIAL_IN_URL"
}

It "catches a credential in each form, and no plain URL"
When call urls_with_credentials
The lines of output should equal 4
The output should not include 'https://github.com/${REPO}'
The output should not include 'https://${HOST}/path'
The output should not include 'https://example.com/$VAR'
End
End

Describe "the run: block scanner"
# Writes a workflow whose run: block opens with the given header and holds an
# expression on line 5, indented two past the run key as an indentation indicator
# of 2 requires.
block_header_workflow() {
  printf 'jobs:\n  test:\n    steps:\n      - run: %s\n          echo "${{ github.sha }}"\n' "$1" \
    >"${SHELLSPEC_TMPBASE}/header.yml"
}

Parameters
"|"
"| # note"
"|2"
"|-2"
">2- # folded"
End

It "reports an expression in a block opened with $1"
block_header_workflow "$1"
When call workflow_scan expressions "${SHELLSPEC_TMPBASE}/header.yml"
The status should be success
The output should include ':5: echo "${{ github.sha }}"'
End
End

Describe "the set -eu scanner"
# Writes a workflow whose only step runs the given run: value, from line 4.
run_workflow() {
  printf 'jobs:\n  test:\n    steps:\n      - run: %s\n' "$1" >"${SHELLSPEC_TMPBASE}/guard.yml"
}

Describe "reports"
Parameters
"make test" ":4: make test"
"|\n          # a note\n          make test" ":6: make test"
"|\n          echo start\n          set -eu" ":5: echo start"
"|\n          set -e\n          make test" ":5: set -e"
"'make test'" ":4: make test"
End

It "the first command of: $1"
run_workflow "$(printf "$1")"
When call workflow_scan set-eu "${SHELLSPEC_TMPBASE}/guard.yml"
The status should be success
The output should equal "${SHELLSPEC_TMPBASE}/guard.yml$2"
End
End

Describe "accepts"
Parameters
"|\n          set -eu\n          make test"
"|\n          # a note\n\n          set -eu\n          make test"
"|\n          set -euo pipefail\n          make test"
"set -eu; make test"
"'set -eu; make test'"
"\"set -eu; make test\""
End

It "$1"
run_workflow "$(printf "$1")"
When call workflow_scan set-eu "${SHELLSPEC_TMPBASE}/guard.yml"
The status should be success
The output should equal ""
End
End
End

Describe "the checkout scanner"
# Writes a workflow whose only step, on line 4, is the given uses: line.
checkout_workflow() {
  printf 'jobs:\n  test:\n    steps:\n      - %s\n' "$1" >"${SHELLSPEC_TMPBASE}/checkout.yml"
}

Describe "reports"
Parameters
"uses: actions/checkout@main" "actions/checkout@main"
"uses: actions/checkout@v4 # actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1" "actions/checkout@v4"
"uses: 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1x'" "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1x"
End

It "$2 from: $1"
checkout_workflow "$1"
When call workflow_scan checkout "${SHELLSPEC_TMPBASE}/checkout.yml"
The status should be success
The output should equal "${SHELLSPEC_TMPBASE}/checkout.yml:4: $2"
End
End

Describe "accepts"
Parameters
"uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
"uses: \"actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1\""
"uses: 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1' # v7.0.1"
End

It "$1"
checkout_workflow "$1"
When call workflow_scan checkout "${SHELLSPEC_TMPBASE}/checkout.yml"
The status should be success
The output should equal ""
End
End

It "ignores references in comments"
printf 'jobs:\n  test:\n    steps:\n      # - uses: actions/checkout@v4\n      - uses: actions/checkout@%s # was uses: actions/checkout@main\n' \
  3d3c42e5aac5ba805825da76410c181273ba90b1 >"${SHELLSPEC_TMPBASE}/checkout.yml"
When call workflow_scan checkout "${SHELLSPEC_TMPBASE}/checkout.yml"
The status should be success
The output should equal ""
End

It "fails when no file holds a checkout reference"
printf 'jobs: {}\n' >"${SHELLSPEC_TMPBASE}/none.yml"
When call workflow_scan checkout "${SHELLSPEC_TMPBASE}/none.yml"
The status should be failure
The error should equal "no actions/checkout reference found"
End
End

Describe "the default scan"
# Enters a tree with a .yaml workflow, a local composite action named action.yaml, a
# published action and a .yaml integration-test workflow, where all but the local action
# hold a ${{ }} expression in a run: block. Without the local action the scan would fail,
# so it also shows that action.yaml counts.
enter_default_scan_tree() {
  tree="${SHELLSPEC_TMPBASE}/default-scan"
  mkdir -p "$tree/.github/workflows" "$tree/.github/actions/local" "$tree/published" \
    "$tree/_tests/integration/workflows"
  printf 'jobs:\n  test:\n    steps:\n      - run: echo "${{ github.sha }}"\n' >"$tree/.github/workflows/ci.yaml"
  printf 'runs:\n  steps:\n    - run: echo ok\n' >"$tree/.github/actions/local/action.yaml"
  printf 'runs:\n  steps:\n    - run: echo "${{ inputs.name }}"\n' >"$tree/published/action.yml"
  printf 'jobs:\n  test:\n    steps:\n      - run: echo "${{ github.ref }}"\n' \
    >"$tree/_tests/integration/workflows/flow.yaml"
  cd "$tree" || return
}

It "covers .yaml files, the published actions and the integration-test workflows"
enter_default_scan_tree
When call workflow_scan expressions
The status should be success
The lines of output should equal 3
The line 1 of output should equal '.github/workflows/ci.yaml:4: echo "${{ github.sha }}"'
The line 2 of output should equal 'published/action.yml:3: echo "${{ inputs.name }}"'
The line 3 of output should equal '_tests/integration/workflows/flow.yaml:4: echo "${{ github.ref }}"'
End
End

Describe "the scans in a tree without .github/actions"
# Enters a tree whose workflow and action pin checkout by SHA, so the missing
# directory is the only thing wrong with it.
enter_tree_without_local_actions() {
  tree="${SHELLSPEC_TMPBASE}/no-local-actions"
  mkdir -p "$tree/.github/workflows" "$tree/foo"
  pin='      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1\n'
  printf "jobs:\n  test:\n    steps:\n$pin" >"$tree/.github/workflows/ci.yml"
  printf "runs:\n  steps:\n$pin" >"$tree/foo/action.yml"
  cd "$tree" || return
}

Parameters
checkout
expressions
End

It "fail the $1 scan"
enter_tree_without_local_actions
When call workflow_scan "$1"
The status should be failure
The error should equal "no file matches .github/actions/*/action.yml or .github/actions/*/action.yaml"
End
End

Describe "the helpers without python3"
# Runs the given helper with a PATH that holds no python3.
without_python3() {
  PATH="${SHELLSPEC_TMPBASE}/no-python3" "$@"
}

It "stop workflow_scan with a diagnostic"
When call without_python3 workflow_scan expressions
The status should be failure
The error should equal "python3 is required"
End

It "stop pr_lint_permissions with a diagnostic"
When call without_python3 pr_lint_permissions
The status should be failure
The error should equal "python3 is required"
End
End
