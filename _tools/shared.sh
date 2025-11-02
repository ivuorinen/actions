#!/bin/sh
# Shared functions and utilities for _tools/ scripts
# This file is sourced by other scripts, not executed directly

# Colors (exported for use by sourcing scripts)
# shellcheck disable=SC2034
RED='\033[0;31m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
# shellcheck disable=SC2034
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
NC='\033[0m' # No Color

# Validate CalVer version format: vYYYY.MM.DD (zero-padded)
validate_version() {
  version="$1"

  # Check format: vYYYY.MM.DD (require zero-padding) using grep
  if ! echo "$version" | grep -qE '^v[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'; then
    return 1
  fi

  # Extract components
  version_no_v="${version#v}"
  year=$(echo "$version_no_v" | cut -d'.' -f1)
  month=$(echo "$version_no_v" | cut -d'.' -f2)
  day=$(echo "$version_no_v" | cut -d'.' -f3)

  # Validate year (2020-2099)
  if [ "$year" -lt 2020 ] || [ "$year" -gt 2099 ]; then
    return 1
  fi

  # Validate month (01-12)
  if [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
    return 1
  fi

  # Validate day (01-31)
  if [ "$day" -lt 1 ] || [ "$day" -gt 31 ]; then
    return 1
  fi

  return 0
}

# Validate major version format: vYYYY
validate_major_version() {
  version="$1"

  # Check format: vYYYY using grep
  if ! echo "$version" | grep -qE '^v[0-9]{4}$'; then
    return 1
  fi

  # Extract year
  year="${version#v}"

  # Validate year (2020-2099)
  if [ "$year" -lt 2020 ] || [ "$year" -gt 2099 ]; then
    return 1
  fi

  return 0
}

# Validate minor version format: vYYYY.MM (zero-padded)
validate_minor_version() {
  version="$1"

  # Check format: vYYYY.MM (require zero-padding) using grep
  if ! echo "$version" | grep -qE '^v[0-9]{4}\.[0-9]{2}$'; then
    return 1
  fi

  # Extract components
  version_no_v="${version#v}"
  year=$(echo "$version_no_v" | cut -d'.' -f1)
  month=$(echo "$version_no_v" | cut -d'.' -f2)

  # Validate year (2020-2099)
  if [ "$year" -lt 2020 ] || [ "$year" -gt 2099 ]; then
    return 1
  fi

  # Validate month (01-12)
  if [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
    return 1
  fi

  return 0
}

# Check if working directory is clean (no uncommitted changes)
check_git_clean() {
  if ! has_git; then
    return 1
  fi
  if ! git diff --quiet || ! git diff --cached --quiet; then
    return 1
  fi
  return 0
}

# Check if currently on specified branch (default: main)
check_on_branch() {
  target_branch="${1:-main}"

  if ! has_git; then
    return 1
  fi

  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 1

  if [ "$current_branch" != "$target_branch" ]; then
    return 1
  fi
  return 0
}

# Check if a git tag exists
check_tag_exists() {
  tag="$1"

  if ! has_git; then
    return 1
  fi

  if git rev-parse "$tag" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Prompt user for yes/no confirmation
# Usage: if prompt_confirmation "Continue?"; then ...; fi
prompt_confirmation() {
  prompt_text="${1:-Continue?}"
  timeout_seconds="${2:-30}"

  # Check if stdin is a TTY (interactive terminal)
  if [ ! -t 0 ]; then
    msg_error "Non-interactive session detected - cannot prompt for confirmation"
    return 1
  fi

  # Check if timeout command is available for optional timeout support
  if command -v timeout >/dev/null 2>&1; then
    printf '%s [y/N] (timeout in %ss) ' "$prompt_text" "$timeout_seconds"

    # Use timeout command to limit read duration
    # shellcheck disable=SC2016
    if response=$(timeout "$timeout_seconds" sh -c 'read -r r && echo "$r"' 2>/dev/null); then
      : # read succeeded within timeout
    else
      printf '\n'
      msg_warn "Confirmation timeout - defaulting to No"
      return 1
    fi
  else
    # No timeout available - plain read
    printf '%s [y/N] ' "$prompt_text"
    read -r response || return 1
  fi

  case "$response" in
    [yY]|[yY][eE][sS])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Message output functions for consistent, colored output
# These functions provide a clean API for printing status messages

# msg_error "message" - Print error message in red with ✗ symbol to stderr
msg_error() {
  printf '%s✗ %s%s\n' "$RED" "$1" "$NC" >&2
}

# msg_success "message" - Print success message in green with ✓ symbol
msg_success() {
  printf '%s✓ %s%s\n' "$GREEN" "$1" "$NC"
}

# msg_done "message" - Print completion message in green with ✅ symbol
msg_done() {
  printf '%s✅ %s%s\n' "$GREEN" "$1" "$NC"
}

# msg_info "message" - Print info/status message in blue (no symbol)
msg_info() {
  printf '%s%s%s\n' "$BLUE" "$1" "$NC"
}

# msg_warn "message" - Print warning message in yellow (no symbol)
msg_warn() {
  printf '%s%s%s\n' "$YELLOW" "$1" "$NC"
}

# msg_item "message" - Print indented item with ✓ in green
msg_item() {
  printf '  %s✓%s %s\n' "$GREEN" "$NC" "$1"
}

# msg_notice "message" - Print indented notice with ℹ in blue
msg_notice() {
  printf '  %sℹ%s %s\n' "$BLUE" "$NC" "$1"
}

# msg_plain "color" "message" - Print plain colored message (no symbol)
# Usage: msg_plain "$YELLOW" "=== BANNER ==="
msg_plain() {
  color="$1"
  message="$2"
  printf '%s%s%s\n' "$color" "$message" "$NC"
}

# Get the directory where the calling script is located
get_script_dir() {
  cd "$(dirname -- "$1")" && pwd
}

# Check if git is available
has_git() {
  command -v git >/dev/null 2>&1
}

# Require git to be available, exit with error if not
require_git() {
  if ! has_git; then
    msg_error "git is not installed or not in PATH"
    printf 'Please install git to use this script.\n' >&2
    exit 1
  fi
}

# Create temp file with error checking
safe_mktemp() {
  _temp_file=""
  if ! _temp_file=$(mktemp); then
    msg_error "Failed to create temp file"
    exit 1
  fi
  printf '%s' "$_temp_file"
}
