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
#
# The forms a lockfile names one in: a git+, git:// or ssh:// URL; an http(s) URL ending in
# .git, or naming an owner and a repository on github.com, gitlab.com or bitbucket, which Yarn 1
# reads as Git; Yarn 2+'s #commit=; pnpm's type: git; and a host shorthand such as github:.
git_ref='git\+[a-z]+://|git://|ssh://|https?://[^[:space:]"#]*\.git([#"[:space:]]|$)'
git_ref="$git_ref"'|https?://(github\.com|gitlab\.com|bitbucket\.(com|org))/[^/[:space:]"#]+/[^/[:space:]"#]+([#"[:space:]]|$)'
git_ref="$git_ref"'|#commit=|type: git|(github|gitlab|bitbucket):'

# references LOCKFILE: the lines of LOCKFILE that can say where a dependency comes from. An npm
# lock also holds each package's funding links and deprecation message, and a pnpm lock its
# deprecation message, which can name a repository on a Git host for a registry package; npm
# names a dependency's source only in its resolved and version fields. Splitting the JSON at
# its commas and braces puts each field on a line of its own, however npm formatted the file:
# format-package-lock=false writes it on one line.
references() {
  case "$1" in
  package-lock.json | npm-shrinkwrap.json) tr ',{}' '[\n*]' <"$1" | grep -E '"(resolved|version)"[[:space:]]*:' ;;
  pnpm-lock.yaml) grep -E -v '^[[:space:]]*deprecated:' "$1" ;;
  *) cat "$1" ;;
  esac
}

for lockfile in package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb; do
  if [ -f "$lockfile" ] && references "$lockfile" | grep -E -q "$git_ref"; then
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
  command -v node >/dev/null 2>&1 || {
    echo "::error::node is required to read the manifests"
    exit 1
  }
  # Yarn 2+ fetches an exec: dependency by running its generator script from the checkout, which
  # no install flag skips, and it runs the generator to resolve one the lockfile lacks before
  # --immutable can fail the install. So yarn.lock and every manifest in the checkout are read;
  # installed packages and Yarn's own files are not the repository's manifests. Each manifest is
  # parsed as JSON, as Yarn reads it, so a value is checked once decoded, however it is written.
  # find reads a pair of braces anywhere in the script as its placeholder, so the script has none,
  # and a find or node that fails stops the install rather than passing the check.
  exec_source=
  if [ -f yarn.lock ] && grep -E -q '@exec:' yarn.lock; then
    exec_source=yarn.lock
  else
    exec_found=$(find . \( -name node_modules -o -name .git -o -name .yarn \) -prune -o \
      -name package.json -type f -exec node -e '
const fs = require("node:fs");
const fields = ["dependencies", "devDependencies", "optionalDependencies", "peerDependencies", "resolutions"];
const execSpec = spec => typeof spec === "string" && spec.trim().startsWith("exec:");
for (const file of process.argv.slice(1)) {
  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    // Yarn cannot read it either, so it resolves nothing from it.
    continue;
  }
  if (fields.some(field => Object.values(manifest?.[field] || []).some(execSpec))) {
    console.log(file);
    break;
  }
}' {} +) || {
      echo "::error::The manifests could not be read for exec: dependencies"
      exit 1
    }
    # Each batch find hands node names its first match, if any.
    exec_source=$(printf '%s\n' "$exec_found" | head -n 1)
  fi
  if [ -n "$exec_source" ]; then
    echo "::error::$exec_source names an exec: dependency, which Yarn builds by running its generator script; the dependencies install only without scripts"
    exit 1
  fi
  # The running Yarn decides the flags, so a Yarn 2+ project needs no .yarnrc.yml: each
  # generation names its frozen-lockfile and script-skipping flags differently. Yarn 2.4.0 added
  # --skip-builds, and 2.0 to 2.3 have no way to install without builds.
  yarn_version=$(yarn --version 2>/dev/null || printf '1.0.0')
  case "$yarn_version" in
  1.*) yarn install --frozen-lockfile --ignore-scripts ;;
  2.[0-3].*)
    echo "::error::Yarn 2.0 to 2.3 cannot install without running builds; use Yarn 1, or 2.4.0 or later"
    exit 1
    ;;
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
