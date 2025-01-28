# ivuorinen/actions/composite-csharp-publish

## C# Publish

### Description

Publishes a C# project to GitHub Packages.

### Inputs

| name             | description                              | required | default     |
| ---------------- | ---------------------------------------- | -------- | ----------- |
| `dotnet-version` | <p>Version of .NET SDK to use.</p>       | `false`  | `""`        |
| `namespace`      | <p>GitHub namespace for the package.</p> | `true`   | `ivuorinen` |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/composite-csharp-publish@main
  with:
      dotnet-version:
      # Version of .NET SDK to use.
      #
      # Required: false
      # Default: ""

      namespace:
      # GitHub namespace for the package.
      #
      # Required: true
      # Default: ivuorinen
```
