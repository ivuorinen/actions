# Validate Inputs - Modular Validation System

A comprehensive, modular validation system for GitHub Actions inputs with automatic convention-based detection, custom validator support, and extensive testing capabilities.

## Features

- 🔍 **Automatic Validation** - Convention-based input detection
- 🧩 **Modular Architecture** - 9 specialized validators
- 🛡️ **Security First** - Injection and traversal protection
- 🎯 **Custom Validators** - Action-specific validation logic
- 🧪 **Test Generation** - Automatic test scaffolding
- 📊 **Performance Tools** - Benchmarking and profiling
- 🐛 **Debug Utilities** - Troubleshooting helpers

## Quick Start

### Using in Your Action

```yaml
# In your action.yml
runs:
  using: composite
  steps:
    - name: Validate inputs
      uses: ./validate-inputs
      with:
        action-type: ${{ github.action }}
```

### Automatic Validation

Name your inputs following conventions for automatic validation:

```yaml
inputs:
  github-token: # Automatically validates token format
    description: GitHub token
    default: ${{ github.token }}

  node-version: # Automatically validates version format
    description: Node.js version
    default: '18'

  dry-run: # Automatically validates boolean
    description: Run without making changes
    default: 'false'
```

## Architecture

```text
validate-inputs/
├── validators/           # Core validator modules
│   ├── base.py          # Abstract base class
│   ├── registry.py      # Dynamic validator discovery
│   ├── conventions.py   # Pattern-based matching
│   ├── boolean.py       # Boolean validation
│   ├── version.py       # Version validation (SemVer/CalVer)
│   ├── token.py         # Token validation
│   ├── numeric.py       # Numeric range validation
│   ├── file.py          # File path validation
│   ├── network.py       # URL/email validation
│   ├── docker.py        # Docker-specific validation
│   ├── security.py      # Security pattern detection
│   └── codeql.py        # CodeQL validation
├── scripts/
│   ├── update-validators.py     # Generate validation rules
│   ├── generate-tests.py        # Generate test files
│   ├── debug-validator.py       # Debug validation issues
│   └── benchmark-validator.py   # Performance testing
├── docs/
│   ├── API.md                   # Complete API reference
│   ├── DEVELOPER_GUIDE.md       # Adding new validators
│   └── ACTION_MAINTAINER.md     # Using validation
├── rules/                # Auto-generated validation rules
├── tests/                # Comprehensive test suite
└── validator.py          # Main entry point
```

## Core Validators

### Version Validator

- **SemVer**: `1.2.3`, `2.0.0-beta.1`
- **CalVer**: `2024.3.15`, `24.03`
- **Flexible**: Accepts both formats

### Token Validator

- **GitHub**: `ghp_*`, `github_pat_*`, `${{ secrets.GITHUB_TOKEN }}`
- **NPM**: UUID format
- **Docker**: Any non-empty value

### Boolean Validator

- **Accepted**: `true`, `false` (case-insensitive)
- **Rejected**: `yes`, `no`, `1`, `0`

### Numeric Validator

- **Ranges**: `0-100`, `1-10`, `1-128`
- **Types**: Integers only by default

### File Validator

- **Security**: No path traversal (`../`)
- **Paths**: Relative paths only
- **Extensions**: Validates common file types

### Network Validator

- **URLs**: HTTP/HTTPS validation
- **Emails**: RFC-compliant
- **Hostnames**: Valid DNS names
- **IPs**: IPv4 and IPv6

### Docker Validator

- **Images**: Lowercase, valid characters
- **Tags**: Alphanumeric with `-`, `_`, `.`
- **Platforms**: `linux/amd64`, `linux/arm64`, etc.
- **Registries**: Known registries validation

### Security Validator

- **Injection**: Command, SQL, script detection
- **Traversal**: Path traversal prevention
- **Secrets**: API key and password detection

## Convention Patterns

The system automatically detects validation types based on input names:

| Pattern              | Validator        | Examples                      |
|----------------------|------------------|-------------------------------|
| `*-token`            | TokenValidator   | `github-token`, `api-token`   |
| `*-version`          | VersionValidator | `node-version`, `go-version`  |
| `dry-run`, `debug`   | BooleanValidator | `dry-run`, `verbose`          |
| `max-*`, `*-limit`   | NumericValidator | `max-retries`, `rate-limit`   |
| `*-file`, `*-path`   | FileValidator    | `config-file`, `output-path`  |
| `*-url`, `webhook-*` | NetworkValidator | `api-url`, `webhook-endpoint` |
| `dockerfile`         | FileValidator    | `dockerfile`                  |
| `image-*`, `tag`     | DockerValidator  | `image-name`, `tag`           |

## Custom Validators

Create action-specific validation logic:

```python
# my-action/CustomValidator.py
from pathlib import Path
import sys

validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator

class CustomValidator(BaseValidator):
    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        # Custom validation logic
        return True

    def get_required_inputs(self) -> list[str]:
        return ["required-field"]
```

## Development Tools

### Generate Validation Rules

```bash
# Update all action rules
make update-validators

# Update specific action
python3 validate-inputs/scripts/update-validators.py --action my-action
```

### Generate Tests

```bash
# Generate missing tests
make generate-tests

# Preview changes
make generate-tests-dry
```

### Debug Validation

```bash
# Test specific inputs
./validate-inputs/scripts/debug-validator.py \
  --action docker-build \
  --input "image-name=myapp" \
  --input "tag=v1.0.0"

# Test input matching
./validate-inputs/scripts/debug-validator.py \
  --test-matching github-token node-version dry-run

# List available validators
./validate-inputs/scripts/debug-validator.py --list-validators
```

### Performance Testing

```bash
# Benchmark specific action
./validate-inputs/scripts/benchmark-validator.py \
  --action docker-build \
  --inputs 20 \
  --iterations 1000

# Compare validators
./validate-inputs/scripts/benchmark-validator.py --compare

# Profile for bottlenecks
./validate-inputs/scripts/benchmark-validator.py \
  --profile docker-build
```

## Testing

```bash
# Run all tests
make test

# Run Python tests only
make test-python

# Run specific test
uv run pytest validate-inputs/tests/test_version_validator.py

# Run with coverage
make test-python-coverage
```

## Documentation

- **[API Reference](API.md)** - Complete validator API documentation
- **[Developer Guide](DEVELOPER_GUIDE.md)** - Adding new validators
- **[Action Maintainer Guide](ACTION_MAINTAINER.md)** - Using validation in actions

## Best Practices

1. **Use Conventions** - Name inputs to trigger automatic validation
2. **Allow Expressions** - Always support `${{ }}` GitHub expressions
3. **Clear Errors** - Provide actionable error messages
4. **Test Thoroughly** - Test valid, invalid, and edge cases
5. **Document Rules** - Document validation in action README
6. **Performance** - Keep validation fast (< 10ms typical)

## Examples

### Complete Action with Validation

```yaml
name: Deploy Application
description: Deploy application with validation

inputs:
  environment:
    description: Deployment environment
    required: true

  github-token:
    description: GitHub token for API access
    default: ${{ github.token }}

  node-version:
    description: Node.js version
    default: '18'

  dry-run:
    description: Preview changes without deploying
    default: 'false'

runs:
  using: composite
  steps:
    # Validate all inputs
    - uses: ./validate-inputs
      with:
        action-type: deploy-application

    # Setup Node.js
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}

    # Deploy application
    - run: |
        if [[ "${{ inputs.dry-run }}" == "true" ]]; then
          echo "DRY RUN: Would deploy to ${{ inputs.environment }}"
        else
          ./deploy.sh --env "${{ inputs.environment }}"
        fi
      shell: bash
```

### Custom Validator Example

```python
# deploy-application/CustomValidator.py
class CustomValidator(BaseValidator):
    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        valid = True

        # Validate environment
        if inputs.get("environment"):
            valid_envs = ["dev", "staging", "prod"]
            if inputs["environment"] not in valid_envs:
                self.add_error(
                    f"Invalid environment: {inputs['environment']}. "
                    f"Must be one of: {', '.join(valid_envs)}"
                )
                valid = False

        # Production requires explicit token
        if inputs.get("environment") == "prod":
            if not inputs.get("github-token"):
                self.add_error("Production deployments require github-token")
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        return ["environment"]
```

## Quality Metrics

- **Test Coverage**: 100%
- **Validators**: 9 specialized + unlimited custom
- **Performance**: < 10ms typical validation time
- **Zero Dependencies**: Uses only Python stdlib + PyYAML
- **Production Ready**: Zero defects policy

## Contributing

1. Create new validator in `validators/` directory
2. Add convention patterns to `conventions.py`
3. Write comprehensive tests
4. Update documentation
5. Run `make all` to verify

## License

Part of ivuorinen/actions - see repository license.
