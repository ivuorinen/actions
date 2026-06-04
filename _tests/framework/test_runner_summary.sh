#!/usr/bin/env bash
# Regression harness for run-tests.sh summary parsing.
# Simulates shellspec outcomes in a tempdir and asserts each is classified
# correctly under the SHIPPED predicate. classify_new below MUST stay byte-for-byte
# in lockstep with the grep in run-tests.sh run_unit_tests (see .claude/rules/
# code-quality.md "Never duplicate a regex ... kept in lockstep"). The classify_old
# block then demonstrates the historical bugs this predicate fixed.

set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/reports/unit"
printf '5 examples, 0 failures\n' >"$TMP/reports/unit/pass.txt"
printf '5 examples, 2 failures\n' >"$TMP/reports/unit/fail.txt"
printf 'Loading spec failed: syntax error near unexpected token\n' >"$TMP/reports/unit/crash.txt"
# N-117 regression: a count ending in 0 must NOT be read as "0 failures".
printf '5 examples, 10 failures\n' >"$TMP/reports/unit/tens.txt"

# MUST match run-tests.sh run_unit_tests exactly: '^[0-9][0-9]* examples?, 0 failures?$'
classify_new() {
  local file="$1"
  if grep -qE '^[0-9][0-9]* examples?, 0 failures?$' "$file"; then
    echo "pass"
  else
    echo "fail"
  fi
}

fails=0
[[ "$(classify_new "$TMP/reports/unit/pass.txt")" == "pass" ]] || {
  echo "pass misclassified"
  fails=1
}
[[ "$(classify_new "$TMP/reports/unit/fail.txt")" == "fail" ]] || {
  echo "fail misclassified"
  fails=1
}
[[ "$(classify_new "$TMP/reports/unit/crash.txt")" == "fail" ]] || {
  echo "crash misclassified (would be the old bug)"
  fails=1
}
[[ "$(classify_new "$TMP/reports/unit/tens.txt")" == "fail" ]] || {
  echo "N-117: '10 failures' misclassified as pass"
  fails=1
}

echo "---"
echo "Demonstrating the historical OLD predicates' bugs:"

# OLD predicate #1 (pre-T-C2): crash output classified as pass.
classify_old() {
  local file="$1"
  if grep -qE "[0-9]+ examples?, 0 failures?" "$file" && ! grep -q "Fatal error occurred" "$file"; then
    echo "pass"
  elif grep -qE "[0-9]+ examples?, [1-9][0-9]* failures?" "$file"; then
    echo "fail"
  else
    if ! grep -q "Fatal error occurred" "$file"; then
      echo "pass"
    else
      echo "fail"
    fi
  fi
}

if [[ "$(classify_old "$TMP/reports/unit/crash.txt")" == "pass" ]]; then
  echo "BUG CONFIRMED: crash classified as pass under old predicate"
else
  echo "bug not reproduced"
fi

# OLD predicate #2 (N-117): '.*0 failures?$' false-matched any count ending in 0.
classify_old_n117() {
  local file="$1"
  if grep -qE '^[0-9][0-9]* examples?.*0 failures?$' "$file"; then
    echo "pass"
  else
    echo "fail"
  fi
}

if [[ "$(classify_old_n117 "$TMP/reports/unit/tens.txt")" == "pass" ]]; then
  echo "BUG CONFIRMED (N-117): '10 failures' classified as pass under old '.*0 failures' predicate"
else
  echo "N-117 bug not reproduced"
fi

exit $fails
