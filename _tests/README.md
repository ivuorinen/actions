# GitHub Actions Testing Framework

A comprehensive testing framework for validating GitHub Actions in this monorepo using ShellSpec and Python-based input validation.

## 🚀 Quick Start

```bash
# Run all tests
make test

# Run only unit tests
make test-unit

# Run tests for specific action
make test-action ACTION=go-build

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

1. **Unit Tests** - Fast validation of action logic, inputs, and outputs using Python validation
2. **Integration Tests** - Test actions in realistic workflow environments
3. **External Usage Tests** - Validate actions work via pinned refs (e.g. `ivuorinen/actions/action-name@<sha>`)

### Technology Stack

- **Unit Testing**: [ShellSpec](https://shellspec.info/) specs + Python-based harness (`_tests/framework/harness/`)
- **Validation**: Centralized Python input validation via `validate-inputs/validator.py`
- **Local Execution**: [nektos/act](https://github.com/nektos/act) - Run GitHub Actions locally
- **CI Integration**: GitHub Actions workflows

### Directory Structure

```text
_tests/
├── README.md                    # This documentation
├── run-tests.sh                 # Main test runner script
├── unit/                        # Unit tests by action
│   ├── spec_helper.sh           # ShellSpec helper with validation functions
│   ├── _harness/                # Internal harness support
│   └── <action-name>/           # One directory per action
├── framework/                   # Core testing utilities
│   └── harness/                 # Python-based test harness
├── fixtures/                    # Shared test fixtures
├── shared/                      # Shared utilities
├── integration/                 # Integration tests
│   └── workflows/               # Test workflows for nektos/act
├── coverage/                    # Coverage reports
└── reports/                     # Test execution reports
```

## ✍️ Writing Tests

### Basic Unit Test Structure

```bash
#!/usr/bin/env shellspec
# _tests/unit/my-action/validation.spec.sh

Describe "my-action validation"
ACTION_DIR="my-action"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating required inputs"
  It "accepts valid input"
    When call validate_input_python "my-action" "input-name" "valid-value"
    The status should be success
  End

  It "rejects invalid input"
    When call validate_input_python "my-action" "input-name" "invalid@value"
    The status should be failure
  End
End

Context "when validating boolean inputs"
  It "accepts true"
    When call validate_input_python "my-action" "dry-run" "true"
    The status should be success
  End

  It "accepts false"
    When call validate_input_python "my-action" "dry-run" "false"
    The status should be success
  End

  It "rejects invalid boolean"
    When call validate_input_python "my-action" "dry-run" "maybe"
    The status should be failure
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
        uses: ivuorinen/actions/my-action@<40-char-sha> # must be pinned SHA or CalVer tag
        with:
          required-input: 'test-value'
```

## 🛠️ Testing Functions

### Primary Validation Function

The framework provides one main validation function that uses the Python validation system:

#### validate_input_python

Tests input validation using the centralized Python validator:

```bash
validate_input_python "action-name" "input-name" "test-value"
```

**Examples:**

```bash
# Boolean validation
validate_input_python "pre-commit" "dry-run" "true"       # success
validate_input_python "pre-commit" "dry-run" "false"      # success
validate_input_python "pre-commit" "dry-run" "maybe"      # failure

# Version validation
validate_input_python "language-version-detect" "default-version" "18.0.0"  # success
validate_input_python "language-version-detect" "default-version" "v1.2.3"  # success
validate_input_python "language-version-detect" "default-version" "invalid" # failure

# Token validation
validate_input_python "npm-publish" "npm-token" "ghp_123..."    # success
validate_input_python "npm-publish" "npm-token" "invalid"       # failure

# Docker validation
validate_input_python "docker-build" "image-name" "myapp"       # success
validate_input_python "docker-build" "tag" "v1.0.0"            # success

# Path validation (security)
validate_input_python "pre-commit" "config-file" "config.yml"   # success
validate_input_python "pre-commit" "config-file" "../etc/pass"  # failure

```

### Helper Functions from spec_helper.sh

```bash
# Setup/cleanup
setup_default_inputs "action-name" "input-name"     # Set required defaults
cleanup_default_inputs "action-name" "input-name"   # Clean up defaults
shellspec_setup_test_env "test-name"               # Setup test environment
shellspec_cleanup_test_env "test-name"             # Cleanup test environment

# Mock execution
shellspec_mock_action_run "action-dir" key1 value1 key2 value2
shellspec_validate_action_output "expected-key" "expected-value"

# Action metadata
validate_action_yml "action.yml"          # Validate YAML structure
get_action_inputs "action.yml"           # Get action inputs
get_action_outputs "action.yml"          # Get action outputs
get_action_name "action.yml"             # Get action name
```

### Complete Action Validation Example

```bash
Describe "comprehensive-action validation"
  ACTION_DIR="comprehensive-action"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating all input types"
    It "validates boolean inputs"
      When call validate_input_python "$ACTION_DIR" "verbose" "true"
      The status should be success

      When call validate_input_python "$ACTION_DIR" "verbose" "false"
      The status should be success

      When call validate_input_python "$ACTION_DIR" "verbose" "invalid"
      The status should be failure
    End

    It "validates numeric inputs"
      When call validate_input_python "$ACTION_DIR" "max-retries" "3"
      The status should be success

      When call validate_input_python "$ACTION_DIR" "max-retries" "999"
      The status should be failure
    End

    It "validates version inputs"
      When call validate_input_python "$ACTION_DIR" "tool-version" "1.0.0"
      The status should be success

      When call validate_input_python "$ACTION_DIR" "tool-version" "v1.2.3-rc.1"
      The status should be success
    End

    It "validates security patterns"
      When call validate_input_python "$ACTION_DIR" "command" "echo test"
      The status should be success

      When call validate_input_python "$ACTION_DIR" "command" "rm -rf /; "
      The status should be failure
    End
  End

  Context "when validating action structure"
    It "has valid YAML structure"
      When call validate_action_yml "$ACTION_FILE"
      The status should be success
    End
  End
End
```

## 🎯 Testing Patterns by Action Type

### Setup Actions (language-version-detect, etc.)

Focus on version detection and environment setup:

```bash
Context "when detecting versions"
  It "detects version from config files"
    When call validate_input_python "language-version-detect" "default-version" "18.0.0"
    The status should be success
  End

  It "accepts default version"
    When call validate_input_python "language-version-detect" "default-version" "3.11"
    The status should be success
  End
End
```

### Linting Actions (eslint-fix, prettier-fix, etc.)

Focus on file processing and security:

```bash
Context "when processing files"
  It "validates working directory"
    When call validate_input_python "eslint-fix" "working-directory" "."
    The status should be success
  End

  It "rejects path traversal"
    When call validate_input_python "eslint-fix" "working-directory" "../etc"
    The status should be failure
  End

  It "validates boolean flags"
    When call validate_input_python "eslint-fix" "fix-only" "true"
    The status should be success
  End
End
```

### Build Actions (docker-build, go-build, etc.)

Focus on build configuration:

```bash
Context "when building"
  It "validates image name"
    When call validate_input_python "docker-build" "image-name" "myapp"
    The status should be success
  End

  It "validates tag format"
    When call validate_input_python "docker-build" "tag" "v1.0.0"
    The status should be success
  End

  It "validates platforms"
    When call validate_input_python "docker-build" "platforms" "linux/amd64,linux/arm64"
    The status should be success
  End
End
```

### Publishing Actions (npm-publish, docker-publish, etc.)

Focus on credentials and registry validation:

```bash
Context "when publishing"
  It "validates token format"
    When call validate_input_python "npm-publish" "npm-token" "ghp_123456789012345678901234567890123456"
    The status should be success
  End

  It "rejects invalid token"
    When call validate_input_python "npm-publish" "npm-token" "invalid-token"
    The status should be failure
  End

  It "validates version"
    When call validate_input_python "npm-publish" "package-version" "1.0.0"
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
./_tests/run-tests.sh -a go-build               # Specific action
./_tests/run-tests.sh -t integration docker-build  # Integration tests for docker-build
./_tests/run-tests.sh --format json --coverage  # JSON output with coverage
```

### Options

| Option                | Description                                    |
| --------------------- | ---------------------------------------------- |
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

2. **Write Unit Tests**

   ```bash
   # _tests/unit/new-action/validation.spec.sh
   #!/usr/bin/env shellspec

   Describe "new-action validation"
   ACTION_DIR="new-action"
   ACTION_FILE="$ACTION_DIR/action.yml"

   Context "when validating inputs"
     It "validates required input"
       When call validate_input_python "new-action" "required-input" "value"
       The status should be success
     End
   End
   End
   ```

3. **Create Integration Test**

   ```bash
   # _tests/integration/workflows/new-action-test.yml
   # (See integration test example above)
   ```

4. **Test Your Tests**

   ```bash
   make test-action ACTION=new-action
   ```

### Pull Request Checklist

- [ ] Tests use `validate_input_python` for input validation
- [ ] All test types pass locally (`make test`)
- [ ] Integration test workflow created
- [ ] Security testing included for user inputs
- [ ] Tests are independent and isolated
- [ ] Proper cleanup in test teardown
- [ ] Documentation updated if needed

## 💡 Best Practices

### 1. Use validate_input_python for All Input Testing

✅ **Good**:

```bash
When call validate_input_python "my-action" "verbose" "true"
The status should be success
```

❌ **Avoid**:

```bash
# Don't manually test validation - use the Python validator
export INPUT_VERBOSE="true"
python3 validate-inputs/validator.py
```

### 2. Group Related Validations

✅ **Good**:

```bash
Context "when validating configuration"
  It "accepts valid boolean"
    When call validate_input_python "my-action" "dry-run" "true"
    The status should be success
  End

  It "accepts valid version"
    When call validate_input_python "my-action" "tool-version" "1.0.0"
    The status should be success
  End
End
```

### 3. Always Include Security Testing

✅ **Always include**:

```bash
It "rejects path traversal"
  When call validate_input_python "pre-commit" "config-file" "../etc/passwd"
  The status should be failure
End
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

The framework automatically sets up test environments via `spec_helper.sh`:

```bash
# Automatic setup on load
- GitHub Actions environment variables
- Temporary directories
- Mock GITHUB_OUTPUT files
- Default required inputs for actions

# Available variables
$PROJECT_ROOT        # Repository root
$TEST_ROOT          # _tests/ directory
$FRAMEWORK_DIR      # _tests/framework/
$FIXTURES_DIR       # _tests/fixtures/
$TEMP_DIR           # Temporary test directory
$GITHUB_OUTPUT      # Mock outputs file
$GITHUB_ENV         # Mock environment file
```

### Python Validation Integration

All input validation uses the centralized Python validation system from `validate-inputs/`:

- Convention-based automatic validation
- 9 specialized validators (Boolean, Version, Token, Numeric, File, Network, Docker, Security, CodeQL)
- Custom validator support per action
- Injection and security pattern detection

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

3. **Enable Debug Mode**

   ```bash
   export SHELLSPEC_DEBUG=1
   shellspec _tests/unit/my-action/validation.spec.sh
   ```

4. **Check Test Output**

   ```bash
   # Test results stored in _tests/reports/
   cat _tests/reports/unit/my-action.txt
   ```

## 📚 Resources

- [ShellSpec Documentation](https://shellspec.info/)
- [nektos/act Documentation](https://nektosact.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Testing GitHub Actions Best Practices](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action#testing-your-action)
- [validate-inputs Documentation](../validate-inputs/docs/README_ARCHITECTURE.md)

## Framework Development

### Framework File Structure

```text
_tests/
├── unit/
│   ├── spec_helper.sh           # ShellSpec configuration and helpers
│   ├── _harness/                # Internal harness support
│   └── <action-name>/           # One directory per action
├── framework/
│   └── harness/                 # Python-based test harness
├── fixtures/                    # Shared test fixtures
├── shared/                      # Shared utilities
└── integration/
    └── workflows/               # Integration test workflows
```

### Available Functions

**From spec_helper.sh (\_tests/unit/spec_helper.sh):**

- `validate_input_python(action, input_name, value)` - Main validation function
- `setup_default_inputs(action, input_name)` - Set default required inputs
- `cleanup_default_inputs(action, input_name)` - Clean up default inputs
- `shellspec_setup_test_env(name)` - Setup test environment
- `shellspec_cleanup_test_env(name)` - Cleanup test environment
- `shellspec_mock_action_run(action_dir, ...)` - Mock action execution
- `shellspec_validate_action_output(key, value)` - Validate outputs

**From harness (\_tests/framework/harness/):**

- `validate_action_yml(file)` - Validate action YAML
- `get_action_inputs(file)` - Extract action inputs
- `get_action_outputs(file)` - Extract action outputs
- `get_action_name(file)` - Get action name

**Last Updated:** October 15, 2025
