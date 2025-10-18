# ivuorinen/actions/csharp-lint-check

## C# Lint Check

### Description

Runs linters like StyleCop or dotnet-format for C# code style checks.

### Inputs

| name             | description                            | required | default |
|------------------|----------------------------------------|----------|---------|
| `dotnet-version` | <p>Version of .NET SDK to use.</p>     | `false`  | `""`    |
| `token`          | <p>GitHub token for authentication</p> | `false`  | `""`    |

### Outputs

| name             | description                                  |
|------------------|----------------------------------------------|
| `lint_status`    | <p>Overall lint status (success/failure)</p> |
| `errors_count`   | <p>Number of formatting errors found</p>     |
| `warnings_count` | <p>Number of formatting warnings found</p>   |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/csharp-lint-check@main
  with:
    dotnet-version:
    # Version of .NET SDK to use.
    #
    # Required: false
    # Default: ""

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
