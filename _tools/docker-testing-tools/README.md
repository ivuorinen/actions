# GitHub Actions Testing Docker Image

Pre-built Docker image with all testing tools to eliminate CI setup time and ensure consistent environments.

## 🚀 Quick Start

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container: ghcr.io/ivuorinen/actions:testing-tools
    steps:
      - uses: actions/checkout@v5
      - run: shellspec _tests/unit/your-action/
```

## 📦 Pre-installed Tools

| Tool           | Version         | Purpose                         |
|----------------|-----------------|---------------------------------|
| **ShellSpec**  | 0.28.1 (pinned) | Shell script testing framework  |
| **nektos/act** | 0.2.71 (pinned) | Local GitHub Actions testing    |
| **TruffleHog** | 3.86.0 (pinned) | Secrets detection               |
| **actionlint** | 1.7.7 (pinned)  | GitHub Actions linting          |
| **Trivy**      | repo stable¹    | Container security scanning     |
| **GitHub CLI** | repo stable¹    | GitHub API interactions         |
| **shellcheck** | repo stable¹    | Shell script linting            |
| **jq**         | repo stable¹    | JSON processing                 |
| **kcov**       | repo stable¹    | Code coverage for shell scripts |
| **Node.js**    | LTS             | JavaScript runtime              |
| **Python**     | 3.x             | Python runtime + PyYAML         |

¹ _Installed via Ubuntu 22.04 LTS repositories for stability and security_

## 🏗️ Building Locally

```bash
cd _tools/docker-testing-tools
./build.sh [tag]        # Build and basic test
./test.sh [tag]         # Comprehensive testing
```

## 📊 Performance Benefits

| Workflow Job      | Before | After | Savings        |
|-------------------|--------|-------|----------------|
| Unit Tests        | ~90s   | ~30s  | **60s**        |
| Integration Tests | ~120s  | ~45s  | **75s**        |
| Coverage          | ~100s  | ~40s  | **60s**        |
| **Total per run** | ~310s  | ~115s | **~3 minutes** |

## 🏗️ Multi-Stage Build Benefits

The Dockerfile uses a **3-stage build process**:

1. **`base`** - System dependencies and Node.js installation
2. **`tools`** - Tool installation (Trivy, GitHub CLI, standalone tools)
3. **`final`** - User setup, ShellSpec installation, and verification

**Advantages:**

- ⚡ **Faster builds** - Docker layer caching optimizes repeated builds
- 📦 **Smaller images** - Only final stage included in image
- 🔒 **Better security** - Build-time dependencies not included in final image
- 🧹 **Cleaner separation** - System vs user tool installation isolated

## 🔧 Usage Examples

### Basic Testing

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container: ghcr.io/ivuorinen/actions:testing-tools
    steps:
      - uses: actions/checkout@v5
      - run: npm ci
      - run: shellspec _tests/unit/
```

### With Coverage

```yaml
jobs:
  coverage:
    runs-on: ubuntu-latest
    container: ghcr.io/ivuorinen/actions:testing-tools
    steps:
      - uses: actions/checkout@v5
      - run: make test-coverage
      - run: kcov --include-pattern=_tests/ coverage/ _tests/run-tests.sh
```

### Integration Testing

```yaml
jobs:
  integration:
    runs-on: ubuntu-latest
    container: ghcr.io/ivuorinen/actions:testing-tools
    steps:
      - uses: actions/checkout@v5
      - run: act workflow_dispatch -W _tests/integration/workflows/
```

## 🐋 Image Variants

- `testing-tools` - Latest stable build from main branch
- `main-testing-tools` - Latest build from main branch
- `pr-*-testing-tools` - Pull request builds for testing

## 🔒 Security

The image is:

- ✅ **Multi-stage build** - Reduced final image size and attack surface
- ✅ **Non-root user** - Runs as `runner` user (uid: 1001) by default
- ✅ **Built from official Ubuntu 22.04 LTS** - Secure and maintained base
- ✅ **Scanned with Trivy** for vulnerabilities during build
- ✅ **Specific tool versions** - No `latest` tags where avoidable
- ✅ **Minimal attack surface** - Only testing tools included
- ✅ **Sudo access** - Available for emergency use only
- ✅ **Transparent build** - Built with GitHub Actions

## 🚨 Migration Guide

### Before (Old Workflow)

```yaml
- name: Install ShellSpec
  run: curl -fsSL https://git.io/shellspec | sh -s -- --yes
- name: Install tools
  run: |
    sudo apt-get update
    sudo apt-get install -y jq shellcheck kcov
```

### After (With Container)

```yaml
jobs:
  test:
    container: ghcr.io/ivuorinen/actions:testing-tools
    # All tools pre-installed! 🎉
```

## 🤝 Contributing

1. Update `Dockerfile` with new tools
2. Test locally with `./build.sh`
3. Submit PR - image builds automatically
4. After merge, image is available as `:testing-tools`

## 📝 Changelog

### v1.1.0

- 🔒 **Security improvements**: Multi-stage build with non-root user
- 🏗️ **Multi-stage Dockerfile**: Optimized build process and smaller final image
- 👤 **Non-root user**: Runs as `runner` user (uid: 1001) for security
- 🧪 **Comprehensive testing**: Added `test.sh` for thorough validation
- 📦 **Better organization**: Improved build stages and tool installation

### v1.0.0

- Initial release with all testing tools
- ShellSpec, act, Trivy, TruffleHog, actionlint
- Node.js LTS, Python 3, essential utilities
- Multi-architecture support (amd64, arm64)
