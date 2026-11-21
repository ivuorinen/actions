#!/usr/bin/env shellspec
# Unit tests for the feature columns generate_listing.cjs writes into the README catalog.
#
# A feature has to come from what an action does or documents, read from its parsed
# action.yml: a comment, a step's text or a setting that turns a cache off says nothing.

Describe "generate_listing.cjs features"
GENERATOR="${PROJECT_ROOT}/generate_listing.cjs"
FIX_ROOT="${SHELLSPEC_TMPBASE}/generate-listing"

# write_action NAME: an action whose action.yml is read from stdin.
write_action() {
  mkdir -p "$FIX_ROOT/$1"
  cat >"$FIX_ROOT/$1/action.yml"
}

# features DIR: the features the catalog lists for the action in DIR, comma separated.
features() {
  node -e 'console.log(require(process.argv[1]).getActionDetails(process.argv[2]).features.join(","))' \
    "$GENERATOR" "$1"
}

It "lists neither feature for a comment, step text or a cache turned off"
write_action quiet <<'EOF'
name: Quiet
description: Does one thing.
runs:
  using: composite
  steps:
    # A comment that mentions detect and actions/cache, which the action never runs.
    - shell: sh
      run: |
        echo "no detection here; cache: none"
    - uses: actions/setup-node@0000000000000000000000000000000000000000
      with:
        package-manager-cache: false
        cache: false
    - uses: docker/build-push-action@0000000000000000000000000000000000000000
      with:
        no-cache: true
EOF
When call features "$FIX_ROOT/quiet"
The output should equal ""
End

It "lists Auto-detection when the name, description or an input's description says so"
write_action input-says <<'EOF'
name: Input says
description: Builds a project.
inputs:
  go-version:
    description: Go version. When empty, it is detected from go.mod.
runs:
  using: composite
  steps: []
EOF
write_action described <<'EOF'
name: Described
description: Detects the language version of a project.
runs:
  using: composite
  steps: []
EOF
write_action thing-detect <<'EOF'
name: Thing detect
description: Reports a thing.
runs:
  using: composite
  steps: []
EOF
When call features "$FIX_ROOT/input-says"
The output should equal "Auto-detection"
Assert [ "$(features "$FIX_ROOT/described")" = "Auto-detection" ]
Assert [ "$(features "$FIX_ROOT/thing-detect")" = "Auto-detection" ]
End

It "lists Caching for an actions/cache step, a cache or cache-from setting, or a cache input"
write_action cache-step <<'EOF'
name: Cache step
description: Caches.
runs:
  using: composite
  steps:
    - uses: actions/cache@0000000000000000000000000000000000000000
      with:
        path: ~/.cache
        key: k
EOF
write_action cache-setting <<'EOF'
name: Cache setting
description: Caches through setup-go.
runs:
  using: composite
  steps:
    - uses: actions/setup-go@0000000000000000000000000000000000000000
      with:
        cache: true
EOF
write_action cache-input <<'EOF'
name: Cache input
description: Caches when asked.
inputs:
  cache-from:
    description: Where to read a build cache from.
runs:
  using: composite
  steps: []
EOF
When call features "$FIX_ROOT/cache-step"
The output should equal "Caching"
Assert [ "$(features "$FIX_ROOT/cache-setting")" = "Caching" ]
Assert [ "$(features "$FIX_ROOT/cache-input")" = "Caching" ]
End

# has_feature DIR FEATURE: succeeds when the catalog lists FEATURE for the action in DIR.
has_feature() {
  case ",$(features "$1")," in
  *",$2,"*) return 0 ;;
  *) return 1 ;;
  esac
}

# lacks_feature DIR FEATURE: succeeds when the catalog does not list FEATURE for DIR.
lacks_feature() {
  ! has_feature "$1" "$2"
}

# The actions whose README entries this reading changed.
It "lists the repository's actions by what they do"
When call features "${PROJECT_ROOT}/php-tests"
The output should include "Caching"
The output should include "Auto-detection"
Assert has_feature "${PROJECT_ROOT}/language-version-detect" Auto-detection
Assert lacks_feature "${PROJECT_ROOT}/npm-publish" Caching
Assert lacks_feature "${PROJECT_ROOT}/ansible-lint-fix" Auto-detection
End
End
