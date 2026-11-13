#!/usr/bin/env shellspec
# Behavior test for the plugin install step: a plugin list splits into one
# argument per plugin, and glob characters stay literal.

Describe "prettier-lint install-plugins (behavior)"
ACTION_DIR="${PROJECT_ROOT}/prettier-lint"

before() {
  shellspec_setup_test_env "prettier-lint-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "prettier-lint-behavior-$$"
  harness_reset
}
AfterEach 'after'

It "does not glob-expand a version range against the working directory"
# `plugin-a@*` is a spec the plugins validator accepts. The decoy file makes the
# glob match, so an unguarded split installs `plugin-a@decoy` instead. `[*]` in
# the mock matches only a literal asterisk, and an unregistered call exits 127.
: >'plugin-a@decoy'
export INPUT_PLUGINS="plugin-a@*,plugin-b"
mock_command npm 'install --save-dev plugin-a@[*] plugin-b' ""

When call run_step "${ACTION_DIR}" "install-plugins"
The status should be success
The stdout should include "Plugins installed successfully"
End

Context "when reading the arguments a package manager receives"
# The harness joins argv with spaces, so it cannot tell `"$plugins_list"` from a real
# split, and run_step reaches only the npm branch. This runs the step's script itself
# with a fake package manager that writes one argument per line.
ARGV_LOG="${SHELLSPEC_TMPBASE}/plugin-argv"
install_with() {
  fake_dir="${SHELLSPEC_TMPBASE}/fake-bin"
  mkdir -p "$fake_dir"
  printf '#!/bin/sh\nprintf "%%s\\n" "$@" >"$ARGV_LOG"\n' >"$fake_dir/$1"
  chmod +x "$fake_dir/$1"
  script=$(yq -r '.runs.steps[] | select(.id == "install-plugins") | .run' "${ACTION_DIR}/action.yml")
  ARGV_LOG="$ARGV_LOG" PATH="$fake_dir:$PATH" PACKAGE_MANAGER="$1" PLUGINS="$2" sh -c "$script"
}

It "keeps a backslash in a plugin path"
When call install_with npm 'plugin-a\c,plugin-b'
The status should be success
The stdout should include "Plugins installed successfully"
The contents of file "$ARGV_LOG" should include 'plugin-a\c
plugin-b'
End

# Parameters applies to every example after it in this block.
Parameters
npm
pnpm
yarn
bun
End

It "gives $1 one argument per plugin"
When call install_with "$1" "plugin-a,plugin-b"
The status should be success
The stdout should include "Plugins installed successfully"
The contents of file "$ARGV_LOG" should include "plugin-a
plugin-b"
End
End
End
