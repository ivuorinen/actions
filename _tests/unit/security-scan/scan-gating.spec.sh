#!/usr/bin/env shellspec
# Tests for which commits security-scan's Gitleaks scan covers and where each scanner reads
# its configuration. They run the action's real check-configs step in a scratch git
# repository against fixture event payloads.

Describe "security-scan scan scope (behavior)"
ACTION_DIR="${PROJECT_ROOT}/security-scan"

# A repository with a base commit and a head commit on top of it.
before() {
  shellspec_setup_test_env "security-scan-gating-$$"
  harness_reset
  export INPUT_ACTIONLINT_ENABLED="true"
  export INPUT_GITLEAKS_CONFIG=".gitleaks.toml"
  export GITHUB_EVENT_NAME="push"
  export GITHUB_EVENT_PATH="${RUNNER_TEMP}/event.json"
  fixture_repo
  printf 'one\n' >file.txt
  git add file.txt
  git commit -q -m base
  BASE=$(git rev-parse HEAD)
  printf 'two\n' >>file.txt
  git commit -q -am head
  HEAD_SHA=$(git rev-parse HEAD)
  printf '{}\n' >"$GITHUB_EVENT_PATH"
}
BeforeEach 'before'

after() {
  unset INPUT_ACTIONLINT_ENABLED INPUT_GITLEAKS_CONFIG
  unset GITHUB_EVENT_NAME GITHUB_EVENT_PATH BASE HEAD_SHA
  shellspec_cleanup_test_env "security-scan-gating-$$"
  harness_reset
}
AfterEach 'after'

run_check_configs() {
  run_step "${ACTION_DIR}" "check-configs"
}

# write_event JQ_FILTER: write the event payload JQ_FILTER builds from $base and $head.
write_event() {
  jq -n --arg base "$BASE" --arg head "$HEAD_SHA" "$1" >"$GITHUB_EVENT_PATH"
}

# pull_request_event NAME: the event NAME with the pull request payload pull_request and the
# review events carry.
pull_request_event() {
  export GITHUB_EVENT_NAME="$1"
  write_event '{pull_request: {base: {sha: $base}, head: {sha: $head}}}'
}

pull_request() { pull_request_event pull_request; }
pull_request_review() { pull_request_event pull_request_review; }
pull_request_review_comment() { pull_request_event pull_request_review_comment; }

merge_group() {
  export GITHUB_EVENT_NAME="merge_group"
  write_event '{merge_group: {base_sha: $base, head_sha: $head}}'
}

# output KEY: print the value the step wrote for KEY.
output() {
  sed -n "s/^$1=//p" "$GITHUB_OUTPUT" | tail -n 1
}

no_output() {
  ! grep -q "^$1=" "$GITHUB_OUTPUT"
}

# in_scan_dir PATH TEXT: the scan directory holds PATH with exactly TEXT.
in_scan_dir() {
  [ -f "$(output scan_dir)/$1" ] && [ "$(cat "$(output scan_dir)/$1")" = "$2" ]
}

# output_file_holds KEY TEXT: the file named by output KEY holds exactly TEXT.
output_file_holds() {
  [ -f "$(output "$1")" ] && [ "$(cat "$(output "$1")")" = "$2" ]
}

# commit_file PATH TEXT: commit TEXT as PATH on top of the head commit, as a pull request would.
commit_file() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
  git add "$1"
  git commit -q -m "change $1"
  HEAD_SHA=$(git rev-parse HEAD)
}

# base_file PATH TEXT: put PATH into the base commit, then rebuild the head commit on it.
base_file() {
  git checkout -q "$BASE"
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
  git add "$1"
  git commit -q -m "base $1"
  BASE=$(git rev-parse HEAD)
  printf 'two\n' >>file.txt
  git commit -q -am head
  HEAD_SHA=$(git rev-parse HEAD)
}

# The harness runs a step with a PATH of its own, so a step that must find a stand-in on
# PATH runs from its script instead, with the inputs the step's env: would pass.
run_check_configs_script() {
  ACTIONLINT_ENABLED="$INPUT_ACTIONLINT_ENABLED" GITLEAKS_CONFIG="$INPUT_GITLEAKS_CONFIG" \
    sh -c "$(step_value "$ACTION_DIR" "Check Required Configurations" run)"
}

# git_reporting VERSION: put a git first on PATH that reports VERSION and runs the real git
# for everything else, found on the PATH without it, as a version manager's shim also needs.
git_reporting() {
  mkdir -p "${RUNNER_TEMP}/bin"
  cat >"${RUNNER_TEMP}/bin/git" <<EOF
#!/bin/sh
if [ "\$1" = version ]; then
  echo "git version $1"
  exit 0
fi
PATH='${PATH}'
export PATH
exec git "\$@"
EOF
  chmod +x "${RUNNER_TEMP}/bin/git"
  export PATH="${RUNNER_TEMP}/bin:${PATH}"
}

Describe "the commits Gitleaks scans"
It "scans from the base to the head of a pull request"
pull_request
When call run_check_configs
The status should be success
Assert expect_output run_gitleaks "true"
Assert expect_output gitleaks_range "${BASE}..${HEAD_SHA}"
End

It "scans from the base to the head of a pull request on its review events"
pull_request_review
When call run_check_configs
The status should be success
The stdout should not include "whole history"
Assert expect_output gitleaks_range "${BASE}..${HEAD_SHA}"
End

It "scans from the base to the head of a merge group"
merge_group
When call run_check_configs
The status should be success
The stdout should not include "whole history"
Assert expect_output gitleaks_range "${BASE}..${HEAD_SHA}"
End

It "scans the commits a push brought"
write_event '{before: $base, after: $head}'
When call run_check_configs
The status should be success
The stdout should not include "whole history"
Assert expect_output gitleaks_range "${BASE}..${HEAD_SHA}"
End

It "scans the whole history on the push that creates a branch"
jq -n --arg head "$HEAD_SHA" '{before: "0000000000000000000000000000000000000000", after: $head}' >"$GITHUB_EVENT_PATH"
When call run_check_configs
The status should be success
The stdout should include "::notice::Gitleaks scans the whole history on this push event"
Assert no_output gitleaks_range
End

Describe "on a pull request or merge group naming a commit the clone lacks"
Parameters
pull_request '{pull_request: {base: {sha: "1111111111111111111111111111111111111111"}, head: {sha: $head}}}'
pull_request '{pull_request: {base: {sha: "HEAD~1 --all"}, head: {sha: $head}}}'
pull_request_review_comment '{pull_request: {base: {sha: "1111111111111111111111111111111111111111"}, head: {sha: $head}}}'
merge_group '{merge_group: {base_sha: $base, head_sha: "2222222222222222222222222222222222222222"}}'
End

It "fails on $1 instead of reading the changes' own configuration"
export GITHUB_EVENT_NAME="$1"
write_event "$2"
When call run_check_configs
The status should be failure
The stdout should include "::error::This clone lacks a commit the $1 event names"
Assert no_output gitleaks_range
Assert no_output scan_dir
End
End

Describe "on events that name no commit range"
Parameters
workflow_dispatch
schedule
release
pull_request_target
End

It "runs every scanner on $1 and scans the whole history"
export GITHUB_EVENT_NAME="$1"
When call run_check_configs
The status should be success
The stdout should include "::notice::Gitleaks scans the whole history on this $1 event"
Assert expect_output run_gitleaks "true"
Assert expect_output run_trivy "true"
Assert expect_output run_actionlint "true"
Assert no_output gitleaks_range
End
End
End

# A pull request's review events check out its merge commit, as pull_request does.
Describe "the configuration on a pull request or merge group"
Parameters
pull_request
pull_request_review
pull_request_review_comment
merge_group
End

It "runs the scanners from an export of the base commit on $1"
base_file trivy.yaml "severity: [CRITICAL]"
commit_file trivy.yaml "severity: [LOW]"
commit_file .trivyignore "CVE-2024-9999"
"$1"
When call run_check_configs
The status should be success
Assert in_scan_dir trivy.yaml "severity: [CRITICAL]"
Assert test ! -e "$(output scan_dir)/.trivyignore"
Assert test "$(output scan_dir)" != "$PWD"
Assert expect_output base_sha "$BASE"
Assert expect_output head_sha "$HEAD_SHA"
End

It "passes the base commit's Gitleaks config, resolved in the export, on $1"
base_file .gitleaks.toml 'title = "base"'
commit_file .gitleaks.toml 'title = "pull request"'
"$1"
When call run_check_configs
The status should be success
Assert expect_output gitleaks_config ".gitleaks.toml"
Assert in_scan_dir .gitleaks.toml 'title = "base"'
End

It "passes the config at the gitleaks-config path in the base commit on $1"
export INPUT_GITLEAKS_CONFIG="security/gitleaks.toml"
base_file security/gitleaks.toml 'title = "custom"'
"$1"
When call run_check_configs
The status should be success
Assert expect_output gitleaks_config "security/gitleaks.toml"
Assert in_scan_dir security/gitleaks.toml 'title = "custom"'
End

It "keeps the default rules when only the changes add a Gitleaks config on $1"
commit_file .gitleaks.toml 'title = "pull request"'
"$1"
When call run_check_configs
The status should be success
Assert output_file_holds gitleaks_config "$(printf '[extend]\nuseDefault = true')"
End

It "removes the checkout's .gitleaksignore, which Gitleaks would read whatever it is told, on $1"
base_file .gitleaksignore "base:file.txt:generic-api-key:1"
commit_file .gitleaksignore "pull-request:file.txt:generic-api-key:2"
"$1"
When call run_check_configs
The status should be success
Assert test ! -e .gitleaksignore
Assert in_scan_dir .gitleaksignore "base:file.txt:generic-api-key:1"
End

It "removes a .gitleaksignore symlink without touching its target on $1"
printf 'keep\n' >"${RUNNER_TEMP}/outside"
ln -s "${RUNNER_TEMP}/outside" .gitleaksignore
git add .gitleaksignore
git commit -q -m "link .gitleaksignore"
HEAD_SHA=$(git rev-parse HEAD)
"$1"
When call run_check_configs
The status should be success
Assert test ! -L .gitleaksignore
The contents of file "${RUNNER_TEMP}/outside" should equal "keep"
End

It "gives jactionlint the base commit's config on $1"
base_file .github/actionlint.yaml "self-hosted-runner: {labels: [base]}"
commit_file .github/actionlint.yaml "self-hosted-runner: {labels: [pull-request]}"
"$1"
When call run_check_configs
The status should be success
Assert output_file_holds jactionlint_config "self-hosted-runner: {labels: [base]}"
End

# jactionlint's own order: .github/jactionlint.yaml, jactionlint.yml, actionlint.yaml, actionlint.yml.
It "takes the base commit's jactionlint config before its actionlint config on $1"
base_file .github/actionlint.yaml "self-hosted-runner: {labels: [actionlint]}"
base_file .github/jactionlint.yml "self-hosted-runner: {labels: [jactionlint]}"
"$1"
When call run_check_configs
The status should be success
Assert output_file_holds jactionlint_config "self-hosted-runner: {labels: [jactionlint]}"
End

It "gives jactionlint an empty config when the base commit has none on $1"
commit_file .github/jactionlint.yaml "self-hosted-runner: {labels: [pull-request]}"
"$1"
When call run_check_configs
The status should be success
Assert output_file_holds jactionlint_config ""
End

It "exports the configs the base tree marks export-ignore on $1"
base_file .gitattributes "/.* export-ignore"
base_file .gitleaks.toml 'title = "base"'
"$1"
When call run_check_configs
The status should be success
Assert expect_output gitleaks_config ".gitleaks.toml"
Assert in_scan_dir .gitleaks.toml 'title = "base"'
End

It "leaves no info/attributes behind when there was none on $1"
"$1"
When call run_check_configs
The status should be success
Assert test ! -e .git/info/attributes
End

It "puts info/attributes back as it was on $1"
mkdir -p .git/info
printf '*.bin binary\n' >.git/info/attributes
"$1"
When call run_check_configs
The status should be success
The contents of file .git/info/attributes should equal "*.bin binary"
End

# Git 2.40 reads attributes from a tree only for git check-attr --source; GIT_ATTR_SOURCE,
# which Gitleaks' git log needs, came in 2.41.
It "fails on $1 when git is too old to read attributes from the base commit"
git_reporting "2.40.1"
"$1"
When call run_check_configs_script
The status should be failure
The stdout should include "::error::git 2.41 or later is required to read git attributes from the base commit; found git version 2.40.1"
Assert no_output scan_dir
End

It "accepts git 2.41 on $1"
git_reporting "2.41.0"
"$1"
When call run_check_configs_script
The status should be success
Assert test -d "$(output scan_dir)"
End
End

Describe "the configuration on other events"
It "runs the scanners in the checkout and passes its Gitleaks config"
commit_file .gitleaks.toml 'title = "repository"'
When call run_check_configs
The status should be success
The stdout should not include "::warning::"
Assert expect_output scan_dir "$PWD"
Assert expect_output gitleaks_config ".gitleaks.toml"
Assert output_file_holds jactionlint_config ""
Assert no_output base_sha
End

# jactionlint runs on a copy of the workflows outside the repository, so it is told which config.
It "passes the checkout's jactionlint config"
commit_file .github/actionlint.yaml "self-hosted-runner: {labels: [actionlint]}"
commit_file .github/jactionlint.yaml "self-hosted-runner: {labels: [jactionlint]}"
When call run_check_configs
The status should be success
The stdout should include "::notice::Gitleaks scans the whole history on this push event"
The stdout should include "::warning::Gitleaks config not found"
Assert expect_output jactionlint_config "${PWD}/.github/jactionlint.yaml"
Assert output_file_holds jactionlint_config "self-hosted-runner: {labels: [jactionlint]}"
End

# jactionlint's order: .github/jactionlint.yaml, jactionlint.yml, actionlint.yaml, actionlint.yml.
Describe "the config name jactionlint takes first"
Parameters
jactionlint.yaml jactionlint.yml
actionlint.yaml actionlint.yml
End

It "passes $1 before $2"
commit_file ".github/$2" "self-hosted-runner: {labels: [second]}"
commit_file ".github/$1" "self-hosted-runner: {labels: [first]}"
When call run_check_configs
The status should be success
The stdout should include "::notice::Gitleaks scans the whole history on this push event"
The stdout should include "::warning::Gitleaks config not found"
Assert expect_output jactionlint_config "${PWD}/.github/$1"
End
End

It "passes an actionlint.yml when it is the only config"
commit_file .github/actionlint.yml "self-hosted-runner: {labels: [only]}"
When call run_check_configs
The status should be success
The stdout should include "::notice::Gitleaks scans the whole history on this push event"
The stdout should include "::warning::Gitleaks config not found"
Assert output_file_holds jactionlint_config "self-hosted-runner: {labels: [only]}"
End

It "passes no config that is a symlink"
printf 'outside\n' >"${RUNNER_TEMP}/outside.yaml"
mkdir -p .github
ln -s "${RUNNER_TEMP}/outside.yaml" .github/jactionlint.yaml
When call run_check_configs
The status should be success
The stdout should include "::notice::Gitleaks scans the whole history on this push event"
The stdout should include "::warning::Gitleaks config not found"
Assert output_file_holds jactionlint_config ""
End

It "passes no config from under a .github that is a symlink"
mkdir -p "${RUNNER_TEMP}/elsewhere"
printf 'outside\n' >"${RUNNER_TEMP}/elsewhere/jactionlint.yaml"
ln -s "${RUNNER_TEMP}/elsewhere" .github
When call run_check_configs
The status should be success
The stdout should include "::notice::Gitleaks scans the whole history on this push event"
The stdout should include "::warning::Gitleaks config not found"
Assert output_file_holds jactionlint_config ""
End

It "leaves the checkout's .gitleaksignore in place"
commit_file .gitleaksignore "repository:file.txt:generic-api-key:1"
write_event '{before: $base, after: $head}'
When call run_check_configs
The status should be success
The stdout should include "::warning::Gitleaks config not found"
The contents of file .gitleaksignore should equal "repository:file.txt:generic-api-key:1"
End

It "warns and passes no config when the Gitleaks config does not exist"
When call run_check_configs
The status should be success
The stdout should include "::warning::Gitleaks config not found"
Assert no_output gitleaks_config
End
End
End
