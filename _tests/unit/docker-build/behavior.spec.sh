#!/usr/bin/env shellspec
# Behavior tests for how docker-build's build step turns inputs into the
# `docker buildx build` command line: one input item is exactly one argv entry,
# and input values never reach $GITHUB_OUTPUT.
#
# Each step runs on its own here, so validate.py is not in the way. The odd values
# below prove the second layer holds even if a value got past validation.

Describe "docker-build build step (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"
REGISTRY_CACHE="type=registry,ref=ghcr.io/acme/app/cache:latest"

before() {
  shellspec_setup_test_env "docker-build-behavior-$$"
  harness_reset
  # A local, single-attempt build. `docker` is mocked, so nothing is built.
  export INPUT_TAG="v1.0.0"
  export INPUT_PUSH="false"
  export INPUT_MAX_RETRIES="1"
  export INPUT_ARCHITECTURES="linux/amd64"
  export INPUT_DOCKERFILE="Dockerfile"
  export INPUT_CONTEXT="."
  export INPUT_CACHE_MODE="max"
  export GITHUB_REPOSITORY="Acme/App"
  unset GITHUB_TOKEN
  mock_command docker "buildx build *" ""
  mock_command docker "inspect *" "sha256:fixture"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-behavior-$$"
  harness_reset
}
AfterEach 'after'

argv_lacks() { ! expect_argv docker "$@" 2>/dev/null; }

Describe "comma-separated list inputs"
It "keeps a build-arg value with spaces in one argv entry"
export INPUT_BUILD_ARGS="FOO=hello world,BAR=x"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --build-arg "FOO=hello world"
Assert expect_argv docker --build-arg "BAR=x"
End

It "keeps flag-like text inside a build-arg value"
export INPUT_BUILD_ARGS="OPTS=--enable-foo  --disable-bar"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --build-arg "OPTS=--enable-foo  --disable-bar"
End

It "ignores whitespace around items, a trailing newline and empty items"
export INPUT_BUILD_ARGS=" A=1, B=2,,C=3
"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --build-arg "A=1" --build-arg "B=2" --build-arg "C=3"
End

It "does not glob-expand values against \$PWD"
# Pre-populate workspace with files that WILL be globbed if noglob is not
# set: reverting `set -f` produces `--build-arg a.go` / `--build-arg b.go`.
: >a.go
: >b.go
export INPUT_BUILD_ARGS="*.go,NAME=app"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --build-arg "*.go" --build-arg "NAME=app"
Assert argv_lacks --build-arg "a.go"
End

It "keeps a build-context path with spaces in one argv entry"
export INPUT_BUILD_CONTEXTS="base=./my dir,img=docker-image://alpine:3.18"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --build-context "base=./my dir"
Assert expect_argv docker --build-context "img=docker-image://alpine:3.18"
End

It "maps secrets to id and src, with spaces kept in one argv entry"
export INPUT_SECRETS="npm=.npmrc, aws=config/aws  credentials"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --secret "id=npm,src=.npmrc"
Assert expect_argv docker --secret "id=aws,src=config/aws  credentials"
End

It "keeps a multi-line value in one argv entry"
export INPUT_BUILD_ARGS="A=1
B=2"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --build-arg "A=1
B=2"
End
End

Describe "paths on disk"
It "rejects a secret that a symlink takes out of the workspace"
: >plain
ln -s /etc/hostname link
export INPUT_SECRETS="ok=plain, bad=link"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be failure
The output should equal "::error::Secret bad resolves outside the workspace"
End

It "rejects a secret below a symlinked directory that leaves the workspace"
ln -s /etc linked
export INPUT_SECRETS="bad=linked/hostname"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be failure
The output should equal "::error::Secret bad resolves outside the workspace"
End

It "accepts plain files and symlinks that stay in the workspace"
mkdir real
: >real/file
ln -s real/file inside
export INPUT_SECRETS="a=real/file,b=inside,c=not-created-yet"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be success
The output should equal ""
End

It "rejects a context that a symlink takes out of the workspace"
ln -s /etc outside
export INPUT_CONTEXT="outside"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be failure
The output should equal "::error::Context resolves outside the workspace"
End

It "rejects a Dockerfile below a symlinked directory that leaves the workspace"
ln -s /etc linked
export INPUT_DOCKERFILE="linked/Dockerfile"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be failure
The output should equal "::error::Dockerfile resolves outside the workspace"
End

It "rejects a local build context that a symlink takes out of the workspace"
ln -s /etc linked
export INPUT_BUILD_CONTEXTS="ok=.,bad=linked"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be failure
The output should equal "::error::Build context bad resolves outside the workspace"
End

It "follows a symlink whose name holds a space"
ln -s /etc "out side"
export INPUT_SECRETS="bad=out side"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be failure
The output should equal "::error::Secret bad resolves outside the workspace"
End

It "checks the path of an oci-layout build context without its tag and digest"
ln -s /etc linked
digest="sha256:$(printf '%064d' 0)"
export INPUT_BUILD_CONTEXTS="bad=oci-layout://linked:v1@${digest}"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be failure
The output should equal "::error::Build context bad resolves outside the workspace"
End

It "does not read remote or reference build contexts as paths"
# As a path, the last value would resolve through this link and leave the workspace.
ln -s /etc github.com
export INPUT_BUILD_CONTEXTS="a=docker-image://alpine:3.20,b=target:build,c=https://example.com/a.git,d=github.com/a/b"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be success
The output should equal ""
End

It "accepts a context, Dockerfile and build context that stay in the workspace"
mkdir real
: >real/Dockerfile
ln -s real inside
export INPUT_CONTEXT="inside"
export INPUT_DOCKERFILE="inside/Dockerfile"
export INPUT_BUILD_CONTEXTS="shared=inside"

When call run_step "${ACTION_DIR}" "build-paths"
The status should be success
The output should equal ""
End
End

Describe "cache inputs"
It "never splits a cache-import spec on whitespace"
export INPUT_CACHE_IMPORT="type=gha --push"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "type=gha --push"
Assert argv_lacks --push
End

It "never splits a cache-from spec on whitespace"
export INPUT_CACHE_FROM="type=gha --push"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "type=gha --push"
Assert argv_lacks --push
End

It "never splits a cache-export spec on whitespace"
export INPUT_CACHE_EXPORT="type=gha --push"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-to "type=gha --push"
Assert argv_lacks --push
End

It "prefers cache-import over cache-from"
export INPUT_CACHE_IMPORT="type=local,src=cache"
export INPUT_CACHE_FROM="type=gha"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "type=local,src=cache"
Assert argv_lacks --cache-from "type=gha"
End

It "strips the trailing newline of a block scalar"
export INPUT_CACHE_FROM="type=gha
"
export INPUT_CACHE_EXPORT="type=gha,mode=max
"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "type=gha"
Assert expect_argv docker --cache-to "type=gha,mode=max"
End

It "always adds the local cache as a fallback"
When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "type=local,src=/tmp/.buildx-cache"
Assert expect_argv docker --cache-to "type=local,dest=/tmp/.buildx-cache-new,mode=max"
End

It "adds no second local export when cache-export is already local"
export INPUT_CACHE_EXPORT="type=local,dest=cache"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-to "type=local,dest=cache"
Assert argv_lacks --cache-to "type=local,dest=/tmp/.buildx-cache-new,mode=max"
End

It "still adds the local export when only another field mentions type=local"
export INPUT_CACHE_EXPORT="type=gha,scope=type=local"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-to "type=gha,scope=type=local"
Assert expect_argv docker --cache-to "type=local,dest=/tmp/.buildx-cache-new,mode=max"
End

It "keeps a local cache path with spaces in one argv entry"
export INPUT_CACHE_EXPORT="type=local,dest=/tmp/my cache"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-to "type=local,dest=/tmp/my cache"
End

It "uses the registry cache when a token is set"
export INPUT_TOKEN="ghp_fixture_0000000000000000000000000000"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "${REGISTRY_CACHE}"
Assert expect_argv docker --cache-to "${REGISTRY_CACHE},mode=max"
End

It "uses the registry cache when GITHUB_TOKEN is set"
export GITHUB_TOKEN="ghp_fixture_0000000000000000000000000000"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "${REGISTRY_CACHE}"
End

It "skips the registry cache without a push or a token"
When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert argv_lacks --cache-from "${REGISTRY_CACHE}"
Assert argv_lacks --cache-to "${REGISTRY_CACHE},mode=max"
End

It "lets cache-export replace the registry cache export"
export INPUT_TOKEN="ghp_fixture_0000000000000000000000000000"
export INPUT_CACHE_EXPORT="type=gha,mode=max"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-to "type=gha,mode=max"
Assert argv_lacks --cache-to "${REGISTRY_CACHE},mode=max"
End
End

Describe "registry cache reference"
# The repository is lower-cased, and each character outside [a-z0-9._/-] becomes "-".
Parameters
"Owner/Repo" "owner/repo"
"my.org_x/Repo-1" "my.org_x/repo-1"
"Owner/Repo+Name@1" "owner/repo-name-1"
"Owner/Repo(x)|y" "owner/repo-x--y"
End

It "normalizes $1 to $2"
export INPUT_TOKEN="ghp_fixture_0000000000000000000000000000"
export GITHUB_REPOSITORY="$1"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --cache-from "type=registry,ref=ghcr.io/$2/cache:latest"
End
End

Describe "other arguments"
It "keeps a dash-leading context from being read as a flag"
export INPUT_CONTEXT="--no-cache"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker -- "--no-cache"
End

It "passes the verbose option as its own entry"
export INPUT_VERBOSE="true"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --load --progress=plain
End
End

Describe "attestations"
It "attaches provenance and an SBOM when pushing, without a format flag"
export INPUT_PUSH="true"
export INPUT_SBOM_FORMAT="spdx-json"
write_docker_build_metadata

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --push --provenance=true --sbom=true
Assert argv_lacks --sbom-format=spdx-json
End

It "omits attestations from a local load, which the docker exporter rejects"
export INPUT_SBOM_FORMAT="spdx-json"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
Assert expect_argv docker --load
Assert argv_lacks --provenance=true
Assert argv_lacks --sbom=true
Assert argv_lacks --sbom-format=spdx-json
End

Context "with build metadata written"
Before 'write_docker_build_metadata'

It "emits no SBOM location, because buildx metadata has none to read"
When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
The contents of file "${GITHUB_OUTPUT}" should include "containerimage.digest"
The contents of file "${GITHUB_OUTPUT}" should not include "sbom-location"
End
End
End

It "writes no input value to GITHUB_OUTPUT"
export INPUT_BUILD_ARGS="A=1
injected_args=1"
export INPUT_BUILD_CONTEXTS="a=b
injected_contexts=1"
export INPUT_SECRETS="a=b
injected_secrets=1"
export INPUT_CACHE_IMPORT="type=gha
injected_from=1"
export INPUT_CACHE_EXPORT="type=gha
injected_to=1"

When call run_step "${ACTION_DIR}" "build"
The status should be success
The output should include "Build attempt 1 of 1"
The contents of file "${GITHUB_OUTPUT}" should not include "injected"
End
End
