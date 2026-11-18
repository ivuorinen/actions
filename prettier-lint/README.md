# Prettier Lint

![check-circle](https://img.shields.io/badge/icon-check-circle-green) ![GitHub](https://img.shields.io/badge/GitHub%20Action-%20-blue) ![License](https://img.shields.io/badge/license-MIT-green)

> Run Prettier in check or fix mode with advanced configuration and reporting

## 🚀 Quick Start

```yaml
name: My Workflow
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read # `mode: 'fix'` needs write to push
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
      - name: Prettier Lint
        uses: ivuorinen/actions/prettier-lint@vYYYY.MM.DD
        with:
          cache: 'true'
          config-file: '.prettierrc'
          email: 'github-actions@github.com'
          fail-on-error: 'true'
          file-pattern: '**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}'
          ignore-file: '.prettierignore'
          max-retries: '3'
          mode: 'check'
          plugins: '@prettier/plugin-xml'
          prettier-version: '3.9.10'
          token: '${{ github.token }}'
          username: 'github-actions'
          working-directory: '.'
```

## 📥 Inputs

| Parameter           | Description                                                                                                                                                                                                                                                                                                                                                                                                 | Required | Default                                          |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------ |
| `cache`             | Enable Prettier caching (lowercase true or false)                                                                                                                                                                                                                                                                                                                                                           | ❌       | `true`                                           |
| `config-file`       | Path to Prettier config file (a path other than the default must exist)                                                                                                                                                                                                                                                                                                                                     | ❌       | `.prettierrc`                                    |
| `email`             | GitHub email for commits (fix mode only)                                                                                                                                                                                                                                                                                                                                                                    | ❌       | `github-actions@github.com`                      |
| `fail-on-error`     | Fail workflow if issues are found (check mode only; lowercase true or false)                                                                                                                                                                                                                                                                                                                                | ❌       | `true`                                           |
| `file-pattern`      | Files to include (glob pattern)                                                                                                                                                                                                                                                                                                                                                                             | ❌       | `**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}` |
| `ignore-file`       | Path to Prettier ignore file. The default reads .gitignore and .prettierignore, as Prettier does; another path must exist and is read with .gitignore in place of .prettierignore.                                                                                                                                                                                                                          | ❌       | `.prettierignore`                                |
| `max-retries`       | Maximum number of retry attempts (1-10, must not be empty)                                                                                                                                                                                                                                                                                                                                                  | ❌       | `3`                                              |
| `mode`              | Mode to run (check or fix)                                                                                                                                                                                                                                                                                                                                                                                  | ❌       | `check`                                          |
| `plugins`           | Comma-separated list of Prettier plugins to install (name or name@version; separate entries with commas only). Installed without running lifecycle scripts and without changing package.json or the lockfile. The package manager may also install Prettier itself as the plugins' peer dependency, at a version no lockfile holds, and the action then runs that copy.                                     | ❌       | -                                                |
| `prettier-version`  | Prettier version to run when the repository has no copy of its own. Empty: the version in this action's package-lock.json, installed with its whole dependency tree locked. A version or "latest": installed from the registry without lifecycle scripts, with its dependencies unlocked. When plugins installs Prettier as their peer dependency, the repository has a copy, unlocked, and that copy runs. | ❌       | -                                                |
| `token`             | GitHub token for authentication. Stays in git config after checkout in fix mode only.                                                                                                                                                                                                                                                                                                                       | ❌       | -                                                |
| `username`          | GitHub username for commits (fix mode only)                                                                                                                                                                                                                                                                                                                                                                 | ❌       | `github-actions`                                 |
| `working-directory` | Directory containing files to format                                                                                                                                                                                                                                                                                                                                                                        | ❌       | `.`                                              |

## 📤 Outputs

| Parameter           | Description                                                                                                                                                                               |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `files-changed`     | Number of files changed (fix mode only)                                                                                                                                                   |
| `files-checked`     | Number of files with an extension named in file-pattern (check mode only). Directories in the pattern and ignore files are not applied, so it can differ from the files Prettier checked. |
| `status`            | Overall status (success/failure)                                                                                                                                                          |
| `unformatted-files` | Number of files with formatting issues (check mode only)                                                                                                                                  |

## 🔐 Permissions

This action requires the following permissions:

| Permission | Access Level |
| ---------- | ------------ |
| `contents` | `write`      |

**Usage in workflow:**

```yaml
permissions:
  contents: write
```

## 💡 Examples

<details>
<summary>Basic Usage</summary>

```yaml
- name: Prettier Lint
  uses: ivuorinen/actions/prettier-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.prettierrc'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    file-pattern: '**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}'
    ignore-file: '.prettierignore'
    max-retries: '3'
    mode: 'check'
    plugins: '@prettier/plugin-xml'
    prettier-version: '3.9.10'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
```

</details>

<details>
<summary>Advanced Configuration</summary>

```yaml
- name: Prettier Lint with custom settings
  uses: ivuorinen/actions/prettier-lint@vYYYY.MM.DD
  with:
    cache: 'true'
    config-file: '.prettierrc'
    email: 'github-actions@github.com'
    fail-on-error: 'true'
    file-pattern: '**/*.{js,jsx,ts,tsx,css,scss,json,md,yaml,yml}'
    ignore-file: '.prettierignore'
    max-retries: '3'
    mode: 'check'
    plugins: '@prettier/plugin-xml'
    prettier-version: '3.9.10'
    token: '${{ github.token }}'
    username: 'github-actions'
    working-directory: '.'
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
