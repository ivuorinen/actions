#!/usr/bin/env shellspec
# Tests for the Buildx docker-publish sets up and the BuildKit cache its build uses. Set up Docker
# Buildx and the build are `uses:`, which the harness does not execute, so their inputs are read
# from action.yml. The Buildx check before them is a shell step, run here with stand-ins on PATH.

Describe "docker-publish tool pins"
ACTION_DIR="${PROJECT_ROOT}/docker-publish"
CHECK_STEP="Check for Buildx"
SETUP_STEP="Set up Docker Buildx"
BUILDX_ERROR="::error::Docker Buildx is required: this runner has none, and the action downloads none unverified"

before() {
  shellspec_setup_test_env "docker-publish-tool-pins-$$"
  BIN_DIR="${RUNNER_TEMP}/bin"
  mkdir -p "$BIN_DIR"
}
BeforeEach 'before'

after() {
  unset BIN_DIR
  shellspec_cleanup_test_env "docker-publish-tool-pins-$$"
}
AfterEach 'after'

# stand_in NAME STATUS: put a NAME on the check's PATH that exits STATUS.
stand_in() {
  printf '#!/bin/sh\nexit %s\n' "$2" >"${BIN_DIR}/$1"
  chmod +x "${BIN_DIR}/$1"
}

# run_check: run the Buildx check with only the stand-ins on PATH, so the host's own Docker
# and Buildx cannot answer for them.
run_check() {
  script=$(step_value "$ACTION_DIR" "$CHECK_STEP" run)
  PATH="$BIN_DIR" /bin/sh -c "$script"
}

Describe "Check for Buildx"
It "passes with the Docker CLI's buildx plugin"
stand_in docker 0
When call run_check
The status should be success
The output should equal ""
End

# setup-buildx runs the plugin whenever the Docker CLI is there, and downloads Buildx when that fails.
It "fails with a Docker CLI that has no buildx plugin, even beside a buildx binary"
stand_in docker 1
stand_in buildx 0
When call run_check
The status should be failure
The output should equal "$BUILDX_ERROR"
End

It "passes with a buildx binary when there is no Docker CLI"
stand_in buildx 0
When call run_check
The status should be success
The output should equal ""
End

It "fails with a buildx binary that does not run"
stand_in buildx 1
When call run_check
The status should be failure
The output should equal "$BUILDX_ERROR"
End

It "fails with neither"
When call run_check
The status should be failure
The output should equal "$BUILDX_ERROR"
End
End

Describe "Set up Docker Buildx"
It "names no Buildx version, so it uses the runner's"
When call step_value "$ACTION_DIR" "$SETUP_STEP" with.version
The output should equal ""
End

# buildx runs the daemon privileged, and a tag can be pushed again.
It "runs BuildKit from an image pinned by digest"
When call step_value "$ACTION_DIR" "$SETUP_STEP" with.driver-opts
The output should equal 'image=moby/buildkit:${{ env.BUILDKIT_IMAGE_TAG }}'
End

It "pins the BuildKit image by digest, in a form Renovate updates"
When call step_value "$ACTION_DIR" "$SETUP_STEP" env.BUILDKIT_IMAGE_TAG
The output should match pattern "v*@sha256:????????????????????????????????????????????????????????????????"
The contents of file "${ACTION_DIR}/action.yml" should include "# renovate: datasource=docker depName=moby/buildkit"
End

# An empty value restores setup-buildx's defaults, which allow insecure entitlements.
It "gives the daemon flags that keep setup-buildx's defaults off"
When call step_value "$ACTION_DIR" "$SETUP_STEP" with.buildkitd-flags
The output should equal "--oci-worker=auto"
End
End

Describe "Build and Push Docker Image"
It "reads the build cache of this image only"
When call step_value "$ACTION_DIR" build with.cache-from
The output should equal 'type=gha,scope=${{ steps.meta.outputs.image-name }}'
End

# A pull_request_target, issue_comment or workflow_run run shares the default branch's cache scope.
It "writes the build cache of this image on push, schedule and workflow_dispatch runs only"
When call step_value "$ACTION_DIR" build with.cache-to
The output should equal "\${{ contains(fromJSON('[\"push\",\"schedule\",\"workflow_dispatch\"]'), github.event_name) && format('type=gha,mode=max,scope={0}', steps.meta.outputs.image-name) || '' }}"
End
End
End
