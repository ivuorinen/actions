#!/usr/bin/env bash
# Build script for GitHub Actions Testing Docker Image

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="ghcr.io/ivuorinen/actions"
IMAGE_TAG="${1:-testing-tools}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building GitHub Actions Testing Docker Image..."
echo "Image: $FULL_IMAGE_NAME"

# Enable BuildKit for better caching and performance
export DOCKER_BUILDKIT=1

# Build the multi-stage image
# Check for buildx support up front, then run the appropriate build command
if docker buildx version >/dev/null 2>&1; then
  echo "Using buildx (multi-arch capable)"
  docker buildx build \
    --pull \
    --tag "$FULL_IMAGE_NAME" \
    --file "$SCRIPT_DIR/Dockerfile" \
    --target final \
    --load \
    "$SCRIPT_DIR"
else
  echo "⚠️  buildx not available, using standard docker build"
  docker build \
    --pull \
    --tag "$FULL_IMAGE_NAME" \
    --file "$SCRIPT_DIR/Dockerfile" \
    --target final \
    "$SCRIPT_DIR"
fi

echo "Build completed successfully!"
echo ""
echo "Testing the image..."

# Test basic functionality
docker run --rm "$FULL_IMAGE_NAME" whoami
docker run --rm "$FULL_IMAGE_NAME" shellspec --version
docker run --rm "$FULL_IMAGE_NAME" act --version

echo "Image tests passed!"
echo ""
echo "To test the image locally:"
echo "  docker run --rm -it $FULL_IMAGE_NAME"
echo ""
echo "To push to registry:"
echo "  docker push $FULL_IMAGE_NAME"
echo ""
echo "To use in GitHub Actions:"
echo "  container: $FULL_IMAGE_NAME"
