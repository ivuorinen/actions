# ivuorinen/actions/composite-csharp-lint-check

## C# Lint Check

### Description

Runs linters like StyleCop or dotnet-format for C# code style checks.

### Inputs

| name             | description                        | required | default |
|------------------|------------------------------------|----------|---------|
| `dotnet-version` | <p>Version of .NET SDK to use.</p> | `false`  | `""`    |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-csharp-lint-check@main
  with:
      dotnet-version:
      # Version of .NET SDK to use.
      #
      # Required: false
      # Default: ""
```
