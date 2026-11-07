#!/usr/bin/env shellspec
# Behavior tests for the steps that read a tool version from a repository file:
# csharp-build, csharp-lint-check, csharp-publish, go-build, language-version-detect,
# php-tests, pr-lint and python-lint-fix.
#
# The file belongs to the checked-out repository, so its value is untrusted. Each step
# asks its action's generated validate.py whether to accept the value; a rejected value
# falls through to the next source and finally to the step's default. These tests run
# the real steps, which also proves the ACTION_PATH wiring. The format rule itself is
# covered value by value in _validation/tests/test_kit.py.

Describe "versions detected from repository files"
before() {
  shellspec_setup_test_env "detected-version-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "detected-version-$$"
  harness_reset
}
AfterEach 'after'

# run_site "<action> <step id> <.tool-versions key> [language input]"
run_site() {
  local action step language
  read -r action step _ language <<<"$1"
  INPUT_LANGUAGE="${language:-}" INPUT_DEFAULT_VERSION="7.0" run_step "${PROJECT_ROOT}/${action}" "$step"
}

# detect_from_tool_versions "<site>" "<version>"
detect_from_tool_versions() {
  local key
  read -r _ _ key _ <<<"$1"
  printf '%s %s\n' "$key" "$2" >.tool-versions
  run_site "$1"
}

not_in_output() {
  ! grep -Fq -- "$1" "$GITHUB_OUTPUT"
}

Describe "every detection step"
Parameters
"csharp-build detect-dotnet-version dotnet"
"csharp-lint-check detect-dotnet-version dotnet"
"csharp-publish detect-dotnet-version dotnet"
"go-build detect-go-version golang"
"php-tests detect-php-version php"
"pr-lint php-version php"
"pr-lint python-version python"
"pr-lint go-version golang"
"python-lint-fix python-version python"
"language-version-detect parse-version php php"
"language-version-detect parse-version python python"
"language-version-detect parse-version golang go"
"language-version-detect parse-version dotnet dotnet"
End

It "rejects shell metacharacters: $1"
When call detect_from_tool_versions "$1" '8.4;evil'
The status should be success
The stderr should include "Using default"
Assert not_in_output 'evil'
End

It "rejects command substitution: $1"
When call detect_from_tool_versions "$1" '8.4$(evil)'
The status should be success
The stderr should include "Using default"
Assert not_in_output 'evil'
End

It "accepts a release version: $1"
When call detect_from_tool_versions "$1" '8.4.1'
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '8.4.1'
End

It "strips a v prefix: $1"
When call detect_from_tool_versions "$1" 'v1.2.3'
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '1.2.3'
End

It "accepts a pre-release: $1"
When call detect_from_tool_versions "$1" '1.0.0-rc.1'
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '1.0.0-rc.1'
End

It "accepts build metadata: $1"
When call detect_from_tool_versions "$1" '1.0.0+build.5'
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '1.0.0+build.5'
End

It "cannot be redirected to a validate.py or re.py in the checkout: $1"
printf 'raise SystemExit(0)\n' >validate.py
printf 'raise SystemExit(0)\n' >re.py
When call detect_from_tool_versions "$1" '8.4;evil'
The status should be success
The stderr should include "Using default"
Assert not_in_output 'evil'
End
End

Describe "language-version-detect repository files"
It "does not turn a multi-line sdk.version into extra step outputs"
printf '%s\n' '{"sdk": {"version": "8.0\npackage-manager=evil\ninjected=1"}}' >global.json
When call run_site "language-version-detect parse-version dotnet dotnet"
The status should be success
The stderr should include "Using default"
Assert expect_output detected-version '7.0'
Assert expect_output package-manager 'dotnet'
Assert not_in_output 'evil'
Assert not_in_output 'injected'
End

It "strips a v prefix from sdk.version"
printf '%s\n' '{"sdk": {"version": "v8.0.100"}}' >global.json
When call run_site "language-version-detect parse-version dotnet dotnet"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '8.0.100'
End

It "keeps a .NET preview SDK from global.json"
printf '%s\n' '{"sdk": {"version": "10.0.100-preview.1.25120.13"}}' >global.json
When call run_site "language-version-detect parse-version dotnet dotnet"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '10.0.100-preview.1.25120.13'
End

It "reads a Go release candidate from go.mod"
printf 'module example.com/m\n\ngo 1.23rc1\n' >go.mod
When call run_site "language-version-detect parse-version golang go"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '1.23rc1'
End

It "rejects a go.mod version with shell metacharacters"
printf 'module example.com/m\n\ngo 1.22;evil\n' >go.mod
When call run_site "language-version-detect parse-version golang go"
The status should be success
The stderr should include "Using default"
Assert not_in_output 'evil'
End

It "reads the lowest PHP version from a composer.json constraint"
printf '%s\n' '{"require": {"php": "^8.2 || ^8.3"}}' >composer.json
When call run_site "language-version-detect parse-version php php"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '8.2'
End

It "reads the Python version from requires-python"
printf '[project]\nrequires-python = ">=3.11"\n' >pyproject.toml
When call run_site "language-version-detect parse-version python python"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '3.11'
End

It "still rejects a bare .NET major, as it did before"
When call detect_from_tool_versions "language-version-detect parse-version dotnet dotnet" '8'
The status should be success
The stderr should include "Using default"
Assert expect_output detected-version '7.0'
End
End

Describe ".NET version forms accepted by the csharp actions"
Parameters:matrix
csharp-build csharp-lint-check csharp-publish
8 8.x 8.0 8.0.x 8.0.4xx 8.0.416 10.0.100-preview.1.25120.13
End

It "accepts $2 in $1"
When call detect_from_tool_versions "$1 detect-dotnet-version dotnet" "$2"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version "$2"
End
End

Describe ".NET wildcards and non-versions in the csharp actions"
Parameters:matrix
csharp-build csharp-lint-check csharp-publish
'8.0.*' 8. latest
End

It "rejects $2 in $1"
When call detect_from_tool_versions "$1 detect-dotnet-version dotnet" "$2"
The status should be success
The stderr should include "Using default"
End
End

Describe "versions the non-.NET steps already rejected"
It "keeps rejecting a bare major in .python-version"
printf '3\n' >.python-version
When call run_site "python-lint-fix python-version python"
The status should be success
The stderr should include "Using default"
End

It "keeps rejecting latest in .tool-versions"
When call detect_from_tool_versions "php-tests detect-php-version php" 'latest'
The status should be success
The stderr should include "Using default"
Assert not_in_output 'latest'
End
End

Describe "values that are not read from repository files"
It "still passes a documented php-version of latest through unchanged"
INPUT_PHP_VERSION="latest"
export INPUT_PHP_VERSION
When call run_site "php-tests detect-php-version php"
The status should be success
The stderr should include "Using default"
Assert expect_output detected-version 'latest'
End
End

Describe "per-language version files"
It "accepts a Python dev build from .python-version"
printf '3.13-dev\n' >.python-version
When call run_site "python-lint-fix python-version python"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '3.13-dev'
End

It "accepts a free-threaded Python build from .python-version"
printf '3.14t-dev\n' >.python-version
When call run_site "pr-lint python-version python"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '3.14t-dev'
End

It "accepts a Go wildcard from .go-version"
printf '1.25.x\n' >.go-version
When call run_site "go-build detect-go-version golang"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version '1.25.x'
End

It "rejects shell metacharacters in the first line of .php-version"
printf '8.4;evil\n' >.php-version
When call run_site "php-tests detect-php-version php"
The status should be success
The stderr should include "Using default"
Assert not_in_output 'evil'
End
End

Describe "go-build devcontainer image"
Parameters
"golang:1.22" "1.22"
"golang:1.22.3" "1.22.3"
"golang:1.22-bookworm" "1.22"
End

It "reads $2 from $1"
mkdir -p .devcontainer
printf '{"image": "%s"}\n' "$1" >.devcontainer/devcontainer.json
When call run_site "go-build detect-go-version golang"
The status should be success
The stderr should not include "Using default"
Assert expect_output detected-version "$2"
End
End
End
