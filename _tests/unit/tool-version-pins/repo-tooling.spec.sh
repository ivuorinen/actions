#!/usr/bin/env shellspec
# Static checks on the repository's own tooling outside the actions: the pre-commit hooks, the
# Makefile, the Claude Code hooks, the test environment, the security workflow and the testing
# image fetch nothing at a floating version, check each download against a digest pinned in the
# repository, and leave each pin where Renovate can update it. check_pins.py and static.spec.sh
# cover the actions themselves; repo_commands.py reads the commands the tooling runs.

Describe "repository tooling pins"
ROOT="${PROJECT_ROOT}"
REPO_COMMANDS="${ROOT}/_tests/unit/tool-version-pins/repo_commands.py"
SETUP_ENV="${ROOT}/.github/actions/setup-test-environment/action.yml"
SECURITY_SUITE="${ROOT}/.github/workflows/security-suite.yml"
DOCKERFILE="${ROOT}/_tools/docker-testing-tools/Dockerfile"
# A shell pattern for a SHA-256 digest: 64 hexadecimal digits.
HEX64=$(printf '[0-9a-f]%.0s' $(seq 64))

before() {
  TREE=$(mktemp -d)
}
BeforeEach 'before'

after() {
  rm -rf "${TREE}"
}
AfterEach 'after'

Describe "pre-commit"
# unfrozen CONFIG: "REPO REV" for each remote hook in the pre-commit CONFIG whose rev is not a
# commit followed, on its own line, by its tag in a frozen comment, then "remote: N", the number
# of remote hooks. Parsed as YAML, so a quoted repository URL is checked like any other, and each
# rev's comment is read where the rev ends.
unfrozen() {
  _harness_python - "$1" <<'PY'
import re
import sys

import yaml

text = open(sys.argv[1], encoding="utf-8").read()
lines = text.splitlines()
remote = 0
repos = next((value for key, value in yaml.compose(text).value if key.value == "repos"), None)
for repo in repos.value if repos is not None else []:
    fields = {key.value: value for key, value in repo.value}
    if fields.get("repo") is None or fields["repo"].value in ("local", "meta"):
        continue
    remote += 1
    rev = fields.get("rev")
    value = rev.value if rev is not None else ""
    after = lines[rev.end_mark.line][rev.end_mark.column :] if rev is not None else ""
    if not (re.fullmatch(r"[0-9a-f]{40}", value) and re.fullmatch(r"\s+# frozen: \S+\s*", after)):
        print(fields["repo"].value, value)
print(f"remote: {remote}")
PY
}

It "finds a floating rev on a quoted or unquoted repository, and a rev whose frozen comment is elsewhere"
printf '%s\n' "repos:" \
  "  - repo: \"https://github.com/example/hooks\"" "    rev: v1" "    hooks: [{id: a}]" \
  "  - repo: https://github.com/example/frozen" \
  "    rev: 0123456789abcdef0123456789abcdef01234567 # frozen: v2" "    hooks: [{id: b}]" \
  "  # rev: 89abcdef0123456789abcdef0123456789abcdef # frozen: v3" \
  "  - repo: https://github.com/example/bare" \
  "    rev: 89abcdef0123456789abcdef0123456789abcdef" "    hooks: [{id: d}]" \
  "  - repo: local" "    hooks: [{id: c, name: c, entry: c, language: system}]" >"${TREE}/config.yaml"
When call unfrozen "${TREE}/config.yaml"
The output should equal "$(printf '%s\n' "https://github.com/example/hooks v1" \
  "https://github.com/example/bare 89abcdef0123456789abcdef0123456789abcdef" "remote: 3")"
End

# A tag can be moved to other code; Renovate keeps this format when it bumps a hook.
It "pins every remote hook to a commit, with its tag in a frozen comment"
When call unfrozen "${ROOT}/.pre-commit-config.yaml"
The output should match pattern "remote: [1-9]*"
The lines of output should equal 1
End
End

Describe "npx and uvx"
# invocations FILE...: each command in FILE that fetches a package at a floating version.
invocations() {
  _harness_python "$REPO_COMMANDS" fetches "$@"
}

It "finds a floating npx and uvx run, after a tool check, in a quoted substitution or in an inline recipe"
printf '%s\n' "lint:" "	npx --yes prettier --check ." "	uvx ruff check ." "	npx --no-install prettier --check ." \
  "	command -v npx >/dev/null && npx --yes prettier --check ." \
  "	command -v npx >/dev/null || { echo \"npx not found\"; exit 1; }" \
  "	echo \"\$\$(npx --yes prettier --version)\"" \
  "inline: ; @npx --yes prettier --check ." \
  "	uv --python-preference system run --locked --with ruff ruff --version" \
  "	uv run --locked -w ruff ruff --version" \
  "	uv run --locked tool.py --with x" >"${TREE}/Makefile"
When call invocations "${TREE}/Makefile"
The lines of output should equal 7
The output should include "Makefile:2: npx --yes prettier --check ."
The output should include "Makefile:3: uvx ruff"
The output should include "Makefile:5: npx --yes prettier --check ."
The output should include "Makefile:7: npx --yes prettier --version"
The output should include "Makefile:8: npx --yes prettier --check ."
The output should include "Makefile:9: uv --python-preference system run --locked --with ruff ruff --version"
The output should include "Makefile:10: uv run --locked -w ruff ruff --version"
End

It "finds npx in an npm script, but not in one that only prints it"
printf '%s\n' '{"scripts": {"lint": "npx yaml-lint x.yml", "ok": "yaml-lint x.yml", "help": "echo \"npx prettier --check .\""}}' \
  >"${TREE}/package.json"
When call invocations "${TREE}/package.json"
The output should include "npx yaml-lint"
The lines of output should equal 1
End

# The npm tools come from package-lock.json, and ruff and pyright from uv.lock.
It "runs npx only with --no-install, and no uvx, in the Makefile, the hooks and the npm scripts"
When call invocations "${ROOT}/Makefile" "${ROOT}/.claude/hooks/post-edit-write.sh" "${ROOT}/package.json"
The output should equal ""
End

It "runs ruff and pyright from the locked dev extra"
The contents of file "${ROOT}/Makefile" should include 'uv run --locked --extra dev ruff check . --no-cache'
The contents of file "${ROOT}/Makefile" should include 'uv run --locked --extra dev pyright .'
The contents of file "${ROOT}/Makefile" should include 'uv run --locked --extra dev ruff format . --no-cache'
End
End

# uncommented PATTERN FILE...: each line matching PATTERN outside a comment, as FILE:LINE.
uncommented() {
  pattern="$1"
  shift
  grep -n -H -E "$pattern" "$@" | grep -E -v ':[0-9]+:[[:space:]]*#' || true
}

Describe "gh-action-readme"
# gar VAR OS ARCH: the Makefile's VAR on a machine whose uname reports OS and ARCH.
gar() {
  mkdir -p "${TREE}/bin"
  printf '#!/bin/sh\ncase "$1" in -s) echo %s ;; -m) echo %s ;; *) exit 1 ;; esac\n' "$2" "$3" >"${TREE}/bin/uname"
  chmod +x "${TREE}/bin/uname"
  PATH="${TREE}/bin:${PATH}" make -s -C "${ROOT}" -p -n help 2>/dev/null | sed -n "s/^$1 := //p"
}

Describe "on each platform it has a release archive for"
Parameters
Linux x86_64 x86_64
Linux aarch64 arm64
Darwin x86_64 x86_64
Darwin arm64 arm64
End

It "pins the SHA-256 of the $1 $3 archive"
When call gar GAR_SHA256 "$1" "$2"
The output should match pattern "$HEX64"
End

It "names the $1 $3 archive"
When call gar GAR_ASSET "$1" "$2"
The output should equal "gh-action-readme_$1_$3.tar.gz"
End
End

It "pins no digest for a platform without an archive"
When call gar GAR_SHA256 Linux i686
The output should equal ""
End

# A replaced archive would come with a replaced checksums file.
It "trusts no checksums file from the release"
When call uncommented 'checksums\.txt' "${ROOT}/Makefile"
The output should equal ""
End
End

Describe "downloads"
# fetches_without_tls FILE...: each curl command FILE runs that does not insist on HTTPS and
# TLS 1.2, read from the arguments curl gets.
fetches_without_tls() {
  _harness_python "$REPO_COMMANDS" insecure-downloads "$@"
}

It "finds a curl download without the TLS options, also when they are only in a comment"
printf '%s\n' "runs:" "  using: composite" "  steps:" "    - shell: sh" "      run: |" \
  "        curl -fsSL \"https://example.com/tool\" -o tool" \
  "        curl -fsSL \"\$URL\" -o tool # --proto '=https' --tlsv1.2" \
  "        curl --proto '=https' --tlsv1.2 -fsSL \"\$URL\" -o tool" \
  "        curl --proto '=https' --tlsv1.3 -fsSL \"\$URL\" -o tool" \
  "        if ! curl; then exit 1; fi" \
  "        curl --proto '=https' --tlsv1.2 --proto '=http' http://example.com/tool -o tool" \
  "        curl --proto '=https' --tlsv1.3 --tlsv1.0 -fsSL \"\$URL\" -o tool" \
  "        curl --proto '=https' --tlsv1.2 -1 https://example.com/tool -o tool" \
  "        curl --proto '=https' --tlsv1.2 -sS1 https://example.com/tool -o tool" \
  "        curl --proto '=https' -1 --tlsv1.2 -fsSL https://example.com/tool -o tool" \
  "        curl --proto '=https' --tlsv1.2 https://example.com/a --next http://example.com/b" \
  "        curl http://example.com/a -: --proto '=https' --tlsv1.2 https://example.com/b" \
  "        curl --proto '=https' --tlsv1.2 https://example.com/a -: --proto '=https' --tlsv1.2 https://example.com/b" \
  "        curl --proto '=https' --tlsv1.2 -o1.txt https://example.com/a" \
  "        curl --proto '=https' --tlsv1.2 --user-agent '-sS1' https://example.com/tool -o tool" \
  "        curl --proto '=https' --user-agent '--tlsv1.2' https://example.com/tool -o tool" \
  "        curl --proto==https --tlsv1.2 https://example.com/tool -o tool" \
  "        curl --proto '=https' --tlsv1.2 --expand-proto '=http' http://example.com/tool -o tool" \
  "        curl --proto '=https' --tlsv1.2 --expand-proto '{{scheme}}' https://example.com/tool -o tool" \
  "        curl --expand-proto '=https' --tlsv1.2 https://example.com/tool -o tool" \
  "        curl --proto '=https' --tlsv1.2 --user-ag '-sS1' https://example.com/tool -o tool" \
  "        curl --proto '=https' --tlsv1.2 --head https://example.com/tool" >"${TREE}/action.yml"
When call fetches_without_tls "${TREE}/action.yml"
The output should include "action.yml:6: curl -fsSL https://example.com/tool -o tool"
The output should include "action.yml:7: curl -fsSL \$... -o tool"
The output should include "action.yml:10: curl"
The output should include "action.yml:11: curl --proto =https --tlsv1.2 --proto =http"
The output should include "action.yml:12: curl --proto =https --tlsv1.3 --tlsv1.0"
The output should include "action.yml:13: curl --proto =https --tlsv1.2 -1 "
The output should include "action.yml:14: curl --proto =https --tlsv1.2 -sS1 "
The output should include "action.yml:16: curl --proto =https --tlsv1.2 https://example.com/a --next"
The output should include "action.yml:17: curl http://example.com/a -: "
The output should include "action.yml:21: curl --proto =https --user-agent --tlsv1.2 "
The output should include "action.yml:22: curl --proto==https --tlsv1.2 "
The output should include "action.yml:23: curl --proto =https --tlsv1.2 --expand-proto =http "
The output should include "action.yml:24: curl --proto =https --tlsv1.2 --expand-proto {{scheme}} "
The lines of output should equal 13
End

# A run step without a shell runs pwsh on a Windows runner, which is not read as bash, and sh in
# a job with a literal container image, whatever runs-on says. An image from an expression can
# come out empty and leave the job on the host, so its steps are read as bash, which parses an
# sh script too. An inherited template such as `bash -e {0}` names bash. An expression in
# runs-on leaves the shell unknown otherwise, so the step stops the check instead of going unread.
It "reads each workflow step with the shell its runner, container and defaults give it"
printf '%s\n' "jobs:" \
  "  windows:" "    runs-on: windows-latest" "    steps:" "      - run: curl -fsSL https://example.com/a -o a" \
  "  templated:" "    runs-on: ubuntu-latest" "    defaults:" "      run:" "        shell: bash -e {0}" "    steps:" \
  "      - run: curl -fsSL https://example.com/b -o b" \
  "  boxed:" "    runs-on: \${{ matrix.runner }}" "    container: alpine:3" "    steps:" \
  "      - run: curl -fsSL https://example.com/d -o d" \
  "  dynamic:" "    runs-on: ubuntu-latest" "    container: \${{ matrix.image }}" "    steps:" \
  "      - run: items=(a b); curl -fsSL https://example.com/e -o e" >"${TREE}/workflow.yml"
When call fetches_without_tls "${TREE}/workflow.yml"
The output should equal "$(printf '%s\n' "${TREE}/workflow.yml:12: curl -fsSL https://example.com/b -o b" \
  "${TREE}/workflow.yml:17: curl -fsSL https://example.com/d -o d" \
  "${TREE}/workflow.yml:22: curl -fsSL https://example.com/e -o e")"
End

It "stops on a workflow step whose shell depends on an expression in runs-on"
printf '%s\n' "jobs:" "  matrix:" "    runs-on: \${{ matrix.os }}" "    steps:" "      - run: curl -fsSL https://example.com/c -o c" \
  >"${TREE}/workflow.yml"
When call fetches_without_tls "${TREE}/workflow.yml"
The status should equal 2
The error should include "runs-on is an expression"
End

It "downloads over HTTPS and TLS 1.2 only"
When call fetches_without_tls "$SETUP_ENV" "$SECURITY_SUITE" "$DOCKERFILE" "${ROOT}/Makefile" "${ROOT}/_tests/run-tests.sh"
The output should equal ""
End

# fixed_tmp FILE...: each fixed path in /tmp FILE hands a command, assigns or redirects to, read
# from the syntax tree; mktemp's template and an expansion such as ${TMPDIR:-/tmp} are not one.
fixed_tmp() {
  _harness_python "$REPO_COMMANDS" fixed-tmp "$@"
}

It "finds a fixed path in /tmp, also beside a mktemp on the same line"
printf '%s\n' 'tar -xzf "$tarball" -C /tmp/' 'work=$(mktemp -d "${TMPDIR:-/tmp}/x.XXXXXX")' \
  'work=$(mktemp -d); tar -xzf "$tarball" -C /tmp/' 'mktemp -d /tmp/y.XXXXXX' 'echo "built in /tmp"' \
  'cp a b > /tmp/out' 'dir=/tmp/cache' >"${TREE}/install.sh"
When call fixed_tmp "${TREE}/install.sh"
The output should equal "$(printf '%s\n' "${TREE}/install.sh:1: /tmp/" "${TREE}/install.sh:3: /tmp/" \
  "${TREE}/install.sh:6: /tmp/out" "${TREE}/install.sh:7: /tmp/cache")"
End

# Another user of the machine could swap a file at a fixed path between the checksum and its use.
It "downloads into a directory of its own, never a fixed path in /tmp"
When call fixed_tmp "$SETUP_ENV" "$SECURITY_SUITE" "${ROOT}/_tests/run-tests.sh"
The output should equal ""
End

It "trusts no checksums file from a release"
When call uncommented 'checksums\.txt' "$SETUP_ENV" "$DOCKERFILE"
The output should equal ""
End
End

Describe "locks"
# unlocked FILE...: each uv run or uv sync in FILE that would update a stale uv.lock instead of
# failing on it.
unlocked() {
  _harness_python "$REPO_COMMANDS" unlocked "$@"
}

# scripted_installs FILE...: each npm install FILE runs that runs the packages' install scripts,
# read from the arguments npm gets.
scripted_installs() {
  _harness_python "$REPO_COMMANDS" install-scripts "$@"
}

It "finds a uv run that would update the lock, however make or the shell wraps it"
printf '%s\n' "TOOL := \$(shell uv run tool.py --version)" "LOCKED := uv run --locked --extra dev ruff" "check:" \
  "	uv run tool.py" "	uv run --locked tool.py" \
  "	echo \"Checking Python\"; uv run ruff check ." \
  "	uv run --locked a.py && uv run b.py" \
  "	uv run lint.py # --locked" \
  "	uv run --project \"#dir\" --locked c.py" \
  "	uv run --project dir d.py --locked" \
  "	log_error \"uv sync failed\"" \
  "	echo \"\$\$(uv run ruff --version)\"" \
  "	echo \"message: \\\" # note\"; uv run ruff check src" \
  "VERSION := \$(strip \$(shell uv run nested.py --version))" \
  "	echo '\$(shell uv run quoted.py)'" \
  "	uv run --color always --locked e.py" \
  "	uv run --color=always --locked f.py" \
  "	uv --color always sync --quiet" \
  "inline: ; uv run g.py" \
  "help: ## run; then stop" \
  "	uv --python-preference system sync" \
  "	uv --python-preference=system sync" \
  "	uv run --locked --no-locked h.py" \
  "	uv run --no-locked --locked i.py" \
  "VALUE := yes # \$(shell uv run commented.py)" \
  "ifneq (\$(shell uv run cond.py),)" \
  "endif" \
  "LEFT_PAREN := (" \
  "RUNNER = uv run --extra dev" \
  "	\$(RUNNER) tool.py" \
  "ARGS := \$(LOCK)" "LOCK := --locked" "	uv run \$(ARGS) frozen.py" \
  "ARGS2 = \$(LOCK2)" "LOCK2 := --locked" "	uv run \$(ARGS2) deferred.py" \
  "define DEFINED_RUNNER" "uv run defined.py" "endef" \
  "define UNUSED_RUNNER" "uv run unused.py" "endef" \
  "	\$(DEFINED_RUNNER)" \
  "define AT_RUNNER" "@uv run at.py" "endef" \
  "	\$(AT_RUNNER)" >"${TREE}/Makefile"
When call unlocked "${TREE}/Makefile"
The output should include "Makefile:1: uv run tool.py --version"
The output should include "Makefile:4: uv run tool.py"
The output should include "Makefile:6: uv run ruff check ."
The output should include "Makefile:7: uv run b.py"
The output should include "Makefile:8: uv run lint.py"
The output should include "Makefile:10: uv run --project dir d.py --locked"
The output should include "Makefile:12: uv run ruff --version"
The output should include "Makefile:13: uv run ruff check src"
The output should include "Makefile:14: uv run nested.py --version"
The output should include "Makefile:15: uv run quoted.py"
The output should include "Makefile:18: uv --color always sync --quiet"
The output should include "Makefile:19: uv run g.py"
The output should include "Makefile:21: uv --python-preference system sync"
The output should include "Makefile:22: uv --python-preference=system sync"
The output should include "Makefile:23: uv run --locked --no-locked h.py"
The output should include "Makefile:26: uv run cond.py"
The output should include "Makefile:30: uv run --extra dev tool.py"
The output should include "Makefile:33: uv run frozen.py"
The output should include "Makefile:43: uv run defined.py"
The output should include "Makefile:47: uv run at.py"
The lines of output should equal 20
End

It "finds a uv sync without --locked in a shell script"
printf '%s\n' '#!/bin/sh' 'uv sync --locked --inexact' 'uv --directory x sync --quiet' 'if ! command -v uv >/dev/null; then exit 1; fi' \
  >"${TREE}/run.sh"
When call unlocked "${TREE}/run.sh"
The output should equal "${TREE}/run.sh:3: uv --directory x sync --quiet"
End

It "runs uv against uv.lock as it stands"
When call unlocked "${ROOT}/Makefile" "${ROOT}/_tests/run-tests.sh" "${ROOT}"/_tests/framework/*.sh
The output should equal ""
End

# As a module, so a venv without it fails rather than running another pre-commit on PATH.
It "runs pre-commit from the locked dev extra"
The contents of file "${ROOT}/Makefile" should include 'PRE_COMMIT := uv run --locked --extra dev python -m pre_commit'
The contents of file "${ROOT}/Makefile" should not include 'uv tool install'
End

# A plain uv sync removes the dev extra, whose pre-commit the git hook runs.
It "keeps the dev extra when the test runner syncs"
The contents of file "${ROOT}/_tests/run-tests.sh" should include 'uv sync --locked --inexact'
End

# Without the nodejs extra, pyright downloads the newest Node.js through nodeenv, unchecked.
It "takes pyright's Node.js from the lock"
The contents of file "${ROOT}/pyproject.toml" should include '"pyright[nodejs]'
End

It "finds an npm install that runs install scripts, also when --ignore-scripts is turned off again"
printf '%s\n' "jobs:" "  build:" "    runs-on: ubuntu-latest" "    steps:" "      - run: npm ci" \
  "      - run: npm ci --ignore-scripts=false" "      - run: npm ci --ignore-scripts" \
  "      - run: npm --ignore-scripts install" "      - run: npm install --ignore-scripts --no-ignore-scripts" \
  "      - run: npm run build" >"${TREE}/workflow.yml"
When call scripted_installs "${TREE}/workflow.yml"
The output should include "workflow.yml:5: npm ci"
The output should include "workflow.yml:6: npm ci --ignore-scripts=false"
The output should include "workflow.yml:9: npm install --ignore-scripts --no-ignore-scripts"
The lines of output should equal 3
End

It "installs npm packages without their install scripts"
When call scripted_installs "${ROOT}"/.github/workflows/*.yml "$SETUP_ENV" "${ROOT}/Makefile"
The output should equal ""
End

# serial DIR: prints serial when the Makefile in DIR runs its targets one at a time, as read by make.
# Only a .NOTPARALLEL without prerequisites does that: make 4.4 serializes just the prerequisites
# of one that has them, and make prints both forms together as one entry with them.
# grep reads the whole database: one that stopped at the first match would cut make off mid-write.
serial() {
  [ "$(make -s -C "$1" -p -n 2>/dev/null | grep -c -E '^\.NOTPARALLEL:[[:space:]]*$')" -gt 0 ] && echo serial || true
}

It "tells a Makefile that runs its targets one at a time from one that runs them in parallel"
mkdir -p "${TREE}/parallel" "${TREE}/scoped" "${TREE}/serial"
printf '%s\n' "all: ; @true" >"${TREE}/parallel/Makefile"
printf '%s\n' "all: ; @true" "x: ; @true" ".NOTPARALLEL: x" >"${TREE}/scoped/Makefile"
printf '%s\n' "all: ; @true" ".NOTPARALLEL:" >"${TREE}/serial/Makefile"
When call serial "${TREE}/parallel"
The output should equal ""
Assert [ -z "$(serial "${TREE}/scoped")" ]
Assert [ "$(serial "${TREE}/serial")" = serial ]
End

# npm ci replaces node_modules, which the npx --no-install targets run from.
It "runs the Makefile's targets one at a time, so install-tools' npm ci cannot race a linter"
When call serial "${ROOT}"
The output should equal "serial"
End
End

Describe "renovate comments"
# unbumped FILE...: each version pin in FILE without a renovate comment on the line before it.
unbumped() {
  _harness_python - "$@" <<'PY'
import re
import sys

for path in sys.argv[1:]:
    lines = open(path, encoding="utf-8").read().splitlines()
    for number, line in enumerate(lines):
        if re.match(r"\s*(ARG\s+)?[A-Z0-9_]+_VERSION\s*[:=]", line):
            if number == 0 or "# renovate: datasource=" not in lines[number - 1]:
                print(f"{path}:{number + 1}: {line.strip()}")
PY
}

It "finds a version without a renovate comment"
printf '%s\n' "env:" "  TOOL_VERSION: '1.0.0'" >"${TREE}/action.yml"
When call unbumped "${TREE}/action.yml"
The output should include "TOOL_VERSION"
End

It "lets Renovate bump each version the test environment, the security workflow and the testing image pin"
When call unbumped "$SETUP_ENV" "$SECURITY_SUITE" "$DOCKERFILE"
The output should equal ""
End

It "reads the testing image's versions with Renovate's Dockerfile manager"
The contents of file "${ROOT}/.github/renovate.json" should include '"customManagers:dockerfileVersions"'
End
End

Describe "image digests"
# managed_pins: each depName and digest the repository's own regex manager reads, as
# "FILE DEPNAME TAG@DIGEST", from the files its managerFilePatterns name.
managed_pins() {
  _harness_python - "${ROOT}" <<'PY'
import json
from pathlib import Path
import re
import sys

import subprocess

root = Path(sys.argv[1])
manager = json.loads((root / ".github/renovate.json").read_text(encoding="utf-8"))["customManagers"][0]
patterns = [re.compile(p.replace("(?<", "(?P<")) for p in manager["matchStrings"]]
files = [re.compile(p.strip("/")) for p in manager["managerFilePatterns"]]
tracked = subprocess.run(["git", "-C", str(root), "ls-files"], capture_output=True, text=True, check=True).stdout
for name in sorted(tracked.splitlines()):
    if not any(f.search(name) for f in files):
        continue
    text = (root / name).read_text(encoding="utf-8", errors="replace")
    for pattern in patterns:
        for found in pattern.finditer(text):
            print(name, found["depName"], f"{found['currentValue']}@{found['currentDigest']}")
PY
}

It "reads the act image run-tests.sh pins"
When call managed_pins
The output should match pattern "*_tests/run-tests.sh catthehacker/ubuntu act-latest@sha256:*"
End

# The shared preset disables digest updates outside github-actions, a re-pushed tag moves only
# by its digest, and a tag without a release timestamp would wait for minimumReleaseAge forever.
digest_updates() {
  _harness_python - "${ROOT}/.github/renovate.json" <<'PY'
import json
import sys

for rule in json.load(open(sys.argv[1], encoding="utf-8"))["packageRules"]:
    if rule.get("matchUpdateTypes") == ["digest"] and rule.get("enabled") is True:
        print(
            " ".join(rule.get("matchDepNames", [])),
            rule.get("minimumReleaseAgeBehaviour", "timestamp-required"),
            "automerge" if rule.get("automerge") else "reviewed",
        )
PY
}

It "updates the digests of the images pinned on a re-pushed tag, through a reviewed pull request"
When call digest_updates
The output should equal "catthehacker/ubuntu owasp/dependency-check-action ubuntu timestamp-optional reviewed"
End

# unpinned_docker_steps FILE...: "FILE: USES" for each docker:// uses value in FILE, as YAML reads
# it, that names no image digest, then "docker steps: N", the number of docker:// values.
unpinned_docker_steps() {
  _harness_python - "$@" <<'PY'
import re
import sys

import yaml


def uses_values(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "uses" and isinstance(value, str):
                yield value
            yield from uses_values(value)
    elif isinstance(node, list):
        for value in node:
            yield from uses_values(value)


count = 0
for path in sys.argv[1:]:
    for uses in uses_values(yaml.safe_load(open(path, encoding="utf-8"))):
        if uses.startswith("docker://"):
            count += 1
            if not re.fullmatch(r"docker://[^@\s]+@sha256:[0-9a-f]{64}", uses):
                print(f"{path}: {uses}")
print(f"docker steps: {count}")
PY
}

It "finds a docker:// step without an image digest, quoted or not"
printf '%s\n' "jobs:" "  scan:" "    runs-on: ubuntu-latest" "    steps:" \
  "      - uses: \"docker://alpine:latest\"" "      - uses: docker://alpine:3" \
  "      - uses: docker://alpine:3@sha256:$(printf '0%.0s' $(seq 64))" >"${TREE}/workflow.yml"
When call unpinned_docker_steps "${TREE}/workflow.yml"
The output should equal "$(printf '%s\n' "${TREE}/workflow.yml: docker://alpine:latest" \
  "${TREE}/workflow.yml: docker://alpine:3" "docker steps: 3")"
End

It "runs every docker:// step in the workflows by digest"
When call unpinned_docker_steps "${ROOT}"/.github/workflows/*.yml
The output should match pattern "docker steps: [1-9]*"
The lines of output should equal 1
End

It "updates the BuildKit image build-testing-image.yml pins"
When call managed_pins
The output should match pattern "*.github/workflows/build-testing-image.yml moby/buildkit v*@sha256:*"
End

# buildx runs the BuildKit daemon privileged; an empty buildkitd-flags restores setup-buildx's
# defaults, which allow insecure entitlements.
build_testing_buildx() {
  _harness_python - "${ROOT}/.github/workflows/build-testing-image.yml" "$1" <<'PY'
import sys

import yaml

steps = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))["jobs"]["build-and-push"]["steps"]
value = next(s for s in steps if s.get("name") == "Set up Docker Buildx")
for key in sys.argv[2].split("."):
    value = value.get(key, "") if isinstance(value, dict) else ""
print(value)
PY
}

It "runs build-testing-image.yml's BuildKit from the pinned image"
When call build_testing_buildx with.driver-opts
The output should equal 'image=moby/buildkit:${{ env.BUILDKIT_IMAGE_TAG }}'
End

It "gives build-testing-image.yml's BuildKit daemon flags that keep setup-buildx's insecure defaults off"
When call build_testing_buildx with.buildkitd-flags
The output should equal '--oci-worker=auto'
End
End
End
