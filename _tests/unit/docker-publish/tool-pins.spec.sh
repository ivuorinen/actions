#!/usr/bin/env shellspec
# docker-publish's Buildx comes from an upstream action that picks a version itself unless told
# one. That step is `uses:`, which the harness does not execute.

Describe "docker-publish tool pins"
It "sets up the pinned Buildx"
The contents of file "${PROJECT_ROOT}/docker-publish/action.yml" should include 'version: ${{ env.BUILDX_VERSION }}'
End
End
