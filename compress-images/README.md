# Compress Images Workflow

## Overview

The **Compress Images** workflow automates the optimization of image assets in
your repository. It ensures that all images are compressed to reduce size while
maintaining quality and creates a pull request with the optimized assets if
changes are detected.

## Features

- Compresses supported image formats (e.g., PNG, JPEG, GIF, and SVG).
- Generates a pull request with optimized images.
- Utilizes the `calibreapp/image-actions` action for high-quality compression.

## Triggers

This workflow is triggered by:

- Manual triggering via `workflow_dispatch`.
- Scheduled runs (optional).

## Inputs

This workflow does not accept direct inputs.

## Usage

### Example Workflow File

```yaml
name: Compress Images Nightly

on:
    workflow_dispatch:
    schedule:
        -   cron: "0 0 * * 0" # Runs every Sunday at midnight

jobs:
    compress-images:
        runs-on: ubuntu-latest

        steps:
            -   name: Checkout Repository
                uses: actions/checkout@v4

            -   name: Compress Images
                uses: ivuorinen/actions/compress-images@main
```

## Notes

- Ensure the `GITHUB_TOKEN` secret is available for authentication.
- The workflow compresses only images that can be optimized without loss of
  quality.

## Troubleshooting

1. **Images Not Compressed:**
    - Verify that the repository contains compressible image formats.
    - Check the logs for specific error messages from the
      `calibreapp/image-actions` step.

2. **Pull Request Not Created:**
    - Ensure the `compressOnly` option is set to `true` and changes are
      detected.
    - Verify that the `GITHUB_TOKEN` secret has permission to create pull
      requests.

3. **Permission Issues:**
    - Check if the token used has write access to the repository.
    - Ensure that the branch protection rules allow automated pull requests.

## License

This workflow is licensed under the MIT License. See
the [LICENSE](../LICENSE.md) file for details.
