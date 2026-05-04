# ivuorinen/actions/csharp-build

## Description

Builds and tests C# projects.

## Inputs

| parameter      | description                                                    | required | default |
|----------------|----------------------------------------------------------------|----------|---------|
| dotnet-version | Version of .NET SDK to use.                                    | `false`  |         |
| max-retries    | Maximum number of retry attempts for dotnet restore operations | `false`  | 3       |
| token          | GitHub token for authentication                                | `false`  |         |

## Outputs

| parameter         | description                                     |
|-------------------|-------------------------------------------------|
| build_status      | Build completion status (success/failure)       |
| test_status       | Test execution status (success/failure/skipped) |
| dotnet_version    | Version of .NET SDK used                        |
| artifacts_path    | Path to build artifacts                         |
| test_results_path | Path to test results                            |

## Runs

This action is a `composite` action.
