# PHP Composer Workflow

## Overview

The **PHP Composer** composable workflow automates the setup of a PHP
environment and installs project dependencies using Composer. It ensures that
the specified PHP version is used and all dependencies are installed correctly.

## Features

- Installs the specified PHP version.
- Installs project dependencies using Composer.
- Caches Composer dependencies for faster builds.

## Inputs

The following inputs are supported by the workflow:

- `php-version` (optional): The PHP version to install. Default is `8.4`.

## Outputs

This workflow does not produce direct outputs.

## Usage

### Example Workflow File

```yaml
name: PHP Composer Example

on:
    workflow_dispatch:

jobs:
    setup-php:
        runs-on: ubuntu-latest

        steps:
            -   name: Checkout Repository
                uses: actions/checkout@v4

            -   name: Setup PHP and Install Dependencies
                uses: ivuorinen/actions/composite-php-composer@main
                with:
                    php-version: "8.4"

            -   name: Verify PHP Version
                run: php -v

            -   name: Verify Composer Installation
                run: composer --version

            -   name: List Installed Dependencies
                run: composer show
```

## Notes

- Ensure that `composer.json` and `composer.lock` are present in the repository
  for proper dependency installation.
- The `php-version` input must be compatible with the project dependencies.
- This workflow uses caching to optimize dependency installation where
  applicable.

## Troubleshooting

1. **PHP Version Not Installed:**
    - Verify that the `php-version` input is correctly specified.
    - Check the logs for errors during PHP installation.

2. **Composer Installation Fails:**
    - Ensure that `composer.json` is properly configured in the repository.
    - Check for conflicts or unsupported PHP extensions in the dependency list.

3. **Cache Issues:**
    - Ensure that the caching mechanism is properly configured and the cache key
      is unique per dependency set.

## License

This workflow is licensed under the MIT License. See
the [LICENSE](../LICENSE.md) file for details.
