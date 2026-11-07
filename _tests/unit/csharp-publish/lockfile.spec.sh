#!/usr/bin/env shellspec
# Restore and setup-dotnet run in `uses:` steps the harness skips, so these
# assertions read action.yml.

Describe "csharp-publish lock file handling"
ACTION_FILE="${PROJECT_ROOT}/csharp-publish/action.yml"

It "restores in locked mode, so a stale lock file fails instead of being rewritten"
When call grep -F 'dotnet restore --locked-mode --verbosity normal' "$ACTION_FILE"
The status should be success
The stdout should include "--locked-mode"
End

It "caches packages only when a lock file exists"
When call lock_aware_dotnet_cache "$ACTION_FILE"
The status should be success
The stdout should include "hashFiles"
End
End
