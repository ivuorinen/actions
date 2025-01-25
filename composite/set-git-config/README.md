# Set Git Config Workflow (ivuorinen/actions/composite/set-git-config)

## Overview

The **Set Git Config** composable workflow configures Git user information for
workflows. This is useful when making commits during automated processes, such
as applying fixes or pushing updates.

## Features

- Sets the Git username and email for the current repository.
- Supports optional configuration of the Git credential helper for
  authentication.

## Inputs

The following inputs are supported by the workflow:

- `username` (optional): The Git username to configure. Default is
  `github-actions`.
- `email` (optional): The Git email to configure. Default is
  `github-actions@github.com`.
- `token` (optional): An optional Git token for authentication. Default is
  `${{ secrets.GITHUB_TOKEN }}`.

## Usage

### Example Workflow File

```yaml
name: Example Workflow

on:
    workflow_dispatch:

jobs:
    configure-git:
        runs-on: ubuntu-latest

        steps:
            -   name: Checkout Repository
                uses: actions/checkout@v4

            -   name: Configure Git
                uses: ivuorinen/actions/composite/set-git-config@main
                with:
                    username: "example-user"
                    email: "example@example.com"
                    token: ${{ secrets.GITHUB_TOKEN }}
```

## Notes

- If a `token` is provided, the workflow will configure the Git credential
  helper for authentication.
- The default username and email are sufficient for most GitHub Actions
  workflows unless specific user attribution is required.

## Troubleshooting

1. **Configuration Fails:**
    - Ensure the inputs are correctly specified in the workflow file.
    - Verify that the provided `token` is valid and has the required
      permissions.
2. **Git Authentication Issues:**
    - Check if the `token` provided has sufficient access to the repository.
    - Confirm that the repository's authentication method supports token-based
      credentials.
3. **Unexpected Commit Metadata:**
    - Verify the `username` and `email` inputs if commits are not attributed as
      expected.

## License

This workflow is licensed under the MIT License. See
the [LICENSE](../../LICENSE.md) file for details.
