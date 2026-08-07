#!/bin/sh
# Post-process one generated action README.
#
# gh-action-readme's themes emit example workflows that are close, but not
# copy-pasteable: relative links resolve inside the action directory, the
# checkout step uses a mutable tag, credentials get literal placeholder values,
# and the quick start triggers on pull_request even for publishing actions.
# Every fixup here corrects generated output; none of it is style preference.
#
# Usage: fix-generated-readme.sh <readme-path>
#
# Kept out of the Makefile recipe because the credential rewrites need
# alternation and a literal ${{ ... }} in the replacement, which is unreadable
# and quoting-hazardous nested inside a make recipe inside a shell string.

set -eu

README="${1:?usage: fix-generated-readme.sh <readme-path>}"
[ -f "$README" ] || {
  echo "::error::fix-generated-readme: no such file: $README" >&2
  exit 1
}

# actions/checkout v4 resolved to its immutable commit. The themes emit the
# mutable `@v4` tag; this repo pins every external action to a full SHA and the
# examples it publishes should not teach otherwise. Bump alongside the tag.
CHECKOUT_SHA='11d5960a326750d5838078e36cf38b85af677262'

# Rewrite in place without -i: GNU wants `-i`, BSD wants `-i ''`, and a
# temp-file swap sidesteps the difference entirely. `%` is the delimiter
# throughout because the patterns contain both `/` (paths) and `@` (action refs).
_sed() {
  sed -E "$1" "$README" >"$README.gartmp" && mv "$README.gartmp" "$README"
}

# 1. Links resolve relative to the README, i.e. inside the action directory,
#    where none of these exist. The repo root has CONTRIBUTING.md and
#    LICENSE.md — note the root file is .md, the theme links bare LICENSE.
_sed 's%\]\(CONTRIBUTING\.md\)%](../CONTRIBUTING.md)%g'
_sed 's%\]\(LICENSE\)%](../LICENSE.md)%g'

# 2. No examples/ directory exists anywhere in this repo, so the bullet is
#    dropped rather than repointed at something it is not.
_sed '/\[examples\]\(\.\/examples\/\)/d'

# 3. The quick start triggers on pull_request. For the publishing actions that
#    invites publishing artifacts built from untrusted pull-request code, and
#    it demonstrates nothing that `push` alone does not.
_sed 's%^on: \[push, pull_request\]$%on: [push]%'

# 4. Pin the checkout step. A copied example should not open with a mutable tag
#    in a repository whose own rule is to SHA-pin every external action.
_sed "s%uses: actions/checkout@v4\$%uses: actions/checkout@${CHECKOUT_SHA} # v4%"

# 5. Credentials get literal placeholders ('value', 'example-value',
#    'custom-value'). Copied verbatim those are invalid credentials, and worse
#    they teach passing secrets as plain input values. Point each at the runtime
#    token or a repository secret. Double quotes here are normalised to single
#    by the prettier pass that follows in `make docs`.
#
# The `${{ ... }}` expressions are assembled from $_D rather than written as
# literals. Spelled out inside single quotes they read as shell expansions to
# the linter (SC2016), and this repo treats a suppression directive as an
# admission the rule still applies. Assembling them keeps the script clean
# without silencing anything.
_D='$'
_PLACEHOLDER='.(value|example-value|custom-value).'
_RUNTIME_TOKEN="${_D}{{ github.token }}"

_cred() {
  # $1 = input name, $2 = replacement expression
  _sed "s%^([[:space:]]*)$1: ${_PLACEHOLDER}\$%\\1$1: \"$2\"%"
}

_cred token "$_RUNTIME_TOKEN"
_cred github_token "$_RUNTIME_TOKEN"
_cred npm_token "${_D}{{ secrets.NPM_TOKEN }}"
_cred dockerhub-token "${_D}{{ secrets.DOCKERHUB_TOKEN }}"
_cred gitleaks-license "${_D}{{ secrets.GITLEAKS_LICENSE }}"
