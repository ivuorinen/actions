#!/usr/bin/env shellspec
# Tests for when security-scan runs Gitleaks and how Trivy limits its SARIF report.
#
# gitleaks-action cannot run here. These tests run the action's real check-configs
# step against fixture event payloads and read the run_gitleaks flag it sets. They
# cannot show gitleaks-action accepting or rejecting an event; that needs a runner.
#
# gitleaks-action (v3.0.0) exits 1 on any event other than push, pull_request,
# workflow_dispatch and schedule, and requires a license only when the owner of the
# repository is not an individual User (it reads repository.owner.login from the event
# payload and asks the API for the account type).

Describe "security-scan gating (behavior)"
ACTION_DIR="${PROJECT_ROOT}/security-scan"

before() {
  shellspec_setup_test_env "security-scan-gating-$$"
  harness_reset
  export INPUT_ACTIONLINT_ENABLED="true"
  export INPUT_GITLEAKS_CONFIG=".gitleaks.toml"
  export INPUT_GITLEAKS_LICENSE=""
  export GITHUB_EVENT_NAME="push"
  export GITHUB_EVENT_PATH="${PWD}/event.json"
  : >.gitleaks.toml
}
BeforeEach 'before'

after() {
  unset INPUT_ACTIONLINT_ENABLED INPUT_GITLEAKS_CONFIG INPUT_GITLEAKS_LICENSE
  unset GITHUB_EVENT_NAME GITHUB_EVENT_PATH
  shellspec_cleanup_test_env "security-scan-gating-$$"
  harness_reset
}
AfterEach 'after'

# $1 is the owner type as GitHub reports it in the event payload.
write_event() {
  jq -n --arg type "$1" '{repository: {owner: {login: "octo", type: $type}}}' >event.json
}

run_check_configs() {
  run_step "${ACTION_DIR}" "check-configs"
}

# Prints a field of the named step. Dotted paths reach into env: and with:.
step_value() {
  _harness_python - "${ACTION_DIR}/action.yml" "$1" "$2" <<'PY'
import sys

import yaml

action_file, step_name, path = sys.argv[1:4]
with open(action_file, encoding="utf-8") as f:
    steps = yaml.safe_load(f)["runs"]["steps"]
value = next(step for step in steps if step.get("name") == step_name)
for key in path.split("."):
    value = value.get(key) if isinstance(value, dict) else None
print("" if value is None else value)
PY
}

Describe "events gitleaks-action does not support"
Parameters
merge_group
pull_request_target
release
End

It "skips Gitleaks on $1 with a notice, even with a license"
export GITHUB_EVENT_NAME="$1"
export INPUT_GITLEAKS_LICENSE="license-key-123"
write_event "Organization"

When call run_check_configs
The status should be success
The stdout should include "::notice::Skipping Gitleaks scan - gitleaks-action does not support the $1 event"
Assert expect_output run_gitleaks "false"
End

It "skips Gitleaks on $1 for a personal account, which needs no license"
export GITHUB_EVENT_NAME="$1"
write_event "User"

When call run_check_configs
The status should be success
The stdout should include "does not support the $1 event"
Assert expect_output run_gitleaks "false"
End

It "still runs Trivy and actionlint on $1"
export GITHUB_EVENT_NAME="$1"
write_event "User"

When call run_check_configs
The status should be success
The stdout should include "does not support the $1 event"
Assert expect_output run_trivy "true"
Assert expect_output run_actionlint "true"
End
End

Describe "events gitleaks-action supports"
Parameters
push
pull_request
workflow_dispatch
schedule
End

It "runs Gitleaks on $1 for a licensed owner"
export GITHUB_EVENT_NAME="$1"
export INPUT_GITLEAKS_LICENSE="license-key-123"
write_event "Organization"

When call run_check_configs
The status should be success
The stdout should not include "::notice::"
Assert expect_output run_gitleaks "true"
End
End

Describe "the license requirement"
It "runs Gitleaks without a license for a personal account"
write_event "User"

When call run_check_configs
The status should be success
The stdout should not include "::warning::"
Assert expect_output run_gitleaks "true"
End

It "skips Gitleaks without a license for an organization"
write_event "Organization"

When call run_check_configs
The status should be success
The stdout should include "::warning::"
The stdout should include "license"
Assert expect_output run_gitleaks "false"
End

It "skips Gitleaks without a license when the event has no owner type"
export GITHUB_EVENT_NAME="schedule"
printf '{}\n' >event.json

When call run_check_configs
The status should be success
The stdout should include "::warning::"
Assert expect_output run_gitleaks "false"
End

It "runs Gitleaks for an organization with a license"
export INPUT_GITLEAKS_LICENSE="license-key-123"
write_event "Organization"

When call run_check_configs
The status should be success
The stdout should not include "::warning::"
Assert expect_output run_gitleaks "true"
End
End

Describe "Trivy severity"
It "limits SARIF output to trivy-severity"
When call step_value "Run Trivy vulnerability scanner" "with.limit-severities-for-sarif"
The output should equal "true"
End
End
End
