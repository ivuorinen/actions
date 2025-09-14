#!/usr/bin/env bash
# Basic ShellSpec test to verify the testing framework works correctly

Describe 'Docker Testing Environment'
  It 'has correct user'
    When call whoami
    The output should equal "runner"
  End

  It 'can access workspace'
    When call pwd
    The output should include "/workspace"
  End

  It 'has ShellSpec available'
    When call shellspec --version
    The status should be success
    The output should include "shellspec"
  End

  It 'has required tools'
    When call which jq
    The status should be success
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
