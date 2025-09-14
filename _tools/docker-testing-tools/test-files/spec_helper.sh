#!/usr/bin/env bash
# ShellSpec helper for Docker testing environment

# Set up common test environment
set -euo pipefail

# Helper functions for tests
ensure_workspace() {
  [[ -d /workspace ]] || mkdir -p /workspace
}

cleanup_test_files() {
  find /workspace -name "test-*" -type f -delete 2>/dev/null || true
}
