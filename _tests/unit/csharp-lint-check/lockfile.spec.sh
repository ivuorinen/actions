#!/usr/bin/env shellspec
# The cache steps are `uses:` steps the harness skips, so this assertion reads action.yml.

Describe "csharp-lint-check lock file handling"
ACTION_FILE="${PROJECT_ROOT}/csharp-lint-check/action.yml"

# The folder is the one NuGet reports, NUGET_PACKAGES when the caller sets it.
It "caches packages only when a lock file exists, under a key that hashes it, from NuGet's folder"
When call nuget_cache_steps "$ACTION_FILE"
The lines of output should equal 5
The line 1 of output should include "hashFiles('**/packages.lock.json') != ''"
The line 2 of output should include "hashFiles('**/packages.lock.json') != ''"
The line 3 of output should include "hashFiles('**/packages.lock.json')"
The line 4 of output should equal "\${{ steps.nuget-folder.outputs.path }}"
The line 5 of output should equal "\${{ steps.nuget-folder.outputs.path }}"
End
End
