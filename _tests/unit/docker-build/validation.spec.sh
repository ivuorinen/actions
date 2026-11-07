#!/usr/bin/env shellspec
# Unit tests for docker-build action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "docker-build action"
ACTION_DIR="docker-build"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating image-name input"
It "accepts valid image name"
When call validate_input_python "docker-build" "image-name" "myapp"
The status should be success
End
It "accepts image name with registry prefix"
When call validate_input_python "docker-build" "image-name" "registry.example.com/myapp"
The status should be success
End
It "rejects command injection in image name"
When call validate_input_python "docker-build" "image-name" "app; rm -rf /"
The status should be failure
End
End

Context "when validating tag input"
It "accepts valid tag format"
When call validate_input_python "docker-build" "tag" "v1.0.0"
The status should be success
End
It "accepts semantic version tag"
When call validate_input_python "docker-build" "tag" "1.2.3"
The status should be success
End
It "accepts latest tag"
When call validate_input_python "docker-build" "tag" "latest"
The status should be success
End
It "rejects invalid tag format"
When call validate_input_python "docker-build" "tag" "invalid_tag!"
The status should be failure
End
End

Context "when validating architectures input"
It "accepts valid architectures list"
When call validate_input_python "docker-build" "architectures" "linux/amd64,linux/arm64"
The status should be success
End
It "accepts single architecture"
When call validate_input_python "docker-build" "architectures" "linux/amd64"
The status should be success
End
It "accepts ARM variants"
When call validate_input_python "docker-build" "architectures" "linux/arm/v7,linux/arm/v6"
The status should be success
End
End

Context "when validating dockerfile input"
It "accepts valid dockerfile path"
When call validate_input_python "docker-build" "dockerfile" "Dockerfile"
The status should be success
End
It "accepts custom dockerfile path"
When call validate_input_python "docker-build" "dockerfile" "docker/Dockerfile.prod"
The status should be success
End
It "rejects malicious dockerfile path"
When call validate_input_python "docker-build" "dockerfile" "../../../etc/passwd"
The status should be failure
End
It "rejects a remote dockerfile"
When call validate_input_python "docker-build" "dockerfile" "https://example.com/Dockerfile"
The status should be failure
End
End

Context "when validating context input"
It "accepts valid build context"
When call validate_input_python "docker-build" "context" "."
The status should be success
End
It "accepts relative context path"
When call validate_input_python "docker-build" "context" "src/app"
The status should be success
End
It "rejects path traversal in context"
# The action's validator runs the kit's docker_local_path check, which rejects '..'.
When call validate_input_python "docker-build" "context" "../../../etc"
The status should be failure
End
It "rejects a remote URL context"
When call validate_input_python "docker-build" "context" "https://example.com/repo.git"
The status should be failure
End
It "rejects an scp-style Git context"
When call validate_input_python "docker-build" "context" "git@example.com:org/repo.git"
The status should be failure
End
It "rejects a bare github.com Git context"
When call validate_input_python "docker-build" "context" "github.com/org/repo"
The status should be failure
End
End

Context "when validating build-contexts input"
It "accepts a relative path"
When call validate_input_python "docker-build" "build-contexts" "shared=./libs/shared"
The status should be success
End
It "accepts several entries with hyphenated names"
When call validate_input_python "docker-build" "build-contexts" "my-libs=libs,other=services/other"
The status should be success
End
It "accepts a docker-image reference"
When call validate_input_python "docker-build" "build-contexts" "alpine=docker-image://alpine:3.20"
The status should be success
End
It "accepts a target reference"
When call validate_input_python "docker-build" "build-contexts" "base=target:builder"
The status should be success
End
It "accepts a Git URL"
When call validate_input_python "docker-build" "build-contexts" "project=https://github.com/org/project.git"
The status should be success
End
It "accepts an OCI layout inside the workspace"
When call validate_input_python "docker-build" "build-contexts" "layout=oci-layout://./layout:1.0.0-rc.1"
The status should be success
End
It "rejects an absolute path"
When call validate_input_python "docker-build" "build-contexts" "shared=/etc"
The status should be failure
End
It "rejects path traversal"
When call validate_input_python "docker-build" "build-contexts" "shared=../.."
The status should be failure
End
It "rejects an absolute path in a later entry"
When call validate_input_python "docker-build" "build-contexts" "ok=./libs,bad=/etc"
The status should be failure
End
It "rejects an OCI layout outside the workspace"
When call validate_input_python "docker-build" "build-contexts" "layout=oci-layout:///etc/layout:1.3"
The status should be failure
End
It "rejects whitespace in a reference"
When call validate_input_python "docker-build" "build-contexts" "alpine=docker-image://alpine --flag"
The status should be failure
End
It "rejects a multi-line value"
When call validate_input_python "docker-build" "build-contexts" "$(printf 'a=./a\nb=./b')"
The status should be failure
End
It "accepts the trailing newline of a block scalar"
When call validate_input_python "docker-build" "build-contexts" "$(printf 'a=./a\n ')"
The status should be success
End
End

Context "when validating secrets input"
It "accepts a relative file"
When call validate_input_python "docker-build" "secrets" "npmrc=.npmrc"
The status should be success
End
It "accepts several entries with hyphenated ids"
When call validate_input_python "docker-build" "secrets" "npm-token=.secrets/npm,aws=config/aws"
The status should be success
End
It "rejects an absolute path"
When call validate_input_python "docker-build" "secrets" "aws=/home/runner/.aws/credentials"
The status should be failure
End
It "rejects path traversal"
When call validate_input_python "docker-build" "secrets" "npmrc=../../.npmrc"
The status should be failure
End
It "rejects an absolute path in a later entry"
When call validate_input_python "docker-build" "secrets" "ok=.npmrc,bad=/etc/passwd"
The status should be failure
End
It "rejects a quoted absolute path"
When call validate_input_python "docker-build" "secrets" 'npmrc="/etc/passwd"'
The status should be failure
End
It "rejects a multi-line value"
When call validate_input_python "docker-build" "secrets" "$(printf 'a=.a\nb=.b')"
The status should be failure
End
It "accepts the trailing newline of a block scalar"
When call validate_input_python "docker-build" "secrets" "$(printf 'a=.a\n ')"
The status should be success
End
End

Context "when validating build-args input"
It "accepts valid build args format"
When call validate_input_python "docker-build" "build-args" "NODE_ENV=production,VERSION=1.0.0"
The status should be success
End
It "accepts empty build args"
When call validate_input_python "docker-build" "build-args" ""
The status should be success
End
It "rejects malicious build args"
When call validate_input_python "docker-build" "build-args" "ARG=\$(rm -rf /)"
The status should be failure
End
End

Context "when validating cache inputs"
It "accepts valid cache mode"
When call validate_input_python "docker-build" "cache-mode" "max"
The status should be success
End
It "accepts min cache mode"
When call validate_input_python "docker-build" "cache-mode" "min"
The status should be success
End
It "accepts inline cache mode"
When call validate_input_python "docker-build" "cache-mode" "inline"
The status should be success
End
It "rejects invalid cache mode"
When call validate_input_python "docker-build" "cache-mode" "invalid"
The status should be failure
End
It "accepts valid cache-from format"
When call validate_input_python "docker-build" "cache-from" "type=registry,ref=myapp:cache"
The status should be success
End
End

Describe "values one input may hold"
Parameters
"build-args" "FOO=hello world"
"build-args" "A=1, B=2"
"build-args" "CFLAGS=-O2 -Wall,OPTS=--enable-foo --disable-bar"
"build-args" "VERSION=1.0.0-rc.1"
"build-args" "VERSION=1.0.0+build"
"build-args" "$(printf 'A=1,B=2\n ')"
"build-contexts" "base=./my dir,img=docker-image://alpine:3.18"
"build-contexts" "project=https://github.com/user/project.git"
"secrets" "npm=.npmrc,aws=config/aws credentials"
"cache-from" "type=registry,ref=ghcr.io/user/app:cache"
"cache-from" "type=registry,ref=ghcr.io/user/app:1.0.0-rc.1"
"cache-from" "type=registry,ref=ghcr.io/user/app:1.0.0+build"
"cache-import" "type=local,src=/tmp/cache"
"cache-import" "type=gha,scope=my-image"
"cache-export" "type=local,dest=/tmp/cache,mode=max"
"cache-export" "type=s3,region=eu-west-1,bucket=my_bucket,name=main;abc123"
End

It "accepts $1 '$2'"
When call validate_input_python "docker-build" "$1" "$2"
The status should be success
End
End

Describe "values that would add docker buildx arguments or step outputs"
Parameters
"build-args" "$(printf 'A=1\nB=2')"
"build-args" "$(printf 'A=1\ninjected=1')"
"build-args" "A=1,--flag=value"
"build-args" "A=1,noequals"
"build-contexts" "$(printf 'a=b\ninjected=1')"
"build-contexts" "a=b,--flag=value"
"build-contexts" "a="
"secrets" "$(printf 'a=b\ninjected=1')"
"secrets" "a=b,--flag=value"
"secrets" "a="
"cache-from" "type=gha --flag"
"cache-from" "$(printf 'type=gha\ninjected=1')"
"cache-from" "type=gha,evil=1"
"cache-import" "type=gha --flag"
"cache-import" "$(printf 'type=gha\ninjected=1')"
"cache-import" "type=oci"
"cache-export" "type=gha,mode=max --flag"
"cache-export" "$(printf 'type=gha\ninjected=1')"
"cache-export" "type=registry,ref=x,src=/tmp/cache"
End

It "rejects $1 '$2'"
When call validate_input_python "docker-build" "$1" "$2"
The status should be failure
End
End

Context "when validating security features"
It "accepts scan-image boolean"
When call validate_input_python "docker-build" "scan-image" "true"
The status should be success
End
It "accepts sign-image boolean"
When call validate_input_python "docker-build" "sign-image" "false"
The status should be success
End
It "accepts valid SBOM format"
When call validate_input_python "docker-build" "sbom-format" "spdx-json"
The status should be success
End
It "rejects cyclonedx SBOM format, which BuildKit does not produce"
When call validate_input_python "docker-build" "sbom-format" "cyclonedx-json"
The status should be failure
End
It "rejects syft SBOM format, which BuildKit does not produce"
When call validate_input_python "docker-build" "sbom-format" "syft-json"
The status should be failure
End
It "rejects invalid SBOM format"
When call validate_input_python "docker-build" "sbom-format" "invalid-format"
The status should be failure
End
End

Context "when validating performance options"
It "accepts valid parallel builds number"
When call validate_input_python "docker-build" "parallel-builds" "4"
The status should be success
End
It "accepts auto parallel builds"
When call validate_input_python "docker-build" "parallel-builds" "0"
The status should be success
End
It "rejects negative parallel builds"
When call validate_input_python "docker-build" "parallel-builds" "-1"
The status should be failure
End
It "rejects non-numeric parallel builds"
When call validate_input_python "docker-build" "parallel-builds" "not-a-number"
The status should be failure
End
End

Context "when checking action.yml structure"
It "has valid YAML syntax"
When call validate_action_yml_quiet "$ACTION_FILE"
The status should be success
End

It "has correct action name"
When call get_action_name "$ACTION_FILE"
The output should match pattern "*Docker*"
End

It "defines all required inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "tag"
End

It "defines all expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "image-digest"
The output should include "metadata"
The output should include "platforms"
The output should include "build-time"
End
End

Context "when validating security"
It "rejects injection in all Docker inputs"
When call validate_input_python "docker-build" "tag" "v1.0.0;rm -rf /"
The status should be failure
End

It "validates buildx version safely"
When call validate_input_python "docker-build" "buildx-version" "0.12.0"
The status should be success
End

It "rejects malicious buildx version"
When call validate_input_python "docker-build" "buildx-version" "0.12;malicious"
The status should be failure
End

It "accepts a BuildKit version on its own"
When call validate_input_python "docker-build" "buildkit-version" "v0.34.2"
The status should be success
End

It "accepts a BuildKit version pinned by digest"
When call validate_input_python "docker-build" "buildkit-version" "v0.34.2@sha256:$(printf 'a%.0s' $(seq 1 64))"
The status should be success
End

It "rejects a BuildKit version with a short digest"
When call validate_input_python "docker-build" "buildkit-version" "v0.34.2@sha256:abc"
The status should be failure
End

It "rejects a malicious BuildKit version"
When call validate_input_python "docker-build" "buildkit-version" "v0.34.2;malicious"
The status should be failure
End
End

Context "when testing outputs"
It "produces all expected outputs consistently"
When call test_action_outputs "$ACTION_DIR" "tag" "v1.0.0" "dockerfile" "Dockerfile"
The status should be success
The stderr should include "Testing action outputs for: docker-build"
The stderr should include "Output test passed for: docker-build"
End
End
End
