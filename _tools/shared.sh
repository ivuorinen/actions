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

# Validate CalVer version format: vYYYY.MM.DD
validate_version() {
  version="$1"

  # Check format: vYYYY.MM.DD using grep
  if ! echo "$version" | grep -qE '^v[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}$'; then
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

  # Validate month (1-12)
  if [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
    return 1
  fi

  # Validate day (1-31)
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

# Validate minor version format: vYYYY.MM
validate_minor_version() {
  version="$1"

  # Check format: vYYYY.MM using grep
  if ! echo "$version" | grep -qE '^v[0-9]{4}\.[0-9]{1,2}$'; then
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

  # Validate month (1-12)
  if [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
    return 1
  fi

  return 0
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
    printf '%b' "${RED}Error: git is not installed or not in PATH${NC}\n" >&2
    printf 'Please install git to use this script.\n' >&2
    exit 1
  fi
}

# Create temp file with error checking
safe_mktemp() {
  _temp_file=""
  if ! _temp_file=$(mktemp); then
    printf '%b' "${RED}Error: Failed to create temp file${NC}\n" >&2
    exit 1
  fi
  printf '%s' "$_temp_file"
}
