#!/usr/bin/env shellspec
# Behavior tests for the "Run dotnet-format" step of csharp-lint-check.
# The step script is extracted from action.yml and run against a stub `dotnet`
# that accepts only the options the real `dotnet format` accepts.

Describe "csharp-lint-check dotnet-format step"
ACTION_FILE="$PWD/csharp-lint-check/action.yml"

setup_stub() {
  WORK=$(mktemp -d)
  mkdir -p "$WORK/bin"
  yq -r '.runs.steps[] | select(.id == "dotnet-format") | .run' "$ACTION_FILE" >"$WORK/step.sh"
  cat >"$WORK/bin/dotnet" <<'STUB'
#!/bin/sh
[ "$1" = "format" ] || exit 64
shift
verify=0
report=""
while [ $# -gt 0 ]; do
  case "$1" in
    --verify-no-changes) verify=1 ;;
    --report) shift; report="$1" ;;
    -*) echo "Unrecognized command or argument '$1'." >&2; exit 1 ;;
    *) printf '%s\n' "$1" >"$STUB_ARG_LOG" ;;
  esac
  shift
done
[ "$STUB_MODE" = "crash" ] && { echo "Unable to find a project" >&2; exit 1; }
[ "$verify" = 1 ] || { echo "dotnet format was called without --verify-no-changes" >&2; exit 1; }
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
  export GITHUB_OUTPUT
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

It "fails with a distinct message when dotnet format itself fails"
When call run_step crash
The status should be failure
The output should include "dotnet format failed with exit code 1"
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
