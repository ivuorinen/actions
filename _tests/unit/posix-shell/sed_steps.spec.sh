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

It "drops the trailing comma from verified platforms"
export INPUT_PUSH="true"
mock_command docker "buildx imagetools inspect *" "Platform: linux/amd64
Platform: linux/arm64"

When call run_step "${ACTION_DIR}" "verify"
The status should be success
Assert expect_output built "linux/amd64,linux/arm64"
End

Describe "cache reference"
Parameters
"Owner/Repo" "owner/repo"
"my.org_x/Repo-1" "my.org_x/repo-1"
"Owner/Repo+Name@1" "owner/repo-name-1"
"Owner/Repo(x)|y" "owner/repo-x--y"
End

It "normalizes $1"
export INPUT_PUSH="true"
export GITHUB_REPOSITORY="$1"

When call run_step "${ACTION_DIR}" "cache"
The status should be success
The contents of file "$GITHUB_OUTPUT" should include "ref=ghcr.io/$2/cache:latest"
End
End
End

Describe "php-tests composer version"
configure_with() {
  mock_command composer "config *" ""
  mock_command composer "--version" "$1"
  run_step "${PROJECT_ROOT}/php-tests" "composer-config"
}

Parameters
"Composer version 2.8.1 2024-10-04 11:31:01" "2.8.1"
"Composer version 2.9.0-RC1 2025-01-01 00:00:00" "2.9.0"
"Composer version 2.8.1+build" "2.8.1"
"PHP Composer version 12.34.56" "12.34.56"
End

It "reads $2 from: $1"
When call configure_with "$1"
The status should be success
The stdout should include "Detected Composer version: $2"
Assert expect_output version "$2"
End

It "fails on a version it cannot read"
When call configure_with "Composer 2.8"
The status should be failure
The stdout should include "Failed to detect Composer version"
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

Parameters
"**/*.{js,ts}" 2
"**/*.{js,ts,md}" 3
"src/**/*.{md}" 1
"{a,b}/*.{js}" 1
"**/*.js" 1
"src/**/*.md" 1
"*.py" 0
End

It "counts $2 for $1"
When call check_pattern "$1"
The status should be success
The stdout should include "Prettier check completed"
Assert expect_output files_checked "$2"
End
End
End
