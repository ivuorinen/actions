# ivuorinen/actions/version-validator

## Version Validator

### Description

Validates and normalizes version strings using customizable regex patterns

### Inputs

| name               | description                             | required | default                                                            |
|--------------------|-----------------------------------------|----------|--------------------------------------------------------------------|
| `version`          | <p>Version string to validate</p>       | `true`   | `""`                                                               |
| `validation-regex` | <p>Regex pattern for validation</p>     | `false`  | `^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$` |
| `language`         | <p>Language name for error messages</p> | `false`  | `version`                                                          |

### Outputs

| name                | description                                                |
|---------------------|------------------------------------------------------------|
| `is-valid`          | <p>Boolean indicating if version is valid (true/false)</p> |
| `validated-version` | <p>Cleaned/normalized version string</p>                   |
| `error-message`     | <p>Error message if validation fails</p>                   |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/version-validator@main
  with:
    version:
    # Version string to validate
    #
    # Required: true
    # Default: ""

    validation-regex:
    # Regex pattern for validation
    #
    # Required: false
    # Default: ^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$

    language:
    # Language name for error messages
    #
    # Required: false
    # Default: version
```
