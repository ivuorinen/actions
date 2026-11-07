#!/usr/bin/env shellspec
# setup-dotnet runs in a `uses:` step the harness skips, so this assertion reads
# action.yml. The restore command runs in behavior.spec.sh, whose exact mocks
# require --locked-mode.

Describe "csharp-build lock file handling"
ACTION_FILE="${PROJECT_ROOT}/csharp-build/action.yml"

It "caches packages only when a lock file exists"
When call lock_aware_dotnet_cache "$ACTION_FILE"
The status should be success
The stdout should include "hashFiles"
End
End
