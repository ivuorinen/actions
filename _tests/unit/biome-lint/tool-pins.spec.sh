#!/usr/bin/env shellspec
# biome-lint installs Biome globally at a pinned version. The npm mock matches only the exact
# package spec, so an unpinned or differently pinned install exits 127 and fails the example.

Describe "biome-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/biome-lint"

before() {
  shellspec_setup_test_env "biome-lint-pins-$$"
  harness_reset
  export INPUT_MAX_RETRIES="1"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "biome-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

It "installs the pinned Biome with npm"
mock_command npm "install -g @biomejs/biome@$(pinned_version biome-lint BIOME_VERSION)" ""
When call run_step "${ACTION_DIR}" "install-biome"
The status should be success
The stdout should include "Biome installed successfully"
End

# npm is not mocked, so any install fails the step.
It "reuses a Biome on PATH at the pinned version"
mock_command biome "--version" "Version: $(pinned_version biome-lint BIOME_VERSION)"
When call run_step "${ACTION_DIR}" "install-biome"
The status should be success
The stdout should include "Biome $(pinned_version biome-lint BIOME_VERSION) already installed"
End

It "installs the pinned Biome over another version on PATH"
mock_command biome "--version" "Version: 1.9.4"
mock_command npm "install -g @biomejs/biome@$(pinned_version biome-lint BIOME_VERSION)" ""
When call run_step "${ACTION_DIR}" "install-biome"
The status should be success
The stdout should include "Biome 1.9.4 is on PATH"
The stdout should include "Biome installed successfully"
End

It "fails with an error when npm cannot install it"
mock_command npm "install -g *" "" 1
When call run_step "${ACTION_DIR}" "install-biome"
The status should be failure
The stdout should include "::error::Failed to install Biome"
End

# pnpm and Yarn cannot install a global tool on a runner: pnpm refuses a global bin directory
# outside PATH, and Yarn 2+ removed `yarn global`. Installing with npm needs neither.
It "does not set up a package manager just to install a global tool"
The contents of file "${ACTION_DIR}/action.yml" should not include "corepack"
The contents of file "${ACTION_DIR}/action.yml" should not include "setup-bun"
The contents of file "${ACTION_DIR}/action.yml" should not include "detect-pm"
End
End
