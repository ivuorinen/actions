#!/bin/sh
# Bump from one major version to another (annual version bump)
set -eu

OLD_VERSION="${1:-}"
NEW_VERSION="${2:-}"

# Source shared utilities
# shellcheck source=_tools/shared.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/shared.sh"

# Check git availability
require_git

if [ -z "$OLD_VERSION" ] || [ -z "$NEW_VERSION" ]; then
  printf '%b' "${RED}Error: OLD_VERSION and NEW_VERSION arguments required${NC}\n"
  printf 'Usage: %s v2025 v2026\n' "$0"
  exit 1
fi

# Validate major version format
if ! validate_major_version "$OLD_VERSION"; then
  printf '%b' "${RED}Error: Invalid old version format: $OLD_VERSION${NC}\n"
  printf 'Expected: vYYYY (e.g., v2025)\n'
  exit 1
fi

if ! validate_major_version "$NEW_VERSION"; then
  printf '%b' "${RED}Error: Invalid new version format: $NEW_VERSION${NC}\n"
  printf 'Expected: vYYYY (e.g., v2026)\n'
  exit 1
fi

printf '%b' "${BLUE}Bumping major version from $OLD_VERSION to $NEW_VERSION${NC}\n"
printf '\n'

# Get SHA for new version tag
if ! git rev-parse "$NEW_VERSION" >/dev/null 2>&1; then
  printf '%b' "${YELLOW}Warning: Tag $NEW_VERSION not found${NC}\n"
  printf 'Creating tag %s pointing to current HEAD...\n' "$NEW_VERSION"

  if ! current_sha=$(git rev-parse HEAD 2>&1); then
    printf '%b' "${RED}Error: Failed to get current HEAD SHA${NC}\n" >&2
    printf 'Git command failed: git rev-parse HEAD\n' >&2
    exit 1
  fi

  git tag -a "$NEW_VERSION" -m "Major version $NEW_VERSION"
  printf '%b' "${GREEN}✓ Created tag $NEW_VERSION pointing to $current_sha${NC}\n"
  printf '\n'
fi

if ! new_sha=$(git rev-list -n 1 "$NEW_VERSION" 2>&1); then
  printf '%b' "${RED}Error: Failed to get SHA for tag $NEW_VERSION${NC}\n" >&2
  printf 'Git command failed: git rev-list -n 1 "%s"\n' "$NEW_VERSION" >&2
  exit 1
fi

if [ -z "$new_sha" ]; then
  printf '%b' "${RED}Error: Empty SHA returned for tag $NEW_VERSION${NC}\n" >&2
  exit 1
fi

printf '%b' "Target SHA for $NEW_VERSION: ${GREEN}$new_sha${NC}\n"
printf '\n'

# Update all action references
printf '%b' "${BLUE}Updating action references...${NC}\n"
"$SCRIPT_DIR/update-action-refs.sh" "$NEW_VERSION" "tag"

# Commit the changes
if ! git diff --quiet; then
  git add -- */action.yml
  git commit -m "chore: bump major version from $OLD_VERSION to $NEW_VERSION

This commit updates all internal action references from $OLD_VERSION
to $NEW_VERSION."

  printf '%b' "${GREEN}✅ Committed version bump${NC}\n"
else
  printf '%b' "${BLUE}No changes to commit${NC}\n"
fi

printf '\n'
printf '%b' "${GREEN}✅ Major version bumped successfully${NC}\n"
printf '\n'
printf '%b' "${YELLOW}Remember to update READMEs:${NC}\n"
printf '  make docs\n'
