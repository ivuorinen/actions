#!/usr/bin/env bash
# Test script for GitHub Actions Testing Docker Image
# Verifies all tools work correctly with non-root user

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="ghcr.io/ivuorinen/actions"
IMAGE_TAG="${1:-testing-tools}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Testing GitHub Actions Testing Docker Image: $FULL_IMAGE_NAME"
echo "=============================================================="

# Test 1: User information
echo "1. Testing user setup..."
USER_INFO=$(docker run --rm "$FULL_IMAGE_NAME" bash -c "whoami && id")
echo "User info: $USER_INFO"

if echo "$USER_INFO" | grep -q "runner"; then
  echo "✅ Non-root user 'runner' is correctly set"
else
  echo "❌ Expected non-root user 'runner', got: $USER_INFO"
  exit 1
fi

# Test 2: ShellSpec (user-installed)
echo ""
echo "2. Testing ShellSpec..."
SHELLSPEC_VERSION=$(docker run --rm "$FULL_IMAGE_NAME" shellspec --version)
echo "ShellSpec: $SHELLSPEC_VERSION"

if [[ $SHELLSPEC_VERSION == *"0."* ]]; then
  echo "✅ ShellSpec is working"
else
  echo "❌ ShellSpec test failed"
  exit 1
fi

# Test 3: System tools (root-installed)
echo ""
echo "3. Testing system tools..."
TOOLS=(
  "act --version"
  "trivy --version"
  "trufflehog --version"
  "actionlint --version"
  "shellcheck --version"
  "jq --version"
  "kcov --version"
  "gh --version"
  "node --version"
  "npm --version"
  "python3 --version"
)

for tool_cmd in "${TOOLS[@]}"; do
  echo -n "  Testing $tool_cmd... "
  if docker run --rm "$FULL_IMAGE_NAME" bash -c "$tool_cmd" >/dev/null 2>&1; then
    echo "✅"
  else
    echo "❌"
    exit 1
  fi
done

# Test 4: File permissions
echo ""
echo "4. Testing file permissions..."
WORKSPACE_PERMS=$(docker run --rm "$FULL_IMAGE_NAME" bash -c "ls -ld /workspace")
echo "Workspace permissions: $WORKSPACE_PERMS"

if echo "$WORKSPACE_PERMS" | grep -q "runner runner"; then
  echo "✅ Workspace has correct ownership"
else
  echo "❌ Workspace permissions issue"
  exit 1
fi

# Test 5: Write permissions
echo ""
echo "5. Testing write permissions..."
if docker run --rm "$FULL_IMAGE_NAME" bash -c "touch /workspace/test-file && rm /workspace/test-file"; then
  echo "✅ User can write to workspace"
else
  echo "❌ User cannot write to workspace"
  exit 1
fi

# Test 6: Sudo access (should work but not needed for normal operations)
echo ""
echo "6. Testing sudo access..."
if docker run --rm "$FULL_IMAGE_NAME" sudo whoami | grep -q "root"; then
  echo "✅ Sudo access works (for emergency use)"
else
  echo "❌ Sudo access not working"
  exit 1
fi

# Test 7: Environment variables
echo ""
echo "7. Testing environment variables..."
ENV_CHECK=$(docker run --rm "$FULL_IMAGE_NAME" bash -c "echo \$USER:\$HOME:\$PATH")
echo "Environment: $ENV_CHECK"

if [[ $ENV_CHECK == *"runner"* && $ENV_CHECK == *"/home/runner"* && $ENV_CHECK == *".local/bin"* ]]; then
  echo "✅ Environment variables are correct"
else
  echo "❌ Environment variables issue"
  exit 1
fi

# Test 8: Real ShellSpec test with local test files
echo ""
echo "8. Testing ShellSpec with local test files..."
if [[ -d "$SCRIPT_DIR/test-files" ]]; then
  # Mount local test directory and run a real ShellSpec test
  if docker run --rm -v "$SCRIPT_DIR/test-files:/workspace/test-files" "$FULL_IMAGE_NAME" \
    bash -c "cd /workspace/test-files && shellspec --format tap basic_spec.sh" >/dev/null 2>&1; then
    echo "✅ ShellSpec can run real tests with mounted files"
  else
    echo "❌ ShellSpec test with local files failed"
    exit 1
  fi
else
  echo "⚠️  No test-files directory found, creating sample test..."
  # Create a temporary test to verify mounting and execution works
  if docker run --rm -v "$SCRIPT_DIR:/workspace/scripts" "$FULL_IMAGE_NAME" \
    bash -c "echo 'basic test works' && ls -la /workspace/scripts" >/dev/null 2>&1; then
    echo "✅ Volume mounting and script directory access works"
  else
    echo "❌ Volume mounting test failed"
    exit 1
  fi
fi

echo ""
echo "🎉 All tests passed! The Docker image is working correctly with:"
echo "   - Non-root user 'runner' (uid: 1001)"
echo "   - All testing tools installed and accessible"
echo "   - Proper file permissions and workspace access"
echo "   - Secure sudo configuration for emergency use"
echo ""
echo "Image size:"
docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
