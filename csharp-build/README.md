# ivuorinen/actions/csharp-build

## C# Build

### Description

Builds and tests C# projects.

### Inputs

| name             | description                        | required | default |
|------------------|------------------------------------|----------|---------|
| `dotnet-version` | <p>Version of .NET SDK to use.</p> | `false`  | `""`    |

### Outputs

| name                | description                                            |
|---------------------|--------------------------------------------------------|
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
```
