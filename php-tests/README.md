# PHP Tests

![check-circle](https://img.shields.io/badge/icon-check-circle-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run PHPUnit tests with optional Laravel setup and Composer dependency management

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
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
          token: '${{ github.token }}'
          username: 'github-actions'
```

## 📥 Inputs

| Parameter       | Description                                                                                             | Required | Default                                             |
|-----------------|---------------------------------------------------------------------------------------------------------|----------|-----------------------------------------------------|
| `composer-args` | Arguments to pass to Composer install                                                                   | ❌        | `--no-progress --prefer-dist --optimize-autoloader` |
| `coverage`      | Code-coverage driver (none, xdebug, pcov)                                                               | ❌        | `none`                                              |
| `email`         | GitHub email for commits                                                                                | ❌        | `github-actions@github.com`                         |
| `extensions`    | PHP extensions to install (comma-separated)                                                             | ❌        | `mbstring, intl, json, pdo_sqlite, sqlite3`         |
| `framework`     | Framework detection mode (auto=detect Laravel via artisan, laravel=force Laravel, generic=no framework) | ❌        | `auto`                                              |
| `max-retries`   | Maximum number of retry attempts for Composer commands                                                  | ❌        | `3`                                                 |
| `php-version`   | PHP Version to use (latest, 8.4, 8.3, etc.)                                                             | ❌        | `latest`                                            |
| `token`         | GitHub token for authentication                                                                         | ❌        | -                                                   |
| `username`      | GitHub username for commits                                                                             | ❌        | `github-actions`                                    |

## 📤 Outputs

| Parameter          | Description                             |
|--------------------|-----------------------------------------|
| `cache-hit`        | Indicates if there was a cache hit      |
| `composer-version` | Installed Composer version              |
| `framework`        | Detected framework (laravel or generic) |
| `php-version`      | The PHP version that was setup          |
| `test-status`      | Test execution status (success/failure) |
| `tests-passed`     | Number of tests passed                  |
| `tests-run`        | Number of tests executed                |

## 🔐 Permissions

This action requires the following permissions:

| Permission | Access Level |
|------------|--------------|
| `contents` | `read`       |

**Usage in workflow:**

```yaml
permissions:
  contents: read
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
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
    token: '${{ github.token }}'
    username: 'github-actions'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: PHP Tests with custom settings
  uses: ivuorinen/actions/php-tests@vYYYY.MM.DD
  with:
    composer-args: '--no-progress --prefer-dist --optimize-autoloader'
    coverage: 'none'
    email: 'github-actions@github.com'
    extensions: 'mbstring, intl, json, pdo_sqlite, sqlite3'
    framework: 'auto'
    max-retries: '3'
    php-version: 'latest'
    token: '${{ github.token }}'
    username: 'github-actions'
```

</details>

## 🔧 Development

See the [action.yml](./action.yml) for the complete action specification.

## 📄 License

This action is distributed under the MIT License. See [LICENSE](../LICENSE.md) for more information.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<div align="center">
  <sub>🚀 Generated with <a href="https://github.com/ivuorinen/gh-action-readme">gh-action-readme</a></sub>
</div>
