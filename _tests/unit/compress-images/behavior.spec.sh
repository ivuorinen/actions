#!/usr/bin/env shellspec
# Behavior tests for compress-images/action.yml: the Compress Images step installs sharp from
# the action's own lock and runs compress_images.mjs, whose own spec tests the compression.

Describe "compress-images action"
ACTION_DIR="${PROJECT_ROOT}/compress-images"

before() {
  shellspec_setup_test_env "compress-images-behavior-$$"
  harness_reset
  export INPUT_WORKING_DIRECTORY="." INPUT_IMAGE_QUALITY="85" INPUT_PNG_QUALITY="95"
  export INPUT_IGNORE_PATHS="node_modules/**,dist/**,build/**"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "compress-images-behavior-$$"
  harness_reset
}
AfterEach 'after'

no_tools_left() {
  [ -z "$(find "$RUNNER_TEMP" -maxdepth 1 -name 'compress-images-tools.*' -print)" ]
}

Describe "Compress Images"
# The step runs the compressor by path, from the prefix npm ci filled.
It "installs sharp from the action's lock without scripts into a new prefix, runs the compressor, and removes the prefix"
mock_command npm "ci --prefix ${RUNNER_TEMP}/compress-images-tools.* --ignore-scripts --no-audit --no-fund" ""
mock_command node "${ACTION_DIR}/compress_images.mjs" "1 compressed, 0 unchanged, 0 unreadable"
When call run_step "${ACTION_DIR}" "compress"
The status should be success
The stdout should include "1 compressed, 0 unchanged, 0 unreadable"
Assert no_tools_left
End

It "fails when the locked install fails, without running the compressor"
mock_command npm "ci *" "" 1
mock_command node "*" "compressor ran"
When call run_step "${ACTION_DIR}" "compress"
The status should be failure
The stdout should not include "compressor ran"
Assert no_tools_left
End

# The validator takes an empty value as unset, so each means its default here too.
It "gives the compressor the default for each empty input"
When call yq -r '.runs.steps[] | select(.id == "compress") | .env | (.WORKING_DIRECTORY, .IMAGE_QUALITY, .PNG_QUALITY, .IGNORE_PATHS)' "${ACTION_DIR}/action.yml"
The line 1 of output should equal "\${{ inputs.working-directory || '.' }}"
The line 2 of output should equal "\${{ inputs.image-quality || '85' }}"
The line 3 of output should equal "\${{ inputs.png-quality || '95' }}"
The line 4 of output should equal "\${{ inputs.ignore-paths || 'node_modules/**,dist/**,build/**' }}"
End
End

Describe "action.yml"
# calibreapp/image-actions ran a container started from a floating node:lts-alpine image
# with the job token, and ignored the working-directory it was given.
It "compresses with its own step, not calibreapp/image-actions"
The contents of file "${ACTION_DIR}/action.yml" should not include "calibreapp"
End

It "sets up Node.js 24 for the compressor"
When call yq -r '.runs.steps[] | select(.name == "Setup Node.js") | .with["node-version"]' "${ACTION_DIR}/action.yml"
The output should equal "24"
End

It "reads its outputs from the Compress Images step"
When call yq -r '.outputs | [.images_compressed.value, .compression_report.value] | join(" ")' "${ACTION_DIR}/action.yml"
The output should equal "\${{ steps.compress.outputs.images_compressed || 'false' }} \${{ steps.compress.outputs.compression_report }}"
End

It "opens a pull request only when an image got smaller, with the report as its body"
When call yq -r '.runs.steps[] | select(.name == "Create New Pull Request If Needed") | [.if, .with.body] | join(" ")' "${ACTION_DIR}/action.yml"
The output should equal "steps.compress.outputs.images_compressed == 'true' \${{ steps.compress.outputs.compression_report }}"
End

# The username and email inputs name who commits the compressed images.
It "commits as the username and email the caller gives"
identity="\${{ format('{0} <{1}>', inputs.username || 'github-actions', inputs.email || 'github-actions@github.com') }}"
When call yq -r '.runs.steps[] | select(.name == "Create New Pull Request If Needed") | (.with.author, .with.committer)' "${ACTION_DIR}/action.yml"
The line 1 of output should equal "$identity"
The line 2 of output should equal "$identity"
End
End

Describe "lock"
It "pins sharp exactly"
When call jq -r '.dependencies.sharp' "${ACTION_DIR}/package.json"
The output should match pattern "[0-9]*.[0-9]*.[0-9]*"
The output should not include "^"
The output should not include "~"
End

It "is complete, with integrity hashes and no install scripts"
When call package_lock_problems "${ACTION_DIR}"
The status should be success
The output should equal ""
End
End
End
