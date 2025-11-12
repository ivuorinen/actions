# Validator API Documentation

## Table of Contents

1. [Base Validator](#base-validator)
2. [Core Validators](#core-validators)
3. [Registry System](#registry-system)
4. [Custom Validators](#custom-validators)
5. [Conventions](#conventions)

## Base Validator

### `BaseValidator`

The abstract base class for all validators. Provides common functionality for validation, error handling, and rule loading.

```python
from validators.base import BaseValidator

class MyValidator(BaseValidator):
    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        # Implementation
        pass
```

#### Methods

| Method                                          | Description                           | Returns     |
|-------------------------------------------------|---------------------------------------|-------------|
| `validate_inputs(inputs)`                       | Main validation entry point           | `bool`      |
| `validate_required_inputs(inputs)`              | Validates required inputs are present | `bool`      |
| `validate_path_security(path)`                  | Checks for path traversal attacks     | `bool`      |
| `validate_security_patterns(value, field_name)` | Checks for injection attacks          | `bool`      |
| `add_error(message)`                            | Adds an error message                 | `None`      |
| `clear_errors()`                                | Clears all error messages             | `None`      |
| `get_required_inputs()`                         | Returns list of required input names  | `list[str]` |
| `get_validation_rules()`                        | Returns validation rules dictionary   | `dict`      |
| `load_rules(action_type)`                       | Loads rules from YAML file            | `dict`      |

#### Properties

| Property      | Type        | Description                     |
|---------------|-------------|---------------------------------|
| `errors`      | `list[str]` | Accumulated error messages      |
| `action_type` | `str`       | The action type being validated |

## Core Validators

### `BooleanValidator`

Validates boolean inputs with flexible string representations.

```python
from validators.boolean import BooleanValidator

validator = BooleanValidator()
validator.validate_boolean("true", "dry-run")  # Returns True
validator.validate_boolean("yes", "dry-run")   # Returns False (not allowed)
```

**Accepted Values**: `true`, `false`, `True`, `False`, `TRUE`, `FALSE`

### `VersionValidator`

Validates version strings in multiple formats.

```python
from validators.version import VersionValidator

validator = VersionValidator()
validator.validate_semantic_version("1.2.3")      # SemVer
validator.validate_calver("2024.3.15")           # CalVer
validator.validate_flexible_version("v1.2.3")    # Either format
```

**Supported Formats**:

- **SemVer**: `1.2.3`, `1.0.0-alpha`, `2.1.0+build123`
- **CalVer**: `2024.3.1`, `2024.03.15`, `24.3.1`
- **Prefixed**: `v1.2.3`, `v2024.3.1`

### `TokenValidator`

Validates authentication tokens for various services.

```python
from validators.token import TokenValidator

validator = TokenValidator()
validator.validate_github_token("ghp_...")  # Classic PAT
validator.validate_github_token("github_pat_...")  # Fine-grained PAT
validator.validate_github_token("${{ secrets.GITHUB_TOKEN }}")  # Expression
```

**Token Types**:

- **GitHub**: `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, `github_pat_`
- **NPM**: UUID format, `${{ secrets.NPM_TOKEN }}`
- **Docker**: Any non-empty value

### `NumericValidator`

Validates numeric values and ranges.

```python
from validators.numeric import NumericValidator

validator = NumericValidator()
validator.validate_numeric_range("5", 0, 10)    # Within range
validator.validate_numeric_range("15", 0, 10)   # Out of range (fails)
```

**Common Ranges**:

- `0-100`: Percentages
- `1-10`: Retry counts
- `1-128`: Thread/worker counts

### `FileValidator`

Validates file paths with security checks.

```python
from validators.file import FileValidator

validator = FileValidator()
validator.validate_file_path("./config.yml")    # Valid
validator.validate_file_path("../../../etc/passwd")  # Path traversal (fails)
validator.validate_file_path("/absolute/path")  # Absolute path (fails)
```

**Security Checks**:

- No path traversal (`../`)
- No absolute paths
- No special characters that could cause injection

### `NetworkValidator`

Validates network-related inputs.

```python
from validators.network import NetworkValidator

validator = NetworkValidator()
validator.validate_url("https://example.com")
validator.validate_email("user@example.com")
validator.validate_hostname("api.example.com")
validator.validate_ip_address("192.168.1.1")
```

**Validation Types**:

- **URLs**: HTTP/HTTPS with valid structure
- **Emails**: RFC-compliant email addresses
- **Hostnames**: Valid DNS names
- **IPs**: IPv4 and IPv6 addresses
- **Ports**: 1-65535 range

### `DockerValidator`

Validates Docker-specific inputs.

```python
from validators.docker import DockerValidator

validator = DockerValidator()
validator.validate_image_name("nginx")
validator.validate_tag("latest")
validator.validate_architectures("linux/amd64,linux/arm64")
validator.validate_registry("ghcr.io")
```

**Docker Validations**:

- **Images**: Lowercase, alphanumeric with `-`, `_`, `/`
- **Tags**: Alphanumeric with `-`, `_`, `.`
- **Platforms**: Valid OS/architecture combinations
- **Registries**: Known registries or valid hostnames

### `SecurityValidator`

Performs security-focused validations.

```python
from validators.security import SecurityValidator

validator = SecurityValidator()
validator.validate_no_injection("safe input")
validator.validate_safe_command("echo hello")
validator.validate_safe_environment_variable("PATH=/usr/bin")
validator.validate_no_secrets("normal text")
```

**Security Patterns Detected**:

- Command injection: `;`, `&&`, `||`, `` ` ``, `$()`
- SQL injection: `' OR '1'='1`, `DROP TABLE`, `--`
- Path traversal: `../`, `..\\`
- Script injection: `<script>`, `javascript:`
- Secrets: API keys, tokens, passwords

### `CodeQLValidator`

Validates CodeQL-specific inputs.

```python
from validators.codeql import CodeQLValidator

validator = CodeQLValidator()
validator.validate_languages(["javascript", "python"])
validator.validate_codeql_queries(["security", "quality"])
validator.validate_codeql_config("./codeql-config.yml")
```

**Supported Languages**: JavaScript, TypeScript, Python, Java, C#, C/C++, Go, Ruby, Kotlin, Swift

## Registry System

### `ValidatorRegistry`

Manages validator discovery and caching.

```python
from validators.registry import ValidatorRegistry

registry = ValidatorRegistry()
validator = registry.get_validator("docker-build")  # Gets appropriate validator
```

#### Methods

| Method                                      | Description               | Returns         |
|---------------------------------------------|---------------------------|-----------------|
| `get_validator(action_type)`                | Gets validator for action | `BaseValidator` |
| `register_validator(name, validator_class)` | Registers a validator     | `None`          |
| `clear_cache()`                             | Clears validator cache    | `None`          |

### `ConventionBasedValidator`

Automatically selects validators based on input naming conventions.

```python
from validators.conventions import ConventionBasedValidator

validator = ConventionBasedValidator("my-action")
validator.validate_inputs({
    "github-token": "ghp_...",     # Uses TokenValidator
    "version": "1.2.3",            # Uses VersionValidator
    "dry-run": "true",             # Uses BooleanValidator
    "max-retries": "5"             # Uses NumericValidator
})
```

## Custom Validators

Custom validators extend the base functionality for specific actions.

### Creating a Custom Validator

1. Create `CustomValidator.py` in your action directory:

```python
from pathlib import Path
import sys

# Add validate-inputs to path
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.docker import DockerValidator

class CustomValidator(BaseValidator):
    def __init__(self, action_type: str = "my-action") -> None:
        super().__init__(action_type)
        self.docker_validator = DockerValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        valid = True

        # Validate required inputs
        valid &= self.validate_required_inputs(inputs)

        # Custom validation logic
        if inputs.get("special-field"):
            valid &= self.validate_special_field(inputs["special-field"])

        return valid

    def get_required_inputs(self) -> list[str]:
        return ["special-field", "another-required"]

    def validate_special_field(self, value: str) -> bool:
        # Custom validation logic
        if not value.startswith("special-"):
            self.add_error(f"Special field must start with 'special-': {value}")
            return False
        return True
```

### Error Propagation

When using sub-validators, propagate their errors:

```python
result = self.docker_validator.validate_image_name(image_name, "image")
if not result:
    for error in self.docker_validator.errors:
        if error not in self.errors:
            self.add_error(error)
    self.docker_validator.clear_errors()
```

## Conventions

### Input Naming Conventions

The system automatically detects validation types based on input names:

| Pattern                       | Validator        | Example                          |
|-------------------------------|------------------|----------------------------------|
| `*-token`                     | TokenValidator   | `github-token`, `npm-token`      |
| `*-version`                   | VersionValidator | `node-version`, `dotnet-version` |
| `dry-run`, `debug`, `verbose` | BooleanValidator | `dry-run`, `skip-tests`          |
| `*-retries`, `*-limit`        | NumericValidator | `max-retries`, `rate-limit`      |
| `*-file`, `*-path`            | FileValidator    | `config-file`, `output-path`     |
| `*-url`, `webhook-*`          | NetworkValidator | `api-url`, `webhook-endpoint`    |
| `*-email`                     | NetworkValidator | `maintainer-email`               |
| `dockerfile`                  | FileValidator    | `dockerfile`                     |
| `image-*`, `tag`, `platform`  | DockerValidator  | `image-name`, `tag`              |

### GitHub Expression Support

All validators support GitHub Actions expressions:

```python
validator.validate_inputs({
    "token": "${{ secrets.GITHUB_TOKEN }}",
    "version": "${{ github.event.release.tag_name }}",
    "dry-run": "${{ github.event_name == 'pull_request' }}"
})
```

Expressions containing `${{` are automatically considered valid.

## Error Handling

### Error Messages

Error messages should be:

- Clear and actionable
- Include the invalid value
- Suggest the correct format

```python
self.add_error(f"Invalid version format: {value}. Expected SemVer (1.2.3) or CalVer (2024.3.1)")
```

### Error Collection

Validators collect all errors before returning:

```python
def validate_inputs(self, inputs: dict[str, str]) -> bool:
    valid = True

    # Check multiple conditions
    if not self.validate_field1(inputs.get("field1")):
        valid = False

    if not self.validate_field2(inputs.get("field2")):
        valid = False

    # Return False only after checking everything
    return valid
```

## Performance Considerations

### Caching

The registry caches validator instances:

```python
registry = ValidatorRegistry()
validator1 = registry.get_validator("docker-build")  # Creates new
validator2 = registry.get_validator("docker-build")  # Returns cached
assert validator1 is validator2  # Same instance
```

### Lazy Loading

Validators are loaded only when needed:

```python
# Only loads DockerValidator if docker-related inputs exist
validator = ConventionBasedValidator("my-action")
validator.validate_inputs(inputs)  # Loads validators on demand
```

## Testing Validators

### Unit Testing

```python
import pytest
from validators.version import VersionValidator

def test_version_validation():
    validator = VersionValidator()

    # Test valid versions
    assert validator.validate_semantic_version("1.2.3", "version")
    assert validator.validate_calver("2024.3.1", "version")

    # Test invalid versions
    assert not validator.validate_semantic_version("invalid", "version")
    assert len(validator.errors) > 0
```

### Integration Testing

```python
def test_custom_validator():
    validator = CustomValidator("my-action")

    inputs = {
        "special-field": "special-value",
        "another-required": "test"
    }

    assert validator.validate_inputs(inputs)
    assert len(validator.errors) == 0
```

## Best Practices

1. **Always validate required inputs first**
2. **Use sub-validators for standard validations**
3. **Propagate errors from sub-validators**
4. **Support GitHub expressions**
5. **Provide clear, actionable error messages**
6. **Test both valid and invalid inputs**
7. **Document custom validation rules**
8. **Follow naming conventions for automatic detection**
