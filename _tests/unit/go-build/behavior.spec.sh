#!/usr/bin/env shellspec
# Behavior-level tests for go-build's dependency steps.
#
# `go mod verify` skips modules missing from the cache, so it can pass after a failed
# `go mod download`. The download has to decide its own step's result.

Describe "go-build (behavior)"
ACTION_DIR="${PROJECT_ROOT}/go-build"

before() {
  shellspec_setup_test_env "go-build-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "go-build-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "Download Dependencies"
It "fails when go mod download fails, even if go mod verify would pass"
mock_command go "mod download" "" 1
mock_command go "mod verify" "" 0

When call run_retry_step "${ACTION_DIR}" "Download Dependencies"
The status should be failure
End

It "succeeds when go mod download succeeds"
mock_command go "mod download" "" 0

When call run_retry_step "${ACTION_DIR}" "Download Dependencies"
The status should be success
End
End

Describe "Verify Dependencies"
It "fails when go mod verify fails"
mock_command go "mod verify" "module changed" 1

When call run_retry_step "${ACTION_DIR}" "Verify Dependencies"
The status should be failure
The output should equal "module changed"
End

It "succeeds when go mod verify succeeds"
mock_command go "mod verify" "all modules verified" 0

When call run_retry_step "${ACTION_DIR}" "Verify Dependencies"
The status should be success
The output should equal "all modules verified"
End
End

Describe "the build"
# The step asks go for the host's OS to name its null device; a Linux host unless an example says.
set_destination() {
  export INPUT_DESTINATION="${PWD}/out"
  mock_command go "env GOHOSTOS" "linux" 0
}
Before 'set_destination'

# go_calls: every recorded call, one JSON array per line.
go_calls() { cat "${HARNESS_SESSION}/calls.jsonl"; }

# The go list call: "main" for a main package with files to build, an empty line for any other.
LIST_MAINS='list -f {{if and (eq .Name "main") (or .GoFiles .CgoFiles)}}main{{end}} ./...'

# Only the go commands an example names are mocked, so any other go command fails the step.
It "compiles every package, then writes the executables when there is a main package"
mock_command go "build -o /dev/null ./..." "" 0
mock_command go "$LIST_MAINS" "$(printf '\nmain')" 0
mock_command go "build -ldflags=-s -w -o ${PWD}/out/ ./..." "" 0

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build completed successfully"
Assert expect_output status success
Assert expect_argv go build -o /dev/null ./...
Assert expect_argv go build "-ldflags=-s -w" -o "${PWD}/out/" ./...
End

# Given one main package alone, go build ./... writes its executable to the working directory
# unless -o names the null device, which on Windows is NUL.
It "keeps nothing from the check build on Windows either"
harness_reset
export INPUT_DESTINATION="${PWD}/out"
mock_command go "env GOHOSTOS" "windows" 0
mock_command go "build -o NUL ./..." "" 0
mock_command go "$LIST_MAINS" "" 0

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build completed successfully"
Assert expect_argv go build -o NUL ./...
End

# go refuses -o with a directory when no package is a main package with files to build, which
# includes a main package of test files alone.
It "passes a module with no main package to build, writing no executables"
mock_command go "build -o /dev/null ./..." "" 0
mock_command go "$LIST_MAINS" "" 0

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build completed successfully"
Assert expect_output status success
The result of function go_calls should not include "-ldflags"
End

It "fails without writing executables when a package does not compile"
mock_command go "build -o /dev/null ./..." "build failed" 1

When call run_step "${ACTION_DIR}" "build"
The status should be failure
The stdout should include "Build failed"
Assert expect_output status failure
The result of function go_calls should not include "-ldflags"
End

It "fails when writing the executables fails"
mock_command go "build -o /dev/null ./..." "" 0
mock_command go "$LIST_MAINS" "main" 0
mock_command go "build -ldflags=-s -w -o ${PWD}/out/ ./..." "link failed" 1

When call run_step "${ACTION_DIR}" "build"
The status should be failure
The stdout should include "Build failed"
Assert expect_output status failure
End

# A directory name could reach go as a flag if the step passed names on. It passes none.
It "passes no repository file name to go"
mkdir -p -- "-toolexec=x" "my app"
printf 'package main\n\nfunc main() {}\n' >"-toolexec=x/main.go"
printf 'package main\n\nfunc main() {}\n' >"my app/main.go"
mock_command go "build*" "" 0
mock_command go "list*" "main" 0

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build completed successfully"
The result of function go_calls should not include "toolexec"
The result of function go_calls should not include "my app"
End
End

# The validator takes an empty destination as unset; passed on, it would run mkdir -p -- "".
It "reads an empty destination as the default in the build, its output and the upload"
When call yq -r '.outputs.binary_path.value, (.runs.steps[] | (.env.DESTINATION, .with.path) | select(. != null))' "${ACTION_DIR}/action.yml"
The output should include "\${{ inputs.destination || './bin' }}"
The output should not include "\${{ inputs.destination }}"
End
End
