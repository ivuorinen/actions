# ivuorinen/actions/version-validator

Validates and normalizes version strings using customizable regex patterns.

## Usage

```yaml
- uses: ivuorinen/actions/version-validator@main
  with:
    version: 'v3.11.2'
    validation-regex: '^[0-9]+\.[0-9]+(\.[0-9]+)?$'
    language: 'Python'
```

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `version` | Version string to validate | Yes | |
| `validation-regex` | Regex pattern for validation | No | `^[0-9]+\.[0-9]+(\.[0-9]+)?$` |
| `language` | Language name for error messages | No | `version` |

## Outputs

| Name | Description |
|------|-------------|
| `is-valid` | Boolean indicating if version is valid (true/false) |
| `validated-version` | Cleaned/normalized version string |
| `error-message` | Error message if validation fails |

## Features

- **Version Cleaning**: Removes 'v' prefixes, whitespace, and line endings
- **Flexible Validation**: Supports custom regex patterns
- **Error Reporting**: Provides detailed error messages
- **Language Context**: Includes language name in error messages

## Example Usage

### Basic Validation

```yaml
- name: Validate Node.js Version
  id: validate
  uses: ivuorinen/actions/version-validator@main
  with:
    version: 'v18.17.0'
    language: 'Node.js'

- name: Use validated version
  if: steps.validate.outputs.is-valid == 'true'
  run: echo "Using Node.js ${{ steps.validate.outputs.validated-version }}"
```

### Custom Validation Pattern

```yaml
- name: Validate Semantic Version
  uses: ivuorinen/actions/version-validator@main
  with:
    version: '1.2.3-alpha.1'
    validation-regex: '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'
    language: 'SemVer'
```

### Error Handling

```yaml
- name: Validate Version
  id: validate
  uses: ivuorinen/actions/version-validator@main
  with:
    version: 'invalid-version'

- name: Handle validation error
  if: steps.validate.outputs.is-valid == 'false'
  run: |
    echo "❌ Validation failed: ${{ steps.validate.outputs.error-message }}"
    exit 1
```
