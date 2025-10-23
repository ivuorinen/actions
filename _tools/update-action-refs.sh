#!/bin/sh
# Update all action references to a specific version tag or SHA
set -eu

TARGET="${1:-}"
MODE="${2:-tag}" # 'tag' or 'direct'

# Source shared utilities
# shellcheck source=_tools/shared.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/shared.sh"

# Check git availability
require_git

if [ -z "$TARGET" ]; then
  printf '%b' "${RED}Error: TARGET argument required${NC}\n"
  printf 'Usage: %s v2025 [mode]\n' "$0"
  printf '  mode: '\''tag'\'' (default) or '\''direct'\''\n'
  exit 1
fi

# Get SHA based on mode
if [ "$MODE" = "direct" ]; then
  # Direct SHA provided
  target_sha="$TARGET"
  printf '%b' "${BLUE}Using direct SHA: $target_sha${NC}\n"
elif [ "$MODE" = "tag" ]; then
  # Resolve tag to SHA
  if ! git rev-parse "$TARGET" >/dev/null 2>&1; then
    printf '%b' "${RED}Error: Tag $TARGET not found${NC}\n"
    exit 1
  fi
  target_sha=$(git rev-list -n 1 "$TARGET")
  printf '%b' "${BLUE}Resolved $TARGET to SHA: $target_sha${NC}\n"
else
  printf '%b' "${RED}Error: Invalid mode: $MODE${NC}\n"
  printf 'Mode must be '\''tag'\'' or '\''direct'\''\n'
  exit 1
fi

# Validate SHA format
if ! echo "$target_sha" | grep -qE '^[a-f0-9]{40}$'; then
  printf '%b' "${RED}Error: Invalid SHA format: $target_sha${NC}\n"
  exit 1
fi

printf '%b' "${BLUE}Updating action references...${NC}\n"

# Update all action.yml files (excluding tests and .github workflows)
# Create temp file to store results
temp_file=$(safe_mktemp)
trap 'rm -f "$temp_file"' EXIT

find . -maxdepth 2 -name "action.yml" -path "*/action.yml" ! -path "./_*" ! -path "./.github/*" | while IFS= read -r file; do
  # Use .bak extension for cross-platform sed compatibility
  if sed -i.bak "s|ivuorinen/actions/\([a-z-]*\)@[a-f0-9]\{40\}|ivuorinen/actions/\1@$target_sha|g" "$file"; then
    rm -f "${file}.bak"
    printf '%b' "  ${GREEN}✓${NC} Updated: $file\n"
    echo "$file" >> "$temp_file"
  fi
done

printf '\n'
if [ -s "$temp_file" ]; then
  updated_count=$(wc -l < "$temp_file" | tr -d ' ')
  printf '%b' "${GREEN}✅ Updated $updated_count action files${NC}\n"
else
  printf '%b' "${BLUE}No files needed updating${NC}\n"
fi
