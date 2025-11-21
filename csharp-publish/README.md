# ivuorinen/actions/csharp-publish

## C# Publish

### Description

Publishes a C# project to GitHub Packages.

### Inputs

| name             | description                                                        | required | default     |
|------------------|--------------------------------------------------------------------|----------|-------------|
| `dotnet-version` | <p>Version of .NET SDK to use.</p>                                 | `false`  | `""`        |
| `namespace`      | <p>GitHub namespace for the package.</p>                           | `true`   | `ivuorinen` |
| `token`          | <p>GitHub token with package write permissions</p>                 | `false`  | `""`        |
| `max-retries`    | <p>Maximum number of retry attempts for dependency restoration</p> | `false`  | `3`         |

### Outputs

| name              | description                                     |
|-------------------|-------------------------------------------------|
| `publish_status`  | <p>Overall publish status (success/failure)</p> |
| `package_version` | <p>Version of the published package</p>         |
| `package_url`     | <p>URL of the published package</p>             |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/csharp-publish@main
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

    token:
    # GitHub token with package write permissions
    #
    # Required: false
    # Default: ""

    max-retries:
    # Maximum number of retry attempts for dependency restoration
    #
    # Required: false
    # Default: 3
```
