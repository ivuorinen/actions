#!/usr/bin/env shellspec
# End-to-end ShellSpec tests for the composite-step harness.

Describe "harness"
FIXTURES="${PROJECT_ROOT}/_tests/fixtures/harness"

before() {
  shellspec_setup_test_env "harness-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "harness-$$"
  harness_reset
}
AfterEach 'after'

Describe "echo-inputs fixture"
It "passes INPUT_FOO through to the step and writes the output"
export INPUT_FOO="hello"
When call run_step "${FIXTURES}/echo-inputs" "emit"
The status should be success
The file "$GITHUB_OUTPUT" should be exist
Assert expect_output echoed hello
End
End

Describe "uses-gh fixture"
It "fails not-found when gh is not mocked"
# The harness shadows unmocked external commands with a not-found stub, so an
# unmocked gh fails as "not found" even on runners where gh ships in /usr/bin.
When call run_step "${FIXTURES}/uses-gh" "fetch"
The status should not be success
The stderr should include "not found"
End

It "runs when gh is mocked"
mock_command gh "release list *" "v2026.4.0"
When call run_step "${FIXTURES}/uses-gh" "fetch"
The status should be success
Assert expect_output tag "v2026.4.0"
End

It "records each argv entry of a mocked call separately"
argv_entries_are_not_joined() { ! expect_argv gh "release list" 2>/dev/null; }
mock_command gh "release list *" "v2026.4.0"
When call run_step "${FIXTURES}/uses-gh" "fetch"
The status should be success
Assert expect_argv gh release list
Assert argv_entries_are_not_joined
End
End

Describe "uses-curl fixture (external CLI present in /usr/bin)"
It "blocks an unmocked external command even when it exists on the system PATH"
# curl ships in /usr/bin on CI runners (and macOS), so this guards the
# regression where gh in /usr/bin slipped past the old system-dir PATH
# restriction: the harness must shadow it regardless of where it is installed.
When call run_step "${FIXTURES}/uses-curl" "fetch"
The status should not be success
The stderr should include "not found"
End
End

Describe "if-conditional fixture"
It "runs the gated step when prior step outputs match"
When call run_all_owned_steps "${FIXTURES}/if-conditional"
The status should be success
Assert expect_output flag yes
Assert expect_output ran true
End
End

Describe "env-export fixture (issue #559)"
It "makes GITHUB_ENV exports visible to subsequent steps"
When call run_all_owned_steps "${FIXTURES}/env-export"
The status should be success
The output should include "hello_world"
End
End

Describe "retry-step fixture"
It "reports success when only an earlier line of an unguarded command fails"
When call run_retry_step "${FIXTURES}/retry-step" "Unguarded"
The status should be success
End

It "stops at the first failure when the command begins with set -eu"
When call run_retry_step "${FIXTURES}/retry-step" "Guarded"
The status should be failure
End

It "fails when a single-line command fails"
When call run_retry_step "${FIXTURES}/retry-step" "Single line"
The status should be failure
End

It "fails loudly when the named retry step does not exist"
When call run_retry_step "${FIXTURES}/retry-step" "Missing"
The status should be failure
The stderr should include "retry step 'Missing' not found"
End

# Run literally, the command would test a non-empty string and pass for the wrong reason.
It "refuses a command that holds an expression instead of running it literally"
When call run_retry_step "${FIXTURES}/retry-step" "Expression"
The status should be failure
The stderr should include "pass the value through env:"
End

It "refuses a run step that holds an expression instead of running it literally"
mkdir -p expression-fixture
cat >expression-fixture/action.yml <<'YAML'
runs:
  using: composite
  steps:
    - id: expr
      shell: sh
      run: test -n "${{ github.sha }}"
YAML
When call run_step "${PWD}/expression-fixture" "expr"
The status should be failure
The stderr should include "pass the value through env:"
End

It "names only the multi-line command that does not begin with set -eu"
When call list_unguarded_retry_commands "${FIXTURES}"
The status should be success
The output should equal "retry-step: Unguarded"
End

It "names the unguarded commands of every action under the root"
mkdir -p scan-root/a scan-root/b
cp "${FIXTURES}/retry-step/action.yml" scan-root/a/
cp "${FIXTURES}/retry-step/action.yml" scan-root/b/
When call list_unguarded_retry_commands "${PWD}/scan-root"
The status should be success
The lines of output should equal 2
The line 1 of output should equal "a: Unguarded"
The line 2 of output should equal "b: Unguarded"
End
End

Describe "step-outputs fixture"
It "resolves an earlier step's output from HARNESS_STEP_OUTPUTS in run_step"
export HARNESS_STEP_OUTPUTS='{"first":{"outputs":{"flag":"seeded"}}}'
When call run_step "${FIXTURES}/step-outputs" "reader"
The status should be success
Assert expect_output seen seeded
End

It "resolves an earlier step's output to empty without HARNESS_STEP_OUTPUTS"
When call run_step "${FIXTURES}/step-outputs" "reader"
The status should be success
Assert expect_output seen ""
End
End

Describe "event-payload fixture"
It "resolves github.event fields from the file at GITHUB_EVENT_PATH"
printf '%s' '{"repository":{"default_branch":"trunk"}}' >event.json
export GITHUB_EVENT_PATH="${PWD}/event.json"
When call run_step "${FIXTURES}/event-payload" "emit"
The status should be success
Assert expect_output default-branch trunk
End

It "resolves github.event fields to empty without a payload file"
export GITHUB_EVENT_PATH="${PWD}/absent.json"
When call run_step "${FIXTURES}/event-payload" "emit"
The status should be success
Assert expect_output default-branch ""
End

It "renders a true github.event field as GitHub does and runs a step gated on it"
printf '%s' '{"deleted":true}' >event.json
export GITHUB_EVENT_PATH="${PWD}/event.json"
When call run_all_owned_steps "${FIXTURES}/event-payload"
The status should be success
The output should include "ran-gated"
Assert expect_output deleted true
Assert expect_output deleted-or-fallback true
End

It "renders a false github.event field as GitHub does and skips a step gated on it"
printf '%s' '{"deleted":false}' >event.json
export GITHUB_EVENT_PATH="${PWD}/event.json"
When call run_all_owned_steps "${FIXTURES}/event-payload"
The status should be success
The output should not include "ran-gated"
The output should not include "ran-on-action"
Assert expect_output deleted false
End

# GitHub's || returns its first truthy operand, and boolean false is falsy.
It "takes the || fallback past a false github.event field"
printf '%s' '{"deleted":false}' >event.json
export GITHUB_EVENT_PATH="${PWD}/event.json"
When call run_step "${FIXTURES}/event-payload" "emit"
The status should be success
Assert expect_output deleted-or-fallback fallback
End

# Any nonempty string is truthy, not only "true".
It "runs a step gated on a nonempty string github.event field"
printf '%s' '{"action":"opened"}' >event.json
export GITHUB_EVENT_PATH="${PWD}/event.json"
When call run_all_owned_steps "${FIXTURES}/event-payload"
The status should be success
The output should include "ran-on-action"
The output should not include "ran-gated"
End
End
End
