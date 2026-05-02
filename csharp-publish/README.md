# ivuorinen/actions/csharp-publish

## Description

Publishes a C# project to GitHub Packages.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| dotnet-version | Version of .NET SDK to use. | `false` |  |
| namespace | GitHub namespace for the package. | `true` | ivuorinen |
| token | GitHub token with package write permissions | `false` |  |
| max-retries | Maximum number of retry attempts for dependency restoration | `false` | 3 |

## Outputs

| parameter | description |
| --- | --- |
| publish_status | Overall publish status (success/failure) |
| package_version | Version of the published package |
| package_url | URL of the published package |

## Runs

This action is a `composite` action.
