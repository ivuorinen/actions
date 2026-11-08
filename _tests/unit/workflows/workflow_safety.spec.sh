#!/usr/bin/env shellspec
# Static checks for the workflows, the local composite actions and the published
# actions: no ${{ }} expression inside a run: block, actions/checkout pinned by full
# SHA, and a pr-lint job that reads contents and only writes where MegaLinter reports.
# The checks read the YAML as text so they need nothing beyond python3.

# Scans the given files, or the workflows, the local composite actions and the
# published actions when no file is given, each as .yml or .yaml. A location that
# matches no file fails the scan instead of dropping out of it. The mode picks what is
# printed:
#   expressions  "<file>:<line>: <text>" for every ${{ }} inside a run: block
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
if mode not in ("expressions", "checkout"):
    sys.exit("unknown mode: %s" % mode)
if not files:
    for patterns in (
        (".github/workflows/*.yml", ".github/workflows/*.yaml"),
        (".github/actions/*/action.yml", ".github/actions/*/action.yaml"),
        ("*/action.yml", "*/action.yaml"),
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


def report_expressions(path, lines):
    index = 0
    while index < len(lines):
        match = key.match(lines[index])
        index += 1
        if not match:
            continue
        indent = len(match.group(1)) + (2 if lines[index - 1].lstrip().startswith("- ") else 0)
        body = [(index, match.group(2))]
        if block.match(match.group(2)):
            body = []
            while index < len(lines):
                text = lines[index]
                if text.strip() and len(text) - len(text.lstrip()) <= indent:
                    break
                body.append((index + 1, text))
                index += 1
        for number, text in body:
            if "${{" in text:
                print("%s:%d: %s" % (path, number, text.strip()))


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

Describe "GitHub workflows and actions"
It "contain no \${{ }} expression inside a run: block"
When call workflow_scan expressions
The status should be success
The output should equal ""
End

It "name actions/checkout only by full commit SHA"
When call workflow_scan checkout
The status should be success
The output should equal ""
End

It "give the pr-lint job read on contents and write only where MegaLinter reports"
When call pr_lint_permissions
The status should be success
The output should equal "contents=read pull-requests=write security-events=write statuses=write"
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
# Enters a tree with a .yaml workflow, a local composite action named action.yaml and
# a published action, where the workflow and the published action each hold a ${{ }}
# expression in a run: block. Without the local action the scan would fail, so it
# also shows that action.yaml counts.
enter_default_scan_tree() {
  tree="${SHELLSPEC_TMPBASE}/default-scan"
  mkdir -p "$tree/.github/workflows" "$tree/.github/actions/local" "$tree/published"
  printf 'jobs:\n  test:\n    steps:\n      - run: echo "${{ github.sha }}"\n' >"$tree/.github/workflows/ci.yaml"
  printf 'runs:\n  steps:\n    - run: echo ok\n' >"$tree/.github/actions/local/action.yaml"
  printf 'runs:\n  steps:\n    - run: echo "${{ inputs.name }}"\n' >"$tree/published/action.yml"
  cd "$tree" || return
}

It "covers .yaml files and the published actions"
enter_default_scan_tree
When call workflow_scan expressions
The status should be success
The lines of output should equal 2
The line 1 of output should equal '.github/workflows/ci.yaml:4: echo "${{ github.sha }}"'
The line 2 of output should equal 'published/action.yml:3: echo "${{ inputs.name }}"'
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
