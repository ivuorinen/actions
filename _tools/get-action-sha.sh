#!/bin/sh
# Get the SHA for a specific version tag
set -eu

VERSION="${1:-}"

# Source shared utilities
# shellcheck source=_tools/shared.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/shared.sh"

# Check git availability
require_git

if [ -z "$VERSION" ]; then
  printf '%b' "${RED}Error: VERSION argument required${NC}\n" >&2
  printf 'Usage: %s v2025\n' "$0" >&2
  exit 1
fi

# Check if tag exists
if ! git rev-parse "$VERSION" >/dev/null 2>&1; then
  printf '%b' "${RED}Error: Tag $VERSION not found${NC}\n" >&2
  printf '\n' >&2
  printf '%b' "${BLUE}Available tags:${NC}\n" >&2
  git tag -l 'v*' | head -20 >&2
  exit 1
fi

# Get SHA for the tag
sha=$(git rev-list -n 1 "$VERSION")

# Check if output is for terminal or pipe
if [ -t 1 ]; then
  # Terminal output - show with colors
  printf '%b' "${GREEN}$sha${NC}\n"
else
  # Piped output - just the SHA
  printf '%s\n' "$sha"
fi
