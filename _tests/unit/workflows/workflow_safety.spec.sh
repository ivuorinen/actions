#!/usr/bin/env shellspec
# Static checks for the workflows, the local composite actions, the published actions and
# the integration-test workflows: no ${{ }} expression inside a run: block, every run: block
# begun with set -eu, actions/checkout pinned by full SHA, and a pr-lint job that reads
# contents and only writes where MegaLinter reports. The scans parse each file with PyYAML, so
# they read a value as GitHub does: without its quotes, with its escapes decoded, without a
# comment after it, and with a value written over several lines joined.

# Scans the given files, or the workflows, the local composite actions, the published actions
# and the integration-test workflows when no file is given, each as .yml or .yaml. A location
# that matches no file fails the scan instead of dropping out of it. The mode picks what is
# printed:
#   expressions  "<file>:<line>: <text>" for every ${{ }} in a run: value
#   set-eu       "<file>:<line>: <command>" for every run: value whose first command, past
#                comments and blank lines, is not set -eu (or bash's set -euo pipefail)
#   checkout     "<file>:<line>: <ref>" for every actions/checkout ref a uses: key
#                names that is not a full commit SHA; finding no ref at all fails
#   credentials  "<file>:<line>: <ref>" for every actions/checkout step that keeps the token in
#                .git/config: one whose persist-credentials is left out, or may read as true
# A literal block's lines keep their own numbers. YAML joins the lines of a folded block and of
# a quoted or plain value, so their lines take the number of the folded block's first line, or
# of the line the value starts on.
workflow_scan() {
  command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required" >&2
    return 1
  }
  _harness_python -I - "$@" <<'PY'
import glob
import re
import sys

import yaml

mode, files = sys.argv[1], sys.argv[2:]
if mode not in ("expressions", "set-eu", "checkout", "credentials"):
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

pinned = re.compile(r"actions/checkout@[0-9a-f]{40}")
# set -eu, or bash's set -euo pipefail, which the integration-test workflows may use, ended by
# whitespace, the line's end or a ; before the next command.
guard = re.compile(r"set -eu(?:o pipefail)?(?:\s|;|$)")


def values(node, name):
    """Yield the scalar value of every name: key in the document, at any depth."""
    if isinstance(node, yaml.MappingNode):
        for key, value in node.value:
            if key.value == name and isinstance(value, yaml.ScalarNode):
                yield value
            else:
                yield from values(value, name)
    elif isinstance(node, yaml.SequenceNode):
        for item in node.value:
            yield from values(item, name)


def run_blocks(root):
    """Yield each run: value's lines as (line number, text)."""
    for node in values(root, "run"):
        lines = node.value.split("\n")
        # PyYAML counts lines from 0, and a block's start is its header.
        start = node.start_mark.line + 1
        if node.style == "|":
            yield [(start + 1 + offset, text) for offset, text in enumerate(lines)]
        elif node.style == ">":
            yield [(start + 1, text) for text in lines]
        else:
            yield [(start, text) for text in lines]


# A shell comment is part of the value, and GitHub expands ${{ }} inside it too.
def report_expressions(path, root):
    for body in run_blocks(root):
        for number, text in body:
            if "${{" in text:
                print("%s:%d: %s" % (path, number, text.strip()))


def report_unguarded(path, root):
    for body in run_blocks(root):
        commands = [(number, text.strip()) for number, text in body if text.strip() and not text.strip().startswith("#")]
        if commands and not guard.match(commands[0][1]):
            print("%s:%d: %s" % (path, commands[0][0], commands[0][1]))


def report_checkout_refs(path, root):
    found = 0
    for node in values(root, "uses"):
        if node.value.startswith("actions/checkout@"):
            found += 1
            if not pinned.fullmatch(node.value):
                print("%s:%d: %s" % (path, node.start_mark.line + 1, node.value))
    return found


def checkout_steps(node):
    """Yield the uses: value and the with: node of every step that runs actions/checkout."""
    if isinstance(node, yaml.MappingNode):
        fields = {key.value: value for key, value in node.value if isinstance(key, yaml.ScalarNode)}
        uses = fields.get("uses")
        if isinstance(uses, yaml.ScalarNode) and uses.value.startswith("actions/checkout@"):
            yield uses, fields.get("with")
        for _, value in node.value:
            yield from checkout_steps(value)
    elif isinstance(node, yaml.SequenceNode):
        for item in node.value:
            yield from checkout_steps(item)


# actions/checkout keeps the token unless its persist-credentials input, true when left out,
# reads as anything but "true" in any case (its input-helper.ts), so a quoted 'false' turns it
# off too. A ${{ }} value may read as true at run time, so it counts as true here.
def report_kept_credentials(path, root):
    for uses, inputs in checkout_steps(root):
        fields = dict(inputs.value) if isinstance(inputs, yaml.MappingNode) else {}
        persist = next((value for key, value in fields.items() if key.value == "persist-credentials"), None)
        # Like checkout's core.getInput, which trims the value before reading it.
        text = (persist.value if isinstance(persist, yaml.ScalarNode) else "true").strip()
        if text.upper() == "TRUE" or "${{" in text:
            print("%s:%d: %s" % (path, uses.start_mark.line + 1, uses.value))


found = 0
for path in files:
    with open(path, encoding="utf-8") as handle:
        root = yaml.compose(handle, Loader=yaml.SafeLoader)
    if mode == "expressions":
        report_expressions(path, root)
    elif mode == "set-eu":
        report_unguarded(path, root)
    elif mode == "credentials":
        report_kept_credentials(path, root)
    else:
        found += report_checkout_refs(path, root)
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
# only the files it lists count. GitHub never runs the integration-test workflows, but a copy of
# one into .github/workflows would run with the default token scopes.
It "grant nothing at the top of a workflow, an integration-test workflow too"
When call grep -L -x 'permissions: {}' .github/workflows/*.yml _tests/integration/workflows/*.yml
The output should equal ""
End

# A checkout that keeps the token leaves it in .git/config for every later step, which in an
# action may build or test the repository's code.
It "check out without persisting the token"
When call workflow_scan credentials
The status should be success
The output should equal ""
End

# The check above passes when it prints nothing, so it must name the checkouts it is for.
It "names a checkout whose persist-credentials is left out or may read as true"
cat >"${SHELLSPEC_TMPBASE}/checkouts.yml" <<'YAML'
jobs:
  a:
    steps:
      - name: Left out
        uses: actions/checkout@x
      - name: True
        uses: actions/checkout@x
        with:
          persist-credentials: true
      - name: Quoted TRUE
        uses: actions/checkout@x
        with:
          persist-credentials: 'TRUE'
      - name: From an expression
        uses: actions/checkout@x
        with:
          persist-credentials: ${{ inputs.persist }}
      - name: False
        uses: actions/checkout@x
        with:
          persist-credentials: false
      - name: Quoted false
        uses: actions/checkout@x
        with:
          persist-credentials: 'false'
      - name: Spaced true
        uses: actions/checkout@x
        with:
          persist-credentials: ' true '
      - name: Spaced false
        uses: actions/checkout@x
        with:
          persist-credentials: ' false '
YAML
When call workflow_scan credentials "${SHELLSPEC_TMPBASE}/checkouts.yml"
The status should be success
The lines of output should equal 5
The line 1 of output should equal "${SHELLSPEC_TMPBASE}/checkouts.yml:5: actions/checkout@x"
The line 2 of output should equal "${SHELLSPEC_TMPBASE}/checkouts.yml:7: actions/checkout@x"
The line 3 of output should equal "${SHELLSPEC_TMPBASE}/checkouts.yml:11: actions/checkout@x"
The line 4 of output should equal "${SHELLSPEC_TMPBASE}/checkouts.yml:15: actions/checkout@x"
The line 5 of output should equal "${SHELLSPEC_TMPBASE}/checkouts.yml:27: actions/checkout@x"
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

Describe "the run: value scanners"
# Writes a workflow whose only step runs the given run: value, from line 4.
run_workflow() {
  printf 'jobs:\n  test:\n    steps:\n      - run: %s\n' "$1" >"${SHELLSPEC_TMPBASE}/run.yml"
}

# GitHub reads a run: value only after YAML has decoded it, so an escape that spells $ is an
# expression, and so is one on a plain value's second line.
Describe "for expressions report"
Parameters
'"echo \\x24{{ github.sha }}"' ':4: echo ${{ github.sha }}'
'echo start\n          ${{ github.sha }}' ':4: echo start ${{ github.sha }}'
End

It "the expression YAML reads in: $1"
run_workflow "$(printf "$1")"
When call workflow_scan expressions "${SHELLSPEC_TMPBASE}/run.yml"
The status should be success
The output should equal "${SHELLSPEC_TMPBASE}/run.yml$2"
End
End

It "for expressions pass over a YAML comment after the value, which GitHub never reads"
run_workflow "'echo ok' # \${{ github.sha }}"
When call workflow_scan expressions "${SHELLSPEC_TMPBASE}/run.yml"
The status should be success
The output should equal ""
End

Describe "for set -eu report"
Parameters
"make test" ":4: make test"
"|\n          # a note\n          make test" ":6: make test"
"|\n          echo start\n          set -eu" ":5: echo start"
"|\n          set -e\n          make test" ":5: set -e"
"'make test'" ":4: make test"
"'make test' # set -eu" ":4: make test"
End

It "the first command of: $1"
run_workflow "$(printf "$1")"
When call workflow_scan set-eu "${SHELLSPEC_TMPBASE}/run.yml"
The status should be success
The output should equal "${SHELLSPEC_TMPBASE}/run.yml$2"
End
End

Describe "for set -eu accept"
Parameters
"|\n          set -eu\n          make test"
"|\n          # a note\n\n          set -eu\n          make test"
"|\n          set -euo pipefail\n          make test"
"set -eu; make test"
"'set -eu; make test'"
"\"set -eu; make test\""
"'set -eu; make test' # Run tests"
"\"set -eu; make test\" # Run tests"
"set -eu;\n          make test"
End

It "$1"
run_workflow "$(printf "$1")"
When call workflow_scan set-eu "${SHELLSPEC_TMPBASE}/run.yml"
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
