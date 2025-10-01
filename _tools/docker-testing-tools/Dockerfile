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
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS
# hadolint ignore=DL3008
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
  && apt-get install -y nodejs --no-install-recommends \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Stage 2: Tool installation
FROM base AS tools

# Set shell to bash with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Trivy security scanner
# hadolint ignore=DL3008
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - \
  && echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends trivy \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install additional dependencies needed by install scripts
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y \
  --no-install-recommends \
  xz-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install standalone tools that don't need system packages
# Split into separate commands for better error reporting

# Install trufflehog
RUN curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin

# Install actionlint (note: rhysd not rhymond)
RUN curl -sL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash \
  && mv actionlint /usr/local/bin/ \
  && actionlint --version

# Install nektos/act (use temp directory to avoid any /bin conflicts)
RUN mkdir -p /tmp/act-install
WORKDIR /tmp/act-install
RUN curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash \
  && mv bin/act /usr/local/bin/act
WORKDIR /
RUN rm -rf /tmp/act-install \
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

# Set up environment for testing
ENV PATH="/home/$USERNAME/.local/bin:$PATH"
ENV SHELLSPEC_VERSION=0.28.1
ENV USER=$USERNAME
ENV HOME="/home/$USERNAME"

# Create the user and group
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash

# Create workspace directory with proper permissions (as root)
RUN mkdir -p /workspace \
  && chown -R $USERNAME:$USERNAME /workspace

# Switch to non-root user for ShellSpec installation
USER $USERNAME
WORKDIR /workspace

# Install ShellSpec testing framework in user's home
# hadolint ignore=SC2016
RUN curl -fsSL https://git.io/shellspec | sh -s -- --yes \
  && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

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
CMD ["/bin/bash"]
