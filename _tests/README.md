# GitHub Actions Testing Framework

A comprehensive testing framework for validating GitHub Actions in this monorepo. This guide covers everything from basic usage to advanced testing patterns.

## 🚀 Quick Start

```bash
# Run all tests
make test

# Run only unit tests
make test-unit

# Run tests for specific action
make test-action ACTION=node-setup

# Run with coverage reporting
make test-coverage
```

### Prerequisites

```bash
# Install ShellSpec (testing framework)
curl -fsSL https://github.com/shellspec/shellspec/releases/latest/download/shellspec-dist.tar.gz | tar -xz
sudo make -C shellspec-* install

# Install nektos/act (optional, for integration tests)
brew install act  # macOS
# or: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

## 📁 Framework Overview

### Architecture

The testing framework uses a **multi-level testing strategy**:

1. **Unit Tests** - Fast validation of action logic, inputs, and outputs
2. **Integration Tests** - Test actions in realistic workflow environments
3. **External Usage Tests** - Validate actions work as `ivuorinen/actions/action-name@main`

### Technology Stack

- **Primary Framework**: [ShellSpec](https://shellspec.info/) - BDD testing for shell scripts
- **Local Execution**: [nektos/act](https://github.com/nektos/act) - Run GitHub Actions locally
- **Coverage**: kcov integration for shell script coverage
- **Mocking**: Custom GitHub API and service mocks
- **CI Integration**: GitHub Actions workflows

### Directory Structure

```text
_tests/
├── README.md                    # This documentation
├── run-tests.sh                 # Main test runner script
├── framework/                   # Core testing utilities
│   ├── setup.sh                # Test environment setup
│   ├── utils.sh                # Common testing functions
│   ├── validation_helpers.sh   # Validation helper functions
│   ├── validation.py           # Python validation utilities
│   └── mocks/                  # Mock services (GitHub API, etc.)
├── unit/                       # Unit tests by action
│   ├── version-file-parser/    # Example unit tests
│   ├── node-setup/            # Example unit tests
│   └── ...                    # One directory per action
├── integration/               # Integration tests
│   ├── workflows/             # Test workflows for nektos/act
│   └── external-usage/        # External reference tests
├── coverage/                  # Coverage reports
└── reports/                   # Test execution reports
```

## ✍️ Writing Tests

### Basic Unit Test Structure

```bash
#!/usr/bin/env shellspec
# _tests/unit/my-action/validation.spec.sh

Include _tests/framework/utils.sh

Describe "my-action validation"
  ACTION_DIR="my-action"
  ACTION_FILE="$ACTION_DIR/action.yml"

  BeforeAll "init_testing_framework"

  Context "input validation"
    It "validates all inputs comprehensively"
      # Use validation helpers for comprehensive testing
      test_boolean_input "verbose"
      test_boolean_input "dry-run"

      test_numeric_range_input "max-retries" 1 10
      test_numeric_range_input "timeout" 1 3600

      test_enum_input "strategy" "fast" "comprehensive" "custom"
      test_enum_input "format" "json" "yaml" "xml"

      test_version_input "tool-version"
      test_security_input "command"
      test_path_input "working-directory"
    End
  End

  Context "action structure"
    It "has valid structure and metadata"
      test_standard_action_structure "$ACTION_FILE" "Expected Action Name"
    End
  End
End
```

### Integration Test Example

```yaml
# _tests/integration/workflows/my-action-test.yml
name: Test my-action Integration
on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Test action locally
        id: test-local
        uses: ./my-action
        with:
          required-input: 'test-value'

      - name: Validate outputs
        run: |
          echo "Output: ${{ steps.test-local.outputs.result }}"
          [[ -n "${{ steps.test-local.outputs.result }}" ]] || exit 1

      - name: Test external reference
        uses: ivuorinen/actions/my-action@main
        with:
          required-input: 'test-value'
```

## 🛠️ Testing Helpers

### Available Validation Helpers

The framework provides comprehensive validation helpers that handle common testing patterns:

#### Boolean Input Testing

```bash
test_boolean_input "verbose"          # Tests: true, false, rejects invalid
test_boolean_input "enable-cache"
test_boolean_input "dry-run"
```

#### Numeric Range Testing

```bash
test_numeric_range_input "max-retries" 1 10    # Tests: min, max, edge cases
test_numeric_range_input "timeout" 1 3600
test_numeric_range_input "parallel-jobs" 1 16
```

#### Version Testing

```bash
test_version_input "version"          # Tests: semver, v-prefix, pre-release
test_version_input "tool-version"
```

#### Enum Testing

```bash
test_enum_input "strategy" "linear" "exponential" "fixed"
test_enum_input "format" "json" "yaml" "xml"
```

#### Docker-Specific Testing

```bash
test_docker_image_input "image-name"  # Tests: valid names, rejects invalid
test_docker_tag_input "tag"           # Tests: semantic versions, latest
test_docker_platforms_input "platforms"  # Tests: architecture formats
```

#### Security Testing

```bash
test_security_input "command"         # Tests: injection patterns, escaping
test_security_input "build-args"      # Tests: command injection, pipes
test_path_input "working-directory"   # Tests: path traversal, absolute paths
```

#### Action Structure Testing

```bash
test_standard_action_structure "$ACTION_FILE" "Action Name"
# Tests: YAML syntax, required fields, input/output definitions
```

### Complete Action Validation Example

```bash
Describe "comprehensive-action validation"
  ACTION_DIR="comprehensive-action"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "complete input validation"
    It "validates all input types systematically"
      # Boolean inputs
      test_boolean_input "verbose"
      test_boolean_input "enable-cache"
      test_boolean_input "dry-run"

      # Numeric ranges
      test_numeric_range_input "max-retries" 1 10
      test_numeric_range_input "timeout" 1 3600
      test_numeric_range_input "parallel-jobs" 1 16

      # Enums
      test_enum_input "strategy" "fast" "comprehensive" "custom"
      test_enum_input "format" "json" "yaml" "xml"

      # Docker-specific
      test_docker_image_input "image-name"
      test_docker_tag_input "tag"
      test_docker_platforms_input "platforms"

      # Security validation
      test_security_input "command"
      test_security_input "build-args"

      # Paths
      test_path_input "working-directory"
      test_path_input "output-directory"

      # Versions
      test_version_input "tool-version"

      # Action structure
      test_standard_action_structure "$ACTION_FILE" "Comprehensive Action"
    End
  End
End
```

## 🎯 Testing Patterns by Action Type

### Setup Actions (node-setup, php-version-detect, etc.)

Focus on version detection and environment setup:

```bash
Context "version detection"
  It "detects version from config files"
    create_mock_node_repo  # or appropriate repo type

    # Test version detection logic
    export INPUT_LANGUAGE="node"
    echo "detected-version=18.0.0" >> "$GITHUB_OUTPUT"

    When call validate_action_output "detected-version" "18.0.0"
    The status should be success
  End

  It "falls back to default when no version found"
    test_version_input "default-version"
  End
End
```

### Linting Actions (eslint-fix, prettier-fix, etc.)

Focus on file processing and fix capabilities:

```bash
Context "file processing"
  BeforeEach "setup_test_env 'lint-test'"
  AfterEach "cleanup_test_env 'lint-test'"

  It "validates inputs and processes files"
    test_boolean_input "fix-only"
    test_path_input "working-directory"
    test_security_input "custom-command"

    # Mock file processing
    echo "files_changed=3" >> "$GITHUB_OUTPUT"
    echo "status=changes_made" >> "$GITHUB_OUTPUT"

    When call validate_action_output "status" "changes_made"
    The status should be success
  End
End
```

### Build Actions (docker-build, go-build, etc.)

Focus on build processes and artifact generation:

```bash
Context "build process"
  BeforeEach "setup_test_env 'build-test'"
  AfterEach "cleanup_test_env 'build-test'"

  It "validates build inputs"
    test_docker_image_input "image-name"
    test_docker_tag_input "tag"
    test_docker_platforms_input "platforms"
    test_numeric_range_input "parallel-builds" 1 16

    # Mock successful build
    echo "build-status=success" >> "$GITHUB_OUTPUT"
    echo "build-time=45" >> "$GITHUB_OUTPUT"

    When call validate_action_output "build-status" "success"
    The status should be success
  End
End
```

### Publishing Actions (npm-publish, docker-publish, etc.)

Focus on registry interactions using mocks:

```bash
Context "publishing"
  BeforeEach "setup_mock_environment"
  AfterEach "cleanup_mock_environment"

  It "validates publishing inputs"
    test_version_input "package-version"
    test_security_input "registry-token"
    test_enum_input "registry" "npm" "github" "dockerhub"

    # Mock successful publish
    echo "publish-status=success" >> "$GITHUB_OUTPUT"
    echo "registry-url=https://registry.npmjs.org/" >> "$GITHUB_OUTPUT"

    When call validate_action_output "publish-status" "success"
    The status should be success
  End
End
```

## 🔧 Running Tests

### Command Line Interface

```bash
# Basic usage
./_tests/run-tests.sh [OPTIONS] [ACTION_NAME...]

# Examples
./_tests/run-tests.sh                           # All tests, all actions
./_tests/run-tests.sh -t unit                   # Unit tests only
./_tests/run-tests.sh -a node-setup             # Specific action
./_tests/run-tests.sh -t integration docker-build  # Integration tests for docker-build
./_tests/run-tests.sh --format json --coverage  # JSON output with coverage
```

### Options

| Option                | Description                                    |
|-----------------------|------------------------------------------------|
| `-t, --type TYPE`     | Test type: `unit`, `integration`, `e2e`, `all` |
| `-a, --action ACTION` | Filter by action name pattern                  |
| `-j, --jobs JOBS`     | Number of parallel jobs (default: 4)           |
| `-c, --coverage`      | Enable coverage reporting                      |
| `-f, --format FORMAT` | Output format: `console`, `json`, `junit`      |
| `-v, --verbose`       | Enable verbose output                          |
| `-h, --help`          | Show help message                              |

### Make Targets

```bash
make test                    # Run all tests
make test-unit              # Unit tests only
make test-integration       # Integration tests only
make test-coverage          # Tests with coverage
make test-action ACTION=name # Test specific action
```

## 🤝 Contributing Tests

### Adding Tests for New Actions

1. **Create Unit Test Directory**

   ```bash
   mkdir -p _tests/unit/new-action
   ```

2. **Write Comprehensive Unit Tests**

   ```bash
   # Copy template and customize
   cp _tests/unit/version-file-parser/validation.spec.sh \
      _tests/unit/new-action/validation.spec.sh
   ```

3. **Use Validation Helpers**

   ```bash
   # Focus on using helpers for comprehensive coverage
   test_boolean_input "verbose"
   test_numeric_range_input "timeout" 1 3600
   test_security_input "command"
   test_standard_action_structure "$ACTION_FILE" "New Action"
   ```

4. **Create Integration Test**

   ```bash
   cp _tests/integration/workflows/version-file-parser-test.yml \
      _tests/integration/workflows/new-action-test.yml
   ```

5. **Test Your Tests**

   ```bash
   make test-action ACTION=new-action
   ```

### Pull Request Checklist

- [ ] Tests use validation helpers for common patterns
- [ ] All test types pass locally (`make test`)
- [ ] Integration test workflow created
- [ ] Security testing included for user inputs
- [ ] Tests are independent and isolated
- [ ] Proper cleanup in test teardown
- [ ] Documentation updated if needed

## 💡 Best Practices

### 1. Use Validation Helpers

✅ **Good**:

```bash
test_boolean_input "verbose"
test_numeric_range_input "timeout" 1 3600
test_enum_input "format" "json" "yaml" "xml"
```

❌ **Avoid**:

```bash
# Don't write manual tests for common patterns
When call test_input_validation "$ACTION_DIR" "verbose" "true" "success"
When call test_input_validation "$ACTION_DIR" "verbose" "false" "success"
```

### 2. Group Related Validations

✅ **Good**:

```bash
Context "complete input validation"
  It "validates all input types"
    test_boolean_input "verbose"
    test_numeric_range_input "timeout" 1 3600
    test_enum_input "format" "json" "yaml"
    test_security_input "command"
  End
End
```

### 3. Include Security Testing

✅ **Always include**:

```bash
test_security_input "command"
test_security_input "user-script"
test_path_input "working-directory"
```

### 4. Write Descriptive Test Names

✅ **Good**:

```bash
It "accepts valid semantic version format"
It "rejects version with invalid characters"
It "falls back to default when no version file exists"
```

❌ **Avoid**:

```bash
It "validates input"
It "works correctly"
```

### 5. Keep Tests Independent

- Each test should work in isolation
- Don't rely on test execution order
- Clean up after each test
- Use proper setup/teardown

## 🔍 Framework Features

### Test Environment Setup

```bash
# Setup test environment
setup_test_env "test-name"

# Create mock repositories
create_mock_repo "node"     # Node.js project
create_mock_repo "php"      # PHP project
create_mock_repo "python"   # Python project
create_mock_repo "go"       # Go project
create_mock_repo "dotnet"   # .NET project

# Cleanup
cleanup_test_env "test-name"
```

### Mock Services

Built-in mocks for external services:

- **GitHub API** - Repository, releases, packages, workflows
- **NPM Registry** - Package publishing and retrieval
- **Docker Registry** - Image push/pull operations
- **Container Registries** - GitHub Container Registry, Docker Hub

### Available Environment Variables

```bash
# Test environment paths
$TEST_WORKSPACE       # Current test workspace
$GITHUB_OUTPUT         # Mock GitHub outputs file
$GITHUB_ENV           # Mock GitHub environment file
$GITHUB_STEP_SUMMARY  # Mock step summary file

# Test framework paths
$TEST_ROOT            # _tests/ directory
$FRAMEWORK_DIR        # _tests/framework/ directory
$FIXTURES_DIR         # _tests/framework/fixtures/
$MOCKS_DIR           # _tests/framework/mocks/
```

## 🚨 Troubleshooting

### Common Issues

#### "ShellSpec command not found"

```bash
# Install ShellSpec globally
curl -fsSL https://github.com/shellspec/shellspec/releases/latest/download/shellspec-dist.tar.gz | tar -xz
sudo make -C shellspec-* install
```

#### "act command not found"

```bash
# Install nektos/act (macOS)
brew install act

# Install nektos/act (Linux)
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

#### Tests timeout

```bash
# Increase timeout for slow operations
export TEST_TIMEOUT=300
```

#### Permission denied on test scripts

```bash
# Make test scripts executable
find _tests/ -name "*.sh" -exec chmod +x {} \;
```

### Debugging Tests

1. **Enable Verbose Mode**

   ```bash
   ./_tests/run-tests.sh -v
   ```

2. **Run Single Test**

   ```bash
   shellspec _tests/unit/my-action/validation.spec.sh
   ```

3. **Check Test Output**

   ```bash
   # Test results stored in _tests/reports/
   cat _tests/reports/unit/my-action.txt
   ```

4. **Debug Mock Environment**

   ```bash
   # Enable mock debugging
   export MOCK_DEBUG=true
   ```

## 📚 Resources

- [ShellSpec Documentation](https://shellspec.info/)
- [nektos/act Documentation](https://nektosact.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Testing GitHub Actions Best Practices](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action#testing-your-action)

---

## Framework Development

### Adding New Framework Features

1. **New Test Utilities**

   ```bash
   # Add to _tests/framework/utils.sh
   your_new_function() {
     local param="$1"
     # Implementation
   }

   # Export for availability
   export -f your_new_function
   ```

2. **New Mock Services**

   ```bash
   # Create _tests/framework/mocks/new-service.sh
   # Follow existing patterns in github-api.sh
   ```

3. **New Validation Helpers**

   ```bash
   # Add to _tests/framework/validation_helpers.sh
   # Update this documentation
   ```

**Last Updated:** August 17, 2025
