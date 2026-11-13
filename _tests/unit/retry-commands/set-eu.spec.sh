#!/usr/bin/env shellspec
# Static check over every action's nick-fields/retry steps.
#
# The action hands `command:` to one shell as one script, and the step's result is
# that script's exit status: the last line's, unless `set -eu` stops it sooner.
#
# `set -eu` only means that in a POSIX shell. The action's default shell on Windows is
# PowerShell, so the actions keep each retry step to a single command, which needs no
# guard in either shell. The check is for any multi-line command added later.

Describe "nick-fields/retry commands"
It "begin with set -eu in every action when they span several lines"
When call list_unguarded_retry_commands "${PROJECT_ROOT}"
The status should be success
The output should equal ""
End
End
