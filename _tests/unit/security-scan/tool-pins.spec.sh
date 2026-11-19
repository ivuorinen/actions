#!/usr/bin/env shellspec
# Tests for the scanner binaries security-scan installs: the archive each runner platform
# fetches, and the SHA-256 that tools.sha256 pins for each. The install step runs with a
# stand-in install_tool.py that records its calls, so nothing is downloaded;
# install-tool.spec.sh tests the real script.

Describe "security-scan tool pins"
ACTION_DIR="${PROJECT_ROOT}/security-scan"
INSTALL_STEP="Install the scanners"

before() {
  shellspec_setup_test_env "security-scan-tool-pins-$$"
  STUB_DIR="${RUNNER_TEMP}/stub"
  mkdir -p "$STUB_DIR"
  export CALLS="${RUNNER_TEMP}/calls"
  : >"$CALLS"
  cat >"${STUB_DIR}/install_tool.py" <<'PY'
import os
import sys

with open(os.environ["CALLS"], "a", encoding="utf-8") as calls:
    calls.write(" ".join(sys.argv[1:]) + "\n")
PY
}
BeforeEach 'before'

after() {
  unset CALLS STUB_DIR
  shellspec_cleanup_test_env "security-scan-tool-pins-$$"
}
AfterEach 'after'

pinned_version() {
  step_value "$ACTION_DIR" "$INSTALL_STEP" "env.$1"
}

lines() {
  printf '%s\n' "$@"
}

# run_install OS ARCH [RUN_ACTIONLINT]: run the install step as a runner with RUNNER_OS OS
# and RUNNER_ARCH ARCH would, at the versions the step pins.
run_install() {
  RUNNER_OS="$1" RUNNER_ARCH="$2" RUN_ACTIONLINT="${3:-true}" ACTION_PATH="$STUB_DIR" \
    GITLEAKS_VERSION="$(pinned_version GITLEAKS_VERSION)" \
    TRIVY_VERSION="$(pinned_version TRIVY_VERSION)" \
    ACTIONLINT_VERSION="$(pinned_version ACTIONLINT_VERSION)" \
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

# downloaded REPO VERSION ARCHIVE: the step fetched ARCHIVE from REPO's release VERSION.
downloaded() {
  grep -Fq "download https://github.com/$1/releases/download/v$2/$3 " "$CALLS"
}

# installed MEMBER: the step installed MEMBER from an archive, checked against tools.sha256.
installed() {
  grep -Eq "^install ${STUB_DIR}/tools\.sha256 [^ ]+ $1 ${RUNNER_TEMP}/security-scan-tools\.[^ /]+\$" "$CALLS"
}

# output_names KEY MEMBER: the step output KEY is MEMBER's path in the tools directory.
output_names() {
  grep -Eq "^$1=${RUNNER_TEMP}/security-scan-tools\.[^ /]+/$2\$" "$GITHUB_OUTPUT"
}

Describe "on each supported platform"
Parameters
Linux X64 linux_x64 linux_amd64 Linux-64bit tar.gz ""
Linux ARM64 linux_arm64 linux_arm64 Linux-ARM64 tar.gz ""
macOS X64 darwin_x64 darwin_amd64 macOS-64bit tar.gz ""
macOS ARM64 darwin_arm64 darwin_arm64 macOS-ARM64 tar.gz ""
Windows X64 windows_x64 windows_amd64 windows-64bit zip .exe
End

It "fetches the $1 $2 release archives of all three scanners"
gitleaks="$(pinned_version GITLEAKS_VERSION)"
actionlint="$(pinned_version ACTIONLINT_VERSION)"
trivy="$(pinned_version TRIVY_VERSION)"
When call run_install "$1" "$2"
The status should be success
Assert downloaded gitleaks/gitleaks "$gitleaks" "gitleaks_${gitleaks}_$3.$6"
Assert downloaded rhysd/actionlint "$actionlint" "actionlint_${actionlint}_$4.$6"
Assert downloaded aquasecurity/trivy "$trivy" "trivy_${trivy}_$5.$6"
End

It "installs the $1 $2 binaries and names them in the step outputs"
When call run_install "$1" "$2"
The status should be success
Assert installed "gitleaks$7"
Assert installed "trivy$7"
Assert installed "actionlint$7"
Assert output_names gitleaks "gitleaks$7"
Assert output_names trivy "trivy$7"
Assert output_names actionlint "actionlint$7"
End
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

Describe "on a platform it pins no binaries for"
Parameters
Linux X86
Windows ARM64
End

It "fails on $1 $2 before downloading anything"
When call run_install "$1" "$2"
The status should be failure
The stdout should include "::error::security-scan pins no scanner binaries for $2 on $1"
Assert test ! -s "$CALLS"
End
End

It "installs no actionlint when actionlint is off"
When call run_install Linux X64 false
The status should be success
The output should equal ""
Assert test "$(fetched)" = "$(lines "gitleaks_$(pinned_version GITLEAKS_VERSION)_linux_x64.tar.gz" \
  "trivy_$(pinned_version TRIVY_VERSION)_Linux-64bit.tar.gz")"
Assert output_names gitleaks gitleaks
Assert test -z "$(grep '^actionlint=' "$GITHUB_OUTPUT")"
End

It "keeps the Trivy database outside the checkout and caches it by day"
When call run_install Linux X64
The status should be success
Assert grep -Fxq "trivy_cache=${RUNNER_TEMP}/security-scan-trivy-cache" "$GITHUB_OUTPUT"
Assert grep -Eq '^date=[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$GITHUB_OUTPUT"
End

# Renovate bumps a version through its comment; the tools.sha256 tests above then fail
# until the new release's digests are pinned.
It "lets Renovate bump each scanner version"
When call cat "${ACTION_DIR}/action.yml"
The output should include "# renovate: datasource=github-releases depName=gitleaks/gitleaks"
The output should include "# renovate: datasource=github-releases depName=aquasecurity/trivy"
The output should include "# renovate: datasource=github-releases depName=rhysd/actionlint"
End
End
