#!/usr/bin/env shellspec
# Behavior-level tests for how security-scan runs its scanners and finds, trusts and
# counts their reports.
#
# The scanner binaries do not run here. The scanner steps run with stand-ins that record
# their arguments, working directory and GIT_ATTR_SOURCE, and the reports are fixtures in
# the shape gitleaks writes, where results carry no `level`. Everything else runs the
# action's real `run:` code. The harness has no `node` shell and no way to seed the `steps`
# context, so the steps that need either are pulled out of action.yml with step_value and
# run directly.

Describe "security-scan reports (behavior)"
ACTION_DIR="${PROJECT_ROOT}/security-scan"

before() {
  shellspec_setup_test_env "security-scan-behavior-$$"
  harness_reset
  export INPUT_ACTIONLINT_ENABLED="true"
  export INPUT_GITLEAKS_CONFIG=".gitleaks.toml"
  export RUN_TRIVY="true"
  export RUN_GITLEAKS="true"
  export HAS_TRIVY="false"
  export HAS_GITLEAKS="false"
  # The runner always sets these; check-configs reads the commit range from the payload.
  export GITHUB_EVENT_NAME="push"
  export GITHUB_EVENT_PATH="${PWD}/event.json"
  printf '%s\n' '{}' >event.json
  SCAN_DIR="${RUNNER_TEMP}/scan-dir"
  mkdir -p "$SCAN_DIR"
}
BeforeEach 'before'

after() {
  unset INPUT_ACTIONLINT_ENABLED INPUT_GITLEAKS_CONFIG
  unset RUN_TRIVY RUN_GITLEAKS HAS_TRIVY HAS_GITLEAKS
  unset GITHUB_EVENT_NAME GITHUB_EVENT_PATH SCAN_DIR
  shellspec_cleanup_test_env "security-scan-behavior-$$"
  harness_reset
}
AfterEach 'after'

run_check_configs() {
  run_step "${ACTION_DIR}" "check-configs"
}

run_verify() {
  sh -c "$(step_value "$ACTION_DIR" 'Verify SARIF files' run)"
}

# The Analyze Results step's script, run from the workspace as the step runs it.
run_analyze() {
  sh -c "$(step_value "$ACTION_DIR" 'Analyze Results' run)"
}

# The step order on a run where the Gitleaks step exits 0 without scanning.
run_check_configs_then_verify() {
  run_check_configs && RUN_TRIVY=false run_verify
}

# fake_tool NAME [STATUS] [LOG]: write a stand-in for the scanner NAME into RUNNER_TEMP. It
# writes each argument it receives on a line of its own to NAME.args, its working directory
# to NAME.cwd and GIT_ATTR_SOURCE (or "unset") to NAME.attr, prints LOG to stderr as its log,
# then exits STATUS.
fake_tool() {
  printf '%s' "${3:-}" >"${RUNNER_TEMP}/$1.log"
  cat >"${RUNNER_TEMP}/$1" <<EOF
#!/bin/sh
printf '%s\n' "\$@" >"${RUNNER_TEMP}/$1.args"
pwd >"${RUNNER_TEMP}/$1.cwd"
printf '%s\n' "\${GIT_ATTR_SOURCE-unset}" >"${RUNNER_TEMP}/$1.attr"
cat "${RUNNER_TEMP}/$1.log" >&2
exit ${2:-0}
EOF
  chmod +x "${RUNNER_TEMP}/$1"
}

# recorded NAME KIND: what the stand-in NAME recorded: args, cwd or attr.
recorded() {
  cat "${RUNNER_TEMP}/$1.$2"
}

lines() {
  printf '%s\n' "$@"
}

# history: make the workspace a repository with two commits, and set RANGE to them.
history() {
  fixture_repo
  git commit -q --allow-empty -m one
  git commit -q --allow-empty -m two
  RANGE="$(git rev-parse HEAD~1)..$(git rev-parse HEAD)"
}

# run_gitleaks [CONFIG] [BASE_SHA] [RANGE]: run the Gitleaks step as check-configs and the
# install step would set it up, with the stand-in in place of the binary.
run_gitleaks() {
  GITLEAKS="${RUNNER_TEMP}/gitleaks" GITLEAKS_CONFIG_PATH="${1:-}" BASE_SHA="${2:-}" GITLEAKS_RANGE="${3:-}" \
    SCAN_DIR="$SCAN_DIR" sh -c "$(step_value "$ACTION_DIR" 'Run Gitleaks' run)"
}

# run_trivy: run the Trivy step with the stand-in and the action's default inputs, which a
# spec overrides by setting SCANNERS, SEVERITY or SCAN_TIMEOUT, empty included.
run_trivy() {
  TRIVY="${RUNNER_TEMP}/trivy" CACHE_DIR="${RUNNER_TEMP}/trivy-cache" SCAN_DIR="$SCAN_DIR" \
    SCANNERS="${SCANNERS-vuln,misconfig,secret}" SEVERITY="${SEVERITY-CRITICAL,HIGH}" SCAN_TIMEOUT="${SCAN_TIMEOUT-10m}" \
    sh -c "$(step_value "$ACTION_DIR" 'Run Trivy vulnerability scanner' run)"
}

# octopus_history: make the workspace a repository whose last commit merges three parents,
# and set RANGE to the commits that merge brought. commit-tree needs no branch for each.
octopus_history() {
  history
  base=$(git rev-parse HEAD)
  tree=$(git rev-parse "${base}^{tree}")
  side_a=$(git commit-tree -p "$base" -m a "$tree")
  side_b=$(git commit-tree -p "$base" -m b "$tree")
  octopus=$(git commit-tree -p "$base" -p "$side_a" -p "$side_b" -m octopus "$tree")
  git reset -q --hard "$octopus"
  RANGE="${base}..${octopus}"
}

# run_jactionlint [CONFIG] [PROFILE]: run the jactionlint step with the stand-in, the config
# check-configs would pass and the jactionlint-profile input, correctness by default.
run_jactionlint() {
  JACTIONLINT="${RUNNER_TEMP}/jactionlint" JACTIONLINT_CONFIG="${1:-${RUNNER_TEMP}/jactionlint.yaml}" \
    PROFILE="${2:-correctness}" sh -c "$(step_value "$ACTION_DIR" 'Run jactionlint' run)"
}

# linted_in_copy: the stand-in ran in a new directory of the step's own under RUNNER_TEMP, a copy
# outside the repository, which holds no .git.
linted_in_copy() {
  case "$(recorded jactionlint cwd)" in
  "${RUNNER_TEMP}"/security-scan-jactionlint.*) [ ! -e "$(recorded jactionlint cwd)/.git" ] ;;
  *) return 1 ;;
  esac
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

# input_field INPUT FIELD: print FIELD of the action input INPUT, or an empty line.
input_field() {
  _harness_python - "${ACTION_DIR}/action.yml" "$1" "$2" <<'PY'
import sys

import yaml

action_file, name, field = sys.argv[1:4]
with open(action_file, encoding="utf-8") as f:
    value = yaml.safe_load(f)["inputs"][name].get(field)
print("" if value is None else value)
PY
}

Context "when choosing the Gitleaks config"
It "passes on a config file that exists"
touch .gitleaks.toml
When call run_check_configs
The status should be success
The stdout should include "whole history"
Assert expect_output run_gitleaks "true"
Assert expect_output gitleaks_config ".gitleaks.toml"
End

It "passes on a config file at a custom path"
mkdir security
touch security/custom.toml
export INPUT_GITLEAKS_CONFIG="security/custom.toml"
When call run_check_configs
The status should be success
The stdout should include "whole history"
Assert expect_output run_gitleaks "true"
Assert expect_output gitleaks_config "security/custom.toml"
End

It "still runs Gitleaks, on its default rules, when the default config file is missing"
When call run_check_configs
The status should be success
The stdout should include "whole history"
The stdout should not include "::warning::"
Assert expect_output run_gitleaks "true"
Assert no_output_key gitleaks_config
End

# A mistyped path would otherwise scan with the default rules.
It "fails on a gitleaks-config other than the default that does not exist"
export INPUT_GITLEAKS_CONFIG="security/custom.toml"
When call run_check_configs
The status should be failure
The stdout should include "::error::gitleaks-config security/custom.toml does not exist"
Assert no_output_key gitleaks_config
End

# The validator takes an empty value as unset, so it means the default here too.
It "takes an empty gitleaks-config as the default"
touch .gitleaks.toml
export INPUT_GITLEAKS_CONFIG=""
When call run_check_configs
The status should be success
The stdout should include "whole history"
Assert expect_output gitleaks_config ".gitleaks.toml"
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

It "does not take a committed report for the result of a scan that wrote none"
write_gitleaks_report 3
When call run_check_configs_then_verify
The status should be failure
The stdout should include "::error::Gitleaks left no valid report"
Assert expect_output has_gitleaks "false"
Assert no_output_line "has_gitleaks=true"
End
End

Context "when running Gitleaks"
It "scans the range check-configs chose, merge commits included, with redaction into results.sarif"
history
fake_tool gitleaks
When call run_gitleaks "" "" "$RANGE"
The status should be success
The output should equal ""
Assert test "$(recorded gitleaks args)" = "$(lines git --no-banner --redact --report-format sarif \
  --report-path "${PWD}/results.sarif" --log-opts "--remerge-diff ${RANGE}" "$PWD")"
End

It "scans the whole history, with the options Gitleaks uses without --log-opts, when there is no range"
history
fake_tool gitleaks
When call run_gitleaks
The status should be success
Assert test "$(recorded gitleaks args | sed -n '/^--log-opts$/{n;p;}')" = "--remerge-diff --full-history --all --diff-filter=tuxdb"
End

It "fails when Gitleaks logs an error, which it does for a git log that failed while still exiting 0"
history
fake_tool gitleaks 0 "$(printf '3:07PM ERR [git] fatal: unrecognized argument: --remerge-diff\n3:07PM ERR error="stderr is not empty"\n3:07PM INF no leaks found\n')"
When call run_gitleaks
The status should be failure
The stdout should include "::error::Gitleaks could not read the whole history"
The stderr should include "ERR [git] fatal: unrecognized argument"
End

# Gitleaks writes a valid report of what it read before git log failed.
It "removes the report Gitleaks still writes after an error, so verification does not accept it"
history
write_gitleaks_report 0
fake_tool gitleaks 0 "$(printf '3:07PM ERR [git] fatal: unrecognized argument: --remerge-diff\n')"
When call run_gitleaks
The status should be failure
The stdout should include "::error::Gitleaks could not read the whole history"
The stderr should include "ERR [git] fatal: unrecognized argument"
Assert no_path results.sarif
End

It "does not take a warning or a found leak for an error"
history
fake_tool gitleaks 1 "$(printf '3:07PM WRN exhaustive rename detection was skipped due to too many files.\n3:07PM WRN leaks found: 1\n')"
When call run_gitleaks
The status should equal 1
The stdout should equal ""
The stderr should include "WRN leaks found: 1"
End

It "fails a range holding a merge of more than two parents, whose own changes it cannot scan"
octopus_history
fake_tool gitleaks
When call run_gitleaks "" "" "$RANGE"
The status should be failure
The stdout should include "::error::1 merge commits with more than two parents in ${RANGE}"
Assert no_path "${RUNNER_TEMP}/gitleaks.args"
End

It "warns about a merge of more than two parents in the whole history, and still scans it"
octopus_history
fake_tool gitleaks
When call run_gitleaks
The status should be success
The stdout should include "::warning::Gitleaks cannot scan what the 1 merge commits with more than two parents"
Assert test -s "${RUNNER_TEMP}/gitleaks.args"
End

It "fails before Gitleaks runs when the range names a commit the clone lacks"
history
fake_tool gitleaks
When call run_gitleaks "" "" "1111111111111111111111111111111111111111..$(git rev-parse HEAD)"
The status should be failure
The stderr should be present
Assert no_path "${RUNNER_TEMP}/gitleaks.args"
End

It "passes the config check-configs chose"
history
fake_tool gitleaks
When call run_gitleaks ".gitleaks.toml"
The status should be success
Assert test "$(recorded gitleaks args | sed -n '/^--config$/{n;p;}')" = ".gitleaks.toml"
End

It "runs in the scan directory, where it reads its ignore file and config paths"
history
fake_tool gitleaks
When call run_gitleaks
The status should be success
Assert test "$(recorded gitleaks cwd)" = "$(cd "$SCAN_DIR" && pwd)"
End

It "reads git attributes from the base commit when check-configs names one"
history
fake_tool gitleaks
When call run_gitleaks "" "0123456789abcdef0123456789abcdef01234567"
The status should be success
Assert test "$(recorded gitleaks attr)" = "0123456789abcdef0123456789abcdef01234567"
End

It "leaves git attributes alone on other events"
history
fake_tool gitleaks
When call run_gitleaks
The status should be success
Assert test "$(recorded gitleaks attr)" = "unset"
End

It "fails the step when Gitleaks finds leaks"
history
fake_tool gitleaks 1
When call run_gitleaks
The status should be failure
End
End

Context "when running Trivy"
It "scans the checkout into a SARIF report limited to trivy-severity, with its cache outside the checkout"
fake_tool trivy
When call run_trivy
The status should be success
Assert test "$(recorded trivy args)" = "$(lines fs --scanners vuln,misconfig,secret --severity CRITICAL,HIGH \
  --timeout 10m --cache-dir "${RUNNER_TEMP}/trivy-cache" --format sarif --output "${PWD}/trivy-results.sarif" "$PWD")"
End

It "runs in the scan directory, where it reads trivy.yaml, .trivyignore and trivy-secret.yaml"
fake_tool trivy
When call run_trivy
The status should be success
Assert test "$(recorded trivy cwd)" = "$(cd "$SCAN_DIR" && pwd)"
End

It "drops the spaces the validator allows around list items, which Trivy would read as part of a name"
fake_tool trivy
SCANNERS="vuln, misconfig" SEVERITY=" CRITICAL , HIGH"
When call run_trivy
The status should be success
Assert test "$(recorded trivy args | sed -n '/^--scanners$/{n;p;}')" = "vuln,misconfig"
Assert test "$(recorded trivy args | sed -n '/^--severity$/{n;p;}')" = "CRITICAL,HIGH"
End

It "leaves Trivy at its defaults for empty inputs, which it would reject as values"
fake_tool trivy
SCANNERS="" SEVERITY="" SCAN_TIMEOUT=""
When call run_trivy
The status should be success
Assert test "$(recorded trivy args)" = "$(lines fs --cache-dir "${RUNNER_TEMP}/trivy-cache" --format sarif \
  --output "${PWD}/trivy-results.sarif" "$PWD")"
End

It "fails the step when Trivy cannot scan"
fake_tool trivy 1
When call run_trivy
The status should be failure
End
End

Context "when running jactionlint"
It "lints a copy of the workflows outside the repository, without shellcheck and pyflakes"
mkdir -p .github/workflows
printf 'name: ci\n' >.github/workflows/ci.yml
fake_tool jactionlint
When call run_jactionlint
The status should be success
Assert test "$(recorded jactionlint args)" = "$(lines --shellcheck= --pyflakes= --no-online --no-baseline --profile correctness \
  --config-file "${RUNNER_TEMP}/jactionlint.yaml" .github/workflows/ci.yml)"
Assert linted_in_copy
The contents of file "$(recorded jactionlint cwd)/.github/workflows/ci.yml" should equal "name: ci"
End

# jactionlint would take an empty --profile as the config's profile, or its own default profile.
It "runs the correctness profile when the profile input is blank"
mkdir -p .github/workflows
touch .github/workflows/ci.yml
fake_tool jactionlint
When call run_jactionlint "${RUNNER_TEMP}/jactionlint.yaml" " "
The status should be success
Assert test "$(recorded jactionlint args)" = "$(lines --shellcheck= --pyflakes= --no-online --no-baseline --profile correctness \
  --config-file "${RUNNER_TEMP}/jactionlint.yaml" .github/workflows/ci.yml)"
End

It "passes the config check-configs chose and the profile input"
mkdir -p .github/workflows
touch .github/workflows/ci.yml
fake_tool jactionlint
When call run_jactionlint "${RUNNER_TEMP}/base.yaml" default
The status should be success
Assert test "$(recorded jactionlint args)" = "$(lines --shellcheck= --pyflakes= --no-online --no-baseline --profile default \
  --config-file "${RUNNER_TEMP}/base.yaml" .github/workflows/ci.yml)"
End

# jactionlint would read a local action through a symlink or a .. path out of the repository.
It "copies no local action a workflow names, so jactionlint reads none"
mkdir -p .github/workflows act
printf 'name: act\n' >act/action.yml
printf 'jobs: {a: {steps: [{uses: ./act}]}}\n' >.github/workflows/ci.yml
fake_tool jactionlint
When call run_jactionlint
The status should be success
Assert linted_in_copy
Assert no_path "$(recorded jactionlint cwd)/act"
End

# Outside the repository jactionlint would read the baseline relative to the copy, where it is missing.
It "applies no baseline the config names, and copies none"
mkdir -p .github/workflows
touch .github/workflows/ci.yml
printf 'baseline: auto\n' >.github/jactionlint.yaml
printf '{"entries": []}\n' >.github/jactionlint-baseline.json
fake_tool jactionlint
When call run_jactionlint "${PWD}/.github/jactionlint.yaml"
The status should be success
Assert test "$(recorded jactionlint args)" = "$(lines --shellcheck= --pyflakes= --no-online --no-baseline --profile correctness \
  --config-file "${PWD}/.github/jactionlint.yaml" .github/workflows/ci.yml)"
Assert no_path "$(recorded jactionlint cwd)/.github/jactionlint-baseline.json"
End

It "lints the regular .yml and .yaml files directly in .github/workflows, never a symlink or a subdirectory"
mkdir -p .github/workflows/sub
touch .github/workflows/ci.yml .github/workflows/release.yaml .github/workflows/sub/nested.yml
printf 'secret\n' >"${RUNNER_TEMP}/outside.yml"
ln -s "${RUNNER_TEMP}/outside.yml" .github/workflows/link.yml
fake_tool jactionlint
When call run_jactionlint
The status should be success
Assert test "$(recorded jactionlint args)" = "$(lines --shellcheck= --pyflakes= --no-online --no-baseline --profile correctness \
  --config-file "${RUNNER_TEMP}/jactionlint.yaml" .github/workflows/ci.yml .github/workflows/release.yaml)"
Assert no_path "$(recorded jactionlint cwd)/.github/workflows/link.yml"
End

It "skips with a notice when the repository has no workflows"
fake_tool jactionlint
When call run_jactionlint
The status should be success
The stdout should include "::notice::No workflow files in .github/workflows"
Assert no_path "${RUNNER_TEMP}/jactionlint.args"
End

It "skips with a notice when .github/workflows holds only symlinks"
mkdir -p .github/workflows
ln -s "${RUNNER_TEMP}/outside.yml" .github/workflows/link.yml
fake_tool jactionlint
When call run_jactionlint
The status should be success
The stdout should include "::notice::No workflow files in .github/workflows"
Assert no_path "${RUNNER_TEMP}/jactionlint.args"
End

It "skips with a warning when .github is a symlink, whose workflows lie elsewhere"
mkdir -p "${RUNNER_TEMP}/elsewhere/workflows"
touch "${RUNNER_TEMP}/elsewhere/workflows/ci.yml"
ln -s "${RUNNER_TEMP}/elsewhere" .github
fake_tool jactionlint
When call run_jactionlint
The status should be success
The stdout should include "::warning::.github is a symlink - jactionlint does not follow it"
Assert no_path "${RUNNER_TEMP}/jactionlint.args"
End

It "skips with a warning when .github/workflows is a symlink"
mkdir -p "${RUNNER_TEMP}/elsewhere" .github
touch "${RUNNER_TEMP}/elsewhere/ci.yml"
ln -s "${RUNNER_TEMP}/elsewhere" .github/workflows
fake_tool jactionlint
When call run_jactionlint
The status should be success
The stdout should include "::warning::.github/workflows is a symlink - jactionlint does not follow it"
Assert no_path "${RUNNER_TEMP}/jactionlint.args"
End

It "fails the step when jactionlint reports findings"
mkdir -p .github/workflows
touch .github/workflows/ci.yml
fake_tool jactionlint 1
When call run_jactionlint
The status should be failure
End
End

Context "when verifying reports"
It "accepts the reports both scanners write"
write_gitleaks_report 0
write_trivy_report
When call run_verify
The status should be success
Assert expect_output has_gitleaks "true"
Assert expect_output has_trivy "true"
End

It "fails when Gitleaks ran and left a report under no other name"
write_gitleaks_report 0 gitleaks-report.sarif
export RUN_TRIVY="false"
When call run_verify
The status should be failure
The stdout should include "::error::Gitleaks left no valid report"
Assert expect_output has_gitleaks "false"
End

It "fails when Trivy ran and left no report"
write_gitleaks_report 0
When call run_verify
The status should be failure
The stdout should include "::error::Trivy left no valid report"
Assert expect_output has_gitleaks "true"
Assert expect_output has_trivy "false"
End

Describe "a report that is JSON but not a SARIF document"
Parameters
'{}'
'{"runs": {}}'
'[]'
'{"runs": []} {"runs": []}'
End

It "rejects $1, which the upload and Analyze Results cannot read"
printf '%s\n' "$1" >results.sarif
export RUN_TRIVY="false"
When call run_verify
The status should be failure
The stdout should include "::error::Gitleaks left no valid report"
Assert no_output_line "has_gitleaks=true"
End
End

It "accepts a report of a scan that found nothing"
printf '%s\n' '{"version": "2.1.0", "runs": []}' >results.sarif
export RUN_TRIVY="false"
When call run_verify
The status should be success
Assert expect_output has_gitleaks "true"
End

It "does not read results.sarif when Gitleaks did not run"
write_gitleaks_report 0
export RUN_GITLEAKS="false" RUN_TRIVY="false"
When call run_verify
The status should be success
Assert no_output_line "has_gitleaks=true"
End

It "fails on a report that is not JSON"
printf 'not json' >results.sarif
export RUN_TRIVY="false"
When call run_verify
The status should be failure
The stdout should include "::error::Gitleaks left no valid report"
Assert no_output_line "has_gitleaks=true"
End
End

Context "when analyzing reports"
It "counts every Gitleaks result as critical and fails"
write_gitleaks_report 2
export HAS_GITLEAKS="true" RUN_TRIVY="false"
When call run_analyze
The status should be failure
The stdout should include "gitleaks: 2 total, 2 critical issues"
The stderr should include "Found 2 critical security issues"
Assert expect_output total_issues "2"
Assert expect_output critical_issues "2"
End

It "passes on a clean Gitleaks report"
write_gitleaks_report 0
export HAS_GITLEAKS="true" RUN_TRIVY="false"
When call run_analyze
The status should be success
The stdout should include "gitleaks: 0 total, 0 critical issues"
Assert expect_output total_issues "0"
Assert expect_output critical_issues "0"
End

It "adds up both scanners' reports"
write_gitleaks_report 0
write_trivy_report
export HAS_GITLEAKS="true" HAS_TRIVY="true"
When call run_analyze
The status should be failure
The stdout should include "trivy: 2 total, 1 critical issues"
The stdout should include "gitleaks: 0 total, 0 critical issues"
The stderr should include "Found 1 critical security issues"
Assert expect_output total_issues "2"
Assert expect_output critical_issues "1"
End

It "does not read results.sarif unless verification accepted it"
write_gitleaks_report 2
export RUN_TRIVY="false"
When call run_analyze
The status should be success
The stdout should not include "gitleaks: 2 total"
End

It "does not count a report under any other name"
write_gitleaks_report 2 gitleaks-report.sarif
export HAS_GITLEAKS="true" RUN_TRIVY="false"
When call run_analyze
The status should be success
The stdout should include "No results file found for gitleaks"
The stdout should not include "gitleaks: 2 total"
End

It "keeps deciding Trivy's critical count by level"
write_trivy_report
export HAS_TRIVY="true" RUN_GITLEAKS="false"
When call run_analyze
The status should be failure
The stdout should include "trivy: 2 total, 1 critical issues"
The stderr should include "Found 1 critical security issues"
Assert expect_output total_issues "2"
Assert expect_output critical_issues "1"
End

# A caller that gates on critical_issues == '0' must not pass on a scan that did not happen.
It "writes no totals when a scanner that was to run left no report to count"
write_gitleaks_report 0
export HAS_GITLEAKS="true"
When call run_analyze
The status should be success
The stdout should include "::warning::No issue totals: trivy left no report to count"
Assert no_output_key total_issues
Assert no_output_key critical_issues
End

It "writes no totals when verification accepted a report it then cannot find"
write_gitleaks_report 0 gitleaks-report.sarif
export HAS_GITLEAKS="true" RUN_TRIVY="false"
When call run_analyze
The status should be success
The stdout should include "::warning::No issue totals: gitleaks left no report to count"
Assert no_output_key total_issues
Assert no_output_key critical_issues
End

It "writes no totals when the job stopped before check-configs chose the scanners"
export RUN_TRIVY="" RUN_GITLEAKS=""
When call run_analyze
The status should be success
The stdout should include "::warning::No issue totals: trivy and gitleaks left no report to count"
Assert no_output_key total_issues
Assert no_output_key critical_issues
End

# A caller that opens an issue on critical findings still sees the ones the other reports hold.
It "writes the critical findings it counted, and no total, when a scanner left no report"
write_gitleaks_report 2
export HAS_GITLEAKS="true"
When call run_analyze
The status should be failure
The stdout should include "gitleaks: 2 total, 2 critical issues"
The stdout should include "::warning::No issue totals: trivy left no report to count"
The stderr should include "Found 2 critical security issues"
Assert no_output_key total_issues
Assert expect_output critical_issues "2"
The contents of file "$GITHUB_STEP_SUMMARY" should include "- Critical Issues: at least 2"
End
End

# These conditions and references only take effect on a runner.
Context "when wiring the steps together"
Parameters
"Run jactionlint" "steps.install-tools.outputs.jactionlint" JACTIONLINT
"Run Gitleaks" "steps.install-tools.outputs.gitleaks" GITLEAKS
"Run Trivy vulnerability scanner" "steps.install-tools.outputs.trivy" TRIVY
End

It "runs the installed binary in \"$1\""
When call step_value "$ACTION_DIR" "$1" "env.$3"
The output should equal "\${{ $2 }}"
End

It "runs \"$1\" after another scanner fails or fails to install, once its own binary is installed"
When call step_value "$ACTION_DIR" "$1" "if"
The output should include "!cancelled()"
The output should include "$2 != ''"
The output should not include "steps.install-tools.outcome"
End
End

Context "when wiring the scan directory and configs"
It "passes Gitleaks the config, commit range, scan directory and base commit check-configs chose"
When call step_value "$ACTION_DIR" "Run Gitleaks" "env"
The output should include "steps.check-configs.outputs.gitleaks_config"
The output should include "steps.check-configs.outputs.gitleaks_range"
The output should include "steps.check-configs.outputs.scan_dir"
The output should include "steps.check-configs.outputs.base_sha"
End

It "passes Trivy the scan directory and its cache directory"
When call step_value "$ACTION_DIR" "Run Trivy vulnerability scanner" "env"
The output should include "steps.check-configs.outputs.scan_dir"
The output should include "steps.install-tools.outputs.trivy_cache"
End

# Trivy does not verify its database, and a cache entry can be saved by another job.
It "restores no Trivy database from a cache"
The contents of file "${ACTION_DIR}/action.yml" should not include "actions/cache@"
End

It "passes jactionlint the config check-configs chose"
When call step_value "$ACTION_DIR" "Run jactionlint" "env.JACTIONLINT_CONFIG"
The output should equal "\${{ steps.check-configs.outputs.jactionlint_config }}"
End

It "passes jactionlint the profile input"
When call step_value "$ACTION_DIR" "Run jactionlint" "env.PROFILE"
The output should equal "\${{ inputs.jactionlint-profile }}"
End

# The step runs git by name from the checkout; on Windows the current directory would come first.
It "keeps the current directory out of the search for git in the inline gitleaks:allow step"
When call step_value "$ACTION_DIR" "Comment on inline gitleaks:allow comments" "env.NoDefaultCurrentDirectoryInExePath"
The output should equal "1"
End
End

Context "when wiring the reports"
It "verifies reports after a failed scan, because leaks fail the Gitleaks step"
When call step_value "$ACTION_DIR" "Verify SARIF files" "if"
The output should include "always()"
The output should include "steps.check-configs.outcome == 'success'"
End

It "uploads the Gitleaks report after a failed scan"
When call step_value "$ACTION_DIR" "Upload Gitleaks results" "if"
The output should include "always()"
The output should include "has_gitleaks == 'true'"
End

It "uploads the Trivy report after a failed Gitleaks scan"
When call step_value "$ACTION_DIR" "Upload Trivy results" "if"
The output should include "always()"
The output should include "has_trivy == 'true'"
End

It "uploads the report Gitleaks writes"
When call step_value "$ACTION_DIR" "Upload Gitleaks results" "with.sarif_file"
The output should equal "results.sarif"
End

It "archives the report Gitleaks writes"
When call step_value "$ACTION_DIR" "Archive Gitleaks results" "with.path"
The output should equal "results.sarif"
End

It "names no Gitleaks report but results.sarif"
When call cat "${ACTION_DIR}/action.yml"
The output should not include "gitleaks-report"
End
End

Context "when wiring the inline gitleaks:allow comment"
It "comments only on a pull request, once check-configs has succeeded"
When call step_value "$ACTION_DIR" "Comment on inline gitleaks:allow comments" "if"
The output should include "github.event_name == 'pull_request'"
The output should include "steps.check-configs.outcome == 'success'"
End

It "runs inline_allows.mjs with the commits check-configs checked"
When call step_value "$ACTION_DIR" "Comment on inline gitleaks:allow comments" "env"
The output should include "steps.check-configs.outputs.base_sha"
The output should include "steps.check-configs.outputs.head_sha"
The output should include "inputs.gitleaks-config"
End

It "imports the module from the action's own directory by file URL, which also works for a Windows path"
When call step_value "$ACTION_DIR" "Comment on inline gitleaks:allow comments" "with.script"
The output should include "pathToFileURL(join(process.env.ACTION_PATH, 'inline_allows.mjs'))"
End

It "has a script that runs as github-script runs it"
script=$(step_value "$ACTION_DIR" "Comment on inline gitleaks:allow comments" "with.script")
When call node -e "new (Object.getPrototypeOf(async function () {}).constructor)('github', 'context', 'core', process.argv[1])" "$script"
The status should be success
End

It "posts with the token input, or the workflow token"
When call step_value "$ACTION_DIR" "Comment on inline gitleaks:allow comments" "with.github-token"
The output should equal "\${{ inputs.token || github.token }}"
End
End

Context "when gitleaks-license is set"
It "has the runner warn that it is deprecated"
When call input_field gitleaks-license deprecationMessage
The output should include "no effect"
End

It "reaches no step but the validator, which masks it"
When call grep -c 'inputs.gitleaks-license' "${ACTION_DIR}/action.yml"
The output should equal "1"
End

It "is passed to the validator"
When call step_value "$ACTION_DIR" "Validate Inputs" "env.INPUT_GITLEAKS_LICENSE"
The output should equal "\${{ inputs.gitleaks-license }}"
End
End
End
