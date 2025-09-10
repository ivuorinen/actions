#!/usr/bin/env bash
# Common validation helpers for GitHub Actions testing
# Provides simplified validation functions that return success/failure directly

set -euo pipefail

# Boolean validation - returns success/failure based on true/false input
validate_boolean() {
  local value="$1"
  [[ $value =~ ^(true|false)$ ]] && echo "success" || echo "failure"
}

# Version validation - supports semantic versioning
validate_version() {
  local value="$1"
  if [[ $value =~ ^v?[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "success"
  elif [[ $value =~ ^v?[0-9]+\.[0-9]+\.[0-9]+-[a-zA-Z0-9.-]+$ ]]; then
    echo "success"
  elif [[ $value =~ ^v?[0-9]+\.[0-9]+\.[0-9]+\+[a-zA-Z0-9.-]+$ ]]; then
    echo "success"
  else
    echo "failure"
  fi
}

# Strict semantic version validation - SemVer 2.0.0 compliant
validate_full_semantic_version() {
  local value="$1"
  # Remove v prefix if present
  value="${value#v}"

  # SemVer 2.0.0 compliant regex
  # Major.Minor.Patch with optional prerelease and build metadata
  # Numeric identifiers must not have leading zeros unless they are zero
  local semver_regex='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
  semver_regex+='(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)'
  semver_regex+='(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?'
  semver_regex+='(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$'

  if [[ $value =~ $semver_regex ]]; then
    echo "success"
  else
    echo "failure"
  fi
}

# Go version validation - specific 1.x.x format with bounds checking
validate_go_version() {
  local value="$1"
  if [[ $value =~ ^1\.[0-9]+(\.([0-9]+))?$ ]]; then
    local minor
    minor=$(echo "$value" | cut -d'.' -f2)
    if [[ $((minor)) -ge 18 && $((minor)) -le 25 ]]; then
      echo "success"
    else
      echo "failure"
    fi
  else
    echo "failure"
  fi
}

# .NET version validation with leading zero and range checks
validate_dotnet_version() {
  local value="$1"
  # Check for leading zeros (not allowed)
  if [[ $value =~ ^0[0-9] || $value =~ \.0[0-9] ]]; then
    echo "failure"
    return
  fi

  # Check basic format: X or X.Y or X.Y.Z (no leading zeros)
  if [[ $value =~ ^[1-9][0-9]*(\.[0-9]+(\.[0-9]+)?)?$ ]]; then
    local major_version
    major_version=$(echo "$value" | cut -d'.' -f1)
    if [[ $major_version =~ ^[0-9]+$ && $((major_version)) -ge 3 && $((major_version)) -le 20 ]]; then
      # Special case: version 20.x should only allow 20.0, not 20.1+
      if [[ $((major_version)) -eq 20 ]]; then
        [[ $value =~ ^20(\.0(\.0)?)?$ ]] && echo "success" || echo "failure"
      else
        echo "success"
      fi
    else
      echo "failure"
    fi
  else
    echo "failure"
  fi
}

# Path safety validation - prevents traversal and absolute paths
validate_path_safe() {
  local value="$1"
  [[ $value != *"../"* && $value != *"/../"* && $value != /* && $value != *"/etc/"* ]] && echo "success" || echo "failure"
}

# Injection pattern validation - checks for common shell injection patterns
validate_no_injection() {
  local value="$1"
  [[ $value != *";"* && $value != *"&&"* && $value != *"|"* && $value != *"\$("* ]] && echo "success" || echo "failure"
}

# Numeric range validation - checks if value is within specified range
validate_numeric_range() {
  local value="$1"
  local min="$2"
  local max="$3"
  if [[ $value =~ ^[0-9]+$ && $((value)) -ge $((min)) && $((value)) -le $((max)) ]]; then
    echo "success"
  else
    echo "failure"
  fi
}

# Name format validation - alphanumeric with hyphens/underscores
validate_name_format() {
  local value="$1"
  [[ $value =~ ^[a-zA-Z0-9][a-zA-Z0-9_/-]*$ ]] && echo "success" || echo "failure"
}

# Docker image name validation - lowercase with specific character set
validate_docker_image_name() {
  local value="$1"
  [[ $value =~ ^[a-z0-9]+([._-][a-z0-9]+)*$ ]] && echo "success" || echo "failure"
}

# Docker tag validation - supports various Docker tag formats
validate_docker_tag() {
  local value="$1"
  [[ $value =~ ^[a-zA-Z0-9v][a-zA-Z0-9._-]*$ ]] && echo "success" || echo "failure"
}

# Docker tags (multiple) validation - comma-separated tags
validate_docker_tags() {
  local value="$1"
  if [[ $value == *";"* || $value == *"&&"* || $value == *"|"* ]]; then
    echo "failure"
    return
  fi

  # Split by comma and validate each tag
  IFS=',' read -ra tag_array <<<"$value"
  for tag in "${tag_array[@]}"; do
    tag=$(echo "$tag" | tr -d '[:space:]') # Remove whitespace
    # Docker tag spec: start with alnum/underscore, then alphanumeric/underscore/dash/period, max 128 chars
    # Also accept common special tags
    if ! [[ $tag =~ ^([A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|latest|nightly|nightly-[0-9]{8}-[0-9]{4})$ ]]; then
      echo "failure"
      return
    fi
  done
  echo "success"
}

# Docker platform validation - supports standard Docker platforms
validate_docker_platforms() {
  local value="$1"
  if [[ $value == *";"* || $value == *"&&"* || $value == *"|"* ]]; then
    echo "failure"
  elif [[ $value =~ ^linux/(amd64|arm64|arm/v7|arm/v6|386|ppc64le|s390x)(,linux/(amd64|arm64|arm/v7|arm/v6|386|ppc64le|s390x))*$ ]]; then
    echo "success"
  else
    echo "failure"
  fi
}

# Docker Hub username validation - Docker Hub rules: 4-30 chars, lowercase letters/digits/hyphens, start/end with alphanumeric
validate_docker_hub_username() {
  local value="$1"
  # Length check and pattern validation
  if [[ ${#value} -ge 4 && ${#value} -le 30 && $value =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
    echo "success"
  else
    echo "failure"
  fi
}

# Email validation - basic email format check
validate_email() {
  local value="$1"
  if [[ $value == *"@"* && $value == *"."* &&
    $value != "@"* && $value != *"@" &&
    $value != *"@." && $value != *" "* ]]; then
    echo "success"
  else
    echo "failure"
  fi
}

# GitHub token validation - supports various GitHub token formats
validate_github_token() {
  local value="$1"
  # shellcheck disable=SC2016
  if [[ $value =~ ^gh[efpousr]_[a-zA-Z0-9]{36}$ ]] ||
    [[ $value =~ ^github_pat_[a-zA-Z0-9_]{50,255}$ ]] ||
    [[ $value == '${{ github.token }}' ]]; then
    echo "success"
  else
    echo "failure"
  fi
}

# Enum validation - checks if value is in allowed list
validate_enum() {
  local value="$1"
  shift
  local allowed_values=("$@")

  for allowed in "${allowed_values[@]}"; do
    if [[ $value == "$allowed" ]]; then
      echo "success"
      return
    fi
  done
  echo "failure"
}

# File extension validation - validates file has allowed extension
validate_file_extension() {
  local value="$1"
  shift
  local allowed_extensions=("$@")

  for ext in "${allowed_extensions[@]}"; do
    if [[ $value == *".$ext" ]]; then
      echo "success"
      return
    fi
  done
  echo "failure"
}

# Empty value validation - handles empty input validation
validate_not_empty() {
  local value="$1"
  [[ -n $value ]] && echo "success" || echo "failure"
}

# Combined validation - runs multiple validators, all must pass
validate_all() {
  local value="$1"
  shift
  local validators=("$@")

  for validator in "${validators[@]}"; do
    if [[ "$($validator "$value")" == "failure" ]]; then
      echo "failure"
      return
    fi
  done
  echo "success"
}

# Combined validation - runs multiple validators, any can pass
validate_any() {
  local value="$1"
  shift
  local validators=("$@")

  for validator in "${validators[@]}"; do
    if [[ "$($validator "$value")" == "success" ]]; then
      echo "success"
      return
    fi
  done
  echo "failure"
}
