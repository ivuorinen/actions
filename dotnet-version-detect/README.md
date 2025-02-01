# ivuorinen/actions/dotnet-version-detect

## Dotnet Version Detect

### Description

Detects .NET SDK version from global.json or defaults to a specified version.

### Inputs

| name              | description                                                         | required | default |
| ----------------- | ------------------------------------------------------------------- | -------- | ------- |
| `default-version` | <p>Default .NET SDK version to use if global.json is not found.</p> | `true`   | `7.0`   |

### Outputs

| name             | description                                  |
| ---------------- | -------------------------------------------- |
| `dotnet-version` | <p>Detected or default .NET SDK version.</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/dotnet-version-detect@main
  with:
    default-version:
    # Default .NET SDK version to use if global.json is not found.
    #
    # Required: true
    # Default: 7.0
```
