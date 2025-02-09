# ivuorinen/actions/csharp-build

## C# Build

### Description

Builds and tests C# projects.

### Inputs

| name             | description                        | required | default |
|------------------|------------------------------------|----------|---------|
| `dotnet-version` | <p>Version of .NET SDK to use.</p> | `false`  | `""`    |

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
