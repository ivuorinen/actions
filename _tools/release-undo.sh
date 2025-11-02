#!/bin/sh
# Undo the most recent release by deleting tags and optionally resetting HEAD
set -eu

# Source shared utilities
# shellcheck source=_tools/shared.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/shared.sh"

# Check git availability
require_git

msg_info "Finding most recent release tags..."

# Portable version sort function
# Sorts CalVer tags vYYYY.MM.DD numerically
version_sort_tags() {
  # Try GNU sort first (Linux and some macOS with GNU coreutils)
  if sort --version 2>/dev/null | grep -q GNU; then
    sort -V
    return
  fi

  # Try gsort (macOS with GNU coreutils via Homebrew)
  if command -v gsort >/dev/null 2>&1; then
    gsort -V
    return
  fi

  # Fallback: awk-based numeric version sort
  awk -F. '{
    # Save original input before modification
    original = $0
    # Remove leading v and split into year, month, day
    gsub(/^v/, "", $0)
    printf "%04d.%02d.%02d %s\n", $1, $2, $3, original
  }' | sort -n | cut -d' ' -f2
}

# Find all release tags matching vYYYY.MM.DD pattern
all_tags=$(git tag -l 'v[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]' | version_sort_tags)

if [ -z "$all_tags" ]; then
  msg_warn "No release tags found"
  exit 0
fi

# Get most recent tag
latest_tag=$(echo "$all_tags" | tail -n 1)

# Extract version components
version_no_v="${latest_tag#v}"
year=$(echo "$version_no_v" | cut -d'.' -f1)
month=$(echo "$version_no_v" | cut -d'.' -f2)
day=$(echo "$version_no_v" | cut -d'.' -f3)

major="v$year"
minor="v$year.$month"
patch="v$year.$month.$day"

printf '\n'
msg_info "Most recent release:"
printf '  Patch: %s\n' "$patch"
printf '  Minor: %s\n' "$minor"
printf '  Major: %s\n' "$major"
printf '\n'

# Show which tags exist
msg_info "Tags that will be deleted:"
for tag in "$patch" "$minor" "$major"; do
  if check_tag_exists "$tag"; then
    tag_sha=$(git rev-list -n 1 "$tag")
    tag_sha_short=$(echo "$tag_sha" | cut -c1-7)
    printf '  %s (points to %s)\n' "$tag" "$tag_sha_short"
  fi
done
printf '\n'

# Check if HEAD commit is a release commit
head_message=$(git log -1 --pretty=%s)
if echo "$head_message" | grep -q "^chore: update action references for release"; then
  msg_warn "Last commit appears to be a release preparation commit:"
  printf '  %s\n' "$head_message"
  printf '\n'
  reset_head=true
else
  reset_head=false
fi

# Confirm deletion
msg_warn "This will:"
printf '  1. Delete tags: %s, %s, %s\n' "$patch" "$minor" "$major"
if [ "$reset_head" = "true" ]; then
  printf '  2. Reset HEAD to previous commit (undo release prep)\n'
fi
printf '\n'

if ! prompt_confirmation "Proceed with rollback?"; then
  msg_warn "Rollback cancelled"
  exit 0
fi
printf '\n'

# Delete tags
msg_info "Deleting tags..."
for tag in "$patch" "$minor" "$major"; do
  if check_tag_exists "$tag"; then
    git tag -d "$tag"
    msg_item "Deleted tag: $tag"
  else
    msg_notice "Tag not found: $tag (skipping)"
  fi
done

# Reset HEAD if needed
if [ "$reset_head" = "true" ]; then
  printf '\n'
  msg_info "Resetting HEAD to previous commit..."
  git reset --hard HEAD~1
  msg_item "Reset complete"
  new_head=$(git rev-parse HEAD)
  new_head_short=$(echo "$new_head" | cut -c1-7)
  printf 'New HEAD: %s%s%s\n' "$GREEN" "$new_head_short" "$NC"
fi

printf '\n'
msg_done "Rollback complete"
printf '\n'
msg_warn "Note:"
printf '  Tags were deleted locally only\n'
printf '  If you had pushed the tags, delete them from remote:\n'
printf '    git push origin --delete %s %s %s\n' "$patch" "$minor" "$major"
