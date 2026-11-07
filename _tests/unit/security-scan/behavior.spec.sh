#!/usr/bin/env shellspec
# Behavior-level tests for how security-scan finds, trusts and counts scanner reports.
#
# gitleaks-action cannot run here: it downloads gitleaks and needs a runner's event
# payload. The reports below are fixtures in the shape gitleaks writes, where results
# carry no `level`. Everything else runs the action's real `run:` code. The harness has
# no `node` shell and no way to seed the `steps` context, so Verify and Analyze are
# pulled out of action.yml with step_value and run directly.

Describe "security-scan reports (behavior)"
ACTION_DIR="${PROJECT_ROOT}/security-scan"

before() {
  shellspec_setup_test_env "security-scan-behavior-$$"
  harness_reset
  export INPUT_ACTIONLINT_ENABLED="true"
  export INPUT_GITLEAKS_CONFIG=".gitleaks.toml"
  export INPUT_GITLEAKS_LICENSE="license-key-123"
  export RUN_ACTIONLINT="true"
  export RUN_TRIVY="true"
  export RUN_GITLEAKS="true"
  export HAS_TRIVY="false"
  export HAS_GITLEAKS="false"
}
BeforeEach 'before'

after() {
  unset INPUT_ACTIONLINT_ENABLED INPUT_GITLEAKS_CONFIG INPUT_GITLEAKS_LICENSE
  unset RUN_ACTIONLINT RUN_TRIVY RUN_GITLEAKS HAS_TRIVY HAS_GITLEAKS
  shellspec_cleanup_test_env "security-scan-behavior-$$"
  harness_reset
}
AfterEach 'after'

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

run_check_configs() {
  run_step "${ACTION_DIR}" "check-configs"
}

run_verify() {
  sh -c "$(step_value 'Verify SARIF files' run)"
}

run_analyze() {
  node -e "$(step_value 'Analyze Results' run)"
}

# The step order on a run where the Gitleaks step exits 0 without scanning.
run_check_configs_then_verify() {
  run_check_configs && run_verify
}

# $1 is the result count. Results carry no `level`, matching gitleaks' SARIF writer.
write_gitleaks_report() {
  jq -n --argjson count "$1" '{
    version: "2.1.0",
    runs: [{
      tool: {driver: {name: "gitleaks", rules: []}},
      results: [range($count) | {
        ruleId: "generic-api-key",
        message: {text: "generic-api-key has detected secret"},
        properties: {tags: []}
      }]
    }]
  }' >"${2:-results.sarif}"
}

# One error and one note, which Trivy marks through `level`.
write_trivy_report() {
  jq -n '{runs: [{results: [
    {ruleId: "CVE-0000-0001", level: "error"},
    {ruleId: "CVE-0000-0002", level: "note"}
  ]}]}' >trivy-results.sarif
}

no_path() {
  [ ! -e "$1" ] && [ ! -L "$1" ]
}

no_output_line() {
  ! grep -Fxq "$1" "$GITHUB_OUTPUT"
}

no_output_key() {
  ! grep -q "^$1=" "$GITHUB_OUTPUT"
}

Context "when deciding whether Gitleaks runs"
It "passes on a config file that exists"
touch .gitleaks.toml
When call run_check_configs
The status should be success
Assert expect_output run_gitleaks "true"
Assert expect_output gitleaks_config ".gitleaks.toml"
End

It "passes on a config file at a custom path"
mkdir security
touch security/custom.toml
export INPUT_GITLEAKS_CONFIG="security/custom.toml"
When call run_check_configs
The status should be success
Assert expect_output run_gitleaks "true"
Assert expect_output gitleaks_config "security/custom.toml"
End

It "still runs Gitleaks when the config file is missing"
When call run_check_configs
The status should be success
The stdout should include "::warning::"
The stdout should include "default rules"
Assert expect_output run_gitleaks "true"
Assert no_output_key gitleaks_config
End

It "skips Gitleaks without a license"
touch .gitleaks.toml
export INPUT_GITLEAKS_LICENSE=""
When call run_check_configs
The status should be success
The stdout should include "skipping"
Assert expect_output run_gitleaks "false"
Assert no_output_line "run_gitleaks=true"
End
End

Context "when the checkout holds files named like scanner reports"
It "removes them before any scan runs"
write_gitleaks_report 3
write_trivy_report
When call run_check_configs
The status should be success
The stdout should be present
Assert no_path results.sarif
Assert no_path trivy-results.sarif
End

It "removes them when Gitleaks is skipped"
write_gitleaks_report 3
export INPUT_GITLEAKS_LICENSE=""
When call run_check_configs
The status should be success
The stdout should include "skipping"
Assert no_path results.sarif
End

It "removes a symlink and leaves its target alone"
printf 'keep' >../target
ln -s ../target results.sarif
When call run_check_configs
The status should be success
The stdout should be present
Assert no_path results.sarif
The contents of file ../target should equal "keep"
End

It "removes a directory"
mkdir results.sarif
touch results.sarif/placeholder
When call run_check_configs
The status should be success
The stdout should be present
Assert no_path results.sarif
End

It "does not read a committed report when the Gitleaks step scanned nothing"
write_gitleaks_report 3
When call run_check_configs_then_verify
The status should be success
The stdout should include "no report"
Assert expect_output has_gitleaks "false"
Assert no_output_line "has_gitleaks=true"
End
End

Context "when verifying reports"
It "accepts the report Gitleaks writes"
write_gitleaks_report 0
write_trivy_report
When call run_verify
The status should be success
Assert expect_output has_gitleaks "true"
Assert expect_output has_trivy "true"
End

It "does not accept a report under any other name"
write_gitleaks_report 0 gitleaks-report.sarif
When call run_verify
The status should be success
The stdout should include "no report"
Assert no_output_line "has_gitleaks=true"
End

It "does not read results.sarif when Gitleaks did not run"
write_gitleaks_report 0
export RUN_GITLEAKS="false"
When call run_verify
The status should be success
Assert no_output_line "has_gitleaks=true"
End

It "rejects a report that is not JSON"
printf 'not json' >results.sarif
When call run_verify
The status should be success
The stdout should include "not valid JSON"
Assert no_output_line "has_gitleaks=true"
End
End

Context "when analyzing reports"
It "counts every Gitleaks result as critical and fails"
write_gitleaks_report 2
export HAS_GITLEAKS="true"
When call run_analyze
The status should be failure
The stdout should include "gitleaks: 2 total, 2 critical issues"
The stderr should include "Found 2 critical security issues"
Assert expect_output total_issues "2"
Assert expect_output critical_issues "2"
End

It "passes on a clean Gitleaks report"
write_gitleaks_report 0
export HAS_GITLEAKS="true"
When call run_analyze
The status should be success
The stdout should include "gitleaks: 0 total, 0 critical issues"
Assert expect_output total_issues "0"
Assert expect_output critical_issues "0"
End

It "does not read results.sarif unless verification accepted it"
write_gitleaks_report 2
When call run_analyze
The status should be success
Assert expect_output total_issues "0"
Assert expect_output critical_issues "0"
End

It "does not count a report under any other name"
write_gitleaks_report 2 gitleaks-report.sarif
export HAS_GITLEAKS="true"
When call run_analyze
The status should be success
The stdout should include "No results file found for gitleaks"
Assert expect_output total_issues "0"
Assert expect_output critical_issues "0"
End

It "keeps deciding Trivy's critical count by level"
write_trivy_report
export HAS_TRIVY="true"
When call run_analyze
The status should be failure
The stdout should include "trivy: 2 total, 1 critical issues"
The stderr should include "Found 1 critical security issues"
Assert expect_output total_issues "2"
Assert expect_output critical_issues "1"
End
End

# gitleaks-action declares no inputs, and these conditions only take effect on a runner.
Context "when wiring the steps together"
It "passes no inputs to gitleaks-action"
When call step_value "Run Gitleaks" "with"
The output should equal ""
End

It "selects the config through the variable gitleaks reads"
When call step_value "Run Gitleaks" "env.GITLEAKS_CONFIG"
The output should equal "\${{ steps.check-configs.outputs.gitleaks_config }}"
End

It "verifies reports after a failed scan, because leaks fail the Gitleaks step"
When call step_value "Verify SARIF files" "if"
The output should include "always()"
The output should include "steps.check-configs.outcome == 'success'"
End

It "uploads the Gitleaks report after a failed scan"
When call step_value "Upload Gitleaks results" "if"
The output should include "always()"
The output should include "has_gitleaks == 'true'"
End

It "uploads the report Gitleaks writes"
When call step_value "Upload Gitleaks results" "with.sarif_file"
The output should equal "results.sarif"
End

It "archives the report Gitleaks writes"
When call step_value "Archive Gitleaks results" "with.path"
The output should equal "results.sarif"
End

It "never names the report path gitleaks-action does not write"
When call cat "${ACTION_DIR}/action.yml"
The output should not include "gitleaks-report"
End
End
End
