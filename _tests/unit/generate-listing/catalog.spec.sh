#!/usr/bin/env shellspec
# Unit tests for the README catalog generate_listing.mjs prints and writes: which directories
# are actions, where an action in no category goes, and when the run fails.

Describe "generate_listing.mjs catalog"
GENERATOR="${PROJECT_ROOT}/generate_listing.mjs"
CASES="${SHELLSPEC_TMPBASE}/generate-listing-catalog"

# in_case NAME: a fresh directory for one example, made the working directory.
in_case() {
  rm -rf "${CASES:?}/$1"
  mkdir -p "$CASES/$1"
  cd "$CASES/$1" || return 1
}

# write_action NAME: an action in the working directory, its action.yml read from stdin.
write_action() {
  mkdir -p "$1"
  cat >"$1/action.yml"
}

# category_headings: the catalog's category headings, in order.
category_headings() {
  node "$GENERATOR" | grep '^#### '
}

It "lists an action in no category under Other, after the categories"
in_case other
write_action lonely <<'EOF'
name: Lonely
description: Belongs to no category.
runs:
  using: composite
  steps: []
EOF
write_action stale <<'EOF'
name: Stale
description: Closes stale issues.
runs:
  using: composite
  steps: []
EOF
When call category_headings
The line 1 of output should equal "#### 📦 Repository (1 action)"
The line 2 of output should equal "#### 📦 Other (1 action)"
End

It "lists only the directories that hold an action.yml"
in_case mixed
mkdir docs
write_action tool <<'EOF'
name: Tool
description: Does one thing.
runs:
  using: composite
  steps: []
EOF
When run node "$GENERATOR"
The status should be success
The output should include '[`tool`][tool]'
The output should not include '[`docs`]'
End

It "fails, naming the file, when an action.yml does not parse"
in_case broken
write_action broken <<'EOF'
name: [
EOF
When run node "$GENERATOR"
The status should be failure
The stderr should include "broken/action.yml"
End

Describe "--update"
It "writes the catalog between the README's LISTING markers"
in_case update
write_action tool <<'EOF'
name: Tool
description: Does one thing.
runs:
  using: composite
  steps: []
EOF
printf '%s\n' 'Before' '<!--LISTING-->' 'old catalog' '<!--/LISTING-->' 'After' >README.md
When run node "$GENERATOR" --update
The status should be success
The output should include "Updated catalog with 1 action"
The line 1 of contents of file README.md should equal 'Before'
The contents of file README.md should include '[`tool`][tool]'
The contents of file README.md should not include 'old catalog'
The contents of file README.md should include 'After'
End

It "fails without the LISTING markers, leaving the README as it was"
in_case no-markers
write_action tool <<'EOF'
name: Tool
description: Does one thing.
runs:
  using: composite
  steps: []
EOF
printf '%s\n' 'Just text' >README.md
When run node "$GENERATOR" --update
The status should be failure
The stderr should include "Could not find LISTING markers"
The contents of file README.md should equal 'Just text'
End
End
End
