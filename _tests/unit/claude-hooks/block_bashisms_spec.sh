#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/block-bashisms.sh
# Tests POSIX compliance checking hook that blocks bash-isms in shell/action files

HOOK=".claude/hooks/block-bashisms.sh"

# Helper: make_input FILE_PATH CONTENT
# Builds the JSON input the hook expects from stdin
make_input() {
  local file_path="$1"
  local content="$2"
  # Use jq to safely encode the content as JSON
  printf '{"tool_input":{"file_path":"%s","new_string":%s}}' \
    "$file_path" \
    "$(printf '%s' "$content" | jq -Rs .)"
}

Describe ".claude/hooks/block-bashisms.sh"

  Describe "file path filtering"

    Context "when file path is empty"
      Data
        | '{"tool_input":{}}'
      End
      It "exits 0 without output"
        When run script "$HOOK"
        The status should be success
        The output should equal ""
      End
    End

    Context "when file path is not a shell or action file"
      Data
        | '{"tool_input":{"file_path":"/some/file.py","new_string":"[[ $x ]]"}}'
      End
      It "exits 0 without checking content"
        When run script "$HOOK"
        The status should be success
        The output should equal ""
      End
    End

    Context "when file path is a .sh file"
      It "processes the content for bash-isms"
        input=$(make_input "/some/script.sh" '[[ $x == y ]]')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "permissionDecision"
      End
    End

    Context "when file path is a .bash file"
      It "processes .bash files"
        input=$(make_input "/some/script.bash" '[[ $x == y ]]')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

    Context "when file path is an action.yml file"
      It "processes action.yml files"
        input=$(make_input "/myaction/action.yml" '[[ $x == y ]]')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

    Context "when file path is an action.yaml file"
      It "processes action.yaml files"
        input=$(make_input "/myaction/action.yaml" '[[ $x == y ]]')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

    Context "when content is empty"
      Data
        | '{"tool_input":{"file_path":"/script.sh","new_string":""}}'
      End
      It "exits 0 without output"
        When run script "$HOOK"
        The status should be success
        The output should equal ""
      End
    End

    Context "when content contains only comments"
      It "exits 0 without output (comments are stripped)"
        input=$(make_input "/script.sh" "# [[ is fine in comments
# function foo() { is fine too")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The status should be success
        The output should equal ""
      End
    End

  End

  Describe "double bracket detection [[ ]]"

    Context "when content contains [["
      It "blocks with deny decision"
        input=$(make_input "/script.sh" 'if [[ $x == y ]]; then echo ok; fi')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End

      It "includes [[ description in reason"
        input=$(make_input "/script.sh" 'if [[ $x == y ]]; then echo ok; fi')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "[[ ]] is not POSIX"
      End
    End

    Context "when content uses POSIX [ ] test"
      It "allows single bracket tests"
        input=$(make_input "/script.sh" 'if [ "$x" = "y" ]; then echo ok; fi')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "regex operator detection =~"

    Context "when content contains =~"
      It "blocks with deny decision"
        input=$(make_input "/script.sh" 'if [[ $x =~ ^foo ]]; then echo ok; fi')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End

      It "includes =~ description in reason"
        input=$(make_input "/script.sh" 'if echo "$x" | grep -qE "^foo"; then :; fi
x=test
if echo "$x" =~ pattern; then :; fi')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "=~ regex operator is bash-only"
      End
    End

  End

  Describe "declare/typeset detection"

    Context "when content uses declare"
      It "blocks declare -a"
        input=$(make_input "/script.sh" 'declare -a myarray')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "declare/typeset is not POSIX"
      End

      It "blocks declare -i"
        input=$(make_input "/script.sh" 'declare -i count=0')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

    Context "when content uses typeset"
      It "blocks typeset"
        input=$(make_input "/script.sh" 'typeset foo=bar')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "declare/typeset is not POSIX"
      End
    End

    Context "when using plain assignment"
      It "allows plain variable assignment"
        input=$(make_input "/script.sh" 'count=0
name=foo')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "function keyword detection"

    Context "when content uses function keyword"
      It "blocks function keyword syntax"
        input=$(make_input "/script.sh" 'function my_func() { echo hello; }')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "function keyword is not POSIX"
      End
    End

    Context "when using POSIX function syntax"
      It "allows POSIX name() { } syntax"
        input=$(make_input "/script.sh" 'my_func() { echo hello; }')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "echo flag detection"

    Context "when content uses echo -e"
      It "blocks echo -e"
        input=$(make_input "/script.sh" 'echo -e "hello\nworld"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "echo -e/-n is not portable"
      End
    End

    Context "when content uses echo -n"
      It "blocks echo -n"
        input=$(make_input "/script.sh" 'echo -n "no newline"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "echo -e/-n is not portable"
      End
    End

    Context "when using printf instead of echo"
      It "allows printf"
        input=$(make_input "/script.sh" 'printf "%s\n" "hello world"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

    Context "when using plain echo without flags"
      It "allows echo without flags"
        input=$(make_input "/script.sh" 'echo "hello world"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "read flag detection"

    Context "when content uses read -p"
      It "blocks read -p"
        input=$(make_input "/script.sh" 'read -p "Enter value: " val')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "read -p/-a are bash-only"
      End
    End

    Context "when content uses read -a"
      It "blocks read -a"
        input=$(make_input "/script.sh" 'read -a myarray <<< "a b c"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End
    End

    Context "when using plain read"
      It "allows plain read"
        input=$(make_input "/script.sh" 'read val')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "bash-only variable detection"

    Context "when content uses \$RANDOM"
      It "blocks \$RANDOM"
        input=$(make_input "/script.sh" 'num=$RANDOM')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "RANDOM"
      End
    End

    Context "when content uses \$BASH_VERSION"
      It "blocks \$BASH_VERSION"
        input=$(make_input "/script.sh" 'echo $BASH_VERSION')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End
    End

    Context "when content uses \$BASHPID"
      It "blocks \$BASHPID"
        input=$(make_input "/script.sh" 'pid=$BASHPID')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End
    End

    Context "when content uses \$BASH_SOURCE"
      It "blocks \$BASH_SOURCE"
        input=$(make_input "/script.sh" 'dir=$(dirname "$BASH_SOURCE")')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "BASH_SOURCE"
      End
    End

  End

  Describe "herestring detection <<<"

    Context "when content uses herestring"
      It "blocks <<< herestring"
        input=$(make_input "/script.sh" 'read var <<< "value"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "herestring is bash-only"
      End
    End

    Context "when using heredoc instead"
      It "allows regular heredoc << EOF"
        input=$(make_input "/script.sh" 'cat << EOF
some content
EOF')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "bash-only redirect detection &>"

    Context "when content uses &>"
      It "blocks &> redirect"
        input=$(make_input "/script.sh" 'command &> /dev/null')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "&> redirect is bash-only"
      End
    End

    Context "when using POSIX redirect"
      It "allows > /dev/null 2>&1"
        input=$(make_input "/script.sh" 'command > /dev/null 2>&1')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "pipefail detection"

    Context "when content uses set -o pipefail"
      It "blocks set -o pipefail"
        input=$(make_input "/script.sh" 'set -o pipefail')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "pipefail is not POSIX"
      End
    End

    Context "when content uses set -euo pipefail"
      It "blocks set -euo pipefail"
        input=$(make_input "/script.sh" 'set -euo pipefail')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "pipefail is not POSIX"
      End
    End

    Context "when using POSIX set -eu"
      It "allows set -eu"
        input=$(make_input "/script.sh" 'set -eu')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "source keyword detection"

    Context "when content uses source"
      It "blocks source keyword"
        input=$(make_input "/script.sh" 'source ./lib/helpers.sh')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "source is bash-only"
      End
    End

    Context "when using POSIX dot sourcing"
      It "allows . (dot) for sourcing"
        input=$(make_input "/script.sh" '. ./lib/helpers.sh')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "array syntax detection"

    Context "when content uses array assignment"
      It "blocks var=() array assignment"
        input=$(make_input "/script.sh" 'myarray=(one two three)')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "Array assignment var=() is bash-only"
      End
    End

    Context "when content uses array subscript"
      It "blocks \${arr[0]} subscript access"
        input=$(make_input "/script.sh" 'echo ${myarray[0]}')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "Array subscript"
      End
    End

    Context "when using space-delimited strings"
      It "allows space-delimited string variables"
        input=$(make_input "/script.sh" 'items="one two three"
for item in $items; do echo "$item"; done')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "multiple violations"

    Context "when content has multiple bash-isms"
      It "reports all violations in the reason"
        input=$(make_input "/script.sh" 'if [[ $x =~ ^foo ]]; then
  echo -e "matched\n"
fi')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
        The output should include "[[ ]] is not POSIX"
        The output should include "=~ regex operator is bash-only"
        The output should include "echo -e/-n is not portable"
      End
    End

  End

  Describe "POSIX-compliant content"

    Context "when content is fully POSIX-compliant"
      It "produces no output for clean sh code"
        input=$(make_input "/script.sh" 'set -eu
my_func() {
  printf "%s\n" "$1"
}
if [ "$1" = "hello" ]; then
  my_func "world"
fi')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

    Context "when action.yml uses POSIX shell patterns"
      It "produces no output for compliant action.yml content"
        input=$(make_input "/myaction/action.yml" 'set -eu
printf "%s=%s\n" "key" "$value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "output format"

    Context "when a violation is detected"
      It "outputs valid JSON"
        input=$(make_input "/script.sh" '[[ $x ]]')
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -e '.hookSpecificOutput.permissionDecision'"
        The output should include "deny"
      End

      It "includes hookEventName PreToolUse"
        input=$(make_input "/script.sh" '[[ $x ]]')
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -e '.hookSpecificOutput.hookEventName'"
        The output should include "PreToolUse"
      End

      It "includes permissionDecisionReason with POSIX violation message"
        input=$(make_input "/script.sh" '[[ $x ]]')
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.permissionDecisionReason'"
        The output should include "POSIX violation"
        The output should include "All scripts must be POSIX sh"
      End
    End

  End

End