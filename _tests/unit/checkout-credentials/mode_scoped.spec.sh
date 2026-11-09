#!/usr/bin/env shellspec
# The checkout token stays in git config only when the action pushes with it.
# Each row is an action and the input condition guarding its push step.

# Prints the checkout's persist-credentials line, then the push step's if line.
credential_scope() {
  grep -E 'persist-credentials:' "$1/action.yml"
  grep -E -B1 'uses: stefanzweifel/git-auto-commit-action@' "$1/action.yml" | head -n 1
}

Describe "checkout token persistence"
Parameters
biome-lint "inputs.mode == 'fix'" "inputs.mode == 'fix' && success()"
eslint-lint "inputs.mode == 'fix'" "inputs.mode == 'fix' && success()"
prettier-lint "inputs.mode == 'fix'" "inputs.mode == 'fix' && success()"
terraform-lint-fix "inputs.auto-fix == 'true'" "steps.check-files.outputs.found == 'true' && inputs.auto-fix == 'true' && fromJSON(steps.fix.outputs.fixed_count) > 0"
End

It "$1 persists the token and pushes only when $2"
When call credential_scope "$1"
The line 1 of output should include "persist-credentials: \${{ $2 }}"
The line 2 of output should equal "      if: $3"
The line 2 of output should include "$2"
End
End
