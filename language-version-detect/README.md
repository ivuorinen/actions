# ivuorinen/actions/language-version-detect

## Language Version Detect

### Description

Detects language version from project configuration files with support for PHP, Python, Go, and .NET.

### Inputs

| name              | description                                                     | required | default |
|-------------------|-----------------------------------------------------------------|----------|---------|
| `language`        | <p>Language to detect version for (php, python, go, dotnet)</p> | `true`   | `""`    |
| `default-version` | <p>Default version to use if no version is detected</p>         | `false`  | `""`    |
| `token`           | <p>GitHub token for authentication</p>                          | `false`  | `""`    |

### Outputs

| name               | description                                                                |
|--------------------|----------------------------------------------------------------------------|
| `detected-version` | <p>Detected or default language version</p>                                |
| `package-manager`  | <p>Detected package manager (python: pip/poetry/pipenv, php: composer)</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/language-version-detect@v2025
  with:
    language:
    # Language to detect version for (php, python, go, dotnet)
    #
    # Required: true
    # Default: ""

    default-version:
    # Default version to use if no version is detected
    #
    # Required: false
    # Default: ""

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
