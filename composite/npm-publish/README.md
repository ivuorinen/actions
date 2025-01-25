# NPM Publish (ivuorinen/actions/composite/npm-publish)

## Overview

The **NPM Publish** workflow automates the process of publishing a package to
the NPM registry. It ensures that your package is properly versioned and
uploaded to the specified registry with optional scope configurations.

## Features

- Publishes a package to the NPM registry.
- Configurable registry URL and package scope.
- Supports secure authentication using NPM tokens.

## Requirements

- A valid NPM token with publishing permissions. Save this token as a GitHub
  secret with the name `NPM_TOKEN`.
- A `package.json` file with the correct package name and version.
- A build step that generates the package artifacts before publishing.

## Inputs

The following inputs are supported by the workflow:

- `package-version` (required): The version of the package to publish.
- `registry-url` (optional): The URL of the NPM registry. Default is
  `https://registry.npmjs.org/`.
- `scope` (optional): The scope of the package to publish. Default is
  `@ivuorinen`.

## Usage

### Example Workflow File

```yaml
name: Publish to NPM

on:
    release: [published]

jobs:
    publish:
        runs-on: ubuntu-latest

        steps:
            -   name: Checkout Repository
                uses: actions/checkout@v4

            -   name: Set Git Config
                uses: ivuorinen/actions/composite/set-git-config@main

            -   name: Publish Package
                uses: ivuorinen/actions/composite/npm-publish@main
                with:
                    registry-url: "https://registry.npmjs.org/"
                    scope: "@ivuorinen"
                    package-version: [detected version]
```

## Notes

- Ensure that the `NPM_TOKEN` secret is configured in your repository settings
  for authentication.
- The `package-version` input should match the version defined in your
  `package.json` file.

## Troubleshooting

1. **Authentication Fails:**
    - Verify that the `NPM_TOKEN` secret is correctly configured and has
      publishing permissions.
    - Ensure the registry URL matches the one your NPM token is configured for.

2. **Version Mismatch:**
    - Check that the `package-version` input matches the `version` field in
      `package.json`.
    - Update `package.json` if necessary before running the workflow.

3. **Publishing Fails:**
    - Confirm that the package name and scope are correctly defined in
      `package.json`.
    - Ensure all dependencies are installed and build steps are completed before
      publishing.

## License

This workflow is licensed under the MIT License. See
the [LICENSE](../../LICENSE.md) file for details.
