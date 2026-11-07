#!/usr/bin/env shellspec
# Static check of .claude/rules/github-output-format.md across every action.yml.
#
# Every line that writes to "$GITHUB_OUTPUT" must be either
#   printf 'key=%s\n' <value> >> "$GITHUB_OUTPUT"      (format separated from value)
# or the closing line `} >> "$GITHUB_OUTPUT"` of a grouped multi-line (delimiter)
# form, as used in docker-build and docker-publish. Anything else (echo, a printf
# with the value inside the format string, a printf with no value) is a violation.

Describe "GITHUB_OUTPUT write format"
violations() {
  # Output "file:line:text" for each non-conforming write in every action.yml.
  for f in "${PROJECT_ROOT}"/*/action.yml; do
    grep -nE '>>[[:space:]]*"?\$\{?GITHUB_OUTPUT' "$f" |
      grep -vE "printf '[A-Za-z0-9_-]+=%s\\\\n' ('[^']*'|\"[^\"]*\"|[^ ]+) >>" |
      grep -vE '^[0-9]+:[[:space:]]*\} >>' |
      sed -E "s|^|${f#"${PROJECT_ROOT}"/}:|"
  done
  # grep -v exits 1 when nothing is left, which is the passing case.
  return 0
}

It "has no write that puts a value in the format string or omits the value"
When call violations
The output should equal ""
The status should be success
End
End
