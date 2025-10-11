# GitHub Actions Testing Framework Docker Image
# Multi-stage build with non-root user for security
# Pre-installs all testing tools to reduce CI runtime

# Stage 1: Base system setup
FROM ubuntu:22.04 AS base

LABEL maintainer="ivuorinen"
LABEL description="GitHub Actions testing framework with pre-installed tools"
LABEL version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/ivuorinen/actions"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies and common tools
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y \
  --no-install-recommends \
  curl \
  git \
  unzip \
  tar \
  gzip \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  build-essential \
  shellcheck \
  kcov \
  python3 \
  python3-pip \
  python3-yaml \
  sudo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS (avoid curl | bash by using repository directly)
# hadolint ignore=DL3008
RUN NODE_MAJOR=20 \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /tmp/nodesource.gpg.key \
  && gpg --dearmor -o /usr/share/keyrings/nodesource.gpg < /tmp/nodesource.gpg.key \
  && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/nodesource.gpg.key

# Stage 2: Tool installation
FROM base AS tools

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Version pinning for security and reproducibility
ARG TRUFFLEHOG_VERSION=3.86.0
ARG ACTIONLINT_VERSION=1.7.7
ARG ACT_VERSION=0.2.71
ARG SHELLSPEC_VERSION=0.28.1

# Install Trivy security scanner (avoid curl | apt-key, use signed-by)
# hadolint ignore=DL3008
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key -o /tmp/trivy.key \
  && gpg --dearmor -o /usr/share/keyrings/trivy.gpg < /tmp/trivy.key \
  && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends trivy \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/trivy.key

# Install GitHub CLI with GPG verification (avoid piping to shell)
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /tmp/githubcli-archive-keyring.gpg \
  && cat /tmp/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/githubcli-archive-keyring.gpg

# Install additional dependencies needed by install scripts
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y \
  --no-install-recommends \
  xz-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install standalone tools that don't need system packages
# Split into separate commands for better error reporting
# All installations download pinned releases directly (no piped scripts)

# Install trufflehog with checksum verification
RUN arch="$(dpkg --print-architecture)" \
  && case "${arch}" in \
  amd64) trufflehog_arch="amd64" ;; \
  arm64) trufflehog_arch="arm64" ;; \
  *) echo "Unsupported architecture: ${arch}" && exit 1 ;; \
  esac \
  && tarball="trufflehog_${TRUFFLEHOG_VERSION}_linux_${trufflehog_arch}.tar.gz" \
  && curl -fsSL "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/${tarball}" -o "/tmp/${tarball}" \
  && curl -fsSL "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_checksums.txt" -o /tmp/checksums.txt \
  && grep "${tarball}" /tmp/checksums.txt | sed "s|${tarball}|/tmp/${tarball}|" | sha256sum -c - \
  && tar -xzf "/tmp/${tarball}" -C /tmp \
  && chmod +x /tmp/trufflehog \
  && mv /tmp/trufflehog /usr/local/bin/trufflehog \
  && rm -f "/tmp/${tarball}" /tmp/checksums.txt \
  && trufflehog --version

# Install actionlint with checksum verification
RUN arch="$(dpkg --print-architecture)" \
  && case "${arch}" in \
  amd64) actionlint_arch="amd64" ;; \
  arm64) actionlint_arch="arm64" ;; \
  *) echo "Unsupported architecture: ${arch}" && exit 1 ;; \
  esac \
  && tarball="actionlint_${ACTIONLINT_VERSION}_linux_${actionlint_arch}.tar.gz" \
  && curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/${tarball}" -o "/tmp/${tarball}" \
  && curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_checksums.txt" -o /tmp/checksums.txt \
  && grep "${tarball}" /tmp/checksums.txt | sed "s|${tarball}|/tmp/${tarball}|" | sha256sum -c - \
  && tar -xzf "/tmp/${tarball}" -C /tmp \
  && chmod +x /tmp/actionlint \
  && mv /tmp/actionlint /usr/local/bin/actionlint \
  && rm -f "/tmp/${tarball}" /tmp/checksums.txt \
  && actionlint --version

# Install nektos/act with checksum verification
RUN arch="$(dpkg --print-architecture)" \
  && case "${arch}" in \
  amd64) act_arch="Linux_x86_64" ;; \
  arm64) act_arch="Linux_arm64" ;; \
  *) echo "Unsupported architecture: ${arch}" && exit 1 ;; \
  esac \
  && tarball="act_${act_arch}.tar.gz" \
  && curl -fsSL "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/${tarball}" -o "/tmp/${tarball}" \
  && curl -fsSL "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/checksums.txt" -o /tmp/checksums.txt \
  && grep "${tarball}" /tmp/checksums.txt | sed "s|${tarball}|/tmp/${tarball}|" | sha256sum -c - \
  && tar -xzf "/tmp/${tarball}" -C /tmp \
  && chmod +x /tmp/act \
  && mv /tmp/act /usr/local/bin/act \
  && rm -f "/tmp/${tarball}" /tmp/checksums.txt \
  && act --version \
  && echo "Verifying system integrity..." \
  && test -f /bin/sh && test -f /bin/bash && echo "✓ Shell binaries intact"

# Stage 3: Final image with non-root user
FROM tools AS final

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Create non-root user for security
ARG USERNAME=runner
ARG USER_UID=1001
ARG USER_GID=$USER_UID
ARG SHELLSPEC_VERSION=0.28.1

# Set up environment for testing
ENV PATH="/home/$USERNAME/.local/bin:$PATH"
ENV USER=$USERNAME
ENV HOME="/home/$USERNAME"

# Create the user and group
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash

# Grant passwordless sudo to runner user for testing scenarios
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# Create workspace directory with proper permissions (as root)
RUN mkdir -p /workspace \
  && chown -R $USERNAME:$USERNAME /workspace

# Switch to non-root user for ShellSpec installation
USER $USERNAME
WORKDIR /workspace

# Install ShellSpec testing framework in user's home
# Note: ShellSpec does not provide checksum files in releases, using official dist tarball
# hadolint ignore=SC2016
RUN mkdir -p ~/.local/bin \
  && tarball="shellspec-dist.tar.gz" \
  && curl -fsSL "https://github.com/shellspec/shellspec/releases/download/${SHELLSPEC_VERSION}/${tarball}" -o "/tmp/${tarball}" \
  && tar -xzf "/tmp/${tarball}" -C "$HOME/.local" \
  && ln -s "$HOME/.local/shellspec/shellspec" "$HOME/.local/bin/shellspec" \
  && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc \
  && shellspec --version \
  && rm -f "/tmp/${tarball}"

# Verify installations (run as root to access all tools)
RUN echo "=== Tool Versions ===" \
  && shellcheck --version \
  && jq --version \
  && kcov --version \
  && trivy --version \
  && trufflehog --version \
  && actionlint --version \
  && act --version \
  && gh --version \
  && node --version \
  && npm --version \
  && python3 --version \
  && echo "=== System tools verified ==="

# Verify user-installed tools
RUN shellspec --version \
  && echo "=== User tools verified ==="

# Health check to verify essential tools are available
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD shellcheck --version && jq --version || exit 1

# Default command runs as non-root user
CMD ["sleep", "infinity"]
