# ivuorinen/actions/csharp-lint-check

## Description

Runs linters like StyleCop or dotnet-format for C# code style checks.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| dotnet-version | Version of .NET SDK to use. | `false` |  |
| token | GitHub token for authentication | `false` |  |

## Outputs

| parameter | description |
| --- | --- |
| lint_status | Overall lint status (success/failure) |
| errors_count | Number of formatting errors found |
| warnings_count | Number of formatting warnings found |

## Runs

This action is a `composite` action.
