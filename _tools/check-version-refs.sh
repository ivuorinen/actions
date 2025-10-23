#!/bin/sh
# Check and display all current SHA-pinned action references
set -eu

# Source shared utilities
# shellcheck source=_tools/shared.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/shared.sh"

# Warn once if git is not available
if ! has_git; then
  printf '%b' "${YELLOW}Warning: git is not installed or not in PATH${NC}\n" >&2
  printf 'Git tag information will not be available.\n' >&2
fi

# Check for required coreutils
for tool in find grep sed printf sort cut tr wc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '%b' "${RED}Error: Required tool '%s' is not installed or not in PATH${NC}\n" "$tool" >&2
    printf 'Please install coreutils to use this script.\n' >&2
    exit 1
  fi
done

printf '%b' "${BLUE}Current SHA-pinned action references:${NC}\n"
printf '\n'

# Create temp files for processing
temp_file=$(safe_mktemp)
trap 'rm -f "$temp_file"' EXIT

temp_input=$(safe_mktemp)
trap 'rm -f "$temp_file" "$temp_input"' EXIT

# Find all action references and collect SHA|action pairs
# Use input redirection to avoid subshell issues with pipeline
find . -maxdepth 2 -name "action.yml" -path "*/action.yml" ! -path "./_*" ! -path "./.github/*" -exec grep -h "uses: ivuorinen/actions/" {} \; > "$temp_input"

while IFS= read -r line; do
  # Extract action name and SHA using sed
  action=$(echo "$line" | sed -n 's|.*ivuorinen/actions/\([a-z-]*\)@.*|\1|p')
  sha=$(echo "$line" | sed -n 's|.*@\([a-f0-9]\{40\}\).*|\1|p')

  if [ -n "$action" ] && [ -n "$sha" ]; then
    printf '%s\n' "$sha|$action" >> "$temp_file"
  fi
done < "$temp_input"

# Check if we found any references
if [ ! -s "$temp_file" ]; then
  printf '%b' "${YELLOW}No SHA-pinned references found${NC}\n"
  exit 0
fi

# Sort by SHA and group
sort "$temp_file" | uniq > "${temp_file}.sorted"
mv "${temp_file}.sorted" "$temp_file"

# Count unique SHAs
sha_count=$(cut -d'|' -f1 "$temp_file" | sort -u | wc -l | tr -d ' ')

if [ "$sha_count" -eq 1 ]; then
  printf '%b' "${GREEN}✓ All references use the same SHA (consistent)${NC}\n"
  printf '\n'
fi

# Process and display grouped by SHA
current_sha=""
actions_list=""

while IFS='|' read -r sha action; do
  if [ "$sha" != "$current_sha" ]; then
    # Print previous SHA group if exists
    if [ -n "$current_sha" ]; then
      # Try to find tags pointing to this SHA
      if has_git; then
        tags=$(git tag --points-at "$current_sha" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
      else
        tags=""
      fi

      printf '%b' "${GREEN}SHA: $current_sha${NC}\n"
      if [ -n "$tags" ]; then
        printf '%b' "  Tags: ${BLUE}$tags${NC}\n"
      fi
      printf '  Actions: %s\n' "$actions_list"
      printf '\n'
    fi

    # Start new SHA group
    current_sha="$sha"
    actions_list="$action"
  else
    # Add to current SHA group
    actions_list="$actions_list, $action"
  fi
done < "$temp_file"

# Print last SHA group
if [ -n "$current_sha" ]; then
  if has_git; then
    tags=$(git tag --points-at "$current_sha" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
  else
    tags=""
  fi

  printf '%b' "${GREEN}SHA: $current_sha${NC}\n"
  if [ -n "$tags" ]; then
    printf '%b' "  Tags: ${BLUE}$tags${NC}\n"
  fi
  printf '  Actions: %s\n' "$actions_list"
  printf '\n'
fi

printf '%b' "${BLUE}Summary:${NC}\n"
printf '  Unique SHAs: %s\n' "$sha_count"
if [ "$sha_count" -gt 1 ]; then
  printf '%b' "  ${YELLOW}⚠ Warning: Multiple SHAs in use (consider updating)${NC}\n"
fi
