#!/usr/bin/env bash
# Basic ShellSpec test to verify the testing framework works correctly

Describe 'Docker Testing Environment'
It 'has correct user'
When call whoami
The status should be success
The output should equal "${EXPECTED_USER:-runner}"
End

It 'can access workspace'
When call pwd
The status should be success
The output should include "${EXPECTED_WORKSPACE:-/workspace}"
End

It 'has ShellSpec available'
# Calling `shellspec --version` recursively from within shellspec captures
# weird framework state instead of the version string. Verify availability
# by resolving the binary via `command -v` — the test is "ShellSpec is on
# PATH and executable" rather than "we can re-run it from inside ourselves".
When call command -v shellspec
The status should be success
The output should include "shellspec"
End

It 'has required tools'
When call which jq
The status should be success
The output should include "jq"
End

It 'can write to workspace'
When call touch test-write-file
The status should be success
End

It 'can clean up test files'
When call rm -f test-write-file
The status should be success
End
End
