# Developer Guide - Adding New Validators

## Table of Contents

1. [Quick Start](#quick-start)
2. [Creating a Core Validator](#creating-a-core-validator)
3. [Creating a Custom Validator](#creating-a-custom-validator)
4. [Adding Convention Patterns](#adding-convention-patterns)
5. [Writing Tests](#writing-tests)
6. [Debugging](#debugging)
7. [Common Patterns](#common-patterns)

## Quick Start

### Adding validation for a new input type

1. **Check if existing validator covers it**:

   ```bash
   # Search for similar validation patterns
   grep -r "validate_.*" validate-inputs/validators/
   ```

2. **Use convention-based detection** (easiest):
   - Name your input following conventions (e.g., `my-token`, `api-version`)
   - System automatically uses appropriate validator

3. **Create custom validator** (for complex logic):

   ```bash
   # Create CustomValidator.py in your action directory
   touch my-action/CustomValidator.py
   ```

## Creating a Core Validator

### Step 1: Create the Validator File

Create `validate-inputs/validators/mytype.py`:

```python
"""Validator for MyType inputs."""

from __future__ import annotations
import re
from typing import Any

from .base import BaseValidator


class MyTypeValidator(BaseValidator):
    """Validates MyType-specific inputs."""

    def __init__(self, action_type: str = "") -> None:
        """Initialize the MyType validator."""
        super().__init__(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate MyType inputs based on conventions.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all validations pass, False otherwise
        """
        valid = True

        for input_name, value in inputs.items():
            # Check if this input should be validated by this validator
            if self._should_validate(input_name):
                if not self.validate_mytype(value, input_name):
                    valid = False

        return valid

    def _should_validate(self, input_name: str) -> bool:
        """Check if input should be validated by this validator."""
        # Define patterns that trigger this validator
        patterns = [
            "mytype",
            "-mytype",
            "mytype-",
        ]

        name_lower = input_name.lower()
        return any(pattern in name_lower for pattern in patterns)

    def validate_mytype(self, value: str, field_name: str) -> bool:
        """Validate a MyType value.

        Args:
            value: The value to validate
            field_name: Name of the field being validated

        Returns:
            True if valid, False otherwise
        """
        # Allow empty for optional fields
        if not value or not value.strip():
            return True

        # Allow GitHub Actions expressions
        if self.is_github_expression(value):
            return True

        # Your validation logic here
        pattern = r"^mytype-[a-z0-9]+$"
        if not re.match(pattern, value):
            self.add_error(
                f"Invalid MyType format for '{field_name}': {value}. "
                f"Expected format: mytype-xxxxx"
            )
            return False

        return True
```

### Step 2: Register the Validator

Add to `validate-inputs/validators/__init__.py`:

```python
from .mytype import MyTypeValidator

__all__ = [
    # ... existing validators ...
    "MyTypeValidator",
]
```

### Step 3: Add Convention Patterns

Update `validate-inputs/validators/conventions.py`:

```python
# In ConventionBasedValidator.PATTERNS dict:
PATTERNS = {
    # Exact matches (highest priority)
    "exact": {
        # ... existing patterns ...
        "mytype-config": "mytype",
    },

    # Prefix patterns
    "prefix": {
        # ... existing patterns ...
        "mytype-": "mytype",
    },

    # Suffix patterns
    "suffix": {
        # ... existing patterns ...
        "-mytype": "mytype",
    },
}

# In get_validator_class method:
validator_map = {
    # ... existing mappings ...
    "mytype": MyTypeValidator,
}
```

## Creating a Custom Validator

### For Complex Action-Specific Logic

Create `my-action/CustomValidator.py`:

```python
"""Custom validator for my-action.

This validator handles complex validation logic specific to my-action.
"""

from __future__ import annotations
from pathlib import Path
import sys

# Add validate-inputs directory to path
validate_inputs_path = Path(__file__).parent.parent / "validate-inputs"
sys.path.insert(0, str(validate_inputs_path))

from validators.base import BaseValidator  # noqa: E402
from validators.version import VersionValidator  # noqa: E402
from validators.token import TokenValidator  # noqa: E402


class CustomValidator(BaseValidator):
    """Custom validator for my-action."""

    def __init__(self, action_type: str = "my-action") -> None:
        """Initialize the custom validator."""
        super().__init__(action_type)
        # Initialize sub-validators
        self.version_validator = VersionValidator(action_type)
        self.token_validator = TokenValidator(action_type)

    def validate_inputs(self, inputs: dict[str, str]) -> bool:
        """Validate my-action specific inputs.

        Args:
            inputs: Dictionary of input names to values

        Returns:
            True if all validations pass, False otherwise
        """
        valid = True

        # Validate required inputs
        valid &= self.validate_required_inputs(inputs)

        # Use sub-validators
        if inputs.get("api-token"):
            if not self.token_validator.validate_github_token(
                inputs["api-token"], "api-token"
            ):
                # Propagate errors
                for error in self.token_validator.errors:
                    if error not in self.errors:
                        self.add_error(error)
                self.token_validator.clear_errors()
                valid = False

        # Custom validation logic
        if inputs.get("mode"):
            valid &= self.validate_mode(inputs["mode"])

        # Cross-field validation
        if inputs.get("source") and inputs.get("target"):
            valid &= self.validate_source_target(
                inputs["source"],
                inputs["target"]
            )

        return valid

    def get_required_inputs(self) -> list[str]:
        """Get list of required inputs.

        Returns:
            List of required input names
        """
        return ["api-token", "mode"]

    def validate_mode(self, mode: str) -> bool:
        """Validate operation mode.

        Args:
            mode: The mode value

        Returns:
            True if valid, False otherwise
        """
        valid_modes = ["development", "staging", "production"]

        if mode not in valid_modes:
            self.add_error(
                f"Invalid mode: {mode}. "
                f"Must be one of: {', '.join(valid_modes)}"
            )
            return False

        return True

    def validate_source_target(self, source: str, target: str) -> bool:
        """Validate source and target relationship.

        Args:
            source: Source value
            target: Target value

        Returns:
            True if valid, False otherwise
        """
        if source == target:
            self.add_error("Source and target cannot be the same")
            return False

        return True
```

## Adding Convention Patterns

### Pattern Priority

Patterns are checked in this order:

1. **Exact match** (highest priority)
2. **Prefix match** (`token-*`)
3. **Suffix match** (`*-token`)
4. **Contains match** (lowest priority)

### Adding a New Pattern

```python
# In validate-inputs/validators/conventions.py

# For automatic token validation of "api-key" inputs:
PATTERNS = {
    "exact": {
        "api-key": "token",  # Maps api-key to TokenValidator
    },
}

# For all inputs ending with "-secret":
PATTERNS = {
    "suffix": {
        "-secret": "security",  # Maps to SecurityValidator
    },
}
```

## Writing Tests

### Core Validator Tests

Create `validate-inputs/tests/test_mytype.py`:

```python
"""Tests for MyTypeValidator."""

import pytest
from validators.mytype import MyTypeValidator


class TestMyTypeValidator:
    """Test MyTypeValidator functionality."""

    def setup_method(self):
        """Set up test fixtures."""
        self.validator = MyTypeValidator("test-action")

    def test_initialization(self):
        """Test validator initialization."""
        assert self.validator.action_type == "test-action"
        assert self.validator.errors == []

    def test_valid_mytype(self):
        """Test valid MyType values."""
        valid_cases = [
            "mytype-abc123",
            "mytype-test",
            "${{ secrets.MYTYPE }}",  # GitHub expression
            "",  # Empty allowed
        ]

        for value in valid_cases:
            self.validator.clear_errors()
            result = self.validator.validate_mytype(value, "test")
            assert result is True, f"Failed for: {value}"
            assert len(self.validator.errors) == 0

    def test_invalid_mytype(self):
        """Test invalid MyType values."""
        invalid_cases = [
            ("invalid", "Invalid MyType format"),
            ("mytype-", "Invalid MyType format"),
            ("MYTYPE-123", "Invalid MyType format"),  # Uppercase
        ]

        for value, expected_error in invalid_cases:
            self.validator.clear_errors()
            result = self.validator.validate_mytype(value, "test")
            assert result is False, f"Should fail for: {value}"
            assert any(
                expected_error in error
                for error in self.validator.errors
            )

    def test_validate_inputs(self):
        """Test full input validation."""
        inputs = {
            "mytype-field": "mytype-valid",
            "other-field": "ignored",
        }

        result = self.validator.validate_inputs(inputs)
        assert result is True
        assert len(self.validator.errors) == 0
```

### Custom Validator Tests

Create `my-action/test_custom_validator.py`:

```python
"""Tests for my-action CustomValidator."""

import sys
from pathlib import Path

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from my_action.CustomValidator import CustomValidator


def test_custom_validator():
    """Test custom validation logic."""
    validator = CustomValidator()

    # Test valid inputs
    inputs = {
        "api-token": "${{ secrets.GITHUB_TOKEN }}",
        "mode": "production",
        "source": "dev",
        "target": "prod",
    }

    assert validator.validate_inputs(inputs) is True
    assert len(validator.errors) == 0

    # Test invalid mode
    validator.clear_errors()
    inputs["mode"] = "invalid"

    assert validator.validate_inputs(inputs) is False
    assert "Invalid mode" in str(validator.errors)
```

### Using Test Generator

Generate test scaffolding automatically:

```bash
# Generate missing tests
make generate-tests

# Preview what would be generated
make generate-tests-dry

# Test specific action
python3 validate-inputs/scripts/generate-tests.py --action my-action
```

## Debugging

### Enable Debug Output

```python
import logging

# In your validator
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class MyValidator(BaseValidator):
    def validate_mytype(self, value: str, field_name: str) -> bool:
        logger.debug(f"Validating {field_name}: {value}")
        # ... validation logic ...
```

### Test Validator Directly

```python
#!/usr/bin/env python3
"""Debug validator directly."""

from validators.mytype import MyTypeValidator

validator = MyTypeValidator("debug")
result = validator.validate_mytype("test-value", "field")

print(f"Valid: {result}")
print(f"Errors: {validator.errors}")
```

### Check Convention Matching

```python
from validators.conventions import ConventionBasedValidator

validator = ConventionBasedValidator("test")
mapper = validator.convention_mapper

# Check what validator would be used
validator_type = mapper.get_validator_type("my-field-name")
print(f"Would use: {validator_type}")
```

## Common Patterns

### Pattern 1: Composing Validators

```python
class CustomValidator(BaseValidator):
    def __init__(self, action_type: str) -> None:
        super().__init__(action_type)
        # Compose multiple validators
        self.token_val = TokenValidator(action_type)
        self.version_val = VersionValidator(action_type)
        self.docker_val = DockerValidator(action_type)
```

### Pattern 2: Error Propagation

```python
def validate_inputs(self, inputs: dict[str, str]) -> bool:
    # Use sub-validator
    result = self.docker_val.validate_image_name(
        inputs["image"], "image"
    )

    if not result:
        # Propagate errors
        for error in self.docker_val.errors:
            if error not in self.errors:
                self.add_error(error)
        self.docker_val.clear_errors()
        return False
```

### Pattern 3: GitHub Expression Support

```python
def validate_field(self, value: str, field_name: str) -> bool:
    # Allow GitHub Actions expressions
    if self.is_github_expression(value):
        return True

    # Your validation logic
    # ...
```

### Pattern 4: Optional vs Required

```python
def validate_field(self, value: str, field_name: str) -> bool:
    # Allow empty for optional fields
    if not value or not value.strip():
        return True

    # Validate non-empty values
    # ...
```

### Pattern 5: Security Checks

```python
def validate_input(self, value: str, field_name: str) -> bool:
    # Always check for injection attempts
    if not self.validate_security_patterns(value, field_name):
        return False

    # Your validation logic
    # ...
```

## Performance Tips

1. **Cache Regex Patterns**:

   ```python
   class MyValidator(BaseValidator):
       # Compile once at class level
       PATTERN = re.compile(r"^mytype-[a-z0-9]+$")

       def validate_mytype(self, value: str, field_name: str) -> bool:
           if not self.PATTERN.match(value):
               # ...
   ```

2. **Lazy Load Sub-Validators**:

   ```python
   @property
   def docker_validator(self):
       if not hasattr(self, "_docker_validator"):
           self._docker_validator = DockerValidator(self.action_type)
       return self._docker_validator
   ```

3. **Early Returns**:

   ```python
   def validate_inputs(self, inputs: dict[str, str]) -> bool:
       # Check required inputs first
       if not self.validate_required_inputs(inputs):
           return False  # Exit early

       # Continue with other validations
       # ...
   ```

## Checklist for New Validators

- [ ] Create validator class extending `BaseValidator`
- [ ] Implement `validate_inputs` method
- [ ] Add to `__init__.py` exports
- [ ] Add convention patterns if applicable
- [ ] Write comprehensive tests
- [ ] Test with GitHub expressions (`${{ }}`)
- [ ] Test with empty/whitespace values
- [ ] Document validation rules
- [ ] Handle error propagation from sub-validators
- [ ] Run linting: `make lint-python`
- [ ] Run tests: `make test-python`
- [ ] Generate tests: `make generate-tests`

## Getting Help

1. **Check existing validators** for similar patterns
2. **Run tests** to verify your implementation
3. **Use debugging** to trace validation flow
4. **Review API documentation** for method signatures
5. **Check test files** for usage examples

## Next Steps

After creating your validator:

1. **Update action rules**: Run `make update-validators`
2. **Test with real action**: Use the validator with your GitHub Action
3. **Document special rules**: Add to action's README
4. **Monitor for issues**: Check GitHub Actions logs for validation errors
