#!/bin/sh
# Release script for creating versioned tags and updating action references
set -eu

VERSION="${1:-}"

# Source shared utilities
# shellcheck source=_tools/shared.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/shared.sh"

if [ -z "$VERSION" ]; then
  printf '%b' "${RED}Error: VERSION argument required${NC}\n"
  printf 'Usage: %s v2025.10.18\n' "$0"
  exit 1
fi

# Validate version format
if ! validate_version "$VERSION"; then
  printf '%b' "${RED}Error: Invalid version format: $VERSION${NC}\n"
  printf 'Expected: vYYYY.MM.DD (e.g., v2025.10.18)\n'
  exit 1
fi

# Extract version components
# Remove leading 'v'
version_no_v="${VERSION#v}"
# Extract year, month, day
year=$(echo "$version_no_v" | cut -d'.' -f1)
month=$(echo "$version_no_v" | cut -d'.' -f2)
day=$(echo "$version_no_v" | cut -d'.' -f3)

major="v$year"
minor="v$year.$month"
patch="v$year.$month.$day"

printf '%b' "${BLUE}Creating release $VERSION${NC}\n"
printf '  Major: %s\n' "$major"
printf '  Minor: %s\n' "$minor"
printf '  Patch: %s\n' "$patch"
printf '\n'

# Get current commit SHA
current_sha=$(git rev-parse HEAD)
printf '%b' "Current HEAD: ${GREEN}$current_sha${NC}\n"
printf '\n'

# Update all action references to current SHA
printf '%b' "${BLUE}Updating action references to $current_sha...${NC}\n"
"$SCRIPT_DIR/update-action-refs.sh" "$current_sha" "direct"

# Commit the changes
if ! git diff --quiet; then
  git add -- */action.yml
  git commit -m "chore: update action references for release $VERSION

This commit updates all internal action references to point to the current
commit SHA in preparation for release $VERSION."

  # Update SHA since we just created a new commit
  current_sha=$(git rev-parse HEAD)
  printf '%b' "${GREEN}✅ Committed updated action references${NC}\n"
  printf '%b' "New HEAD: ${GREEN}$current_sha${NC}\n"
else
  printf '%b' "${BLUE}No changes to commit${NC}\n"
fi

# Create/update tags
printf '%b' "${BLUE}Creating tags...${NC}\n"

# Create patch tag
git tag -a "$patch" -m "Release $patch"
printf '%b' "  ${GREEN}✓${NC} Created tag: $patch\n"

# Move/create minor tag
if git rev-parse "$minor" >/dev/null 2>&1; then
  git tag -f -a "$minor" -m "Latest $minor release: $patch"
  printf '%b' "  ${GREEN}✓${NC} Updated tag: $minor (force)\n"
else
  git tag -a "$minor" -m "Latest $minor release: $patch"
  printf '%b' "  ${GREEN}✓${NC} Created tag: $minor\n"
fi

# Move/create major tag
if git rev-parse "$major" >/dev/null 2>&1; then
  git tag -f -a "$major" -m "Latest $major release: $patch"
  printf '%b' "  ${GREEN}✓${NC} Updated tag: $major (force)\n"
else
  git tag -a "$major" -m "Latest $major release: $patch"
  printf '%b' "  ${GREEN}✓${NC} Created tag: $major\n"
fi

printf '\n'
printf '%b' "${GREEN}✅ Release $VERSION created successfully${NC}\n"
printf '\n'
printf '%b' "${YELLOW}All tags point to: $current_sha${NC}\n"
printf '\n'
printf '%b' "${BLUE}Tags created:${NC}\n"
printf '  %s\n' "$patch"
printf '  %s\n' "$minor"
printf '  %s\n' "$major"
