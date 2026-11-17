#!/usr/bin/env shellspec
# The Determine Image Name step: the image-name input as given, or else the repository name.

Describe "docker-build image name step (behavior)"
ACTION_DIR="${PROJECT_ROOT}/docker-build"

before() {
  shellspec_setup_test_env "docker-build-image-name-$$"
  harness_reset
  export GITHUB_REPOSITORY="acme/app"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "docker-build-image-name-$$"
  harness_reset
}
AfterEach 'after'

It "uses the repository name when image-name is empty"
When call run_step "${ACTION_DIR}" "image-name"
The status should be success
Assert expect_output name "app"
End

# Docker rejects a repository name that has an uppercase letter.
It "lower-cases the repository name"
export GITHUB_REPOSITORY="Acme/My-App"
When call run_step "${ACTION_DIR}" "image-name"
The status should be success
Assert expect_output name "my-app"
End

# validate.py does not check a blank value, so the step treats it as left out.
It "uses the repository name when image-name is blank"
export INPUT_IMAGE_NAME="   "
When call run_step "${ACTION_DIR}" "image-name"
The status should be success
Assert expect_output name "app"
End

It "uses image-name as given"
export INPUT_IMAGE_NAME="registry.example.com/ns/app"
When call run_step "${ACTION_DIR}" "image-name"
The status should be success
Assert expect_output name "registry.example.com/ns/app"
End
End
