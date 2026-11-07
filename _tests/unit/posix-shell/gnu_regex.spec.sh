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
"grep -P 'x' file"
"grep -oP 'x' file"
"grep --perl-regexp 'x' file"
"sed -i 's/a/b/' file"
"sed -Ei 's/a/b/' file"
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
"grep --extended-regexp 'a+' file"
"grep -E '1\.0\.0\+build' file"
"grep -E 'a\|b' file"
"sed -E 's/\+/plus/'"
"sed -E 's/\?//'"
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

It "stays fast on a long run of bracket expressions in an unclosed s command"
scan_long_brackets() {
  printf "sed -E 's!%s'\n" "$(printf '%040000d' 0 | sed -E 's/00/[]/g')" | python3 "$SCANNER" /dev/stdin
}
When call scan_long_brackets
The status should be success
The output should equal ""
End

It "fails loudly when given nothing to scan"
When run python3 "$SCANNER"
The status should equal 2
The output should include "usage"
End
End
End
