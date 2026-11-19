#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/route-bash-to-context-mode.sh
# Tests that the hook lets only git commit and git push run in Bash and denies the rest

HOOK=".claude/hooks/route-bash-to-context-mode.sh"

# Helper: make_input COMMAND
make_input() {
  printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)"
}

Describe ".claude/hooks/route-bash-to-context-mode.sh"

Describe "a single git commit or git push in a listed form"
Parameters
"git commit -m message"
"git commit -m 'fix: a change; with & | \$(punctuation)'"
"git commit -F /tmp/msg.txt"
"git commit --amend --no-edit"
"git commit -s -m x"
"git commit --signoff --quiet -m x"
"git commit -q -F /tmp/msg.txt"
"git push"
"  git push origin main"
"git push -u origin fix/a-branch"
"git push --set-upstream origin main"
"git push --tags"
"git push --follow-tags origin"
"git push --dry-run origin main"
"git push --force-with-lease origin HEAD:refs/heads/main"
"git push --force-with-lease=main origin main"
"git push --force-with-lease=main:abc123 origin main"
End

It "allows: $1"
When call hook_run "$HOOK" "$(make_input "$1")"
The status should be success
The output should equal ""
End
End

Describe "every other command"
Parameters
"ls -la"
"git status"
"git commitx"
"make lint"
"echo git commit"
End

It "denies: $1"
When call hook_run "$HOOK" "$(make_input "$1")"
The status should be success
The output should include '"permissionDecision":"deny"'
End
End

Describe "a git commit or git push that would run another command"
# In these rows, \n stands for a line break in the command.
Parameters
'git commit -m x && ls'
'git push; ls'
'git push origin main | cat'
'git push &'
'git commit -m "$(date)"'
'git commit -m `date`'
'git push <(ls)'
'git push =(ls)'
'git commit -m x\nls'
"git commit -F - <<'EOF'\nmsg\nEOF\nls"
"git commit -F - <<'EOF'\nmsg\nEOF\nls\nEOF"
"git commit -F - #<<'EOF'\nls\nEOF"
"git commit -F - \\\\<<'EOF'\nls\nEOF"
"git commit -m 'open <<'EOF'\nls\nEOF"
'git commit -F - <<EOF\n$(date)\nEOF'
End

It "denies: $1"
When call hook_field "$HOOK" "$(make_input "$(printf '%b' "$1")")" .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End
End

Describe "a git commit or git push outside the listed forms"
# In these rows, \n stands for a line break in the command.
Parameters
'git push origin main > out.txt'
'git push ${x}'
'git commit -F - <<"MSG"\nmsg\nMSG'
'git commit -F - <<-EOF\nmsg\nEOF'
"git commit -F - <<'EOF' <<'END'\nmsg\nEOF\nEND"
'git commit'
'git commit --amend'
'git commit -m =ls'
'git commit -F =ls'
'git push +main'
'git push origin +main'
'git push origin :main'
'git push ../other main'
'git push /tmp/repo main'
'git push ext::sh'
'git push https://example.com/repo.git main'
End

It "denies: $1"
When call hook_field "$HOOK" "$(make_input "$(printf '%b' "$1")")" .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End
End

Describe "a git option that is not listed"
# git accepts any unambiguous abbreviation of an option, so the hook lists the ones it allows.
Parameters
'git commit --no-verify -m x'
'git commit -n -m x'
'git commit -a -m x'
'git push --receive-pack=x origin'
'git push --rec=x origin'
'git push --exec=x origin'
'git push --force origin main'
End

It "denies: $1"
When call hook_field "$HOOK" "$(make_input "$1")" .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End
End

Describe "a commit message in a heredoc with a quoted delimiter"
# In these rows, \n stands for a line break in the command.
Parameters
"git commit -F - <<'EOF'\nfix: a change\n\nThe body.\nEOF"
"git commit -F - <<'MSG'\nfix: mention \$(this) and \`that\` as text\nMSG"
"git commit --amend -s -F - <<'EOF'\nfix: a change\nEOF"
End

It "allows: $1"
When call hook_run "$HOOK" "$(make_input "$(printf '%b' "$1")")"
The status should be success
The output should equal ""
End
End

Describe "deny reason"
It "is valid JSON that points to context-mode"
When call hook_field "$HOOK" "$(make_input ls)" .hookSpecificOutput.permissionDecisionReason
The status should be success
The output should include "ctx_execute"
The output should include ".claude/rules/context-mode-always.md"
End
End

Describe "input handling"
It "allows valid input with no command"
When call hook_run "$HOOK" '{"tool_input":{}}'
The status should be success
The output should equal ""
End

It "denies input that is not JSON"
When call hook_field "$HOOK" "not json" .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End

# Removing the byte would leave an allowed git push, so the hook must judge the bytes as sent.
It "denies a raw control byte inside the input, which is not JSON"
When call hook_field "$HOOK" "{\"tool_input\":{\"command\":\"git pu$(printf '\001')sh origin main\"}}" \
  .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End

It "denies a raw NUL inside the input, which a shell variable would drop"
When run sh -c 'printf "{\"tool_input\":{\"command\":\"git pu\\000sh origin main\"}}" | sh "$1"' _ "$HOOK"
The status should be success
The output should include '"permissionDecision":"deny"'
End

It "denies an escaped control character, which the command keeps"
When call hook_field "$HOOK" '{"tool_input":{"command":"git pu\u0001sh origin main"}}' \
  .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End
End

End
