#!/usr/bin/env shellspec
# Behavior tests for prettier-lint's "Install Prettier Plugins" step.
#
# The step runs before the auto-commit step, which stages every tracked file
# that changed. A plugin install must therefore run no lifecycle scripts and
# leave package.json and the lockfile exactly as committed.
#
# The harness cannot feed `steps.detect-pm.outputs.*` into a step, so the spec
# extracts the step's `run:` script and runs it with fake package managers on
# PATH. A fake logs its argv and, like the real pnpm and yarn (neither has a
# --no-save flag), rewrites package.json and the lockfile on `add` unless it was
# told not to save. Flag names were checked against each tool's `add --help`.

Describe "prettier-lint plugin install"
ACTION_FILE="${PROJECT_ROOT}/prettier-lint/action.yml"

setup() {
  shellspec_setup_test_env "prettier-lint-plugins-$$"
  FAKE_BIN="${SHELLSPEC_TEST_TEMP_DIR}/bin"
  CALLS="${SHELLSPEC_TEST_TEMP_DIR}/calls"
  STEP="${SHELLSPEC_TEST_TEMP_DIR}/step.sh"
  mkdir -p "$FAKE_BIN"
  cat >"${FAKE_BIN}/fakepm" <<'FAKE'
#!/bin/sh
printf '%s %s\n' "$(basename "$0")" "$*" >>"$CALLS"
printf 'scripts=%s\n' "${YARN_ENABLE_SCRIPTS:-unset}" >>"$CALLS"
case " $* " in
  *" --no-save "*) exit 0 ;;
esac
printf '"plugin": "added"\n' >>package.json
for lock in pnpm-lock.yaml yarn.lock; do
  if [ -f "$lock" ]; then printf 'plugin: added\n' >>"$lock"; fi
done
FAKE
  chmod +x "${FAKE_BIN}/fakepm"
  for pm in npm pnpm yarn bun; do
    ln -s fakepm "${FAKE_BIN}/${pm}"
  done
  _harness_python -c '
import sys, yaml
steps = yaml.safe_load(open(sys.argv[1]))["runs"]["steps"]
print(next(s for s in steps if s.get("name") == "Install Prettier Plugins")["run"])
' "$ACTION_FILE" >"$STEP"
  printf '{"name":"proj"}\n' >package.json
  printf 'lock: original\n' >pnpm-lock.yaml
  printf 'lock: original\n' >yarn.lock
  cp package.json pnpm-lock.yaml yarn.lock "$SHELLSPEC_TEST_TEMP_DIR/"
}
BeforeEach 'setup'

teardown() {
  shellspec_cleanup_test_env "prettier-lint-plugins-$$"
}
AfterEach 'teardown'

# $1 = package manager, $2 = plugins input
run_install() {
  PATH="${FAKE_BIN}:${PATH}" CALLS="$CALLS" PACKAGE_MANAGER="$1" PLUGINS="$2" sh "$STEP"
}

# True when package.json and both lockfiles equal their committed copies.
manifests_unchanged() {
  for f in package.json pnpm-lock.yaml yarn.lock; do
    cmp -s "$f" "${SHELLSPEC_TEST_TEMP_DIR}/$f" || return 1
  done
}

installed_call() {
  grep -v '^scripts=' "$CALLS"
}

Describe "per package manager"
It "npm installs without saving and without scripts"
When call run_install npm "plugin-a,plugin-b"
The status should be success
The stdout should include "Installing Prettier plugins"
Assert [ "$(installed_call)" = "npm install --no-save --ignore-scripts plugin-a plugin-b" ]
Assert manifests_unchanged
End

It "bun installs without saving and without scripts"
When call run_install bun "plugin-a,plugin-b"
The status should be success
The stdout should include "Installing Prettier plugins"
Assert [ "$(installed_call)" = "bun add --no-save --ignore-scripts plugin-a plugin-b" ]
Assert manifests_unchanged
End

It "pnpm skips scripts and restores package.json and the lockfile"
When call run_install pnpm "plugin-a,plugin-b"
The status should be success
The stdout should include "Installing Prettier plugins"
Assert [ "$(installed_call | head -n 1)" = "pnpm add -D --ignore-scripts plugin-a plugin-b" ]
Assert manifests_unchanged
End

It "yarn classic skips scripts and restores package.json and the lockfile"
When call run_install yarn "plugin-a,plugin-b"
The status should be success
The stdout should include "Installing Prettier plugins"
Assert [ "$(installed_call | head -n 1)" = "yarn add -D --ignore-scripts plugin-a plugin-b" ]
Assert manifests_unchanged
End

It "yarn berry disables scripts through the environment and restores the manifests"
printf 'nodeLinker: node-modules\n' >.yarnrc.yml
When call run_install yarn "plugin-a,plugin-b"
The status should be success
The stdout should include "Installing Prettier plugins"
Assert [ "$(installed_call | head -n 1)" = "yarn add -D plugin-a plugin-b" ]
Assert [ "$(grep '^scripts=' "$CALLS")" = "scripts=false" ]
Assert manifests_unchanged
End
End

Describe "plugin separator"
It "splits a comma-separated list into one argument per plugin"
When call run_install npm "@scope/plugin-a@^1.0.0,plugin-b"
The status should be success
The stdout should include "Installing Prettier plugins"
Assert [ "$(installed_call)" = "npm install --no-save --ignore-scripts @scope/plugin-a@^1.0.0 plugin-b" ]
End
End
End
