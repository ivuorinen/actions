# ivuorinen/actions/go-build

## Description

Builds the Go project.

## Inputs

| parameter   | description                                                     | required | default |
|-------------|-----------------------------------------------------------------|----------|---------|
| go-version  | Go version to use.                                              | `false`  |         |
| destination | Build destination directory.                                    | `false`  | ./bin   |
| max-retries | Maximum number of retry attempts for go mod download operations | `false`  | 3       |
| token       | GitHub token for authentication                                 | `false`  |         |

## Outputs

| parameter     | description                                     |
|---------------|-------------------------------------------------|
| build_status  | Build completion status (success/failure)       |
| test_status   | Test execution status (success/failure/skipped) |
| go_version    | Version of Go used                              |
| binary_path   | Path to built binaries                          |
| coverage_path | Path to coverage report                         |

## Runs

This action is a `composite` action.
