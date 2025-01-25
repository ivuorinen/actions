# Reusable Pre-Commit Checks (ivuorinen/actions/composite/pre-commit)

## Overview

The **Reusable Pre-Commit Checks** workflow runs pre-commit checks with flexible
configurations. It ensures that all committed code adheres to style, formatting,
and other quality guidelines specified in the pre-commit configuration file.

## Features

- Runs `pre-commit` checks across all files or specific configurations.
- Supports automatic fixes and pushes changes if applicable.
- Integrates seamlessly with repositories using pre-commit configurations.

## Triggers

This workflow is triggered by:

- Invocation from another workflow using `workflow_call`.

## Inputs

The following inputs are supported by the workflow:

- `config-path` (optional): Path to the pre-commit configuration file. Default is
  `.pre-commit-config.yaml`.

## Usage

### Example Workflow File

```yaml
name: Run Pre-Commit Checks

on:
    pull_request:
        branches:
            - main
            - master

jobs:
    pre-commit:
        runs-on: ubuntu-latest

        steps:
            -   name: Set Git Config
                uses: ivuorinen/actions/composite/set-git-config@main

            -   name: Checkout Repository
                uses: actions/checkout@v4

            -   name: Pre-Commit Checks
                uses: ivuorinen/actions/composite/pre-commit@main
```

## Notes

- Ensure the `config-path` input points to a valid `.pre-commit-config.yaml`
  file.
- The repository must have a valid pre-commit configuration file for the checks
  to work.
- If changes are automatically fixed, they will be pushed back to the branch.

## Troubleshooting

1. **Pre-Commit Installation Fails:**
    - Verify that Python and `pip` are available on the runner.
    - Ensure the runner has access to install packages globally or in a virtual
      environment.

2. **Configuration Not Found:**
    - Confirm that the path specified in `config-path` points to a valid
      `.pre-commit-config.yaml` file.

3. **Push Fails:**
    - Check if the `GITHUB_TOKEN` secret has sufficient permissions to push
      changes.
    - Ensure that the branch is not protected against direct pushes.

## License

This workflow is licensed under the MIT License. See
the [LICENSE](../../LICENSE.md) file for details.
