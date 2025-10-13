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
ENV NODE_MAJOR=20

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies and common tools
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y \
  --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  git \
  gnupg \
  gzip \
  jq \
  kcov \
  lsb-release \
  python3 \
  python3-pip \
  python3-yaml \
  shellcheck \
  sudo \
  tar \
  unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL --proto '=https' --tlsv1.2 https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /tmp/nodesource.gpg.key \
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

# Install all APT-based and standalone tools in a single optimized layer
# 1. Configure APT repositories (Trivy, GitHub CLI)
# 2. Install APT packages (trivy, gh, xz-utils)
# 3. Download all tool tarballs and checksums in parallel
# 4. Verify checksums and install tools
# hadolint ignore=DL3008
RUN set -eux \
  # Detect architecture once
  && arch="$(dpkg --print-architecture)" \
  && case "${arch}" in \
    amd64) trufflehog_arch="amd64"; actionlint_arch="amd64"; act_arch="Linux_x86_64" ;; \
    arm64) trufflehog_arch="arm64"; actionlint_arch="arm64"; act_arch="Linux_arm64" ;; \
    *) echo "Unsupported architecture: ${arch}" && exit 1 ;; \
  esac \
  # Configure APT repositories for Trivy and GitHub CLI
  && echo "=== Configuring APT repositories ===" \
  && curl -fsSL --proto '=https' --tlsv1.2 https://aquasecurity.github.io/trivy-repo/deb/public.key -o /tmp/trivy.key \
  && gpg --dearmor -o /usr/share/keyrings/trivy.gpg < /tmp/trivy.key \
  && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
    | tee -a /etc/apt/sources.list.d/trivy.list \
  && curl -fsSL --proto '=https' --tlsv1.2 https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /tmp/githubcli-archive-keyring.gpg \
  && cat /tmp/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  # Install APT packages
  && echo "=== Installing APT packages ===" \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh trivy xz-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/trivy.key /tmp/githubcli-archive-keyring.gpg \
  # Download all tool tarballs and checksums
  && echo "=== Downloading standalone tools ===" \
  && trufflehog_tarball="trufflehog_${TRUFFLEHOG_VERSION}_linux_${trufflehog_arch}.tar.gz" \
  && actionlint_tarball="actionlint_${ACTIONLINT_VERSION}_linux_${actionlint_arch}.tar.gz" \
  && act_tarball="act_${act_arch}.tar.gz" \
  && curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/${trufflehog_tarball}" -o "/tmp/${trufflehog_tarball}" \
  && curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_checksums.txt" -o /tmp/trufflehog_checksums.txt \
  && curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/${actionlint_tarball}" -o "/tmp/${actionlint_tarball}" \
  && curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_checksums.txt" -o /tmp/actionlint_checksums.txt \
  && curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/${act_tarball}" -o "/tmp/${act_tarball}" \
  && curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/checksums.txt" -o /tmp/act_checksums.txt \
  # Verify checksums and install trufflehog
  && echo "=== Verifying checksums and installing tools ===" \
  && grep "${trufflehog_tarball}" /tmp/trufflehog_checksums.txt \
   | sed "s|${trufflehog_tarball}|/tmp/${trufflehog_tarball}|" \
   | sha256sum -c - \
  && tar -xzf "/tmp/${trufflehog_tarball}" -C /tmp \
  && chmod +x /tmp/trufflehog \
  && mv /tmp/trufflehog /usr/local/bin/trufflehog \
  # Verify checksum and install actionlint
  && grep "${actionlint_tarball}" /tmp/actionlint_checksums.txt \
    | sed "s|${actionlint_tarball}|/tmp/${actionlint_tarball}|" \
    | sha256sum -c - \
  && tar -xzf "/tmp/${actionlint_tarball}" -C /tmp \
  && chmod +x /tmp/actionlint \
  && mv /tmp/actionlint /usr/local/bin/actionlint \
  # Verify checksum and install act
  && grep "${act_tarball}" /tmp/act_checksums.txt \
    | sed "s|${act_tarball}|/tmp/${act_tarball}|" \
    | sha256sum -c - \
  && tar -xzf "/tmp/${act_tarball}" -C /tmp \
  && chmod +x /tmp/act \
  && mv /tmp/act /usr/local/bin/act \
  # Clean up all temporary files
  && rm -f /tmp/*.tar.gz /tmp/*_checksums.txt \
  # Verify all installations
  && echo "=== Verifying tool installations ===" \
  && trivy --version \
  && gh --version \
  && trufflehog --version \
  && actionlint --version \
  && act --version \
  && test -f /bin/sh && test -f /bin/bash && echo "✓ Shell binaries intact" \
  && echo "=== All tools installed successfully ==="

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

# Create the user and group, then
# grant passwordless sudo to runner user for testing scenarios, then
# create workspace directory with proper permissions (as root)
RUN groupadd --gid "$USER_GID" "$USERNAME" \
  && useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME" -s /bin/bash \
  && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
  && chmod 0440 "/etc/sudoers.d/$USERNAME" \
  && mkdir -p /workspace \
  && chown -R "$USERNAME:$USERNAME" /workspace

# Switch to non-root user for ShellSpec installation
USER "$USERNAME"
WORKDIR /workspace

# Install ShellSpec testing framework in user's home with checksum verification, then
# verify installations (run as root to access all tools)
# ShellSpec 0.28.1 checksum: 350d3de04ba61505c54eda31a3c2ee912700f1758b1a80a284bc08fd8b6c5992
# hadolint ignore=SC2016
RUN mkdir -p ~/.local/bin \
  && tarball="shellspec-dist.tar.gz" \
  && expected_checksum="350d3de04ba61505c54eda31a3c2ee912700f1758b1a80a284bc08fd8b6c5992" \
  && curl -fsSL --proto '=https' --tlsv1.2 "https://github.com/shellspec/shellspec/releases/download/${SHELLSPEC_VERSION}/${tarball}" -o "/tmp/${tarball}" \
  && echo "${expected_checksum}  /tmp/${tarball}" | sha256sum -c - \
  && tar -xzf "/tmp/${tarball}" -C "$HOME/.local" \
  && ln -s "$HOME/.local/shellspec/shellspec" "$HOME/.local/bin/shellspec" \
  && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc \
  && shellspec --version \
  && rm -f "/tmp/${tarball}" \
  && echo "ShellSpec installed successfully" \
  && echo "Verifying installed tool versions..." \
  && echo "=== Tool Versions ===" \
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
  && echo "=== System tools verified ===" \
  && echo "=== Verify user-installed tools ===" \
  && shellspec --version \
  && echo "=== User tools verified ===" \
  && echo "=== Build complete ==="

# Default command keeps container running for GitHub Actions
CMD ["/bin/bash", "-c", "tail -f /dev/null"]
