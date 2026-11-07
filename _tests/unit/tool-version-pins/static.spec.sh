#!/usr/bin/env shellspec
# Static checks across every action.yml: nothing fetches a tool at a floating version, and every
# pin is written in the shape Renovate's githubActionsVersions preset can track. The per-action
# tool-pins.spec.sh files test what each action does with its pins.

Describe "tool version pins"
CHECK_PINS="${PROJECT_ROOT}/_tests/unit/tool-version-pins/check_pins.py"

Describe "every action in this repository"
It "fetches nothing at a floating version and keeps its pins trackable"
When run python3 "${CHECK_PINS}" "${PROJECT_ROOT}"
The status should be success
The stdout should match pattern "checked * renovate comments"
End
End

Describe "the check itself"
before() {
  TREE=$(mktemp -d)
  mkdir -p "${TREE}/sample"
}
BeforeEach 'before'

after() {
  rm -rf "${TREE}"
}
AfterEach 'after'

# A tree holding one action, with one valid pin so the only violation is the one under test.
write_action() {
  printf '%s\n' \
    "inputs:" \
    "  sample-version:" \
    "    description: 'Sample'" \
    "    default: '${2:-}'" \
    "runs:" \
    "  steps:" \
    "    - name: Pin" \
    "      env:" \
    "        # renovate: datasource=npm depName=sample" \
    "        SAMPLE_VERSION: '1.2.3'" \
    "      run: ${1}" >"${TREE}/sample/action.yml"
}

Describe "on an action.yml with a floating reference"
Parameters
"corepack prepare pnpm@latest --activate"
"corepack prepare yarn@stable --activate"
"npx --yes prettier --check ."
"npx -y prettier --check ."
"npx prettier --check ."
"bun-version: latest"
End

It "fails on: $1"
write_action "$1"
When run python3 "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "floating tool reference"
End
End

It "accepts npx --no-install"
write_action "npx --no-install prettier --check ."
When run python3 "${CHECK_PINS}" "${TREE}"
The status should be success
The stdout should match pattern "checked * renovate comments"
End

Describe "on a version input defaulting to a floating keyword"
Parameters
"latest"
"stable"
End

It "fails on: $1"
write_action "true" "$1"
When run python3 "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "defaults to $1"
End
End

Describe "on a renovate comment the preset cannot match"
Parameters
"        SAMPLE: '1.2.3'"
"        sample_version: '1.2.3'"
"        OTHER: 'x'"
End

It "fails on the variable line: $1"
printf '%s\n' "runs:" "  steps:" "    - run: true" "      env:" \
  "        # renovate: datasource=npm depName=sample" "$1" >"${TREE}/sample/action.yml"
When run python3 "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "outside the preset's shape"
End
End

Describe "on a renovate comment over a range"
Parameters
"^1.2.3"
"latest"
"1"
End

It "fails on the value: $1"
printf '%s\n' "runs:" "  steps:" "    - run: true" "      env:" \
  "        # renovate: datasource=npm depName=sample" "        SAMPLE_VERSION: '$1'" >"${TREE}/sample/action.yml"
When run python3 "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "not an exact version: $1"
End
End

It "fails on an env reference its own step does not define"
printf '%s\n' "runs:" "  steps:" "    - uses: a/b@1" "      env:" \
  "        # renovate: datasource=npm depName=sample" "        SAMPLE_VERSION: '1.2.3'" \
  "      with:" "        version: \${{ env.SAMPL_VERSION }}" >"${TREE}/sample/action.yml"
When run python3 "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "env.SAMPL_VERSION is not defined"
End

It "fails on a tree with no renovate comments"
printf '%s\n' "runs:" "  steps:" "    - run: true" >"${TREE}/sample/action.yml"
When run python3 "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "no renovate comments found"
End
End
End
