# ivuorinen/actions - My Reusable GitHub Actions and Workflows

## Overview

This repository contains a collection of reusable GitHub Actions
designed to streamline CI/CD processes and ensure code quality.

Each action is fully self-contained and can be used independently in any GitHub repository.

### Key Features

- **Production-Ready Actions** covering setup, linting, building, testing, and deployment
- **Self-Contained Design** - each action works independently without dependencies
- **External Usage Ready** - use any action with pinned refs: `ivuorinen/actions/action-name@2025-01-15` or `@<commit-sha>` for supply-chain security
- **Multi-Language Support** including Node.js, PHP, Python, Go, C#, and more
- **Standardized Patterns** with consistent error handling and input/output interfaces
- **Comprehensive Testing** with dual testing framework (ShellSpec + pytest)
- **Modular Build System** using Makefile for development and maintenance

<!--LISTING-->
<!-- This section is auto-generated. Run 'npm run update-catalog' to update. -->

## 📚 Action Catalog

This repository contains **30 reusable GitHub Actions** for CI/CD automation.

### Quick Reference (30 Actions)

| Icon | Action                                               | Category   | Description                                                     | Key Features                                 |
|:----:|:-----------------------------------------------------|:-----------|:----------------------------------------------------------------|:---------------------------------------------|
|  🔀  | [`action-versioning`][action-versioning]             | Utilities  | Automatically update SHA-pinned action references to match l... | Token auth, Outputs                          |
|  📦  | [`ansible-lint-fix`][ansible-lint-fix]               | Linting    | Lints and fixes Ansible playbooks, commits changes, and uplo... | Token auth, Outputs                          |
|  ✅   | [`biome-lint`][biome-lint]                           | Other      | Run Biome linter in check or fix mode                           | Token auth, Outputs                          |
| 🛡️  | [`codeql-analysis`][codeql-analysis]                 | Repository | Run CodeQL security analysis for a single language with conf... | Auto-detection, Token auth, Outputs          |
|  💾  | [`common-cache`][common-cache]                       | Repository | Standardized caching strategy for all actions                   | Caching, Outputs                             |
| 🖼️  | [`compress-images`][compress-images]                 | Repository | Compress images on demand (workflow_dispatch), and at 11pm e... | Token auth, Outputs                          |
|  📝  | [`csharp-build`][csharp-build]                       | Build      | Builds and tests C# projects.                                   | Auto-detection, Token auth, Outputs          |
|  📝  | [`csharp-lint-check`][csharp-lint-check]             | Linting    | Runs linters like StyleCop or dotnet-format for C# code styl... | Auto-detection, Token auth, Outputs          |
|  📦  | [`csharp-publish`][csharp-publish]                   | Publishing | Publishes a C# project to GitHub Packages.                      | Auto-detection, Token auth, Outputs          |
|  📦  | [`docker-build`][docker-build]                       | Build      | Builds a Docker image for multiple architectures with enhanc... | Caching, Auto-detection, Token auth, Outputs |
|  ☁️  | [`docker-publish`][docker-publish]                   | Publishing | Publish a Docker image to GitHub Packages and Docker Hub.       | Auto-detection, Token auth, Outputs          |
|  ✅   | [`eslint-lint`][eslint-lint]                         | Other      | Run ESLint in check or fix mode with advanced configuration ... | Caching, Token auth, Outputs                 |
|  📦  | [`go-build`][go-build]                               | Build      | Builds the Go project.                                          | Caching, Auto-detection, Token auth, Outputs |
|  📝  | [`go-lint`][go-lint]                                 | Linting    | Run golangci-lint with advanced configuration, caching, and ... | Caching, Token auth, Outputs                 |
|  📝  | [`language-version-detect`][language-version-detect] | Other      | Detects language version from project configuration files wi... | Auto-detection, Token auth, Outputs          |
| 🖥️  | [`node-setup`][node-setup]                           | Setup      | Sets up Node.js environment with version detection and packa... | Auto-detection, Token auth, Outputs          |
|  📦  | [`npm-publish`][npm-publish]                         | Publishing | Publishes the package to the NPM registry with configurable ... | Token auth, Outputs                          |
| 🖥️  | [`php-composer`][php-composer]                       | Testing    | Runs Composer install on a repository with advanced caching ... | Auto-detection, Token auth, Outputs          |
|  💻  | [`php-laravel-phpunit`][php-laravel-phpunit]         | Testing    | Setup PHP, install dependencies, generate key, create databa... | Auto-detection, Token auth, Outputs          |
|  ✅   | [`php-tests`][php-tests]                             | Testing    | Run PHPUnit tests on the repository                             | Token auth, Outputs                          |
|  ✅   | [`pr-lint`][pr-lint]                                 | Linting    | Runs MegaLinter against pull requests                           | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`pre-commit`][pre-commit]                           | Linting    | Runs pre-commit on the repository and pushes the fixes back ... | Auto-detection, Token auth, Outputs          |
|  ✅   | [`prettier-lint`][prettier-lint]                     | Other      | Run Prettier in check or fix mode with advanced configuratio... | Caching, Token auth, Outputs                 |
|  📝  | [`python-lint-fix`][python-lint-fix]                 | Linting    | Lints and fixes Python files, commits changes, and uploads S... | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`release-monthly`][release-monthly]                 | Repository | Creates a release for the current month, incrementing patch ... | Token auth, Outputs                          |
|  📦  | [`stale`][stale]                                     | Repository | A GitHub Action to close stale issues and pull requests.        | Token auth, Outputs                          |
| 🏷️  | [`sync-labels`][sync-labels]                         | Repository | Sync labels from a YAML file to a GitHub repository             | Token auth, Outputs                          |
| 🖥️  | [`terraform-lint-fix`][terraform-lint-fix]           | Linting    | Lints and fixes Terraform files with advanced validation and... | Token auth, Outputs                          |
| 🛡️  | [`validate-inputs`][validate-inputs]                 | Validation | Centralized Python-based input validation for GitHub Actions... | Token auth, Outputs                          |
|  📦  | [`version-file-parser`][version-file-parser]         | Utilities  | Universal parser for common version detection files (.tool-v... | Auto-detection, Outputs                      |

### Actions by Category

#### 🔧 Setup (1 action)

| Action                         | Description                                           | Languages                       | Features                            |
|:-------------------------------|:------------------------------------------------------|:--------------------------------|:------------------------------------|
| 🖥️ [`node-setup`][node-setup] | Sets up Node.js environment with version detection... | Node.js, JavaScript, TypeScript | Auto-detection, Token auth, Outputs |

#### 🛠️ Utilities (2 actions)

| Action                                          | Description                                           | Languages          | Features                |
|:------------------------------------------------|:------------------------------------------------------|:-------------------|:------------------------|
| 🔀 [`action-versioning`][action-versioning]     | Automatically update SHA-pinned action references ... | -                  | Token auth, Outputs     |
| 📦 [`version-file-parser`][version-file-parser] | Universal parser for common version detection file... | Multiple Languages | Auto-detection, Outputs |

#### 📝 Linting (7 actions)

| Action                                         | Description                                           | Languages                  | Features                                     |
|:-----------------------------------------------|:------------------------------------------------------|:---------------------------|:---------------------------------------------|
| 📦 [`ansible-lint-fix`][ansible-lint-fix]      | Lints and fixes Ansible playbooks, commits changes... | Ansible, YAML              | Token auth, Outputs                          |
| 📝 [`csharp-lint-check`][csharp-lint-check]    | Runs linters like StyleCop or dotnet-format for C#... | C#, .NET                   | Auto-detection, Token auth, Outputs          |
| 📝 [`go-lint`][go-lint]                        | Run golangci-lint with advanced configuration, cac... | Go                         | Caching, Token auth, Outputs                 |
| ✅ [`pr-lint`][pr-lint]                         | Runs MegaLinter against pull requests                 | Conventional Commits       | Caching, Auto-detection, Token auth, Outputs |
| 📦 [`pre-commit`][pre-commit]                  | Runs pre-commit on the repository and pushes the f... | Python, Multiple Languages | Auto-detection, Token auth, Outputs          |
| 📝 [`python-lint-fix`][python-lint-fix]        | Lints and fixes Python files, commits changes, and... | Python                     | Caching, Auto-detection, Token auth, Outputs |
| 🖥️ [`terraform-lint-fix`][terraform-lint-fix] | Lints and fixes Terraform files with advanced vali... | Terraform, HCL             | Token auth, Outputs                          |

#### 🧪 Testing (3 actions)

| Action                                          | Description                                           | Languages    | Features                            |
|:------------------------------------------------|:------------------------------------------------------|:-------------|:------------------------------------|
| 🖥️ [`php-composer`][php-composer]              | Runs Composer install on a repository with advance... | PHP          | Auto-detection, Token auth, Outputs |
| 💻 [`php-laravel-phpunit`][php-laravel-phpunit] | Setup PHP, install dependencies, generate key, cre... | PHP, Laravel | Auto-detection, Token auth, Outputs |
| ✅ [`php-tests`][php-tests]                      | Run PHPUnit tests on the repository                   | PHP          | Token auth, Outputs                 |

#### 🏗️ Build (3 actions)

| Action                            | Description                                           | Languages | Features                                     |
|:----------------------------------|:------------------------------------------------------|:----------|:---------------------------------------------|
| 📝 [`csharp-build`][csharp-build] | Builds and tests C# projects.                         | C#, .NET  | Auto-detection, Token auth, Outputs          |
| 📦 [`docker-build`][docker-build] | Builds a Docker image for multiple architectures w... | Docker    | Caching, Auto-detection, Token auth, Outputs |
| 📦 [`go-build`][go-build]         | Builds the Go project.                                | Go        | Caching, Auto-detection, Token auth, Outputs |

#### 🚀 Publishing (3 actions)

| Action                                | Description                                           | Languages    | Features                            |
|:--------------------------------------|:------------------------------------------------------|:-------------|:------------------------------------|
| 📦 [`csharp-publish`][csharp-publish] | Publishes a C# project to GitHub Packages.            | C#, .NET     | Auto-detection, Token auth, Outputs |
| ☁️ [`docker-publish`][docker-publish] | Publish a Docker image to GitHub Packages and Dock... | Docker       | Auto-detection, Token auth, Outputs |
| 📦 [`npm-publish`][npm-publish]       | Publishes the package to the NPM registry with con... | Node.js, npm | Token auth, Outputs                 |

#### 📦 Repository (6 actions)

| Action                                   | Description                                           | Languages                                               | Features                            |
|:-----------------------------------------|:------------------------------------------------------|:--------------------------------------------------------|:------------------------------------|
| 🛡️ [`codeql-analysis`][codeql-analysis] | Run CodeQL security analysis for a single language... | JavaScript, TypeScript, Python, Java, C#, C++, Go, Ruby | Auto-detection, Token auth, Outputs |
| 💾 [`common-cache`][common-cache]        | Standardized caching strategy for all actions         | -                                                       | Caching, Outputs                    |
| 🖼️ [`compress-images`][compress-images] | Compress images on demand (workflow_dispatch), and... | -                                                       | Token auth, Outputs                 |
| 📦 [`release-monthly`][release-monthly]  | Creates a release for the current month, increment... | -                                                       | Token auth, Outputs                 |
| 📦 [`stale`][stale]                      | A GitHub Action to close stale issues and pull req... | -                                                       | Token auth, Outputs                 |
| 🏷️ [`sync-labels`][sync-labels]         | Sync labels from a YAML file to a GitHub repositor... | YAML, GitHub                                            | Token auth, Outputs                 |

#### ✅ Validation (1 action)

| Action                                   | Description                                           | Languages            | Features            |
|:-----------------------------------------|:------------------------------------------------------|:---------------------|:--------------------|
| 🛡️ [`validate-inputs`][validate-inputs] | Centralized Python-based input validation for GitH... | YAML, GitHub Actions | Token auth, Outputs |

### Feature Matrix

| Action                                               | Caching | Auto-detection | Token auth | Outputs |
|:-----------------------------------------------------|:-------:|:--------------:|:----------:|:-------:|
| [`action-versioning`][action-versioning]             |    -    |       -        |     ✅      |    ✅    |
| [`ansible-lint-fix`][ansible-lint-fix]               |    -    |       -        |     ✅      |    ✅    |
| [`biome-lint`][biome-lint]                           |    -    |       -        |     ✅      |    ✅    |
| [`codeql-analysis`][codeql-analysis]                 |    -    |       ✅        |     ✅      |    ✅    |
| [`common-cache`][common-cache]                       |    ✅    |       -        |     -      |    ✅    |
| [`compress-images`][compress-images]                 |    -    |       -        |     ✅      |    ✅    |
| [`csharp-build`][csharp-build]                       |    -    |       ✅        |     ✅      |    ✅    |
| [`csharp-lint-check`][csharp-lint-check]             |    -    |       ✅        |     ✅      |    ✅    |
| [`csharp-publish`][csharp-publish]                   |    -    |       ✅        |     ✅      |    ✅    |
| [`docker-build`][docker-build]                       |    ✅    |       ✅        |     ✅      |    ✅    |
| [`docker-publish`][docker-publish]                   |    -    |       ✅        |     ✅      |    ✅    |
| [`eslint-lint`][eslint-lint]                         |    ✅    |       -        |     ✅      |    ✅    |
| [`go-build`][go-build]                               |    ✅    |       ✅        |     ✅      |    ✅    |
| [`go-lint`][go-lint]                                 |    ✅    |       -        |     ✅      |    ✅    |
| [`language-version-detect`][language-version-detect] |    -    |       ✅        |     ✅      |    ✅    |
| [`node-setup`][node-setup]                           |    -    |       ✅        |     ✅      |    ✅    |
| [`npm-publish`][npm-publish]                         |    -    |       -        |     ✅      |    ✅    |
| [`php-composer`][php-composer]                       |    -    |       ✅        |     ✅      |    ✅    |
| [`php-laravel-phpunit`][php-laravel-phpunit]         |    -    |       ✅        |     ✅      |    ✅    |
| [`php-tests`][php-tests]                             |    -    |       -        |     ✅      |    ✅    |
| [`pr-lint`][pr-lint]                                 |    ✅    |       ✅        |     ✅      |    ✅    |
| [`pre-commit`][pre-commit]                           |    -    |       ✅        |     ✅      |    ✅    |
| [`prettier-lint`][prettier-lint]                     |    ✅    |       -        |     ✅      |    ✅    |
| [`python-lint-fix`][python-lint-fix]                 |    ✅    |       ✅        |     ✅      |    ✅    |
| [`release-monthly`][release-monthly]                 |    -    |       -        |     ✅      |    ✅    |
| [`stale`][stale]                                     |    -    |       -        |     ✅      |    ✅    |
| [`sync-labels`][sync-labels]                         |    -    |       -        |     ✅      |    ✅    |
| [`terraform-lint-fix`][terraform-lint-fix]           |    -    |       -        |     ✅      |    ✅    |
| [`validate-inputs`][validate-inputs]                 |    -    |       -        |     ✅      |    ✅    |
| [`version-file-parser`][version-file-parser]         |    -    |       ✅        |     -      |    ✅    |

### Language Support

| Language             | Actions                                                                                                                                            |
|:---------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------|
| .NET                 | [`csharp-build`][csharp-build], [`csharp-lint-check`][csharp-lint-check], [`csharp-publish`][csharp-publish]                                       |
| Ansible              | [`ansible-lint-fix`][ansible-lint-fix]                                                                                                             |
| C#                   | [`codeql-analysis`][codeql-analysis], [`csharp-build`][csharp-build], [`csharp-lint-check`][csharp-lint-check], [`csharp-publish`][csharp-publish] |
| C++                  | [`codeql-analysis`][codeql-analysis]                                                                                                               |
| Conventional Commits | [`pr-lint`][pr-lint]                                                                                                                               |
| Docker               | [`docker-build`][docker-build], [`docker-publish`][docker-publish]                                                                                 |
| GitHub               | [`sync-labels`][sync-labels]                                                                                                                       |
| GitHub Actions       | [`validate-inputs`][validate-inputs]                                                                                                               |
| Go                   | [`codeql-analysis`][codeql-analysis], [`go-build`][go-build], [`go-lint`][go-lint]                                                                 |
| HCL                  | [`terraform-lint-fix`][terraform-lint-fix]                                                                                                         |
| Java                 | [`codeql-analysis`][codeql-analysis]                                                                                                               |
| JavaScript           | [`codeql-analysis`][codeql-analysis], [`node-setup`][node-setup]                                                                                   |
| Laravel              | [`php-laravel-phpunit`][php-laravel-phpunit]                                                                                                       |
| Multiple Languages   | [`pre-commit`][pre-commit], [`version-file-parser`][version-file-parser]                                                                           |
| Node.js              | [`node-setup`][node-setup], [`npm-publish`][npm-publish]                                                                                           |
| PHP                  | [`php-composer`][php-composer], [`php-laravel-phpunit`][php-laravel-phpunit], [`php-tests`][php-tests]                                             |
| Python               | [`codeql-analysis`][codeql-analysis], [`pre-commit`][pre-commit], [`python-lint-fix`][python-lint-fix]                                             |
| Ruby                 | [`codeql-analysis`][codeql-analysis]                                                                                                               |
| Terraform            | [`terraform-lint-fix`][terraform-lint-fix]                                                                                                         |
| TypeScript           | [`codeql-analysis`][codeql-analysis], [`node-setup`][node-setup]                                                                                   |
| YAML                 | [`ansible-lint-fix`][ansible-lint-fix], [`sync-labels`][sync-labels], [`validate-inputs`][validate-inputs]                                         |
| npm                  | [`npm-publish`][npm-publish]                                                                                                                       |

### Action Usage

All actions can be used independently in your workflows:

```yaml
# Recommended: Use pinned refs for supply-chain security
- uses: ivuorinen/actions/action-name@vYYYY-MM-DD # Date-based tag (example)
  with:
    # action-specific inputs

# Alternative: Use commit SHA for immutability
- uses: ivuorinen/actions/action-name@abc123def456 # Full commit SHA
  with:
    # action-specific inputs
```

> **Security Note**: Always pin to specific tags or commit SHAs instead of `@main` to ensure reproducible workflows and supply-chain integrity.

<!-- Reference Links -->

[action-versioning]: action-versioning/README.md
[ansible-lint-fix]: ansible-lint-fix/README.md
[biome-lint]: biome-lint/README.md
[codeql-analysis]: codeql-analysis/README.md
[common-cache]: common-cache/README.md
[compress-images]: compress-images/README.md
[csharp-build]: csharp-build/README.md
[csharp-lint-check]: csharp-lint-check/README.md
[csharp-publish]: csharp-publish/README.md
[docker-build]: docker-build/README.md
[docker-publish]: docker-publish/README.md
[eslint-lint]: eslint-lint/README.md
[go-build]: go-build/README.md
[go-lint]: go-lint/README.md
[language-version-detect]: language-version-detect/README.md
[node-setup]: node-setup/README.md
[npm-publish]: npm-publish/README.md
[php-composer]: php-composer/README.md
[php-laravel-phpunit]: php-laravel-phpunit/README.md
[php-tests]: php-tests/README.md
[pr-lint]: pr-lint/README.md
[pre-commit]: pre-commit/README.md
[prettier-lint]: prettier-lint/README.md
[python-lint-fix]: python-lint-fix/README.md
[release-monthly]: release-monthly/README.md
[stale]: stale/README.md
[sync-labels]: sync-labels/README.md
[terraform-lint-fix]: terraform-lint-fix/README.md
[validate-inputs]: validate-inputs/README.md
[version-file-parser]: version-file-parser/README.md

---

<!--/LISTING-->

## Usage

### Using Actions Externally

All actions in this repository can be used in your workflows like any other GitHub Action.

**⚠️ Security Best Practice**: Always pin actions to specific tags or commit SHAs instead of `@main` to ensure:

- **Reproducibility**: Workflows behave consistently over time
- **Supply-chain integrity**: Protection against unexpected changes or compromises
- **Immutability**: Reference exact versions that cannot be modified

```yaml
steps:
  - name: Setup Node.js with Auto-Detection
    uses: ivuorinen/actions/node-setup@2025-01-15 # Date-based tag
    with:
      default-version: '20'

  - name: Detect PHP Version
    uses: ivuorinen/actions/php-version-detect@abc123def456 # Commit SHA
    with:
      default-version: '8.2'

  - name: Universal Version Parser
    uses: ivuorinen/actions/version-file-parser@2025-01-15
    with:
      language: 'python'
      tool-versions-key: 'python'
      dockerfile-image: 'python'
      version-file: '.python-version'
      default-version: '3.12'
```

Actions achieve modularity through composition:

```yaml
steps:
  - name: Parse Version
    id: parse-version
    uses: ivuorinen/actions/version-file-parser@2025-01-15
    with:
      language: 'node'
      tool-versions-key: 'nodejs'
      dockerfile-image: 'node'
      version-file: '.nvmrc'
      default-version: '20'

  - name: Setup Node.js
    uses: actions/setup-node@sha
    with:
      node-version: ${{ steps.parse-version.outputs.detected-version }}
```

## Development

This repository uses a Makefile-based build system for development tasks:

```bash
# Full workflow - docs, format, and lint
make all

# Individual operations
make docs          # Generate documentation for all actions
make format        # Format all files (markdown, YAML, JSON)
make lint          # Run all linters
make check         # Quick syntax and tool checks

# Development workflow
make dev           # Format then lint (good for development)
make ci            # CI workflow - check, docs, lint
```

### Python Development

For Python development (validation system), use these specialized commands:

```bash
# Python development workflow
make dev-python         # Format, lint, and test Python code
make test-python        # Run Python unit tests
make test-python-coverage  # Run tests with coverage reporting

# Individual Python operations
make format-python      # Format Python files with ruff
make lint-python        # Lint Python files with ruff
```

The Python validation system (`validate-inputs/`) includes:

- **CalVer and SemVer Support**: Flexible version validation for different schemes
- **Comprehensive Test Suite**: Extensive test cases covering all validation types
- **Security Features**: Command injection and path traversal protection
- **Performance**: Efficient Python regex engine vs multiple bash processes

### Testing

```bash
# Run all tests (Python + GitHub Actions)
make test

# Run specific test types
make test-python           # Python validation tests only
make test-actions          # GitHub Actions tests only
make test-action ACTION=node-setup  # Test specific action

# Coverage reporting
make test-coverage         # All tests with coverage
make test-python-coverage  # Python tests with coverage
```

For detailed development guidelines, see [CLAUDE.md](CLAUDE.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for details.
