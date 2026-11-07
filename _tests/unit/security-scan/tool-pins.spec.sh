#!/usr/bin/env shellspec
# security-scan's actionlint comes from an upstream action that defaults to `latest`. That step
# is `uses:`, which the harness does not execute.

Describe "security-scan tool pins"
It "sets up the pinned actionlint"
The contents of file "${PROJECT_ROOT}/security-scan/action.yml" should include 'version: ${{ env.ACTIONLINT_VERSION }}'
End
End
