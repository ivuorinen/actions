#!/bin/sh
# Install a repository's Node dependencies for linters to read, so no install scripts, hooks
# or builds run. PACKAGE_MANAGER names npm, pnpm, yarn or bun; the current directory is the
# repository. pr-lint, eslint-lint and prettier-lint each ship this file unchanged, as their
# specs check, and run it with sh.
#
# Yarn's yarnPath and plugins settings still load code from the checkout: `yarn install` has
# no flag to skip plugins, and ignoring yarnPath breaks projects that pin Yarn with it.
set -eu

printf 'Installing dependencies using %s...\n' "$PACKAGE_MANAGER"

# A package manager builds a Git dependency from its repository, running its install and pack
# scripts, whatever flags the outer install has: Yarn 2+, for one, runs a full install and a
# pack in the clone. Such a dependency cannot install without scripts, so a lockfile that names
# one stops the install. Bun's binary bun.lockb holds the same URLs as plain strings, which grep
# matches in a binary file too.
for lockfile in package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb; do
  if [ -f "$lockfile" ] && grep -E -q 'git\+[a-z]+://|git://|#commit=|type: git|(github|gitlab|bitbucket):' "$lockfile"; then
    echo "::error::$lockfile names a Git dependency, which is built from its repository with its scripts; the dependencies install only without scripts"
    exit 1
  fi
done

case "$PACKAGE_MANAGER" in
pnpm)
  # Frozen: a lockfile that does not match the manifest or the settings fails the install,
  # rather than resolving the dependencies again.
  command -v pnpm >/dev/null 2>&1 || {
    echo "::error::pnpm is required to install dependencies"
    exit 1
  }
  pnpm install --frozen-lockfile --ignore-scripts --ignore-pnpmfile
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
  # A repository with no package.json has nothing to install, and npm ci fails for it; a lint
  # tool then comes from the action's own lockfile. pnpm, Yarn and Bun can install a workspace
  # without a root manifest, so they run regardless.
  if [ ! -f package.json ]; then
    printf 'No package.json: no dependencies to install\n'
    exit 0
  fi
  command -v npm >/dev/null 2>&1 || {
    echo "::error::npm is required to install dependencies"
    exit 1
  }
  npm ci --ignore-scripts
  ;;
esac

printf '✅ Dependencies installed successfully\n'
