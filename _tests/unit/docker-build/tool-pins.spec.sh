#!/usr/bin/env shellspec
# Tests for the tools docker-build sets up. QEMU comes from an upstream action that defaults to
# `latest`, and that step is `uses:`, which the harness does not execute, so its pin is read from
# action.yml. The Buildx check, the Trivy install, the scan and its processing are shell steps,
# run here with stand-ins, so nothing is downloaded; security-scan's install-tool.spec.sh tests
# install_tool.py.

Describe "docker-build tool pins"
ACTION_DIR="${PROJECT_ROOT}/docker-build"
ACTION_FILE="${ACTION_DIR}/action.yml"
CHECK_STEP="Check for Buildx"
INSTALL_STEP="Install Trivy"
SCAN_STEP="Scan Image for Vulnerabilities"
PROCESS_STEP="Process Scan Results"
BUILDX_ERROR="::error::Docker Buildx is required: this runner has none, and the action downloads none unverified"

before() {
  shellspec_setup_test_env "docker-build-tool-pins-$$"
  STUB_DIR="${RUNNER_TEMP}/stub"
  BIN_DIR="${RUNNER_TEMP}/bin"
  mkdir -p "$STUB_DIR" "$BIN_DIR"
  # The check reads buildx-version with tr, a POSIX utility, so it stays on the check's PATH.
  ln -s "$(command -v tr)" "${BIN_DIR}/tr"
  export CALLS="${RUNNER_TEMP}/calls"
  : >"$CALLS"
  export FAIL=""
  # Records each call; the subcommand FAIL names fails.
  cat >"${STUB_DIR}/install_tool.py" <<'PY'
import os
import sys

with open(os.environ["CALLS"], "a", encoding="utf-8") as calls:
    calls.write(" ".join(sys.argv[1:]) + "\n")
if sys.argv[1] == os.environ.get("FAIL"):
    print("::error::" + sys.argv[1] + " failed")
    sys.exit(1)
PY
}
BeforeEach 'before'

after() {
  unset CALLS STUB_DIR BIN_DIR FAIL
  shellspec_cleanup_test_env "docker-build-tool-pins-$$"
}
AfterEach 'after'

lines() {
  printf '%s\n' "$@"
}

# stand_in NAME STATUS: put a NAME on the check's PATH that exits STATUS.
stand_in() {
  printf '#!/bin/sh\nexit %s\n' "$2" >"${BIN_DIR}/$1"
  chmod +x "${BIN_DIR}/$1"
}

# run_check [BUILDX_VERSION]: run the Buildx check with only the stand-ins on PATH, so the
# host's own Docker and Buildx cannot answer for them.
run_check() {
  script=$(step_value "$ACTION_DIR" "$CHECK_STEP" run)
  BUILDX_VERSION="${1:-}" PATH="$BIN_DIR" /bin/sh -c "$script"
}

pinned_version() {
  step_value "$ACTION_DIR" "$INSTALL_STEP" env.TRIVY_VERSION
}

# run_install OS ARCH: run the install step as a runner with RUNNER_OS OS and RUNNER_ARCH ARCH
# would, at the version the step pins.
run_install() {
  RUNNER_OS="$1" RUNNER_ARCH="$2" ACTION_PATH="$STUB_DIR" TRIVY_VERSION="$(pinned_version)" \
    sh -c "$(step_value "$ACTION_DIR" "$INSTALL_STEP" run)"
}

# The file name of each archive the install step downloaded, one per line.
fetched() {
  sed -n 's|^download https://github\.com/[^ ]*/\([^/ ]*\) .*|\1|p' "$CALLS"
}

# The archive names tools.sha256 pins, sorted.
pinned_names() {
  awk '!/^#/ && NF { print $2 }' "${ACTION_DIR}/tools.sha256" | sort -u
}

# Each archive name the install step fetches on some supported platform, sorted.
fetched_on_every_platform() {
  for platform in Linux/X64 Linux/ARM64 macOS/X64 macOS/ARM64 Windows/X64; do
    run_install "${platform%/*}" "${platform#*/}" || return 1
  done
  fetched | sort -u
}

Describe "Check for Buildx"
It "passes with the Docker CLI's buildx plugin"
stand_in docker 0
When call run_check
The status should be success
The output should equal ""
End

# setup-buildx runs the plugin whenever the Docker CLI is there, and downloads Buildx when that fails.
It "fails with a Docker CLI that has no buildx plugin, even beside a buildx binary"
stand_in docker 1
stand_in buildx 0
When call run_check
The status should be failure
The output should equal "$BUILDX_ERROR"
End

It "passes with a buildx binary when there is no Docker CLI"
stand_in buildx 0
When call run_check
The status should be success
The output should equal ""
End

It "fails with a buildx binary that does not run"
stand_in buildx 1
When call run_check
The status should be failure
The output should equal "$BUILDX_ERROR"
End

It "fails with neither"
When call run_check
The status should be failure
The output should equal "$BUILDX_ERROR"
End

# A named version is downloaded, which the input's description says is unverified.
It "passes without Buildx when the caller names a version"
When call run_check v0.38.2
The status should be success
The output should equal ""
End

# setup-buildx trims the input, so a blank one would download the newest release.
It "fails without Buildx when the version the caller names is blank"
When call run_check "$(printf ' \t ')"
The status should be failure
The output should equal "$BUILDX_ERROR"
End

It "reads buildx-version through the environment"
When call step_value "$ACTION_DIR" "$CHECK_STEP" env.BUILDX_VERSION
The output should equal '${{ inputs.buildx-version }}'
End
End

It "sets up the pinned QEMU image"
The contents of file "${ACTION_FILE}" should include 'image: docker.io/tonistiigi/binfmt:${{ env.BINFMT_IMAGE_TAG }}'
End

# setup-qemu-action runs the image privileged, and a tag can be pushed again.
It "pins the QEMU image by digest"
The contents of file "${ACTION_FILE}" should match pattern "*BINFMT_IMAGE_TAG: 'qemu-v*@sha256:????????????????????????????????????????????????????????????????'*"
End

Describe "Install Trivy"
Parameters
Linux X64 Linux-64bit tar.gz ""
Linux ARM64 Linux-ARM64 tar.gz ""
macOS X64 macOS-64bit tar.gz ""
macOS ARM64 macOS-ARM64 tar.gz ""
Windows X64 windows-64bit zip .exe
End

It "fetches the $1 $2 release archive, installs it once checked, and names the binary"
version="$(pinned_version)"
When call run_install "$1" "$2"
The status should be success
Assert test "$(fetched)" = "trivy_${version}_$3.$4"
Assert grep -Fq "download https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_$3.$4 " "$CALLS"
Assert grep -Eq "^install ${STUB_DIR}/tools\.sha256 [^ ]+/trivy_${version}_$3\.$4 trivy$5 ${RUNNER_TEMP}/docker-build-tools\.[^ /]+\$" "$CALLS"
Assert grep -Eq "^trivy=${RUNNER_TEMP}/docker-build-tools\.[^ /]+/trivy$5\$" "$GITHUB_OUTPUT"
End
End

Describe "Install Trivy on a platform it pins no binary for"
Parameters
Linux X86
Windows ARM64
End

It "fails on $1 $2 before downloading anything"
When call run_install "$1" "$2"
The status should be failure
The stdout should equal "::error::docker-build pins no Trivy binary for $2 on $1"
Assert test ! -s "$CALLS"
End
End

Describe "Install Trivy when a stage fails"
Parameters
download
install
End

It "fails at the $1 and names no binary"
FAIL="$1"
When call run_install Linux X64
The status should be failure
The stdout should equal "::error::$1 failed"
Assert test -z "$(grep '^trivy=' "$GITHUB_OUTPUT")"
End
End

# A new directory: nothing earlier in the job can have put a database there, and no committed
# symlink can redirect the report.
It "keeps Trivy's database and report in the step's own new directory"
When call run_install Linux X64
The status should be success
Assert grep -Eq "^cache=${RUNNER_TEMP}/docker-build-tools\.[^ /]+/trivy-cache\$" "$GITHUB_OUTPUT"
Assert grep -Eq "^report=${RUNNER_TEMP}/docker-build-tools\.[^ /]+/trivy-results\.json\$" "$GITHUB_OUTPUT"
End

# Trivy does not verify its database, and a cache entry can be saved by another job.
It "restores no Trivy database from a cache"
The contents of file "${ACTION_FILE}" should not include "actions/cache@"
End

Describe "tools.sha256"
It "pins exactly the archives the supported platforms fetch"
When call fetched_on_every_platform
The status should be success
The output should equal "$(pinned_names)"
End

It "pins each archive with a 64-character SHA-256 in sha256sum format"
When call awk '!/^#/ && NF && !(NF == 2 && $1 ~ /^[0-9a-f]+$/ && length($1) == 64)' "${ACTION_DIR}/tools.sha256"
The output should equal ""
End
End

# security-scan's install-tool.spec.sh tests the script; this keeps docker-build's copy that script.
It "ships security-scan's install_tool.py unchanged"
When call cmp "${ACTION_DIR}/install_tool.py" "${PROJECT_ROOT}/security-scan/install_tool.py"
The status should be success
End

# Renovate bumps the version through its comment; the tools.sha256 tests above then fail
# until the new release's digests are pinned.
It "lets Renovate bump the Trivy version"
When call step_value "$ACTION_DIR" "$INSTALL_STEP" env.TRIVY_VERSION
The output should match pattern "[0-9]*.[0-9]*.[0-9]*"
The contents of file "${ACTION_FILE}" should include "# renovate: datasource=github-releases depName=aquasecurity/trivy"
End

Describe "Scan Image for Vulnerabilities"
# run_scan IMAGE_REF: run the scan step with a stand-in Trivy that records its arguments.
run_scan() {
  printf '#!/bin/sh\nprintf "%%s\\n" "$@" >"$CALLS"\n' >"${STUB_DIR}/trivy"
  chmod +x "${STUB_DIR}/trivy"
  TRIVY="${STUB_DIR}/trivy" CACHE_DIR="${RUNNER_TEMP}/trivy-cache" REPORT="${RUNNER_TEMP}/report.json" IMAGE_REF="$1" \
    sh -c "$(step_value "$ACTION_DIR" "$SCAN_STEP" run)"
}

It "scans the image for high and critical findings with the installed Trivy, its cache and report path"
When call run_scan "ghcr.io/owner/repo@sha256:0123"
The status should be success
Assert test "$(cat "$CALLS")" = "$(lines image --severity HIGH,CRITICAL --cache-dir "${RUNNER_TEMP}/trivy-cache" \
  --format json --output "${RUNNER_TEMP}/report.json" "ghcr.io/owner/repo@sha256:0123")"
End

It "runs the Trivy the install step checked, with the directories it made"
When call step_value "$ACTION_DIR" "$SCAN_STEP" env
The output should include '"TRIVY": "${{ steps.install-trivy.outputs.trivy }}"'
The output should include '"CACHE_DIR": "${{ steps.install-trivy.outputs.cache }}"'
The output should include '"REPORT": "${{ steps.install-trivy.outputs.report }}"'
End
End

Describe "Process Scan Results"
# run_process JSON: run the step on a report holding JSON.
run_process() {
  printf '%s\n' "$1" >"${RUNNER_TEMP}/report.json"
  REPORT="${RUNNER_TEMP}/report.json" sh -c "$(step_value "$ACTION_DIR" "$PROCESS_STEP" run)"
}

It "outputs the report and warns about its critical findings"
When call run_process '{"Results":[{"Vulnerabilities":[{"VulnerabilityID":"CVE-1","Severity":"CRITICAL"},{"VulnerabilityID":"CVE-2","Severity":"HIGH"}]}]}'
The status should be success
The output should equal "::warning::Found 1 critical vulnerabilities in image"
Assert grep -Fxq 'results={"Results":[{"Vulnerabilities":[{"VulnerabilityID":"CVE-1","Severity":"CRITICAL"},{"VulnerabilityID":"CVE-2","Severity":"HIGH"}]}]}' "$GITHUB_OUTPUT"
End

It "reads a report with no Results quietly"
When call run_process '{"ArtifactName":"scratch"}'
The status should be success
The output should equal ""
Assert grep -Fxq 'results={"ArtifactName":"scratch"}' "$GITHUB_OUTPUT"
End

It "reads the report the install step placed"
When call step_value "$ACTION_DIR" "$PROCESS_STEP" env.REPORT
The output should equal '${{ steps.install-trivy.outputs.report }}'
End
End
End
