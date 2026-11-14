#!/usr/bin/env shellspec
# Behavior tests for the remaining steps that post-process text with sed, run through the
# real steps. See detection.spec.sh for why they run on GNU tools at all: they pin what a
# pattern matches, so a rewrite that turns a literal into an operator fails here.

Describe "steps that post-process text with sed"
before() {
  shellspec_setup_test_env "posix-shell-sed-steps-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "posix-shell-sed-steps-$$"
  harness_reset
}
AfterEach 'after'

Describe "docker-build"
ACTION_DIR="${PROJECT_ROOT}/docker-build"

It "drops the trailing comma from detected platforms"
export INPUT_AUTO_DETECT_PLATFORMS="true"
mock_command docker "buildx ls*" "builder  docker  linux/arm64 linux/amd64"

When call run_step "${ACTION_DIR}" "detect-platforms"
The status should be success
The stdout should include "Detected platforms"
Assert expect_output platforms "linux/amd64,linux/arm64"
End

# The registry cache reference is normalized inside the build step, so its cases live in
# _tests/unit/docker-build/behavior.spec.sh, which sets up that step's inputs and mocks.
End

Describe "php-tests composer version"
detect_with() {
  mock_command composer "--no-plugins --version" "$1"
  run_step "${PROJECT_ROOT}/php-tests" "composer-version"
}

# Parameters applies to every later example in this block, so the single example comes first.
It "fails on a version it cannot read"
When call detect_with "Composer 2.8"
The status should be failure
The stdout should include "Failed to detect Composer version"
End

Parameters
"Composer version 2.8.1 2024-10-04 11:31:01" "2.8.1"
"Composer version 2.9.0-RC1 2025-01-01 00:00:00" "2.9.0"
"Composer version 2.8.1+build" "2.8.1"
"PHP Composer version 12.34.56" "12.34.56"
End

It "reads $2 from: $1"
When call detect_with "$1"
The status should be success
The stdout should include "Detected Composer version: $2"
Assert expect_output version "$2"
End
End

Describe "prettier-lint files_checked"
check_pattern() {
  mkdir -p src
  : >a.js
  : >b.ts
  : >src/c.md
  export INPUT_FILE_PATTERN="$1"
  export INPUT_FAIL_ON_ERROR="false"
  export INPUT_CACHE="false"
  export INPUT_CONFIG_FILE=".prettierrc"
  mock_command npx "prettier --check *" ""
  run_step "${PROJECT_ROOT}/prettier-lint" "check"
}

# files_checked counts the files whose extension the pattern names, anywhere in the tree.
# Prettier lists the files it checks only in its debug log, so the count does not apply the
# pattern's directories: {a,b}/*.{js} counts the a.js at the root. These rows pin which
# extensions the sed reads from each pattern.
Parameters
"**/*.{js,ts}" 2
"**/*.{js,ts,md}" 3
"src/**/*.{md}" 1
"{a,b}/*.{js}" 1
"**/*.js" 1
"src/**/*.md" 1
"*.py" 0
End

It "counts $2 files by extension for $1"
When call check_pattern "$1"
The status should be success
The stdout should include "Prettier check completed"
Assert expect_output files_checked "$2"
End
End
End
