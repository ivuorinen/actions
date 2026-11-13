#!/usr/bin/env shellspec
# Behavior tests for the sed and grep pipelines that read versions from repository files.
#
# These run the real steps, so on Linux they pin what each pattern matches with GNU tools.
# They hold for the basic and the extended spelling of a pattern alike, which is what makes
# them the check that rewriting one as the other changed nothing. gnu_regex.spec.sh is what
# keeps the GNU-only spelling out.

Describe "version detection from repository files"
before() {
  shellspec_setup_test_env "posix-shell-detection-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "posix-shell-detection-$$"
  harness_reset
}
AfterEach 'after'

# run_site "<action> <step id> [language input]"
run_site() {
  local action step language
  read -r action step language <<<"$1"
  INPUT_LANGUAGE="${language:-}" INPUT_DEFAULT_VERSION="0.0" run_step "${PROJECT_ROOT}/${action}" "$step"
}

Describe ".tool-versions"
# run_site takes "<action> <step id> [language input]"; the key follows the "|".
from_tool_versions() {
  printf '%s %s\n' "${1#*|}" "$2" >.tool-versions
  run_site "${1%|*}"
}

Parameters:matrix
"csharp-build detect-dotnet-version|dotnet" "csharp-lint-check detect-dotnet-version|dotnet" "csharp-publish detect-dotnet-version|dotnet" "go-build detect-go-version|golang" "php-tests detect-php-version|php" "pr-lint php-version|php" "pr-lint go-version|golang" "python-lint-fix python-version|python" "language-version-detect parse-version php|php" "language-version-detect parse-version python|python" "language-version-detect parse-version go|golang" "language-version-detect parse-version dotnet|dotnet"
"v8.4.1|8.4.1" "V8.4.1-rc.1|8.4.1-rc.1" "8.4.1+build|8.4.1+build"
End

It "strips a leading v from ${2%|*}: $1"
When call from_tool_versions "$1" "${2%|*}"
The status should be success
The stderr should be present
Assert expect_output detected-version "${2#*|}"
End
End

Describe "composer.json"
from_require() {
  jq -n --arg version "$2" '{require: {php: $version}}' >composer.json
  run_site "$1"
}

from_platform() {
  jq -n --arg version "$2" '{require: {php: "*"}, config: {platform: {php: $version}}}' >composer.json
  run_site "$1"
}

Parameters:matrix
"language-version-detect parse-version php" "php-tests detect-php-version" "pr-lint php-version"
"^8.3|8.3" ">=8.3.1 <9.0|8.3.1" "8.4.0-rc.1|8.4.0" "v8.4.1-rc.1|8.4.1" "8.4.1+build|8.4.1" "8.4.5+sha.abc1234|8.4.5"
End

It "reads ${2%|*} from require.php: $1"
When call from_require "$1" "${2%|*}"
The status should be success
The stderr should include "Final detected"
Assert expect_output detected-version "${2#*|}"
End

It "falls back to ${2%|*} in config.platform.php: $1"
When call from_platform "$1" "${2%|*}"
The status should be success
The stderr should include "Final detected"
Assert expect_output detected-version "${2#*|}"
End
End

Describe "composer.json without a dotted version"
from_bare_major() {
  jq -n '{require: {php: "8"}}' >composer.json
  run_site "$1"
}

Parameters
"language-version-detect parse-version php"
"php-tests detect-php-version"
"pr-lint php-version"
End

It "uses the default: $1"
When call from_bare_major "$1"
The status should be success
The stderr should include "Using default"
End
End

Describe "composer.json constraint that spans lines"
# Each line yields a match, and clean_version would join them into a version that does not exist.
from_multiline_require() {
  printf '%s\n' '{"require": {"php": "^8.2 ||\n^8.3"}}' >composer.json
  run_site "$1"
}

from_multiline_platform() {
  printf '%s\n' '{"require": {"php": "*"}, "config": {"platform": {"php": "8.2.1 ||\n8.3"}}}' >composer.json
  run_site "$1"
}

Parameters
"language-version-detect parse-version php"
"php-tests detect-php-version"
"pr-lint php-version"
End

It "reads one version from require.php: $1"
When call from_multiline_require "$1"
The status should be success
The stderr should include "Final detected"
Assert expect_output detected-version "8.2"
End

It "reads one version from config.platform.php: $1"
When call from_multiline_platform "$1"
The status should be success
The stderr should include "Final detected"
Assert expect_output detected-version "8.2.1"
End
End

Describe "pyproject.toml"
from_pyproject() {
  printf '[project]\nname = "x"\n%b\n' "$2" >pyproject.toml
  run_site "$1"
}

Parameters:matrix
"language-version-detect parse-version python"
'requires-python = ">=3.11"|3.11' '  requires-python = "^3.12.1"|3.12.1' '\trequires-python = "~=3.13"|3.13' 'requires-python=">=3.13.0-rc.1"|3.13.0' 'requires-python = ">=3.12.4+build"|3.12.4'
End

It "reads ${2%|*}: $1"
When call from_pyproject "$1" "${2%|*}"
The status should be success
The stderr should include "Final detected"
Assert expect_output detected-version "${2#*|}"
End
End

Describe "pyproject.toml with a look-alike key"
from_lookalike() {
  printf '[project]\nx-requires-python = ">=3.9"\n' >pyproject.toml
  run_site "$1"
}

Parameters
"language-version-detect parse-version python"
End

It "uses the default: $1"
When call from_lookalike "$1"
The status should be success
The stderr should include "Using default"
End
End

Describe "container images in language-version-detect"
from_dockerfile() {
  printf 'FROM %s\n' "$2" >Dockerfile
  run_site "language-version-detect parse-version $1"
}

from_devcontainer() {
  mkdir -p .devcontainer
  jq -n --arg image "$2" '{image: $image}' >.devcontainer/devcontainer.json
  run_site "language-version-detect parse-version $1"
}

Parameters
php php:8.4 8.4
php php:8.4.2-alpine 8.4.2
php docker.io/library/php:8.3.12-fpm 8.3.12
php php:8.4.1-rc.1 8.4.1
php php:8.4.1+build 8.4.1
php php:latest 0.0
python python:3.12-slim 3.12
go golang:1.24.3-alpine 1.24.3
dotnet dotnet:8.0 8.0
End

It "reads $2 from a Dockerfile"
When call from_dockerfile "$1" "$2"
The status should be success
The stderr should include "Final detected"
Assert expect_output detected-version "$3"
End

It "reads $2 from devcontainer.json"
When call from_devcontainer "$1" "$2"
The status should be success
The stderr should include "Final detected"
Assert expect_output detected-version "$3"
End
End

Describe "pr-lint's packageManager fallback"
# The fallback runs only without jq, which stays on the harness PATH, so run_step cannot
# reach it. This reads the pattern out of the action rather than keeping a second copy.
matches_package_manager() {
  local pattern
  pattern=$(sed -n -E "s/.*grep -[[:alpha:]]+ '(\"packageManager\"[^']*)'.*/\1/p" "${PROJECT_ROOT}/pr-lint/action.yml")
  [ -n "$pattern" ] && printf '%s\n' "$1" | grep -qE "$pattern"
}

Parameters
'{"packageManager": "pnpm@9.0.0"}' success
'{ "packageManager"  :  "yarn@4" }' success
'{"packageManager":"npm@10.1.0-rc.1+sha.abc1234"}' success
'{"packageManager": ""}' failure
'{"name": "packageManager"}' failure
End

It "$2 on $1"
When call matches_package_manager "$1"
The status should be "$2"
End
End
End
