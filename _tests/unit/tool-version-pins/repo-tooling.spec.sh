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
# commit with its tag in a frozen comment, then "remote: N", the number of remote hooks.
# Parsed as YAML, so a quoted repository URL is checked like any other.
unfrozen() {
  _harness_python - "$1" <<'PY'
import re
import sys

import yaml

text = open(sys.argv[1], encoding="utf-8").read()
remote = [repo for repo in yaml.safe_load(text).get("repos", []) if repo.get("repo") not in ("local", "meta")]
for repo in remote:
    rev = str(repo.get("rev", ""))
    commit = re.fullmatch(r"[0-9a-f]{40}", rev)
    if not (commit and re.search(rf"rev:\s*['\"]?{rev}['\"]?\s+# frozen: \S+", text)):
        print(repo.get("repo"), rev)
print(f"remote: {len(remote)}")
PY
}

It "finds a floating rev on a quoted or unquoted repository"
printf '%s\n' "repos:" \
  "  - repo: \"https://github.com/example/hooks\"" "    rev: v1" "    hooks: [{id: a}]" \
  "  - repo: https://github.com/example/frozen" \
  "    rev: 0123456789abcdef0123456789abcdef01234567 # frozen: v2" "    hooks: [{id: b}]" \
  "  - repo: local" "    hooks: [{id: c, name: c, entry: c, language: system}]" >"${TREE}/config.yaml"
When call unfrozen "${TREE}/config.yaml"
The output should equal "$(printf '%s\n' "https://github.com/example/hooks v1" "remote: 2")"
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
  "inline: ; @npx --yes prettier --check ." >"${TREE}/Makefile"
When call invocations "${TREE}/Makefile"
The lines of output should equal 5
The output should include "Makefile:2: npx --yes prettier --check ."
The output should include "Makefile:3: uvx ruff"
The output should include "Makefile:5: npx --yes prettier --check ."
The output should include "Makefile:7: npx --yes prettier --version"
The output should include "Makefile:8: npx --yes prettier --check ."
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
The output should match pattern "????????????????????????????????????????????????????????????????"
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
# fetches_without_tls FILE...: each curl download in FILE that does not insist on HTTPS and TLS 1.2.
fetches_without_tls() {
  _harness_python - "$@" <<'PY'
import re
import sys

for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    for match in re.finditer(r"(?<![\w-])curl\s(?:[^\n]*\\\n)*[^\n]*", text):
        command = match.group(0)
        if not re.search(r"https?://|\$[{(]?\w*URL", command):
            continue
        if "--proto '=https'" not in command or "--tlsv1.2" not in command:
            print(f"{path}: {command.splitlines()[0].strip()}")
PY
}

It "finds a curl download without the TLS options"
printf '%s\n' 'run: curl -fsSL "https://example.com/tool" -o tool' >"${TREE}/action.yml"
When call fetches_without_tls "${TREE}/action.yml"
The output should include "curl -fsSL"
End

It "downloads over HTTPS and TLS 1.2 only"
When call fetches_without_tls "$SETUP_ENV" "$SECURITY_SUITE" "$DOCKERFILE" "${ROOT}/Makefile" "${ROOT}/_tests/run-tests.sh"
The output should equal ""
End

# fixed_tmp FILE...: each use of a fixed path in /tmp outside a comment; a mktemp template is not one.
fixed_tmp() {
  uncommented '/tmp' "$@" | grep -v 'mktemp' || true
}

It "finds a fixed path in /tmp"
printf '%s\n' 'tar -xzf "$tarball" -C /tmp/' 'work=$(mktemp -d "${TMPDIR:-/tmp}/x.XXXXXX")' >"${TREE}/install.sh"
When call fixed_tmp "${TREE}/install.sh"
The output should include "-C /tmp/"
The lines of output should equal 1
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

# scripted_installs FILE...: each npm ci or npm install in FILE that runs the packages' install scripts.
scripted_installs() {
  uncommented 'npm (ci|install)' "$@" | grep -v -- '--ignore-scripts' | grep -v 'npm ci --ignore-scripts' || true
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
  "help: ## run; then stop" >"${TREE}/Makefile"
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
The lines of output should equal 12
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

It "finds an npm install that runs install scripts"
printf '%s\n' "run: npm ci" >"${TREE}/workflow.yml"
When call scripted_installs "${TREE}/workflow.yml"
The output should include "npm ci"
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

# unpinned_docker_steps: each docker:// step in a workflow without an image digest.
unpinned_docker_steps() {
  grep -n -H -E 'uses:[[:space:]]*docker://' "${ROOT}"/.github/workflows/*.yml | grep -v -E '@sha256:[0-9a-f]{64}' || true
}

It "runs every docker:// step in the workflows by digest"
When call unpinned_docker_steps
The output should equal ""
End

It "has a docker:// step to check"
When call grep -c 'uses: docker://' "$SECURITY_SUITE"
The output should equal 1
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
