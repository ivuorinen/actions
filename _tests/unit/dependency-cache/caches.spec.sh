#!/usr/bin/env shellspec
# No action saves a cache from an event that can run pull-request code under the default
# branch's cache scope, such as pull_request_target, issue_comment or workflow_run: a later run
# there would restore and execute what it saved. A cache is restored with actions/cache/restore
# and saved with actions/cache/save only from a push, a schedule or a manual dispatch, and the
# setup actions' own caches, which save from any event, are off. node_modules is never cached:
# the dependencies install on every run.

TRUSTED_EVENTS="contains(fromJSON('[\"push\", \"schedule\", \"workflow_dispatch\"]'), github.event_name)"

# steps_using PATTERN: "<action>: <step name>|<if>" for each step of every action whose uses:
# matches PATTERN.
steps_using() {
  for action_file in "${PROJECT_ROOT}"/*/action.yml; do
    action=${action_file#"${PROJECT_ROOT}"/}
    action=${action%/action.yml}
    yq -r ".runs.steps[] | select((.uses // \"\") | test(\"$1\")) | (.name // \"?\") + \"|\" + (.if // \"\")" \
      "$action_file" | sed "s|^|$action: |"
  done
}

# restored_node_modules: each action whose cache step names node_modules, one per line.
restored_node_modules() {
  for action_file in "${PROJECT_ROOT}"/*/action.yml; do
    yq -r '.runs.steps[] | select((.uses // "") | test("^actions/cache(/restore)?@")) | .with.path // ""' "$action_file" |
      grep -q 'node_modules' && printf '%s\n' "${action_file#"${PROJECT_ROOT}"/}"
  done
  return 0
}

# untrusted_saves: each save step whose condition lets another event through.
untrusted_saves() {
  steps_using '^actions/cache/save@' | grep -v -F "$TRUSTED_EVENTS"
  return 0
}

# setup_caches_on: each setup step whose own cache is not turned off in so many words. setup-go and
# setup-node keep a cache when the input is left out. (yq's // would read an explicit false as
# missing, so the value is compared as text.)
setup_caches_on() {
  for action_file in "${PROJECT_ROOT}"/*/action.yml; do
    action=${action_file#"${PROJECT_ROOT}"/}
    yq -r '.runs.steps[]
      | select(
          (((.uses // "") | test("^actions/setup-(go|dotnet)@")) and ((.with.cache | tostring) != "false"))
          or (((.uses // "") | test("^actions/setup-node@")) and ((.with."package-manager-cache" | tostring) != "false")))
      | .uses' "$action_file" | sed "s|^|${action%/action.yml}: |"
  done
}

Describe "Actions caches"
It "never hold node_modules"
When call restored_node_modules
The output should equal ""
End

# actions/cache saves in its post step whatever the event; the save is the action's to guard.
It "are never written by actions/cache, which saves on any event"
When call steps_using '^actions/cache@'
The output should equal ""
End

It "are saved only from a push, a schedule or a manual dispatch"
When call untrusted_saves
The output should equal ""
End

It "are saved by every action that restores one"
When call steps_using '^actions/cache/save@'
The lines of output should equal "$(steps_using '^actions/cache/restore@' | wc -l)"
End

It "are not kept by setup-go, setup-dotnet or setup-node"
When call setup_caches_on
The output should equal ""
End

Describe "the dependency install"
Parameters
eslint-lint install-deps
prettier-lint install-deps
pr-lint install-node
End

# pr-lint installs only for a Node project; nothing about a cache may decide it.
It "runs in $1 whatever a cache holds"
When call yq -r ".runs.steps[] | select(.id == \"$2\") | .if // \"\"" "${PROJECT_ROOT}/$1/action.yml"
The output should not include "cache"
End
End
End
