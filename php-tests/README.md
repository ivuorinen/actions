# PHP Tests Workflow (ivuorinen/actions/php-tests)

## Overview

The **PHP Tests** workflow automates running tests for PHP projects using
PHPUnit. It ensures that your code is tested for functionality and correctness
during pull requests or manual triggers.

## Features

- Installs PHP dependencies using Composer.
- Runs tests using PHPUnit.
- Supports custom PHP versions.

## Triggers

This workflow is triggered by:

- Pull requests targeting the `main` and `master` branches.
- Manual triggering via `workflow_dispatch`.

## Inputs

This workflow does not accept direct inputs.

## Usage

### Example Workflow File

```yaml
name: Run PHP Tests

on:
    pull_request:
        branches:
            - main
            - master
    workflow_dispatch:

jobs:
    test:
        runs-on: ubuntu-latest

        steps:
            -   name: Checkout Repository
                uses: actions/checkout@v4

            -   name: Set Up PHP and Install Dependencies
                uses: ivuorinen/actions/composite/php-composer@main

            -   name: Run PHPUnit Tests
                run: vendor/bin/phpunit --verbose
```

## Notes

- Ensure that `composer.json` and `phpunit.xml` files are present in the
  repository.
- The PHP version can be customized using the `php-version` input.

## Troubleshooting

1. **Dependency Installation Fails:**
    - Verify that the `composer.json` file is correctly configured.
    - Ensure the specified PHP version is compatible with the dependencies.

2. **Tests Fail to Run:**
    - Confirm that the `phpunit.xml` configuration file is correctly set up.
    - Ensure all required dependencies for tests are installed.

3. **Unexpected Errors:**
    - Check the logs for detailed error messages.
    - Run `composer install` and `phpunit` locally to replicate and debug
      issues.

## License

This workflow is licensed under the MIT License. See the [LICENSE](../LICENSE)
file for details.
