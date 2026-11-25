#!/usr/bin/env shellspec
# The push token never stays in git config. Each checkout persists none, and the one step that
# pushes, git-auto-commit-action, gets the token in its own environment through a git credential
# helper, so code that runs before it finds no token in .git/config. Every action that pushes
# fixes gives its push step the same environment.

# persistence ACTION: each checkout's persist-credentials value, one per line.
persistence() {
  yq -r '.runs.steps[] | select((.uses // "") | test("^actions/checkout@")) | .with."persist-credentials"' \
    "${PROJECT_ROOT}/$1/action.yml"
}

# push_env ACTION: the push step's environment, as one line of JSON.
push_env() {
  yq -o=json -I=0 '.runs.steps[] | select((.uses // "") | test("^stefanzweifel/git-auto-commit-action@")) | .env' \
    "${PROJECT_ROOT}/$1/action.yml"
}

Describe "push credentials"
Parameters
ansible-lint-fix
biome-lint
eslint-lint
pre-commit
prettier-lint
python-lint-fix
terraform-lint-fix
End

It "$1 persists no token at checkout"
When call persistence "$1"
The output should equal "false"
End

It "$1 gives its push step the environment ansible-lint-fix does"
When call push_env "$1"
The output should equal "$(push_env ansible-lint-fix)"
End
End

It "takes the token from the action's input, or the workflow's"
When call push_env ansible-lint-fix
The output should include '"GH_TOKEN":"${{ inputs.token || github.token }}"'
End

# A suppression would leave the finding standing: zizmor reports a persisted checkout token.
It "suppresses no zizmor finding in an action"
When call grep -l 'zizmor: ignore' "${PROJECT_ROOT}"/*/action.yml
The status should be failure
End

Describe "the push step's credential helper"
# fill_credential: git's answer to a credential request for github.com, in a repository whose own
# config names another helper, with the push step's GIT_CONFIG_* entries and GH_TOKEN set.
fill_credential() {
  local env_json repo
  env_json=$(push_env ansible-lint-fix)
  repo=$(mktemp -d "${SHELLSPEC_TMPBASE}/credential.XXXXXX")
  git -C "$repo" init -q
  git -C "$repo" config credential.helper '!f() { echo username=other; echo password=other-token; }; f'
  printf 'protocol=https\nhost=github.com\n\n' | (
    cd "$repo" &&
      env GH_TOKEN=step-token GIT_TERMINAL_PROMPT=0 \
        GIT_CONFIG_COUNT="$(jq -r .GIT_CONFIG_COUNT <<<"$env_json")" \
        GIT_CONFIG_KEY_0="$(jq -r .GIT_CONFIG_KEY_0 <<<"$env_json")" \
        GIT_CONFIG_VALUE_0="$(jq -r .GIT_CONFIG_VALUE_0 <<<"$env_json")" \
        GIT_CONFIG_KEY_1="$(jq -r .GIT_CONFIG_KEY_1 <<<"$env_json")" \
        GIT_CONFIG_VALUE_1="$(jq -r .GIT_CONFIG_VALUE_1 <<<"$env_json")" \
        git credential fill
  )
}

It "answers with the step's token, not a helper the repository configures"
When call fill_credential
The status should be success
The output should include "username=x-access-token"
The output should include "password=step-token"
The output should not include "other-token"
End
End
