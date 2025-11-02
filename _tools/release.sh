#!/bin/sh
# Release script for creating versioned tags and updating action references
set -eu

# Parse arguments
VERSION=""
DRY_RUN=false
SKIP_CONFIRM=false
PREP_ONLY=false
TAG_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --yes|--no-confirm)
      SKIP_CONFIRM=true
      shift
      ;;
    --prep-only)
      PREP_ONLY=true
      shift
      ;;
    --tag-only)
      TAG_ONLY=true
      shift
      ;;
    --help|-h)
      printf 'Usage: %s [OPTIONS] VERSION\n' "$0"
      printf '\n'
      printf 'Options:\n'
      printf '  --dry-run        Show what would happen without making changes\n'
      printf '  --yes            Skip confirmation prompt\n'
      printf '  --no-confirm     Alias for --yes\n'
      printf '  --prep-only      Only update refs and commit (no tags)\n'
      printf '  --tag-only       Only create tags (assumes prep done)\n'
      printf '  --help, -h       Show this help message\n'
      printf '\n'
      printf 'Examples:\n'
      printf '  %s v2025.11.01\n' "$0"
      printf '  %s --dry-run v2025.11.01\n' "$0"
      printf '  %s --yes v2025.11.01\n' "$0"
      exit 0
      ;;
    -*)
      printf 'Unknown option: %s\n' "$1" >&2
      printf 'Use --help for usage information\n' >&2
      exit 1
      ;;
    *)
      VERSION="$1"
      shift
      ;;
  esac
done

# Source shared utilities
# shellcheck source=_tools/shared.sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/shared.sh"

if [ -z "$VERSION" ]; then
  msg_error "VERSION argument required"
  printf 'Usage: %s [OPTIONS] VERSION\n' "$0"
  printf 'Use --help for more information\n'
  exit 1
fi

# Validate version format
if ! validate_version "$VERSION"; then
  msg_error "Invalid version format: $VERSION"
  printf 'Expected: vYYYY.MM.DD with zero-padded month/day (e.g., v2025.10.18, v2025.01.05)\n'
  printf 'Invalid: v2025.1.5 (must be zero-padded)\n'
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

# Show dry-run banner if applicable
if [ "$DRY_RUN" = "true" ]; then
  msg_plain "$YELLOW" "=== DRY RUN MODE ==="
  printf 'No changes will be made to git repository\n'
  printf '\n'
fi

msg_info "Creating release $VERSION"
printf '  Major: %s\n' "$major"
printf '  Minor: %s\n' "$minor"
printf '  Patch: %s\n' "$patch"
printf '\n'

# Check if git is available (required for all modes)
if ! require_git 2>/dev/null; then
  msg_error "git not available"
  exit 1
fi

# Pre-flight checks (skip for --tag-only since prep should be done)
if [ "$TAG_ONLY" = "false" ]; then
  msg_info "Running pre-flight checks..."
  msg_item "git is available"

  # Check if on main branch
  if ! check_on_branch "main"; then
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    msg_error "Not on main branch (currently on: $current_branch)"
    if [ "$DRY_RUN" = "false" ]; then
      exit 1
    fi
  else
    msg_item "On main branch"
  fi

  # Check if working directory is clean
  if ! check_git_clean; then
    msg_error "Working directory has uncommitted changes"
    if [ "$DRY_RUN" = "false" ]; then
      printf 'Please commit or stash changes before creating a release\n'
      exit 1
    fi
  else
    msg_item "Working directory is clean"
  fi

  # Check if patch tag already exists
  if check_tag_exists "$patch"; then
    msg_error "Tag $patch already exists"
    if [ "$DRY_RUN" = "false" ]; then
      printf 'Use a different version or delete the existing tag first\n'
      exit 1
    fi
  else
    msg_item "Tag $patch does not exist"
  fi

  printf '\n'
fi

# Get current commit SHA
current_sha=$(git rev-parse HEAD)
printf 'Current HEAD: %s%s%s\n' "$GREEN" "$current_sha" "$NC"
printf '\n'

# Confirmation prompt (skip if --yes or --dry-run)
if [ "$DRY_RUN" = "false" ] && [ "$SKIP_CONFIRM" = "false" ]; then
  if ! prompt_confirmation "Proceed with release $VERSION?"; then
    msg_warn "Release cancelled by user"
    exit 0
  fi
  printf '\n'
fi

# Skip prep if --tag-only
if [ "$TAG_ONLY" = "true" ]; then
  msg_info "Skipping preparation (--tag-only mode)"
  printf '\n'
else
  # Update all action references to current SHA
  msg_info "Updating action references to $current_sha..."
  if [ "$DRY_RUN" = "true" ]; then
    msg_warn "[DRY RUN] Would run: update-action-refs.sh $current_sha direct"
  else
    "$SCRIPT_DIR/update-action-refs.sh" "$current_sha" "direct"
  fi
fi

# Commit the changes (skip if --tag-only)
if [ "$TAG_ONLY" = "false" ]; then
  if ! git diff --quiet; then
    if [ "$DRY_RUN" = "true" ]; then
      msg_warn "[DRY RUN] Would add: */action.yml"
      msg_warn "[DRY RUN] Would commit: update action references for release $VERSION"
    else
      git add -- */action.yml
      git commit -m "chore: update action references for release $VERSION

This commit updates all internal action references to point to the current
commit SHA in preparation for release $VERSION."

      # Update SHA since we just created a new commit
      current_sha=$(git rev-parse HEAD)
      msg_done "Committed updated action references"
      printf 'New HEAD: %s%s%s\n' "$GREEN" "$current_sha" "$NC"
    fi
  else
    msg_info "No changes to commit"
  fi
fi

# Exit early if --prep-only
if [ "$PREP_ONLY" = "true" ]; then
  printf '\n'
  msg_done "Preparation complete (--prep-only mode)"
  msg_warn "Run with --tag-only to create tags"
  exit 0
fi

# Create/update tags
printf '\n'
msg_info "Creating tags..."

# Create patch tag
if [ "$DRY_RUN" = "true" ]; then
  msg_warn "[DRY RUN] Would create tag: $patch"
else
  git tag -a "$patch" -m "Release $patch"
  msg_item "Created tag: $patch"
fi

# Move/create minor tag
if git rev-parse "$minor" >/dev/null 2>&1; then
  if [ "$DRY_RUN" = "true" ]; then
    msg_warn "[DRY RUN] Would force-update tag: $minor"
  else
    git tag -f -a "$minor" -m "Latest $minor release: $patch"
    msg_item "Updated tag: $minor (force)"
  fi
else
  if [ "$DRY_RUN" = "true" ]; then
    msg_warn "[DRY RUN] Would create tag: $minor"
  else
    git tag -a "$minor" -m "Latest $minor release: $patch"
    msg_item "Created tag: $minor"
  fi
fi

# Move/create major tag
if git rev-parse "$major" >/dev/null 2>&1; then
  if [ "$DRY_RUN" = "true" ]; then
    msg_warn "[DRY RUN] Would force-update tag: $major"
  else
    git tag -f -a "$major" -m "Latest $major release: $patch"
    msg_item "Updated tag: $major (force)"
  fi
else
  if [ "$DRY_RUN" = "true" ]; then
    msg_warn "[DRY RUN] Would create tag: $major"
  else
    git tag -a "$major" -m "Latest $major release: $patch"
    msg_item "Created tag: $major"
  fi
fi

printf '\n'
if [ "$DRY_RUN" = "true" ]; then
  msg_done "Dry run complete - no changes made"
  printf '\n'
  msg_info "Would have created release $VERSION"
else
  msg_done "Release $VERSION created successfully"
fi
printf '\n'
msg_plain "$YELLOW" "All tags point to: $current_sha"
printf '\n'
msg_info "Tags created:"
printf '  %s\n' "$patch"
printf '  %s\n' "$minor"
printf '  %s\n' "$major"
printf '\n'

# Enhanced next steps
if [ "$DRY_RUN" = "false" ]; then
  msg_warn "Next steps:"
  printf '  1. Review changes: git show HEAD\n'
  printf '  2. Verify CI status: gh run list --limit 5\n'
  printf '  3. Push tags: git push origin main --tags --force-with-lease\n'
  printf '  4. Update workflow refs: make update-version-refs MAJOR=%s\n' "$major"
  printf '  5. Update README examples if needed\n'
  printf '  6. Create GitHub release: gh release create %s --generate-notes\n' "$VERSION"
  printf '\n'
  msg_info "If something went wrong:"
  printf '  Rollback: make release-undo\n'
else
  msg_warn "To execute this release:"
  printf '  Run without --dry-run flag\n'
fi
