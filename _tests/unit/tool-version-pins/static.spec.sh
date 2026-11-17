#!/usr/bin/env shellspec
# Static checks across every action.yml: nothing fetches a tool at a floating version, and every
# pin is written in a shape Renovate tracks: the githubActionsVersions preset, or one of the
# repository's own managers in .github/renovate.json. The per-action tool-pins.spec.sh files test
# what each action does with its pins.

Describe "tool version pins"
CHECK_PINS="${PROJECT_ROOT}/_tests/unit/tool-version-pins/check_pins.py"

Describe "every action in this repository"
It "fetches nothing at a floating version and keeps its pins trackable"
When call _harness_python "${CHECK_PINS}" "${PROJECT_ROOT}"
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
"npx >out.txt prettier --check ."
"npx>out.txt prettier --check ."
"npx -p prettier prettier --check ."
"npx --package=prettier prettier --check ."
"npx -- prettier --check ."
"bunx prettier --check ."
"bunx --no prettier --check ."
"npx --no-audit prettier --check ."
"CI=1 'npx' prettier --check ."
"sh -c 'npx prettier --check .'"
"bun x prettier --check ."
"npm exec prettier -- --check ."
"npm x prettier -- --check ."
"npm init vite"
"pnpx prettier --check ."
"uvx ruff check ."
"pipx run ruff check ."
"pnpm dlx prettier --check ."
"yarn dlx prettier --check ."
"npx prettier --no --check ."
"bunx prettier --no-install --check ."
"corepack pnpm dlx prettier --check ."
"sh -c \"npx prettier \$files\""
"npm --prefix . exec prettier -- --check ."
"pnpm -C . dlx prettier --check ."
"yarn --cwd . dlx prettier --check ."
"pnpm create vite"
"bun create vite"
"uv tool run ruff check ."
"uv run --with ruff ruff check ."
"sudo -uroot npx prettier --check ."
"git clone https://example.com/repo@main"
"bun-version: latest"
End

It "fails on: $1"
write_action "$1"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "floating tool reference"
End
End

Describe "on an action.yml that fetches nothing"
Parameters
"npx --no-install prettier --check ."
"npx --no prettier --check ."
"bunx --no-install prettier --check ."
"command -v npx >/dev/null 2>&1 || exit 1"
"command -v bunx >/dev/null 2>&1 || exit 1"
'echo "::error::running Prettier requires npx"'
'echo "npx is required"'
"npm exec --no -- prettier --check ."
"npm init -y"
"pnpm init"
"uv run ruff check ."
End

It "accepts: $1"
write_action "$1"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be success
The stdout should match pattern "checked * renovate comments"
End
End

It "reads a here-document fed to a shell"
printf '%s\n' "runs:" "  steps:" "    - name: Pin" "      env:" \
  "        # renovate: datasource=npm depName=sample" "        SAMPLE_VERSION: '1.2.3'" \
  "      run: |" "        sh <<'EOF'" "        npx prettier --check ." "        EOF" >"${TREE}/sample/action.yml"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "sample:9: floating tool reference: npx prettier --check ."
End

Describe "on a version input defaulting to a floating keyword"
Parameters
"latest"
"stable"
End

It "fails on: $1"
write_action "true" "$1"
When call _harness_python "${CHECK_PINS}" "${TREE}"
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
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "outside the preset's shape"
End
End

Describe "on a renovate comment over a range"
Parameters
"^1.2.3"
"latest"
"1"
"1.2"
"1.2.3 - 2.0.0"
End

It "fails on the value: $1"
printf '%s\n' "runs:" "  steps:" "    - run: true" "      env:" \
  "        # renovate: datasource=npm depName=sample" "        SAMPLE_VERSION: '$1'" >"${TREE}/sample/action.yml"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "not an exact version: $1"
End
End

# setup-php installs the newest patch of the major.minor it is given.
It "accepts major.minor for the PHP pin only"
printf '%s\n' "runs:" "  steps:" "    - run: true" "      env:" \
  "        # renovate: datasource=github-tags depName=php/php-src" "        DEFAULT_VERSION: '8.5'" >"${TREE}/sample/action.yml"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be success
The stdout should match pattern "checked * renovate comments"
End

It "fails on an env reference its own step does not define"
printf '%s\n' "runs:" "  steps:" "    - uses: a/b@1" "      env:" \
  "        # renovate: datasource=npm depName=sample" "        SAMPLE_VERSION: '1.2.3'" \
  "      with:" "        version: \${{ env.SAMPL_VERSION }}" >"${TREE}/sample/action.yml"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "env.SAMPL_VERSION is not defined"
End

Describe "on a pin only the repository's own manager reads"
# A digest-pinned image tag, as .github/renovate.json's manager matches it.
write_manager() {
  mkdir -p "${TREE}/.github"
  printf '%s\n' '{"customManagers": [{"customType": "regex", "matchStrings": [' \
    "\"# renovate: datasource=(?<datasource>\\\\S+) depName=(?<depName>\\\\S+)\\\\s+[A-Z0-9_]+_IMAGE_TAG:\\\\s*'(?<currentValue>[^'@]+)@(?<currentDigest>sha256:[a-f0-9]{64})'\"" \
    ']}]}' >"${TREE}/.github/renovate.json"
}
write_image_pin() {
  printf '%s\n' "runs:" "  steps:" "    - run: true" "      env:" \
    "        # renovate: datasource=docker depName=moby/buildkit" \
    "        DEFAULT_BUILDKIT_IMAGE_TAG: '$1@sha256:$(printf 'a%.0s' $(seq 1 64))'" >"${TREE}/sample/action.yml"
}

It "accepts an exact version the manager matches"
write_manager
write_image_pin "v0.34.2"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be success
The stdout should match pattern "checked * renovate comments"
End

It "still fails on a range the manager matches"
write_manager
write_image_pin "^0.34.2"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "not an exact version: ^0.34.2"
End

It "fails on it when the repository has no such manager"
write_image_pin "v0.34.2"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "outside the preset's shape"
End
End

It "fails on a tree with no renovate comments"
printf '%s\n' "runs:" "  steps:" "    - run: true" >"${TREE}/sample/action.yml"
When call _harness_python "${CHECK_PINS}" "${TREE}"
The status should be failure
The stdout should include "no renovate comments found"
End
End
End
