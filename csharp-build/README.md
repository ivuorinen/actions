# ivuorinen/actions/csharp-build

## C# Build

### Description

Builds and tests C# projects.

### Inputs

| name             | description                                                           | required | default |
| ---------------- | --------------------------------------------------------------------- | -------- | ------- |
| `dotnet-version` | <p>Version of .NET SDK to use.</p>                                    | `false`  | `""`    |
| `max-retries`    | <p>Maximum number of retry attempts for dotnet restore operations</p> | `false`  | `3`     |
| `token`          | <p>GitHub token for authentication</p>                                | `false`  | `""`    |

### Outputs

| name                | description                                            |
| ------------------- | ------------------------------------------------------ |
| `build_status`      | <p>Build completion status (success/failure)</p>       |
| `test_status`       | <p>Test execution status (success/failure/skipped)</p> |
| `dotnet_version`    | <p>Version of .NET SDK used</p>                        |
| `artifacts_path`    | <p>Path to build artifacts</p>                         |
| `test_results_path` | <p>Path to test results</p>                            |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/csharp-build@main
  with:
    dotnet-version:
    # Version of .NET SDK to use.
    #
    # Required: false
    # Default: ""

    max-retries:
    # Maximum number of retry attempts for dotnet restore operations
    #
    # Required: false
    # Default: 3

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
