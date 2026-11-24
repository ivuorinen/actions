#!/bin/sh
# Install a repository's Node dependencies for linters to read, so no install scripts, hooks
# or builds run. PACKAGE_MANAGER names npm, pnpm, yarn or bun; the current directory is the
# repository. pr-lint, eslint-lint and prettier-lint each ship this file unchanged, as their
# specs check, and run it with sh.
#
# Yarn's yarnPath and plugins settings still load code from the checkout: `yarn install` has
# no flag to skip plugins, and ignoring yarnPath breaks projects that pin Yarn with it.
set -eu

# A repository with no package.json has nothing to install, and a frozen install fails for it;
# a lint tool then comes from the action's own lockfile.
if [ ! -f package.json ]; then
  printf 'No package.json: no dependencies to install\n'
  exit 0
fi

printf 'Installing dependencies using %s...\n' "$PACKAGE_MANAGER"

case "$PACKAGE_MANAGER" in
pnpm)
  # pnpm compares the lockfile's pnpmfileChecksum even with the pnpmfile ignored, so a
  # lockfile recording one fails a frozen install. Only for that error, install without the
  # frozen check; that drops the checksum, so put the lockfile back for the steps that lint
  # or commit the tree.
  command -v pnpm >/dev/null 2>&1 || {
    echo "::error::pnpm is required to install dependencies"
    exit 1
  }
  pnpm_status=0
  pnpm_output=$(pnpm install --frozen-lockfile --ignore-scripts --ignore-pnpmfile 2>&1) || pnpm_status=$?
  printf '%s\n' "$pnpm_output"
  if [ "$pnpm_status" -ne 0 ]; then
    case "$pnpm_output" in
    *ERR_PNPM_LOCKFILE_CONFIG_MISMATCH*) ;;
    *) exit "$pnpm_status" ;;
    esac
    command -v git >/dev/null 2>&1 || {
      echo "::error::git is required to restore pnpm-lock.yaml after the unfrozen install"
      exit 1
    }
    pnpm install --no-frozen-lockfile --ignore-scripts --ignore-pnpmfile
    git checkout -- pnpm-lock.yaml
  fi
  ;;
yarn)
  command -v yarn >/dev/null 2>&1 || {
    echo "::error::yarn is required to install dependencies"
    exit 1
  }
  # The running Yarn decides the flags, so a Yarn 2+ project needs no .yarnrc.yml: each
  # generation names its frozen-lockfile and script-skipping flags differently.
  yarn_version=$(yarn --version 2>/dev/null || printf '1.0.0')
  case "$yarn_version" in
  1.*) yarn install --frozen-lockfile --ignore-scripts ;;
  2.*) yarn install --immutable --skip-builds ;;
  *) yarn install --immutable --mode=skip-build ;;
  esac
  ;;
bun)
  command -v bun >/dev/null 2>&1 || {
    echo "::error::bun is required to install dependencies"
    exit 1
  }
  bun install --frozen-lockfile --ignore-scripts
  ;;
npm | *)
  command -v npm >/dev/null 2>&1 || {
    echo "::error::npm is required to install dependencies"
    exit 1
  }
  npm ci --ignore-scripts
  ;;
esac

printf '✅ Dependencies installed successfully\n'
