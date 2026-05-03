#!/usr/bin/env shellspec
# Behavior test for docker-build comma-split parsers: glob chars in values
# must not expand against the runner's working directory.

Describe "docker-build parse-build-args (behavior)"
  ACTION_DIR="${PROJECT_ROOT}/docker-build"

  before() {
    shellspec_setup_test_env "docker-build-behavior-$$"
    harness_reset
  }
  BeforeEach 'before'

  after() {
    shellspec_cleanup_test_env "docker-build-behavior-$$"
    harness_reset
  }
  AfterEach 'after'

  It "does not glob-expand build-arg values containing * against \$PWD"
    # Pre-populate workspace with files that WILL be globbed if noglob
    # is not set. Value is a bare `*.go` — this IS a shell glob that
    # matches the created files, so reverting `set -f` in the action
    # produces two extra `--build-arg a.go` / `--build-arg b.go` entries.
    : > a.go
    : > b.go
    export INPUT_BUILD_ARGS="*.go,NAME=app"

    When call run_step "${ACTION_DIR}" "build-args"
    The status should be success
    # Literal *.go preserved; filenames must NOT appear in args output.
    Assert expect_output args " --build-arg *.go --build-arg NAME=app"
  End

  It "produces expected flags for normal comma-separated values"
    export INPUT_BUILD_ARGS="KEY=value,FOO=bar"

    When call run_step "${ACTION_DIR}" "build-args"
    The status should be success
    Assert expect_output args " --build-arg KEY=value --build-arg FOO=bar"
  End
End
