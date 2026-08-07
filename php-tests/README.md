# PHP Tests

<div align="center">
  <img src="https://img.shields.io/badge/icon-check-circle-green" alt="check-circle" />
  <img src="https://img.shields.io/badge/status-stable-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
</div>

## Overview

Run PHPUnit tests with optional Laravel setup and Composer dependency management

This GitHub Action provides a robust solution for your CI/CD pipeline with comprehensive configuration options and detailed output information.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Input Parameters](#input-parameters)
- [Output Parameters](#output-parameters)
- [Examples](#examples)

- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

Add the following step to your GitHub Actions workflow:

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: PHP Tests
        uses: ivuorinen/actions/php-tests@vYYYY.MM.DD
        with:
          composer-args: '--no-progress --prefer-dist --optimize-autoloader'
          coverage: 'none'
          email: 'github-actions@github.com'
          extensions: 'mbstring, intl, json, pdo_sqlite, sqlite3'
          framework: 'auto'
          max-retries: '3'
          php-version: 'latest'
          token: 'your-value-here'
          username: 'github-actions'
```

## Configuration

This action supports various configuration options to customize its behavior according to your needs.

### Input Parameters

| Parameter           | Description                                                                                             | Type     | Required | Default Value                                       |
|---------------------|---------------------------------------------------------------------------------------------------------|----------|----------|-----------------------------------------------------|
| **`composer-args`** | Arguments to pass to Composer install                                                                   | `string` | ❌ No     | `--no-progress --prefer-dist --optimize-autoloader` |
| **`coverage`**      | Code-coverage driver (none, xdebug, pcov)                                                               | `string` | ❌ No     | `none`                                              |
| **`email`**         | GitHub email for commits                                                                                | `string` | ❌ No     | `github-actions@github.com`                         |
| **`extensions`**    | PHP extensions to install (comma-separated)                                                             | `string` | ❌ No     | `mbstring, intl, json, pdo_sqlite, sqlite3`         |
| **`framework`**     | Framework detection mode (auto=detect Laravel via artisan, laravel=force Laravel, generic=no framework) | `string` | ❌ No     | `auto`                                              |
| **`max-retries`**   | Maximum number of retry attempts for Composer commands                                                  | `string` | ❌ No     | `3`                                                 |
| **`php-version`**   | PHP Version to use (latest, 8.4, 8.3, etc.)                                                             | `string` | ❌ No     | `latest`                                            |
| **`token`**         | GitHub token for authentication                                                                         | `string` | ❌ No     | _None_                                              |
| **`username`**      | GitHub username for commits                                                                             | `string` | ❌ No     | `github-actions`                                    |

#### Parameter Details

##### `composer-args`

Arguments to pass to Composer install

- **Type**: String
- **Required**: No
- **Default**: `--no-progress --prefer-dist --optimize-autoloader`

```yaml
with:
  composer-args: '--no-progress --prefer-dist --optimize-autoloader'
```

##### `coverage`

Code-coverage driver (none, xdebug, pcov)

- **Type**: String
- **Required**: No
- **Default**: `none`

```yaml
with:
  coverage: 'none'
```

##### `email`

GitHub email for commits

- **Type**: String
- **Required**: No
- **Default**: `github-actions@github.com`

```yaml
with:
  email: 'github-actions@github.com'
```

##### `extensions`

PHP extensions to install (comma-separated)

- **Type**: String
- **Required**: No
- **Default**: `mbstring, intl, json, pdo_sqlite, sqlite3`

```yaml
with:
  extensions: 'mbstring, intl, json, pdo_sqlite, sqlite3'
```

##### `framework`

Framework detection mode (auto=detect Laravel via artisan, laravel=force Laravel, generic=no framework)

- **Type**: String
- **Required**: No
- **Default**: `auto`

```yaml
with:
  framework: 'auto'
```

##### `max-retries`

Maximum number of retry attempts for Composer commands

- **Type**: String
- **Required**: No
- **Default**: `3`

```yaml
with:
  max-retries: '3'
```

##### `php-version`

PHP Version to use (latest, 8.4, 8.3, etc.)

- **Type**: String
- **Required**: No
- **Default**: `latest`

```yaml
with:
  php-version: 'latest'
```

##### `token`

GitHub token for authentication

- **Type**: String
- **Required**: No

```yaml
with:
  token: 'your-value-here'
```

##### `username`

GitHub username for commits

- **Type**: String
- **Required**: No
- **Default**: `github-actions`

```yaml
with:
  username: 'github-actions'
```

### Output Parameters

This action provides the following outputs that can be used in subsequent workflow steps:

| Parameter              | Description                             | Usage                                      |
|------------------------|-----------------------------------------|--------------------------------------------|
| **`cache-hit`**        | Indicates if there was a cache hit      | `\${{ steps. .outputs.cache-hit }}`        |
| **`composer-version`** | Installed Composer version              | `\${{ steps. .outputs.composer-version }}` |
| **`framework`**        | Detected framework (laravel or generic) | `\${{ steps. .outputs.framework }}`        |
| **`php-version`**      | The PHP version that was setup          | `\${{ steps. .outputs.php-version }}`      |
| **`test-status`**      | Test execution status (success/failure) | `\${{ steps. .outputs.test-status }}`      |
| **`tests-passed`**     | Number of tests passed                  | `\${{ steps. .outputs.tests-passed }}`     |
| **`tests-run`**        | Number of tests executed                | `\${{ steps. .outputs.tests-run }}`        |

#### Using Outputs

```yaml
- name: PHP Tests
  id: action-step
  uses: ivuorinen/actions/php-tests@vYYYY.MM.DD

- name: Use Output
  run: |
    echo "cache-hit: \${{ steps.action-step.outputs.cache-hit }}"
    echo "composer-version: \${{ steps.action-step.outputs.composer-version }}"
    echo "framework: \${{ steps.action-step.outputs.framework }}"
    echo "php-version: \${{ steps.action-step.outputs.php-version }}"
    echo "test-status: \${{ steps.action-step.outputs.test-status }}"
    echo "tests-passed: \${{ steps.action-step.outputs.tests-passed }}"
    echo "tests-run: \${{ steps.action-step.outputs.tests-run }}"
```

## 🔐 Required Permissions

This action requires specific GitHub permissions to function correctly. Ensure your workflow includes these permissions:

| Permission | Access Level | Description                   |
|------------|--------------|-------------------------------|
| `contents` | `read`       | Required for action operation |

### How to Set Permissions

```yaml
name: My Workflow
on: [push]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ivuorinen/actions/php-tests@vYYYY.MM.DD
```

**Note:** If your workflow doesn't specify permissions, GitHub uses default permissions which may not include all required permissions above.

## Examples

### Basic Usage

```yaml
- name: Basic PHP Tests
  uses: ivuorinen/actions/php-tests@vYYYY.MM.DD
  with:
    composer-args: '--no-progress --prefer-dist --optimize-autoloader'
    coverage: 'none'
    email: 'github-actions@github.com'
    extensions: 'mbstring, intl, json, pdo_sqlite, sqlite3'
    framework: 'auto'
    max-retries: '3'
    php-version: 'latest'
    token: 'example-value'
    username: 'github-actions'
```

### Advanced Configuration

```yaml
- name: Advanced PHP Tests
  uses: ivuorinen/actions/php-tests@vYYYY.MM.DD
  with:
    composer-args: "--no-progress --prefer-dist --optimize-autoloader"
    coverage: "none"
    email: "github-actions@github.com"
    extensions: "mbstring, intl, json, pdo_sqlite, sqlite3"
    framework: "auto"
    max-retries: "3"
    php-version: "latest"
    token: "\${{ vars.TOKEN }}"
    username: "github-actions"
  env:
    GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
```

### Conditional Usage

```yaml
- name: Conditional PHP Tests
  if: github.event_name == 'push'
  uses: ivuorinen/actions/php-tests@vYYYY.MM.DD
  with:
    composer-args: '--no-progress --prefer-dist --optimize-autoloader'
    coverage: 'none'
    email: 'github-actions@github.com'
    extensions: 'mbstring, intl, json, pdo_sqlite, sqlite3'
    framework: 'auto'
    max-retries: '3'
    php-version: 'latest'
    token: 'production-value'
    username: 'github-actions'
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure you have set up the required secrets in your repository settings.
2. **Permission Issues**: Check that your GitHub token has the necessary permissions.
3. **Configuration Errors**: Validate your input parameters against the schema.

### Getting Help

- Check the [action.yml](./action.yml) for the complete specification
- Open an issue if you encounter problems

## Contributing

We welcome contributions! Please see our [Contributing Guide](../CONTRIBUTING.md) for details.

### Development Setup

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](../LICENSE.md) file for details.

## Support

If you find this action helpful, please consider:

- ⭐ Starring this repository
- 🐛 Reporting issues
- 💡 Suggesting improvements
- 🤝 Contributing code

---

<div align="center">
  <sub>📚 Documentation generated with <a href="https://github.com/ivuorinen/gh-action-readme">gh-action-readme</a></sub>
</div>
