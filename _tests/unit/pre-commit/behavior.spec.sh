#!/usr/bin/env shellspec
# Behavior tests for the steps that install and run pre-commit.
#
# python3 is mocked in every example that executes a step: it lives in /usr/bin,
# which stays on the harness PATH, so an unmocked call would run a real pip
# install. Each mock's glob is the whole expected argv, and an unregistered argv
# exits 127, so a changed flag or an unpinned install fails the example.

Describe "pre-commit run steps (behavior)"
ACTION_DIR="${PROJECT_ROOT}/pre-commit"
ACTION_FILE="${ACTION_DIR}/action.yml"
RUN_PREFIX="-P -m pre_commit run --show-diff-on-failure --color=always"

before() {
  shellspec_setup_test_env "pre-commit-behavior-$$"
  harness_reset
  export INPUT_PRE_COMMIT_CONFIG=".pre-commit-config.yaml"
  export INPUT_BASE_BRANCH=""
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "pre-commit-behavior-$$"
  harness_reset
}
AfterEach 'after'

step_line() {
  grep -n "^    - name: $1\$" "$ACTION_FILE" | cut -d: -f1
}

ascending() {
  [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ]
}

Context "when installing pre-commit"
# The whole argv is the mock's glob: an install that is not hash-locked, binary-only, read
# from the action's own lock, or run with the checkout on sys.path (no -P) exits 127.
It "installs from the action's hash-locked requirements and lists what was installed"
mock_command python3 "-P -m pip install --require-hashes --only-binary=:all: -r ${ACTION_DIR}/requirements.lock.txt" "installed"
mock_command python3 "-P -m pip freeze --local" "pre-commit==0.0.0"

When call run_step "${ACTION_DIR}" "install-pre-commit"
The status should be success
The stdout should include "installed"
The stdout should include "pre-commit==0.0.0"
End

It "fails the step when the install fails"
mock_command python3 "-P -m pip install *" "no matching distribution" 1

When call run_step "${ACTION_DIR}" "install-pre-commit"
The status should be failure
The stdout should include "no matching distribution"
End
End

Context "when running hooks"
It "checks all files when no base branch is set"
mock_command python3 "${RUN_PREFIX} --config .pre-commit-config.yaml --all-files" "hooks ran"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be success
The stdout should include "hooks ran"
End

It "compares against the base branch when one is set"
# The checkout holds the base branch as origin/<base>; base_branch.spec.sh covers the rest.
git init -q .
git -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false commit -q --allow-empty -m base
git update-ref refs/remotes/origin/main HEAD
export INPUT_BASE_BRANCH="main"
mock_command python3 "${RUN_PREFIX} --config .pre-commit-config.yaml --from-ref refs/remotes/origin/main --to-ref HEAD" "hooks ran"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be success
The stdout should include "hooks ran"
End

It "uses the configured config file"
export INPUT_PRE_COMMIT_CONFIG="ci/hooks.yaml"
mock_command python3 "${RUN_PREFIX} --config ci/hooks.yaml --all-files" "hooks ran"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be success
The stdout should include "hooks ran"
End

# The validator takes an empty value as unset; passed on, it would run pre-commit with --config "".
It "takes an empty pre-commit-config as the default"
export INPUT_PRE_COMMIT_CONFIG=""
mock_command python3 "${RUN_PREFIX} --config .pre-commit-config.yaml --all-files" "hooks ran"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be success
The stdout should include "hooks ran"
End

It "fails the step when a hook fails, and leaves its fixes to push"
mock_command python3 "${RUN_PREFIX} *" "hook failed" 1

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be failure
The stdout should include "hook failed"
Assert expect_output finished true
End

It "marks a clean run as finished"
mock_command python3 "${RUN_PREFIX} *" "hooks ran"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be success
The stdout should include "hooks ran"
Assert expect_output finished true
End

# 3 an unexpected error, 130 an interrupt: either can stop a hook halfway.
Parameters
3
130
End

It "pushes nothing after exit status $1"
mock_command python3 "${RUN_PREFIX} *" "stopped" "$1"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should equal "$1"
The stdout should include "stopped"
The contents of file "$GITHUB_OUTPUT" should not include "finished="
End

It "pushes fixes only after a run that finished"
When call step_value "${ACTION_DIR}" push-fixes if
The output should equal "always() && steps.pre-commit.outputs.finished == 'true'"
End

It "does not expand glob characters against the workspace"
# Discriminating fixture: an unquoted expansion would replace the pattern with
# these file names, and [*] in the glob only matches a literal asterisk.
: >a.yaml
: >b.yaml
export INPUT_PRE_COMMIT_CONFIG="*.yaml"
mock_command python3 "${RUN_PREFIX} --config [*].yaml --all-files" "hooks ran"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be success
The stdout should include "hooks ran"
End

It "does not evaluate shell syntax in input values"
# The action's validator rejects this value first. This covers the layer behind
# it: the step must treat whatever reaches it as data.
# The value names no ref, so the step stops at the base-branch check and prints it as text.
# The action always runs in a checkout, so the example does too.
git init -q .
export INPUT_BASE_BRANCH="\$(touch evaluated)"

When call run_step "${ACTION_DIR}" "pre-commit"
The status should be failure
The stdout should include "::error::base-branch '\$(touch evaluated)' is neither"
The path "evaluated" should not be exist
End
End

Context "when pinning what the action runs"
It "does not delegate to the upstream pre-commit action"
When call grep -F "pre-commit/action@" "$ACTION_FILE"
The status should be failure
End

It "pins actions/cache to a full commit SHA"
When call grep -Eq 'uses: actions/cache@[0-9a-f]{40} # v[0-9]' "$ACTION_FILE"
The status should be success
End

It "caches the pre-commit environments directory"
When call grep -Fq 'path: ~/.cache/pre-commit' "$ACTION_FILE"
The status should be success
End

It "keys the cache on the architecture, the interpreter and the config file in use"
When call grep -Fq 'key: pre-commit-3|${{ runner.arch }}|${{ env.pythonLocation }}|${{ hashFiles(inputs.pre-commit-config || '"'"'.pre-commit-config.yaml'"'"') }}' "$ACTION_FILE"
The status should be success
End

It "installs, then restores the cache, then runs hooks"
install_line=$(step_line "Install pre-commit")
cache_line=$(step_line "Cache pre-commit environments")
run_line=$(step_line "Run pre-commit")
When call ascending "$install_line" "$cache_line" "$run_line"
The status should be success
End
End
End
