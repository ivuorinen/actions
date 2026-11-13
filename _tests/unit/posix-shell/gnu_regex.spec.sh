#!/usr/bin/env shellspec
# Static guard: no action may use GNU-only sed or grep syntax, or sed without -E.
#
# GNU tools accept all of it, so a test that only runs the steps on Linux cannot
# see the problem. The block-bashisms hook does not cover it either: it runs on
# edits made through Claude Code, not on the repository or in CI.

Describe "GNU-only sed and grep syntax"
SCANNER="${PROJECT_ROOT}/_tests/unit/posix-shell/find_gnu_regex.py"

scan_line() {
  printf '%s\n' "$1" | python3 "$SCANNER" /dev/stdin
}

It "is absent from every action.yml"
When run python3 "$SCANNER" "$PROJECT_ROOT"/*/action.yml "$PROJECT_ROOT"/.github/actions/*/action.yml
The status should be success
The output should equal ""
End

It "is absent from the repository's own POSIX scripts"
When run python3 "$SCANNER" "$PROJECT_ROOT"/.claude/hooks/*.sh "$PROJECT_ROOT"/_tools/*.sh
The status should be success
The output should equal ""
End

Describe "the scanner"
Parameters
"sed 's/a\+/b/'"
"sed -n 's/\(a\)\?/\1/p'"
"sed -e 's/a\+/b/' file"
"sed 's/a|b\|c/d/'"
"grep 'a\|b' file"
"grep -q 'a\+' file"
"xargs grep -l 'a\|b'"
"grep -A 20 'a\?' file"
"grep -E '^\s*x' file"
"grep -E '\S+' file"
"sed -E 's/\w+//'"
"sed -E 's/\W//'"
"grep -E '\d+' file"
"grep -E '\D' file"
"grep '\bfoo' file"
"grep '\Bfoo' file"
"grep '\<foo\>' file"
"sed -E 's/\t/X/'"
"sed -E 's/a/\t/'"
"grep -E 'a\tb' file"
"sed -E 's/\r\$//'"
"sed -E 's/\f//'"
"sed -E 's/\v//'"
"sed -E 's/\a//'"
"sed -E 's/\x41/a/'"
"sed -E 's/\o101/a/'"
"sed -E 's/\cA//'"
"sed -E 's/\\\`a/b/'"
"sed -E \"s/a\\\\'/b/\""
"grep -P 'x' file"
"grep -oP 'x' file"
"grep --perl-regexp 'x' file"
"sed -i 's/a/b/' file"
"sed -Ei 's/a/b/' file"
"sed -iE 's/(a)/X/' file"
"sed -es/a/b/E file"
"sed -e -E 's/a/b/' file"
"grep -E -e '-F' -e '\s' file"
"grep -E --regexp -F -e '\s' file"
"grep -E -ve -F -e '\s' file"
"sed -i '' 's/a/b/' file"
"sed -i .bak 's/a/b/' file"
"sed --in-place 's/a/b/' file"
"sed --in-place=.bak 's/a/b/' file"
"sed -r 's/(a)/b/'"
"sed -nr 's/(a)/b/p'"
"sed --regexp-extended 's/(a)/b/'"
"sed 's/(a|b)+/c/'"
"sed -n 's/a?/b/p'"
"sed 's#(a)#b#'"
"sed 's/foo/bar/'"
"sed -n 's/a/b/p'"
"sed -e 's/a/b/' file"
"sed -i.bak 's/a/b/' file"
"sed 's/\(a\)/\1/'"
"sed 's/a\{2\}/b/'"
"sed 's/[+?|()]/x/'"
"sed 's|a|b|'"
"LC_ALL=C sed 's/a/b/'"
"x=\"\$(printf '%s' \"\$y\" | sed 's/^[vV]//')\""
"sed -E 's/.*{x}/y/'"
"sed -E 's/a{,3}/b/'"
"x=\"\$(printf '%s' \"\$y\" | sed 's/a\+/b/')\""
"x=\$(printf '%s' \"\$y\" | grep -E '^\s*a' | head -1)"
"printf 'a' | tr -d 'b' | sed 's/a\+/b/'"
"if grep -q 'a\|b' file; then"
End

It "reports: $1"
When call scan_line "$1"
The status should be failure
The output should include "/dev/stdin:1:"
End
End

Describe "the scanner"
Parameters
"sed -E 's/a+/b/'"
"sed -n -E 's/(a)?/\1/p'"
"sed -nE 's/(a|b)+/c/p'"
"sed --posix -E 's/a+/b/'"
"grep -E '^[[:space:]]*x' file"
"grep -qE 'a|b' file"
"grep -Eq 'a|b' file"
"grep -iE 'a\+b' file"
"grep -fPATTERNS file"
"grep -eFOO -E 'a\+b' file"
"grep --extended-regexp 'a+' file"
"grep -E '1\.0\.0\+build' file"
"grep -E 'a\|b' file"
"sed -E 's/\+/plus/'"
"sed -E 's/\?//'"
"sed -E 'N;s/\n/ /'"
"grep -F 'a\+b' file"
"grep -iF 'a\sb' file"
"grep --fixed-strings 'a\+b' file"
"sed -E 's/\(a\)/x/'"
"sed -E 's/a{2}/b/'"
"sed -E 's/a{2,3}/b/'"
"sed -E 's/.*\{([^}]*)}.*/\1/'"
"sed -E 's/[{]/x/'"
"sed -E 's/a/{b}/'"
"sed -n -E \"s/.*\${image}:([0-9]+).*/\1/p\""
"sed -E 's/[+?|()]/x/'"
"sed -E 's/[[:space:]]*\$//'"
"sed -E 's/[^a-z0-9._\/-]/-/g'"
"sed -E 's|a|b|'"
"sed -E -e 's/a/b/' file"
"sed -E -i.bak 's/a/b/' file"
"sed -Ei.bak 's/a/b/' file"
"LC_ALL=C sed -E 's/a/b/'"
"grep -l 'a\\\\s' file"
"grep -- '-a' file"
"find . -exec grep -l foo {} \+"
"find . -exec grep -l foo {} \;"
"printf '%s' \"\$y\" | sed -E 's/^[vV]//' | tr -d ' \n\r'"
"grep -c 'a' file | tr -d '\s'"
"# sed 's/a\+/b/' is only prose here"
"  # grep -E '^\s*x'"
"echo \"falling back to grep for error counting\""
"autopep8 --in-place file"
"preg_match('/a\+/', \$b);"
End

It "accepts: $1"
When call scan_line "$1"
The status should be success
The output should equal ""
End
End

Describe "the scanner"
It "follows a pattern onto a continuation line"
When call scan_line "sed -n \\
  's/a\+/b/p'"
The status should be failure
The output should include "/dev/stdin:1:"
End

It "keeps the options before a quoted sed script that spans lines"
When call scan_line "sed -E '
  s/a/b/
'"
The status should be success
The output should equal ""
End

It "reports grep -P before a quoted pattern that spans lines"
When call scan_line "grep -P 'a
  b'"
The status should be failure
The output should include "grep -P is GNU-only"
End

It "reports GNU sed's tab escape, which other seds read as the letter t"
When call scan_line "sed -E 's/\t/X/'"
The status should be failure
The output should include '\t is GNU-only'
End

It "reads the E in sed -iE as the backup extension, not as -E"
When call scan_line "sed -iE 's/(a)/X/' file"
The status should be failure
The output should include "sed without -E"
End

It "reads the word after grep -e as its pattern, not as -F"
When call scan_line "grep -E -e '-F' -e '\s' file"
The status should be failure
The output should include '\s is GNU-only'
End

# A backtracking regex would not return on this input, so the scan runs under a deadline.
scan_long_brackets() {
  fixture="${SHELLSPEC_TMPBASE}/long-brackets.txt"
  printf "sed -E 's!%s%s'\n" "$(printf '%040000d' 0 | sed -E 's/00/[]/g')" "$1" >"$fixture"
  python3 -c 'import subprocess, sys; sys.exit(subprocess.run([sys.executable, sys.argv[1], sys.argv[2]], timeout=60).returncode)' \
    "$SCANNER" "$fixture"
}

It "stays fast on a long run of bracket expressions in an unclosed s command"
When call scan_long_brackets ""
The status should be success
The output should equal ""
End

It "reads a regex to its end after a long run of bracket expressions"
When call scan_long_brackets "{!x!"
The status should be failure
The output should include "a literal {"
End

It "fails loudly when given nothing to scan"
When run python3 "$SCANNER"
The status should equal 2
The output should include "usage"
End
End
End
