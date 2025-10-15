# Action Maintainer Guide

## Overview

This guide helps action maintainers understand and use the validation system for their GitHub Actions.

## Table of Contents

1. [How Validation Works](#how-validation-works)
2. [Using Automatic Validation](#using-automatic-validation)
3. [Custom Validation](#custom-validation)
4. [Testing Your Validation](#testing-your-validation)
5. [Common Scenarios](#common-scenarios)
6. [Troubleshooting](#troubleshooting)

## How Validation Works

### Automatic Integration

Your action automatically gets input validation when using `validate-inputs`:

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

### Validation Flow

1. **Input Collection**: All `INPUT_*` environment variables are collected
2. **Validator Selection**: System chooses appropriate validator
3. **Validation Execution**: Each input is validated
4. **Error Reporting**: Any errors are reported via `::error::`
5. **Status Output**: Results written to `GITHUB_OUTPUT`

## Using Automatic Validation

### Naming Conventions

Name your inputs to get automatic validation:

| Input Pattern        | Validation Type    | Example                          |
|----------------------|--------------------|----------------------------------|
| `*-token`            | Token validation   | `github-token`, `npm-token`      |
| `*-version`          | Version validation | `node-version`, `python-version` |
| `dry-run`, `verbose` | Boolean            | `dry-run: true`                  |
| `max-*`, `*-limit`   | Numeric range      | `max-retries`, `rate-limit`      |
| `*-file`, `*-path`   | File path          | `config-file`, `output-path`     |
| `*-url`, `webhook-*` | URL validation     | `api-url`, `webhook-endpoint`    |

### Example Action

```yaml
name: My Action
description: Example action with automatic validation

inputs:
  github-token: # Automatically validates GitHub token format
    description: GitHub token for API access
    required: true
    default: ${{ github.token }}

  node-version: # Automatically validates version format
    description: Node.js version to use
    required: false
    default: '18'

  max-retries: # Automatically validates numeric range
    description: Maximum number of retries (1-10)
    required: false
    default: '3'

  config-file: # Automatically validates file path
    description: Configuration file path
    required: false
    default: '.config.yml'

  dry-run: # Automatically validates boolean
    description: Run in dry-run mode
    required: false
    default: 'false'

runs:
  using: composite
  steps:
    - uses: ./validate-inputs
      with:
        action-type: ${{ github.action }}

    - run: echo "Inputs validated successfully"
      shell: bash
```

### Validation Rules File

After creating your action, generate validation rules:

```bash
# Generate rules for your action
make update-validators

# Or for a specific action
python3 validate-inputs/scripts/update-validators.py --action my-action
```

This creates `my-action/rules.yml`:

```yaml
schema_version: '1.0'
action: my-action
description: Example action with automatic validation
required_inputs:
  - github-token
optional_inputs:
  - node-version
  - max-retries
  - config-file
  - dry-run
conventions:
  github-token: github_token
  node-version: semantic_version
  max-retries: numeric_range_1_10
  config-file: file_path
  dry-run: boolean
```

## Custom Validation

### When to Use Custom Validation

Create a custom validator when:

- You have complex business logic
- Cross-field validation is needed
- Special format requirements exist
- Default validation is insufficient

### Creating a Custom Validator

1. **Create `CustomValidator.py`** in your action directory:

```python
#!/usr/bin/env python3
"""Custom validator for my-action."""

from __future__ import annotations
from pathlib import Path
import sys

# Add validate-inputs to path
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator
from validators.version import VersionValidator


class CustomValidator(BaseValidator):
    """Custom validator for my-action."""

    def __init__(self, action_type: str = "my-action") -> None:
        super().__init__(action_type)
        self.version_validator = VersionValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        valid = True

        # Check required inputs
        valid &= self.validate_required_inputs(inputs)

        # Custom validation
        if inputs.get("environment"):
            valid &= self.validate_environment(inputs["environment"])

        # Cross-field validation
        if inputs.get("environment") == "production":
            if not inputs.get("approval-required"):
                self.add_error(
                    "Production deployments require approval-required=true"
                )
                valid = False

        return valid

    def get_required_inputs(self) -> list[str]:
        return ["environment", "target"]

    def validate_environment(self, env: str) -> bool:
        valid_envs = ["development", "staging", "production"]
        if env not in valid_envs:
            self.add_error(
                f"Invalid environment: {env}. "
                f"Must be one of: {', '.join(valid_envs)}"
            )
            return False
        return True

    def get_validation_rules(self) -> dict:
        """Get validation rules."""
        rules_path = Path(__file__).parent / "rules.yml"
        return self.load_rules(rules_path)
```

1. **Test your validator** (optional but recommended):

```python
# my-action/test_custom_validator.py
from CustomValidator import CustomValidator

def test_valid_inputs():
    validator = CustomValidator()
    inputs = {
        "environment": "production",
        "target": "app-server",
        "approval-required": "true"
    }
    assert validator.validate_inputs(inputs) is True
    assert len(validator.errors) == 0
```

## Testing Your Validation

### Manual Testing

```bash
# Test with environment variables
export INPUT_ACTION_TYPE="my-action"
export INPUT_GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}"
export INPUT_NODE_VERSION="18.0.0"
export INPUT_DRY_RUN="true"

python3 validate-inputs/validator.py
```

### Integration Testing

Create a test workflow:

```yaml
# .github/workflows/test-my-action.yml
name: Test My Action Validation

on:
  pull_request:
    paths:
      - 'my-action/**'
      - 'validate-inputs/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Test valid inputs
      - name: Test with valid inputs
        uses: ./my-action
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          node-version: '18.0.0'
          dry-run: 'true'

      # Test invalid inputs (should fail)
      - name: Test with invalid inputs
        id: invalid
        continue-on-error: true
        uses: ./my-action
        with:
          github-token: 'invalid-token'
          node-version: 'not-a-version'
          dry-run: 'maybe'

      - name: Check failure
        if: steps.invalid.outcome != 'failure'
        run: exit 1
```

### Generating Tests

Use the test generator:

```bash
# Generate tests for your action
make generate-tests

# Preview what would be generated
make generate-tests-dry

# Run the generated tests
make test
```

## Common Scenarios

### Scenario 1: Required Inputs

```yaml
inputs:
  api-key:
    description: API key for service
    required: true # No default value
```

Validation automatically enforces this requirement.

### Scenario 2: Dependent Inputs

Use custom validator for dependent fields:

```python
def validate_inputs(self, inputs: dict[str, str]) -> bool:
    # If using custom registry, token is required
    if inputs.get("registry") and not inputs.get("registry-token"):
        self.add_error("registry-token required when using custom registry")
        return False
    return True
```

### Scenario 3: Complex Formats

```python
def validate_cron_schedule(self, schedule: str) -> bool:
    """Validate cron schedule format."""
    import re

    # Simple cron pattern (not exhaustive)
    pattern = r'^(\*|[0-9,\-\*/]+)\s+(\*|[0-9,\-\*/]+)\s+(\*|[0-9,\-\*/]+)\s+(\*|[0-9,\-\*/]+)\s+(\*|[0-9,\-\*/]+)$'

    if not re.match(pattern, schedule):
        self.add_error(f"Invalid cron schedule: {schedule}")
        return False
    return True
```

### Scenario 4: External Service Validation

```python
def validate_docker_image_exists(self, image: str) -> bool:
    """Check if Docker image exists (example)."""
    # Note: Be careful with external calls in validation
    # Consider caching or making this optional

    # Allow GitHub Actions expressions
    if self.is_github_expression(image):
        return True

    # Simplified check - real implementation would need error handling
    import subprocess
    result = subprocess.run(
        ["docker", "manifest", "inspect", image],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        self.add_error(f"Docker image not found: {image}")
        return False
    return True
```

## Troubleshooting

### Issue: Validation Not Running

**Check**:

1. Is `validate-inputs` action called in your workflow?
2. Is `action-type` parameter set correctly?
3. Are environment variables prefixed with `INPUT_`?

**Debug**:

```yaml
- name: Debug inputs
  run: |
    env | grep INPUT_ | sort
  shell: bash

- uses: ./validate-inputs
  with:
    action-type: ${{ github.action }}
```

### Issue: Custom Validator Not Found

**Check**:

1. Is `CustomValidator.py` in action directory?
2. Is class named exactly `CustomValidator`?
3. Is file readable and valid Python?

**Debug**:

```bash
# Test import directly
python3 -c "from my_action.CustomValidator import CustomValidator; print('Success')"
```

### Issue: Validation Too Strict

**Solutions**:

1. **Allow GitHub expressions**:

```python
if self.is_github_expression(value):
    return True
```

1. **Make fields optional**:

```python
if not value or not value.strip():
    return True  # Empty is OK for optional fields
```

1. **Add to allowed values**:

```python
valid_values = ["option1", "option2", "custom"]  # Add more options
```

### Issue: Validation Not Strict Enough

**Solutions**:

1. **Create custom validator** with stricter rules
2. **Add pattern matching**:

```python
import re
if not re.match(r'^[a-z0-9\-]+$', value):
    self.add_error("Only lowercase letters, numbers, and hyphens allowed")
```

1. **Add length limits**:

```python
if len(value) > 100:
    self.add_error("Value too long (max 100 characters)")
```

### Getting Validation Status

Access validation results in subsequent steps:

```yaml
- uses: ./validate-inputs
  id: validation
  with:
    action-type: my-action

- name: Check validation status
  run: |
    echo "Status: ${{ steps.validation.outputs.status }}"
    echo "Valid: ${{ steps.validation.outputs.valid }}"
    echo "Action: ${{ steps.validation.outputs.action }}"
    echo "Inputs validated: ${{ steps.validation.outputs.inputs_validated }}"
  shell: bash
```

### Debugging Validation Errors

Enable debug output:

```yaml
- uses: ./validate-inputs
  with:
    action-type: my-action
  env:
    ACTIONS_RUNNER_DEBUG: true
    ACTIONS_STEP_DEBUG: true
```

View specific errors:

```bash
# In your action
- name: Validate
  id: validate
  uses: ./validate-inputs
  continue-on-error: true
  with:
    action-type: my-action

- name: Show errors
  if: steps.validate.outcome == 'failure'
  run: |
    echo "Validation failed!"
    # Errors are already shown via ::error::
  shell: bash
```

## Best Practices

1. **Use conventions** when possible for automatic validation
2. **Document validation rules** in your action's README
3. **Test with invalid inputs** to ensure validation works
4. **Allow GitHub expressions** (`${{ }}`) in all validators
5. **Provide clear error messages** that explain how to fix the issue
6. **Make validation fast** - avoid expensive operations
7. **Cache validation results** if checking external resources
8. **Version your validation** - use `validate-inputs@v1` etc.
9. **Monitor validation failures** in your action's usage

## Resources

- [API Documentation](./API.md) - Complete validator API reference
- [Developer Guide](./DEVELOPER_GUIDE.md) - Adding new validators
- [Test Generator](../scripts/generate-tests.py) - Automatic test creation
- [Rule Generator](../scripts/update-validators.py) - Rule file generation

## Support

For validation issues:

1. Check error messages for specific problems
2. Review validation rules in action folder's `rules.yml`
3. Test with simplified inputs
4. Create custom validator if needed
5. Report bugs via GitHub Issues
