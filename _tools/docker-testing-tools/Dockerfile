# GitHub Actions Testing Framework Docker Image
# Multi-stage build with non-root user for security
# Pre-installs all testing tools to reduce CI runtime

# Centralized ARG defaults to avoid version drift across stages. Renovate bumps each version
# through its comment; the SHA-256 of each archive in the tools stage is for the version
# here, so a bump fails the build until those values match the new release.
# KCOV_COMMIT is the commit the v${KCOV_VERSION} tag points to, which a moved tag fails to check out.
# renovate: datasource=github-tags depName=SimonKagstrom/kcov extractVersion=^v(?<version>.+)$
ARG KCOV_VERSION=43
ARG KCOV_COMMIT=a39874f938ce13f7a65f253120d1ec946b349ffe
# renovate: datasource=github-releases depName=trufflesecurity/trufflehog extractVersion=^v(?<version>.+)$
ARG TRUFFLEHOG_VERSION=3.99.7
# renovate: datasource=github-releases depName=jdx/jactionlint extractVersion=^v(?<version>.+)$
ARG JACTIONLINT_VERSION=2.6.0
# renovate: datasource=github-releases depName=nektos/act extractVersion=^v(?<version>.+)$
ARG ACT_VERSION=0.2.82
# renovate: datasource=github-releases depName=aquasecurity/trivy extractVersion=^v(?<version>.+)$
ARG TRIVY_VERSION=0.70.0
# renovate: datasource=github-releases depName=cli/cli extractVersion=^v(?<version>.+)$
ARG GH_VERSION=2.105.0
# renovate: datasource=github-releases depName=shellspec/shellspec
ARG SHELLSPEC_VERSION=0.28.1
# renovate: datasource=github-releases depName=mvdan/sh extractVersion=^v(?<version>.+)$
ARG SHFMT_VERSION=3.14.1

# Stage 1: Build kcov separately to keep final image slim
FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db AS kcov-builder

ARG KCOV_VERSION
ARG KCOV_COMMIT

# Install only build dependencies needed for kcov
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    g++ \
    git \
    libcurl4-openssl-dev \
    libdw-dev \
    libelf-dev \
    libiberty-dev \
    libssl-dev \
    make \
    pkg-config \
    python3 \
    zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Build kcov from source
WORKDIR /tmp/kcov-build
RUN git clone --depth 1 --branch "v${KCOV_VERSION}" https://github.com/SimonKagstrom/kcov.git . \
  && git checkout "${KCOV_COMMIT}"

WORKDIR /tmp/kcov-build/build
RUN cmake .. \
  && make \
  && make install DESTDIR=/kcov-install

# Stage 2: Base system setup
FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db AS base

LABEL maintainer="ivuorinen"
LABEL description="GitHub Actions testing framework with pre-installed tools"
LABEL version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/ivuorinen/actions"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies and common tools.
# Ubuntu 26.04 ships nodejs 22.x and npm in the universe repo, so the NodeSource
# repo previously used to install Node 20 on 24.04 is no longer required —
# Ubuntu 26.04's native nodejs/npm pair installs cleanly without the
# NodeSource-vs-Ubuntu apt conflict (NodeSource's nodejs Conflicts with
# Ubuntu's npm package).
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y \
  --no-install-recommends \
  ca-certificates \
  curl \
  git \
  gzip \
  jq \
  nodejs \
  npm \
  python3 \
  python3-pip \
  python3-yaml \
  shellcheck \
  sudo \
  tar \
  unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Stage 2: Tool installation
FROM base AS tools

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Version pinning for security and reproducibility (inherit from global ARGs)
ARG TRUFFLEHOG_VERSION
ARG JACTIONLINT_VERSION
ARG ACT_VERSION
ARG TRIVY_VERSION
ARG GH_VERSION
ARG SHELLSPEC_VERSION
ARG SHFMT_VERSION

# Install the standalone tools in a single layer. Each comes from its release archive and is
# installed only when the archive's SHA-256 matches the value pinned below, rather than a
# checksums file from the same release, which would be replaced along with the archive.
# hadolint ignore=DL3008
RUN set -eux \
  && arch="$(dpkg --print-architecture)" \
  && case "${arch}" in \
    amd64) \
      trufflehog_sha256="bdbea0508e439b144f49de14e775908de5f902f3d14ea7ae8354bae72b0b72ef"; \
      jactionlint_sha256="d5400967b8f0d3a5ae9a4cee21f56400a50eb3f05d0cbb4ef17184f17f0760c8"; \
      act_arch="x86_64"; act_sha256="76645c0bbe4bb69a8f0ba3caefa681b2f4c04babd4679c67861af9a276a3561f"; \
      trivy_arch="64bit"; trivy_sha256="8b4376d5d6befe5c24d503f10ff136d9e0c49f9127a4279fd110b727929a5aa9"; \
      gh_sha256="79e7ab5db738c48777b696e374f8b428f0647debfb424f44d2f426370407fe2f"; \
      shfmt_sha256="76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf" ;; \
    arm64) \
      trufflehog_sha256="3060f7c9f18c70afdc432984cacabdd1e9103729b5d5fee7fb6755a90d1c59d4"; \
      jactionlint_sha256="c726185a85f26d09aa94ea556509a19827979074b35d65f357f3a4947573e934"; \
      act_arch="arm64"; act_sha256="ebf375e700f6f2c139fe3c5508af2ec85032a75e7d29f6a388a58c0fab76e951"; \
      trivy_arch="ARM64"; trivy_sha256="2f6bb988b553a1bbac6bdd1ce890f5e412439564e17522b88a4541b4f364fc8d"; \
      gh_sha256="b1278c75107423d818f1937fd92cafc9e5e9b606631568f68d7fb816f5885a02"; \
      shfmt_sha256="5f2db09dae91fca848f7adbdd014632e921a383863a2ad7e0450ad3aba0c6489" ;; \
    *) echo "Unsupported architecture: ${arch}" && exit 1 ;; \
  esac \
  && apt-get update \
  && apt-get install -y --no-install-recommends xz-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # fetch URL SHA256 FILE: download URL to /tmp/FILE and check it against SHA256.
  && fetch() { \
    curl -fsSL --proto '=https' --tlsv1.2 "$1" -o "/tmp/$3" \
    && echo "$2  /tmp/$3" | sha256sum -c -; \
  } \
  && echo "=== Downloading and verifying standalone tools ===" \
  && fetch "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_${arch}.tar.gz" \
    "$trufflehog_sha256" trufflehog.tar.gz \
  && fetch "https://github.com/jdx/jactionlint/releases/download/v${JACTIONLINT_VERSION}/jactionlint_${JACTIONLINT_VERSION}_linux_${arch}.tar.gz" \
    "$jactionlint_sha256" jactionlint.tar.gz \
  && fetch "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${act_arch}.tar.gz" \
    "$act_sha256" act.tar.gz \
  && fetch "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz" \
    "$trivy_sha256" trivy.tar.gz \
  && fetch "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${arch}.tar.gz" \
    "$gh_sha256" gh.tar.gz \
  # shfmt, which the posix-shell tests parse run: scripts with, is a bare binary.
  && fetch "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${arch}" \
    "$shfmt_sha256" shfmt \
  && echo "=== Installing standalone tools ===" \
  && tar -xzf /tmp/trufflehog.tar.gz -C /tmp trufflehog \
  && tar -xzf /tmp/jactionlint.tar.gz -C /tmp jactionlint \
  && tar -xzf /tmp/act.tar.gz -C /tmp act \
  && tar -xzf /tmp/trivy.tar.gz -C /tmp trivy \
  && tar -xzf /tmp/gh.tar.gz -C /tmp "gh_${GH_VERSION}_linux_${arch}/bin/gh" \
  && install -m 0755 /tmp/trufflehog /tmp/jactionlint /tmp/act /tmp/trivy /tmp/shfmt /usr/local/bin/ \
  && install -m 0755 "/tmp/gh_${GH_VERSION}_linux_${arch}/bin/gh" /usr/local/bin/gh \
  && rm -rf /tmp/*.tar.gz /tmp/trufflehog /tmp/jactionlint /tmp/act /tmp/trivy /tmp/shfmt "/tmp/gh_${GH_VERSION}_linux_${arch}" \
  # Verify all installations
  && echo "=== Verifying tool installations ===" \
  && trivy --version \
  && gh --version \
  && trufflehog --version \
  && jactionlint --version \
  && act --version \
  && shfmt --version \
  && test -f /bin/sh && test -f /bin/bash && echo "✓ Shell binaries intact" \
  && echo "=== All tools installed successfully ==="

# Stage 3: Final image with non-root user
FROM tools AS final

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Tests run as a non-root user by default. It has passwordless sudo, which tests that install
# packages need, so it is a convenience and not a security boundary.
ARG USERNAME=runner
ARG USER_UID=1001
ARG USER_GID=$USER_UID
ARG SHELLSPEC_VERSION

# Set up environment for testing
ENV PATH="/home/$USERNAME/.local/bin:$PATH"
ENV USER=$USERNAME
ENV HOME="/home/$USERNAME"

# Create the user and group, then
# grant passwordless sudo to runner user for testing scenarios, then
# create workspace directory with proper permissions (as root)
# checkov:skip=CKV2_DOCKER_1:workspace is created via RUN mkdir, not COPY; --chown flag is not applicable here
RUN groupadd --gid "$USER_GID" "$USERNAME" \
  && useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME" -s /bin/bash \
  && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
  && chmod 0440 "/etc/sudoers.d/$USERNAME" \
  && mkdir -p /workspace \
  && chown -R "$USERNAME:$USERNAME" /workspace

# Copy kcov from builder stage (avoiding build dependencies in final image)
# kcov is built at KCOV_VERSION in its own stage, so its build dependencies stay out of this image
COPY --from=kcov-builder /kcov-install/usr/local/ /usr/local/

# Install only runtime dependencies for kcov (not build dependencies)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libcurl4 \
    libdw1 \
    libelf1 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Switch to non-root user for ShellSpec installation
USER "$USERNAME"
WORKDIR /workspace

# Install ShellSpec testing framework in user's home with checksum verification, then
# verify installations (run as root to access all tools)
# ShellSpec - version-aware checksum verification
# hadolint ignore=SC2016
RUN set -eux; \
  mkdir -p ~/.local/bin; \
  tarball="shellspec-dist.tar.gz"; \
  # Pinned SHA-256 checksum for ShellSpec 0.28.1 shellspec-dist.tar.gz
  # Source: https://github.com/shellspec/shellspec/releases/download/0.28.1/shellspec-dist.tar.gz
  expected_checksum="350d3de04ba61505c54eda31a3c2ee912700f1758b1a80a284bc08fd8b6c5992"; \
  \
  # Download ShellSpec
  curl -fsSL --proto '=https' --tlsv1.2 \
    "https://github.com/shellspec/shellspec/releases/download/${SHELLSPEC_VERSION}/${tarball}" \
    -o "/tmp/${tarball}"; \
  \
  # Verify checksum
  actual_checksum=$(sha256sum "/tmp/${tarball}" | awk '{print $1}'); \
  if [ "${actual_checksum}" != "${expected_checksum}" ]; then \
    echo "Error: Checksum verification failed for ShellSpec ${SHELLSPEC_VERSION}" >&2; \
    echo "Expected: ${expected_checksum}" >&2; \
    echo "Got:      ${actual_checksum}" >&2; \
    rm -f "/tmp/${tarball}"; \
    exit 1; \
  fi; \
  echo "Checksum verified successfully"; \
  \
  tar -xzf "/tmp/${tarball}" -C "$HOME/.local"; \
  ln -s "$HOME/.local/shellspec/shellspec" "$HOME/.local/bin/shellspec"; \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc; \
  shellspec --version; \
  rm -f "/tmp/${tarball}" \
  && echo "ShellSpec installed successfully" \
  && echo "Verifying installed tool versions..." \
  && echo "=== Tool Versions ===" \
  && shellcheck --version \
  && jq --version \
  && kcov --version \
  && trivy --version \
  && trufflehog --version \
  && jactionlint --version \
  && act --version \
  && gh --version \
  && node --version \
  && npm --version \
  && python3 --version \
  && echo "=== System tools verified ===" \
  && echo "=== Verify user-installed tools ===" \
  && shellspec --version \
  && echo "=== User tools verified ===" \
  && echo "=== Build complete ==="

# Health check to verify essential tools are accessible
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD shellspec --version > /dev/null 2>&1 && \
      shellcheck --version > /dev/null 2>&1 && \
      jq --version > /dev/null 2>&1 || exit 1

# Default command keeps container running for GitHub Actions
CMD ["/bin/bash", "-c", "tail -f /dev/null"]
