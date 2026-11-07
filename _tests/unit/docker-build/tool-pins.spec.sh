#!/usr/bin/env shellspec
# docker-build's Buildx and QEMU images come from upstream actions that default to `latest`, so
# each has to be told a version. Those steps are `uses:`, which the harness does not execute.

Describe "docker-build tool pins"
ACTION_FILE="${PROJECT_ROOT}/docker-build/action.yml"

It "sets up the pinned Buildx unless the caller names one"
The contents of file "${ACTION_FILE}" should include 'version: ${{ inputs.buildx-version || env.DEFAULT_BUILDX_VERSION }}'
End

It "sets up the pinned QEMU image"
The contents of file "${ACTION_FILE}" should include 'image: docker.io/tonistiigi/binfmt:${{ env.BINFMT_VERSION }}'
End
End
