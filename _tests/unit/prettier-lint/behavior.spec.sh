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

It "gives every package manager the split list, not one quoted string"
# The harness joins argv with spaces, so it cannot tell `"$plugins_list"` from a
# real split, and run_step reaches only the npm branch. This covers all four.
When call grep -cE '^ +(pnpm add -D|yarn add -D|bun add -D|npm install --save-dev) "\$@"$' "${ACTION_DIR}/action.yml"
The stdout should equal "4"
End
End
