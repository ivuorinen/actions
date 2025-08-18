#!/usr/bin/env bash
# Test environment setup utilities
# Provides common setup functions for GitHub Actions testing

set -euo pipefail

# Global test configuration
export GITHUB_ACTIONS=true
export GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-ivuorinen/actions}"
export GITHUB_SHA="${GITHUB_SHA:-fake-sha}"
export GITHUB_REF="${GITHUB_REF:-refs/heads/main}"
export GITHUB_TOKEN="${GITHUB_TOKEN:-ghp_fake_token_for_testing}"

# Test framework directories
TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRAMEWORK_DIR="${TEST_ROOT}/framework"
FIXTURES_DIR="${FRAMEWORK_DIR}/fixtures"
MOCKS_DIR="${FRAMEWORK_DIR}/mocks"

# Export directories for use by other scripts
export FIXTURES_DIR MOCKS_DIR
TEMP_DIR=$(mktemp -d) || exit 1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Setup test environment
setup_test_env() {
  local test_name="${1:-unknown}"

  log_info "Setting up test environment for: $test_name"

  # Create temporary directory for test
  export TEST_TEMP_DIR="${TEMP_DIR}/${test_name}"
  mkdir -p "$TEST_TEMP_DIR"

  # Create fake GitHub workspace
  export TEST_WORKSPACE="${TEST_TEMP_DIR}/workspace"
  mkdir -p "$TEST_WORKSPACE"

  # Setup fake GitHub outputs
  export GITHUB_OUTPUT="${TEST_TEMP_DIR}/github-output"
  export GITHUB_ENV="${TEST_TEMP_DIR}/github-env"
  export GITHUB_PATH="${TEST_TEMP_DIR}/github-path"
  export GITHUB_STEP_SUMMARY="${TEST_TEMP_DIR}/github-step-summary"

  # Initialize output files
  touch "$GITHUB_OUTPUT" "$GITHUB_ENV" "$GITHUB_PATH" "$GITHUB_STEP_SUMMARY"

  # Change to test workspace
  cd "$TEST_WORKSPACE"

  log_success "Test environment setup complete"
}

# Cleanup test environment
cleanup_test_env() {
  local test_name="${1:-unknown}"

  log_info "Cleaning up test environment for: $test_name"

  if [[ -n ${TEST_TEMP_DIR:-} && -d $TEST_TEMP_DIR ]]; then
    rm -rf "$TEST_TEMP_DIR"
    log_success "Test environment cleanup complete"
  fi
}

# Cleanup framework temp directory
cleanup_framework_temp() {
  if [[ -n ${TEMP_DIR:-} && -d $TEMP_DIR ]]; then
    rm -rf "$TEMP_DIR"
    log_info "Framework temp directory cleaned up"
  fi
}

# Create a mock GitHub repository structure
create_mock_repo() {
  local repo_type="${1:-node}"

  case "$repo_type" in
  "node")
    create_mock_node_repo
    ;;
  "php")
    create_mock_php_repo
    ;;
  "python")
    create_mock_python_repo
    ;;
  "go")
    create_mock_go_repo
    ;;
  "dotnet")
    create_mock_dotnet_repo
    ;;
  *)
    log_warning "Unknown repo type: $repo_type"
    ;;
  esac
}

# Create mock Node.js repository
create_mock_node_repo() {
  cat >package.json <<EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "engines": {
    "node": ">=18.0.0"
  },
  "scripts": {
    "test": "npm test",
    "lint": "eslint .",
    "build": "npm run build"
  },
  "devDependencies": {
    "eslint": "^8.0.0"
  }
}
EOF

  echo "node_modules/" >.gitignore
  mkdir -p src
  echo 'console.log("Hello, World!");' >src/index.js
}

# Create mock PHP repository
create_mock_php_repo() {
  cat >composer.json <<EOF
{
  "name": "test/project",
  "type": "project",
  "require": {
    "php": "^8.1"
  },
  "require-dev": {
    "phpunit/phpunit": "^10.0"
  },
  "autoload": {
    "psr-4": {
      "App\\\\": "src/"
    }
  }
}
EOF

  mkdir -p src tests
  echo "<?php echo 'Hello, World!';" >src/index.php

  cat >phpunit.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<phpunit bootstrap="vendor/autoload.php">
    <testsuites>
        <testsuite name="Unit">
            <directory suffix="Test.php">./tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
EOF
}

# Create mock Python repository
create_mock_python_repo() {
  cat >pyproject.toml <<EOF
[tool.poetry]
name = "test-project"
version = "0.1.0"
description = ""

[tool.poetry.dependencies]
python = "^3.8"

[tool.poetry.dev-dependencies]
pytest = "^7.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOF

  echo "print('Hello, World!')" >main.py
  echo "3.9.0" >.python-version
}

# Create mock Go repository
create_mock_go_repo() {
  cat >go.mod <<EOF
module test-project

go 1.21

require (
    github.com/stretchr/testify v1.8.0
)
EOF

  cat >main.go <<EOF
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
EOF
}

# Create mock .NET repository
create_mock_dotnet_repo() {
  cat >global.json <<EOF
{
  "sdk": {
    "version": "8.0.0"
  }
}
EOF

  cat >TestProject.csproj <<EOF
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <OutputType>Exe</OutputType>
  </PropertyGroup>
</Project>
EOF

  echo 'Console.WriteLine("Hello, World!");' >Program.cs
}

# Validate action outputs
validate_action_output() {
  local expected_key="$1"
  local expected_value="$2"
  local output_file="${3:-$GITHUB_OUTPUT}"

  if grep -q "^${expected_key}=${expected_value}$" "$output_file"; then
    log_success "Output validation passed: $expected_key=$expected_value"
    return 0
  else
    log_error "Output validation failed: $expected_key=$expected_value not found"
    log_error "Actual outputs:"
    cat "$output_file" >&2
    return 1
  fi
}

# Run action locally (simulation)
run_action_step() {
  local action_path="$1"
  local step_name="$2"
  shift 2

  log_info "Running action step: $step_name"

  # Source the action's shell script (for composite actions)
  if [[ -f $action_path ]]; then
    # Set up inputs as environment variables
    while [[ $# -gt 0 ]]; do
      local key="$1"
      local value="$2"
      export "INPUT_${key^^}"="$value"
      shift 2
    done

    # Execute the action step
    bash "$action_path"
  else
    log_error "Action script not found: $action_path"
    return 1
  fi
}

# Check if required tools are available
check_required_tools() {
  local tools=("git" "jq" "curl" "python3" "tar" "make")
  local missing_tools=()

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    return 1
  fi

  log_success "All required tools are available"
  return 0
}

# Initialize testing framework
init_testing_framework() {
  log_info "Initializing GitHub Actions Testing Framework"

  # Check requirements
  check_required_tools

  # Temporary directory already created by mktemp above

  # Set up cleanup trap
  trap 'cleanup_framework_temp' EXIT

  log_success "Testing framework initialized"
}

# Export all functions for use in tests
export -f setup_test_env cleanup_test_env cleanup_framework_temp create_mock_repo
export -f create_mock_node_repo create_mock_php_repo create_mock_python_repo
export -f create_mock_go_repo create_mock_dotnet_repo
export -f validate_action_output run_action_step check_required_tools
export -f log_info log_success log_warning log_error
export -f init_testing_framework
