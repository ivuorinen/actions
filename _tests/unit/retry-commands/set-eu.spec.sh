#!/usr/bin/env shellspec
# Static check over every action's nick-fields/retry steps.
#
# The action hands `command:` to one shell as one script, and the step's result is
# that script's exit status: the last line's, unless `set -eu` stops it sooner.
#
# The commands are POSIX sh scripts, and `set -eu` only means that in a POSIX shell.
# nick-fields/retry runs PowerShell on Windows unless told otherwise, and refuses sh there,
# so every retry step runs bash.

Describe "nick-fields/retry commands"
It "begin with set -eu in every action when they span several lines"
When call list_unguarded_retry_commands "${PROJECT_ROOT}"
The status should be success
The output should equal ""
End

It "run under bash in every action"
When call list_retry_steps_without_bash "${PROJECT_ROOT}"
The status should be success
The output should equal ""
End
End
