#!/usr/bin/env bash
# Regression harness for run-tests.sh summary parsing.
# Simulates three shellspec outcomes in a tempdir and asserts each is
# classified correctly under the NEW predicate. Then demonstrates the
# OLD predicate's bug (crash output classified as pass).

set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/reports/unit"
printf '5 examples, 0 failures\n' > "$TMP/reports/unit/pass.txt"
printf '5 examples, 2 failures\n' > "$TMP/reports/unit/fail.txt"
printf 'Loading spec failed: syntax error near unexpected token\n' > "$TMP/reports/unit/crash.txt"

classify_new() {
  local file="$1"
  if grep -qE '^[0-9]+ examples?, 0 failures?$' "$file"; then
    echo "pass"
  else
    echo "fail"
  fi
}

fails=0
[[ "$(classify_new "$TMP/reports/unit/pass.txt")"  == "pass" ]] || { echo "pass misclassified"; fails=1; }
[[ "$(classify_new "$TMP/reports/unit/fail.txt")"  == "fail" ]] || { echo "fail misclassified"; fails=1; }
[[ "$(classify_new "$TMP/reports/unit/crash.txt")" == "fail" ]] || { echo "crash misclassified (would be the old bug)"; fails=1; }

echo "---"
echo "Demonstrating current buggy behavior under the OLD predicate:"
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

exit $fails
