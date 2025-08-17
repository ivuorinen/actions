#!/usr/bin/env bash
# Mock GitHub API for testing
# Provides fake responses for GitHub API endpoints

set -euo pipefail

MOCK_API_PORT="${MOCK_API_PORT:-8888}"
MOCK_API_HOST="${MOCK_API_HOST:-localhost}"
MOCK_API_URL="http://${MOCK_API_HOST}:${MOCK_API_PORT}"

# Mock responses directory
MOCK_RESPONSES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/responses"
mkdir -p "$MOCK_RESPONSES_DIR"

# Start mock API server
start_mock_api_server() {
  log_info "Starting mock GitHub API server on port $MOCK_API_PORT"

  # Create mock responses
  create_mock_responses

  # Start simple HTTP server using Python
  if command -v python3 >/dev/null 2>&1; then
    (cd "$MOCK_RESPONSES_DIR" && python3 -m http.server "$MOCK_API_PORT" >/dev/null 2>&1) &
    MOCK_API_PID=$!

    # Wait for server to start
    sleep 2

    if kill -0 "$MOCK_API_PID" 2>/dev/null; then
      log_success "Mock API server started with PID: $MOCK_API_PID"
      export MOCK_API_PID
      export GITHUB_API_URL="$MOCK_API_URL"
    else
      log_error "Failed to start mock API server"
      return 1
    fi
  else
    log_error "Python3 not available for mock server"
    return 1
  fi
}

# Stop mock API server
stop_mock_api_server() {
  if [[ -n ${MOCK_API_PID:-} ]]; then
    log_info "Stopping mock API server (PID: $MOCK_API_PID)"
    if kill "$MOCK_API_PID" 2>/dev/null; then
      log_success "Mock API server stopped"
    else
      log_warning "Mock API server may have already stopped"
    fi
    unset MOCK_API_PID
  fi
}

# Create mock API responses
create_mock_responses() {
  log_info "Creating mock API responses"

  # Mock repository information
  cat >"${MOCK_RESPONSES_DIR}/repos_ivuorinen_actions.json" <<EOF
{
  "id": 123456789,
  "name": "actions",
  "full_name": "ivuorinen/actions",
  "owner": {
    "login": "ivuorinen",
    "id": 12345,
    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
    "type": "User"
  },
  "private": false,
  "html_url": "https://github.com/ivuorinen/actions",
  "description": "GitHub Actions monorepo with 41 reusable actions",
  "created_at": "2023-01-01T00:00:00Z",
  "updated_at": "2025-08-11T10:00:00Z",
  "pushed_at": "2025-08-11T10:00:00Z",
  "size": 1024,
  "stargazers_count": 42,
  "watchers_count": 42,
  "language": "Shell",
  "default_branch": "main"
}
EOF

  # Mock releases
  cat >"${MOCK_RESPONSES_DIR}/repos_ivuorinen_actions_releases.json" <<EOF
[
  {
    "id": 987654321,
    "tag_name": "v1.0.0",
    "name": "v1.0.0",
    "body": "Initial release of GitHub Actions monorepo",
    "draft": false,
    "prerelease": false,
    "created_at": "2025-08-01T00:00:00Z",
    "published_at": "2025-08-01T00:00:00Z",
    "author": {
      "login": "ivuorinen",
      "id": 12345
    },
    "assets": []
  }
]
EOF

  # Mock user information
  cat >"${MOCK_RESPONSES_DIR}/user.json" <<EOF
{
  "login": "ivuorinen",
  "id": 12345,
  "avatar_url": "https://github.com/images/error/octocat_happy.gif",
  "name": "Ismo Vuorinen",
  "email": "ismo@example.com",
  "public_repos": 50,
  "public_gists": 10,
  "followers": 100,
  "following": 50,
  "created_at": "2020-01-01T00:00:00Z"
}
EOF

  # Mock packages (for publishing tests)
  cat >"${MOCK_RESPONSES_DIR}/user_packages.json" <<EOF
[
  {
    "id": 111111,
    "name": "test-package",
    "package_type": "npm",
    "visibility": "public",
    "url": "https://api.github.com/users/ivuorinen/packages/npm/test-package",
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-08-11T00:00:00Z"
  }
]
EOF

  # Mock workflow runs
  cat >"${MOCK_RESPONSES_DIR}/repos_ivuorinen_actions_actions_runs.json" <<EOF
{
  "total_count": 1,
  "workflow_runs": [
    {
      "id": 555666777,
      "name": "Test Workflow",
      "head_branch": "main",
      "head_sha": "abc123def456",
      "status": "completed",
      "conclusion": "success",
      "workflow_id": 123,
      "created_at": "2025-08-11T09:00:00Z",
      "updated_at": "2025-08-11T09:05:00Z",
      "run_started_at": "2025-08-11T09:00:30Z"
    }
  ]
}
EOF

  # Mock issue labels (for sync-labels action)
  cat >"${MOCK_RESPONSES_DIR}/repos_ivuorinen_actions_labels.json" <<EOF
[
  {
    "id": 1001,
    "name": "bug",
    "color": "d73a4a",
    "description": "Something isn't working",
    "default": true
  },
  {
    "id": 1002,
    "name": "enhancement",
    "color": "a2eeef",
    "description": "New feature or request",
    "default": true
  }
]
EOF

  # Mock container registry
  mkdir -p "${MOCK_RESPONSES_DIR}/v2"
  cat >"${MOCK_RESPONSES_DIR}/v2/_catalog.json" <<EOF
{
  "repositories": [
    "ivuorinen/test-app",
    "ivuorinen/another-app"
  ]
}
EOF

  log_success "Mock API responses created"
}

# Mock curl command for GitHub API calls
mock_github_api_call() {
  local url="$1"
  local method="${2:-GET}"

  # Data parameter reserved for future POST/PUT request mocking
  # Currently unused but kept for API consistency

  log_info "Mock API call: $method $url"

  # Extract endpoint from URL
  local endpoint
  endpoint=$(echo "$url" | sed 's|https://api.github.com/||' | tr '/' '_')

  local response_file="${MOCK_RESPONSES_DIR}/${endpoint}.json"

  if [[ -f $response_file ]]; then
    cat "$response_file"
    return 0
  else
    # Return generic success response
    case "$method" in
    "POST" | "PUT" | "PATCH")
      echo '{"message": "Success", "status": "ok"}'
      ;;
    "DELETE")
      echo '{"message": "Deleted", "status": "ok"}'
      ;;
    *)
      echo '{"message": "Not Found", "status": "error"}' >&2
      return 1
      ;;
    esac
  fi
}

# Mock npm registry calls
mock_npm_registry_call() {
  local url="$1"
  local method="${2:-GET}"

  log_info "Mock NPM registry call: $method $url"

  case "$method" in
  "PUT")
    # Mock successful publish
    echo '{"ok": true, "id": "test-package", "rev": "1-abc123"}'
    ;;
  "GET")
    # Mock package info
    echo '{"name": "test-package", "version": "1.0.0", "description": "Test package"}'
    ;;
  *)
    echo '{"error": "Method not allowed"}' >&2
    return 1
    ;;
  esac
}

# Mock Docker registry calls
mock_docker_registry_call() {
  local url="$1"
  local method="${2:-GET}"

  log_info "Mock Docker registry call: $method $url"

  case "$url" in
  *"/v2/")
    # Registry API version check
    echo '{}'
    ;;
  *"/manifests/"*)
    case "$method" in
    "PUT")
      echo '{"digest": "sha256:abc123def456"}'
      ;;
    "GET")
      echo '{"schemaVersion": 2, "mediaType": "application/vnd.docker.distribution.manifest.v2+json"}'
      ;;
    esac
    ;;
  *"/blobs/"*)
    case "$method" in
    "POST")
      echo '{"uuid": "upload-uuid-123"}'
      ;;
    "PUT")
      echo '{"digest": "sha256:layer123"}'
      ;;
    esac
    ;;
  *)
    echo '{"errors": [{"code": "NOT_FOUND", "message": "repository not found"}]}' >&2
    return 1
    ;;
  esac
}

# Setup mock environment for testing
setup_mock_environment() {
  log_info "Setting up mock environment for API testing"

  # Override curl command to use mocks
  export MOCK_CURL=true

  # Create mock curl function
  cat >"${TEMP_DIR}/mock_curl.sh" <<'EOF'
#!/bin/bash
# Mock curl command for testing

if [[ "$1" == "-s" ]]; then
    shift
fi

url="$1"

case "$url" in
    "https://api.github.com/"*)
        source "$(dirname "$0")/../framework/mocks/github-api.sh"
        mock_github_api_call "$@"
        ;;
    "https://registry.npmjs.org/"*)
        source "$(dirname "$0")/../framework/mocks/github-api.sh"
        mock_npm_registry_call "$@"
        ;;
    "https://ghcr.io/"*|"https://docker.io/"*)
        source "$(dirname "$0")/../framework/mocks/github-api.sh"
        mock_docker_registry_call "$@"
        ;;
    *)
        # Fall back to real curl for other URLs
        command curl "$@"
        ;;
esac
EOF

  chmod +x "${TEMP_DIR}/mock_curl.sh"

  # Add mock curl to PATH
  export PATH="${TEMP_DIR}:$PATH"

  log_success "Mock environment setup complete"
}

# Cleanup mock environment
cleanup_mock_environment() {
  stop_mock_api_server

  if [[ -f "${TEMP_DIR}/mock_curl.sh" ]]; then
    rm -f "${TEMP_DIR}/mock_curl.sh"
  fi

  log_info "Mock environment cleaned up"
}

# Export functions
export -f start_mock_api_server stop_mock_api_server create_mock_responses
export -f mock_github_api_call mock_npm_registry_call mock_docker_registry_call
export -f setup_mock_environment cleanup_mock_environment
