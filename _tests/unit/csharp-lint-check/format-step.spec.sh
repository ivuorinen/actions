#!/usr/bin/env shellspec
# Behavior tests for the "Run dotnet-format" step of csharp-lint-check.
# The step script is extracted from action.yml and run against a stub `dotnet`
# that accepts only the options the real `dotnet restore` and `dotnet format` accept,
# and logs each call to $STUB_CALLS.

Describe "csharp-lint-check dotnet-format step"
ACTION_FILE="$PWD/csharp-lint-check/action.yml"

setup_stub() {
  WORK=$(mktemp -d)
  mkdir -p "$WORK/bin"
  step_value "$(dirname "$ACTION_FILE")" dotnet-format run >"$WORK/step.sh"
  cat >"$WORK/bin/dotnet" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$STUB_CALLS"
case "$1" in
  restore)
    shift
    locked=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --locked-mode) locked=1 ;;
        -*) echo "Unrecognized command or argument '$1'." >&2; exit 1 ;;
      esac
      shift
    done
    [ "$locked" = 1 ] || { echo "dotnet restore was called without --locked-mode" >&2; exit 1; }
    [ "$STUB_MODE" = "restore-fails" ] && { echo "error NU1004: The packages lock file is inconsistent" >&2; exit 1; }
    exit 0
    ;;
  format) shift ;;
  *) exit 64 ;;
esac
verify=0
no_restore=0
report=""
while [ $# -gt 0 ]; do
  case "$1" in
    --verify-no-changes) verify=1 ;;
    --no-restore) no_restore=1 ;;
    --report) shift; report="$1" ;;
    -*) echo "Unrecognized command or argument '$1'." >&2; exit 1 ;;
    *) printf '%s\n' "$1" >"$STUB_ARG_LOG" ;;
  esac
  shift
done
[ "$STUB_MODE" = "crash" ] && { echo "Unable to find a project" >&2; exit 1; }
[ "$verify" = 1 ] || { echo "dotnet format was called without --verify-no-changes" >&2; exit 1; }
[ "$no_restore" = 1 ] || { echo "dotnet format was called without --no-restore" >&2; exit 1; }
if [ "$STUB_MODE" = "dirty" ]; then
  printf '[{"FileName":"a.cs","FileChanges":[{"LineNumber":1},{"LineNumber":2}]},{"FileName":"b.cs","FileChanges":[{"LineNumber":3}]}]' >"$report/format-report.json"
  exit 2
fi
printf '[]' >"$report/format-report.json"
exit 0
STUB
  chmod +x "$WORK/bin/dotnet"
  GITHUB_OUTPUT="$WORK/output"
  : >"$GITHUB_OUTPUT"
  STUB_CALLS="$WORK/calls"
  : >"$STUB_CALLS"
  export GITHUB_OUTPUT STUB_CALLS
}

cleanup_stub() {
  rm -rf "$WORK"
}

run_step() {
  STUB_MODE="$1" PATH="$WORK/bin:$PATH" sh "$WORK/step.sh" 2>&1
}

BeforeEach 'setup_stub'
AfterEach 'cleanup_stub'

It "passes on a clean run with zero counts"
When call run_step clean
The status should be success
The contents of file "$GITHUB_OUTPUT" should include "errors_count=0"
The contents of file "$GITHUB_OUTPUT" should include "warnings_count=0"
End

It "fails on findings and counts every reported change"
When call run_step dirty
The status should be failure
The output should include "::error::Code formatting issues found (3)"
The contents of file "$GITHUB_OUTPUT" should include "errors_count=3"
End

# A run dotnet format did not finish has no counts to report.
It "fails with a distinct message when dotnet format itself fails, and writes no counts"
When call run_step crash
The status should be failure
The output should include "dotnet format failed with exit code 1"
The contents of file "$GITHUB_OUTPUT" should not include "errors_count="
The contents of file "$GITHUB_OUTPUT" should not include "warnings_count="
End

# The implicit restore of dotnet format does not run in locked mode, so a lock file that
# no longer matches the projects would not stop it.
It "restores in locked mode first, then formats without restoring"
When call run_step clean
The status should be success
The line 1 of contents of file "$STUB_CALLS" should equal "restore --locked-mode"
The line 2 of contents of file "$STUB_CALLS" should start with "format --verify-no-changes --no-restore"
End

It "fails before formatting when the locked restore fails, and writes no counts"
When call run_step restore-fails
The status should be failure
The output should include "::error::dotnet restore --locked-mode failed"
The lines of contents of file "$STUB_CALLS" should equal 1
The contents of file "$GITHUB_OUTPUT" should not include "errors_count="
End

It "restores the project when one is set"
export PROJECT="src/App.sln" STUB_ARG_LOG="${WORK}/arg"
When call run_step clean
The status should be success
The line 1 of contents of file "$STUB_CALLS" should equal "restore src/App.sln --locked-mode"
End

It "gives dotnet format the project when one is set"
export PROJECT="src/App.sln" STUB_ARG_LOG="${WORK}/arg"
When call run_step clean
The status should be success
The contents of file "${WORK}/arg" should equal "src/App.sln"
End

It "gives dotnet format no path when the project is empty"
export PROJECT="" STUB_ARG_LOG="${WORK}/arg"
When call run_step clean
The status should be success
The path "${WORK}/arg" should not be exist
End

It "does not pass options dotnet format rejects or promise SARIF"
When call grep -E -e '--report-file|--check|sarif|upload-sarif' "$ACTION_FILE"
The status should be failure
End
End
