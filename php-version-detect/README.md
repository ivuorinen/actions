# ivuorinen/actions/php-version-detect

## PHP Version Detect

### Description

Detects the PHP version from the project's composer.json, phpunit.xml, or other configuration files.

### Inputs

| name              | description                                                  | required | default |
|-------------------|--------------------------------------------------------------|----------|---------|
| `default-version` | <p>Default PHP version to use if no version is detected.</p> | `false`  | `8.2`   |
| `token`           | <p>GitHub token for authentication</p>                       | `false`  | `""`    |

### Outputs

| name          | description                             |
|---------------|-----------------------------------------|
| `php-version` | <p>Detected or default PHP version.</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/php-version-detect@main
  with:
    default-version:
    # Default PHP version to use if no version is detected.
    #
    # Required: false
    # Default: 8.2

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
