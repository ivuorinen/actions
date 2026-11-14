#!/usr/bin/env shellspec
# Unit tests for python-lint-fix/flake8_to_sarif.py, which turns flake8's custom
# --format output into the SARIF log uploaded to code scanning. The field values
# below are the ones flake8 produces for those cases; the format string itself is
# exercised against this parser in behavior.spec.sh.

Describe "flake8_to_sarif.py"
CONVERTER="${PROJECT_ROOT}/python-lint-fix/flake8_to_sarif.py"

before() {
  shellspec_setup_test_env "python-lint-fix-sarif-$$"
  RESULTS="${SHELLSPEC_TEST_TEMP_DIR}/results.txt"
  SARIF="${SHELLSPEC_TEST_TEMP_DIR}/flake8.sarif"
  : >"$RESULTS"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "python-lint-fix-sarif-$$"
}
AfterEach 'after'

convert() { python3 "$CONVERTER" "$RESULTS" "$SARIF" "$SHELLSPEC_TEST_WORKSPACE"; }
add_result() { printf '%s\n' "$1" >>"$RESULTS"; }
sarif() { jq -c "$1" "$SARIF"; }

Context "counting results"
It "prints the number of results"
add_result "(1, 1, 'F401', './a.py', \"'os' imported but unused\")"
add_result "(2, 2, 'E225', './a.py', 'missing whitespace around operator')"
When call convert
The status should be success
The output should equal "2"
End

It "ignores the statistics, benchmark and file-name lines flake8 can add to the same file"
add_result "(1, 1, 'F401', './a.py', \"'os' imported but unused\")"
add_result "1     F401 'os' imported but unused"
add_result "0.012             seconds elapsed"
add_result "./a.py"
When call convert
The status should be success
The output should equal "1"
End

It "writes a valid empty log when there are no results"
convert >/dev/null
When call sarif '[.version, .runs[0].tool.driver.name, .runs[0].results]'
The output should equal '["2.1.0","flake8",[]]'
End
End

Context "mapping locations"
It "uses flake8's line and column for the region"
add_result "(4, 8, 'E225', './a.py', 'missing whitespace around operator')"
convert >/dev/null
When call sarif '.runs[0].results[0].locations[0].physicalLocation.region'
The output should equal '{"startLine":4,"startColumn":8}'
End

It "declares the column unit SARIF requires of a run with results"
add_result "(4, 8, 'E225', './a.py', 'missing whitespace around operator')"
convert >/dev/null
When call sarif '.runs[0].columnKind'
The output should equal '"unicodeCodePoints"'
End

It "moves flake8's line 0 for an unreadable file to the first line SARIF allows"
add_result "(0, 1, 'E902', './gone.py', 'FileNotFoundError: gone')"
convert >/dev/null
When call sarif '.runs[0].results[0].locations[0].physicalLocation.region.startLine'
The output should equal "1"
End

It "writes the URI relative to the root with no leading ./"
add_result "(1, 1, 'F401', './sub/a.py', 'unused')"
convert >/dev/null
When call sarif '.runs[0].results[0].locations[0].physicalLocation.artifactLocation'
The output should equal '{"uri":"sub/a.py","uriBaseId":"%SRCROOT%"}'
End

It "percent-encodes characters a URI cannot hold, including a newline in a file name"
add_result "(1, 1, 'F401', './a b\\nc.py', 'unused')"
When call convert
The status should be success
The output should equal "1"
The contents of file "$SARIF" should include '"uri": "a%20b%0Ac.py"'
End

It "keeps a file name that is not valid UTF-8"
add_result "(1, 1, 'F401', './\\udce4.py', 'unused')"
When call convert
The status should be success
The output should equal "1"
The contents of file "$SARIF" should include '"uri": "%E4.py"'
End

It "records the root the URIs are relative to"
convert >/dev/null
When call sarif '.runs[0].originalUriBaseIds["%SRCROOT%"].uri'
The output should end with '/workspace/"'
End
End

Context "describing rules and severities"
It "reports E codes as errors"
add_result "(1, 1, 'E999', './a.py', 'SyntaxError: invalid syntax')"
convert >/dev/null
When call sarif '.runs[0].results[0] | [.ruleId, .level, .message.text]'
The output should equal '["E999","error","SyntaxError: invalid syntax"]'
End

It "reports other codes as warnings"
add_result "(1, 1, 'F401', './a.py', 'unused')"
add_result "(1, 1, 'W291', './a.py', 'trailing whitespace')"
add_result "(1, 1, 'C901', './a.py', 'too complex')"
convert >/dev/null
When call sarif '[.runs[0].results[].level]'
The output should equal '["warning","warning","warning"]'
End

It "lists each rule once"
add_result "(1, 1, 'F401', './a.py', 'unused')"
add_result "(2, 1, 'F401', './a.py', 'unused')"
convert >/dev/null
When call sarif '.runs[0].tool.driver.rules'
The output should equal '[{"id":"F401","defaultConfiguration":{"level":"warning"}}]'
End
End
End
