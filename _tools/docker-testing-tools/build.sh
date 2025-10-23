#!/bin/sh
# Build script for GitHub Actions Testing Docker Image

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="ghcr.io/ivuorinen/actions"
IMAGE_TAG="${1:-testing-tools}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

printf 'Building GitHub Actions Testing Docker Image...\n'
printf 'Image: %s\n' "$FULL_IMAGE_NAME"

# Enable BuildKit for better caching and performance
export DOCKER_BUILDKIT=1

# Build the multi-stage image
# Check for buildx support up front, then run the appropriate build command
if docker buildx version >/dev/null 2>&1; then
  printf 'Using buildx (multi-arch capable)\n'
  docker buildx build \
    --pull \
    --tag "$FULL_IMAGE_NAME" \
    --file "$SCRIPT_DIR/Dockerfile" \
    --target final \
    --load \
    "$SCRIPT_DIR"
else
  printf '⚠️  buildx not available, using standard docker build\n'
  docker build \
    --pull \
    --tag "$FULL_IMAGE_NAME" \
    --file "$SCRIPT_DIR/Dockerfile" \
    --target final \
    "$SCRIPT_DIR"
fi

printf 'Build completed successfully!\n'
printf '\n'
printf 'Testing the image...\n'

# Test basic functionality
docker run --rm "$FULL_IMAGE_NAME" whoami
docker run --rm "$FULL_IMAGE_NAME" shellspec --version
docker run --rm "$FULL_IMAGE_NAME" act --version

printf 'Image tests passed!\n'
printf '\n'
printf 'To test the image locally:\n'
printf '  docker run --rm -it %s\n' "$FULL_IMAGE_NAME"
printf '\n'
printf 'To push to registry:\n'
printf '  docker push %s\n' "$FULL_IMAGE_NAME"
printf '\n'
printf 'To use in GitHub Actions:\n'
printf '  container: %s\n' "$FULL_IMAGE_NAME"
