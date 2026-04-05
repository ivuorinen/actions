# ivuorinen/actions - My Reusable GitHub Actions and Workflows

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/ivuorinen/actions/badge)](https://scorecard.dev/viewer/?uri=github.com/ivuorinen/actions)

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

This repository contains **26 reusable GitHub Actions** for CI/CD automation.

### Quick Reference (26 Actions)

| Icon | Action                                               | Category   | Description                                                     | Key Features                                 |
|:----:|:-----------------------------------------------------|:-----------|:----------------------------------------------------------------|:---------------------------------------------|
|  📦  | [`ansible-lint-fix`][ansible-lint-fix]               | Linting    | Lints and fixes Ansible playbooks, commits changes, and uplo... | Caching, Token auth, Outputs                 |
|  ✅   | [`biome-lint`][biome-lint]                           | Linting    | Run Biome linter in check or fix mode                           | Caching, Auto-detection, Token auth, Outputs |
| 🛡️  | [`codeql-analysis`][codeql-analysis]                 | Repository | Run CodeQL security analysis for a single language with conf... | Auto-detection, Token auth, Outputs          |
| 🖼️  | [`compress-images`][compress-images]                 | Repository | Compress images on demand (workflow_dispatch), and at 11pm e... | Token auth, Outputs                          |
|  📝  | [`csharp-build`][csharp-build]                       | Build      | Builds and tests C# projects.                                   | Caching, Auto-detection, Token auth, Outputs |
|  📝  | [`csharp-lint-check`][csharp-lint-check]             | Linting    | Runs linters like StyleCop or dotnet-format for C# code styl... | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`csharp-publish`][csharp-publish]                   | Publishing | Publishes a C# project to GitHub Packages.                      | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`docker-build`][docker-build]                       | Build      | Builds a Docker image for multiple architectures with enhanc... | Caching, Auto-detection, Token auth, Outputs |
|  ☁️  | [`docker-publish`][docker-publish]                   | Publishing | Simple wrapper to publish Docker images to GitHub Packages a... | Token auth, Outputs                          |
|  ✅   | [`eslint-lint`][eslint-lint]                         | Linting    | Run ESLint in check or fix mode with advanced configuration ... | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`go-build`][go-build]                               | Build      | Builds the Go project.                                          | Caching, Auto-detection, Token auth, Outputs |
|  📝  | [`go-lint`][go-lint]                                 | Linting    | Run golangci-lint with advanced configuration, caching, and ... | Caching, Token auth, Outputs                 |
|  📝  | [`language-version-detect`][language-version-detect] | Setup      | DEPRECATED: This action is deprecated. Inline version detect... | Auto-detection, Token auth, Outputs          |
|  📦  | [`npm-publish`][npm-publish]                         | Publishing | Publishes the package to the NPM registry with configurable ... | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`npm-semantic-release`][npm-semantic-release]       | Other      | Runs semantic-release for automated npm versioning and publi... | Caching, Auto-detection, Outputs             |
|  ✅   | [`php-tests`][php-tests]                             | Testing    | Run PHPUnit tests with optional Laravel setup and Composer d... | Caching, Auto-detection, Token auth, Outputs |
|  ✅   | [`pr-lint`][pr-lint]                                 | Linting    | Runs MegaLinter against pull requests                           | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`pre-commit`][pre-commit]                           | Linting    | Runs pre-commit on the repository and pushes the fixes back ... | Auto-detection, Token auth, Outputs          |
|  ✅   | [`prettier-lint`][prettier-lint]                     | Linting    | Run Prettier in check or fix mode with advanced configuratio... | Caching, Auto-detection, Token auth, Outputs |
|  📝  | [`python-lint-fix`][python-lint-fix]                 | Linting    | Lints and fixes Python files, commits changes, and uploads S... | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`release-monthly`][release-monthly]                 | Repository | Creates a release for the current month, incrementing patch ... | Token auth, Outputs                          |
| 🛡️  | [`security-scan`][security-scan]                     | Security   | Comprehensive security scanning for GitHub Actions including... | Caching, Token auth, Outputs                 |
|  📦  | [`stale`][stale]                                     | Repository | A GitHub Action to close stale issues and pull requests.        | Token auth, Outputs                          |
| 🏷️  | [`sync-labels`][sync-labels]                         | Repository | Sync labels from a YAML file to a GitHub repository             | Token auth, Outputs                          |
| 🖥️  | [`terraform-lint-fix`][terraform-lint-fix]           | Linting    | Lints and fixes Terraform files with advanced validation and... | Token auth, Outputs                          |
| 🛡️  | [`validate-inputs`][validate-inputs]                 | Validation | Centralized Python-based input validation for GitHub Actions... | Token auth, Outputs                          |

### Actions by Category

#### 🔧 Setup (1 action)

| Action                                                  | Description                                           | Languages                      | Features                            |
|:--------------------------------------------------------|:------------------------------------------------------|:-------------------------------|:------------------------------------|
| 📝 [`language-version-detect`][language-version-detect] | DEPRECATED: This action is deprecated. Inline vers... | PHP, Python, Go, .NET, Node.js | Auto-detection, Token auth, Outputs |

#### 📝 Linting (10 actions)

| Action                                         | Description                                           | Languages                                    | Features                                     |
|:-----------------------------------------------|:------------------------------------------------------|:---------------------------------------------|:---------------------------------------------|
| 📦 [`ansible-lint-fix`][ansible-lint-fix]      | Lints and fixes Ansible playbooks, commits changes... | Ansible, YAML                                | Caching, Token auth, Outputs                 |
| ✅ [`biome-lint`][biome-lint]                   | Run Biome linter in check or fix mode                 | JavaScript, TypeScript, JSON                 | Caching, Auto-detection, Token auth, Outputs |
| 📝 [`csharp-lint-check`][csharp-lint-check]    | Runs linters like StyleCop or dotnet-format for C#... | C#, .NET                                     | Caching, Auto-detection, Token auth, Outputs |
| ✅ [`eslint-lint`][eslint-lint]                 | Run ESLint in check or fix mode with advanced conf... | JavaScript, TypeScript                       | Caching, Auto-detection, Token auth, Outputs |
| 📝 [`go-lint`][go-lint]                        | Run golangci-lint with advanced configuration, cac... | Go                                           | Caching, Token auth, Outputs                 |
| ✅ [`pr-lint`][pr-lint]                         | Runs MegaLinter against pull requests                 | Conventional Commits                         | Caching, Auto-detection, Token auth, Outputs |
| 📦 [`pre-commit`][pre-commit]                  | Runs pre-commit on the repository and pushes the f... | Python, Multiple Languages                   | Auto-detection, Token auth, Outputs          |
| ✅ [`prettier-lint`][prettier-lint]             | Run Prettier in check or fix mode with advanced co... | JavaScript, TypeScript, Markdown, YAML, JSON | Caching, Auto-detection, Token auth, Outputs |
| 📝 [`python-lint-fix`][python-lint-fix]        | Lints and fixes Python files, commits changes, and... | Python                                       | Caching, Auto-detection, Token auth, Outputs |
| 🖥️ [`terraform-lint-fix`][terraform-lint-fix] | Lints and fixes Terraform files with advanced vali... | Terraform, HCL                               | Token auth, Outputs                          |

#### 🧪 Testing (1 action)

| Action                     | Description                                           | Languages    | Features                                     |
|:---------------------------|:------------------------------------------------------|:-------------|:---------------------------------------------|
| ✅ [`php-tests`][php-tests] | Run PHPUnit tests with optional Laravel setup and ... | PHP, Laravel | Caching, Auto-detection, Token auth, Outputs |

#### 🏗️ Build (3 actions)

| Action                            | Description                                           | Languages | Features                                     |
|:----------------------------------|:------------------------------------------------------|:----------|:---------------------------------------------|
| 📝 [`csharp-build`][csharp-build] | Builds and tests C# projects.                         | C#, .NET  | Caching, Auto-detection, Token auth, Outputs |
| 📦 [`docker-build`][docker-build] | Builds a Docker image for multiple architectures w... | Docker    | Caching, Auto-detection, Token auth, Outputs |
| 📦 [`go-build`][go-build]         | Builds the Go project.                                | Go        | Caching, Auto-detection, Token auth, Outputs |

#### 🚀 Publishing (3 actions)

| Action                                | Description                                           | Languages    | Features                                     |
|:--------------------------------------|:------------------------------------------------------|:-------------|:---------------------------------------------|
| 📦 [`csharp-publish`][csharp-publish] | Publishes a C# project to GitHub Packages.            | C#, .NET     | Caching, Auto-detection, Token auth, Outputs |
| ☁️ [`docker-publish`][docker-publish] | Simple wrapper to publish Docker images to GitHub ... | Docker       | Token auth, Outputs                          |
| 📦 [`npm-publish`][npm-publish]       | Publishes the package to the NPM registry with con... | Node.js, npm | Caching, Auto-detection, Token auth, Outputs |

#### 📦 Repository (5 actions)

| Action                                   | Description                                           | Languages                                               | Features                            |
|:-----------------------------------------|:------------------------------------------------------|:--------------------------------------------------------|:------------------------------------|
| 🛡️ [`codeql-analysis`][codeql-analysis] | Run CodeQL security analysis for a single language... | JavaScript, TypeScript, Python, Java, C#, C++, Go, Ruby | Auto-detection, Token auth, Outputs |
| 🖼️ [`compress-images`][compress-images] | Compress images on demand (workflow_dispatch), and... | Images, PNG, JPEG                                       | Token auth, Outputs                 |
| 📦 [`release-monthly`][release-monthly]  | Creates a release for the current month, increment... | GitHub Actions                                          | Token auth, Outputs                 |
| 📦 [`stale`][stale]                      | A GitHub Action to close stale issues and pull req... | GitHub Actions                                          | Token auth, Outputs                 |
| 🏷️ [`sync-labels`][sync-labels]         | Sync labels from a YAML file to a GitHub repositor... | YAML, GitHub                                            | Token auth, Outputs                 |

#### 🛡️ Security (1 action)

| Action                               | Description                                           | Languages | Features                     |
|:-------------------------------------|:------------------------------------------------------|:----------|:-----------------------------|
| 🛡️ [`security-scan`][security-scan] | Comprehensive security scanning for GitHub Actions... | -         | Caching, Token auth, Outputs |

#### ✅ Validation (1 action)

| Action                                   | Description                                           | Languages            | Features            |
|:-----------------------------------------|:------------------------------------------------------|:---------------------|:--------------------|
| 🛡️ [`validate-inputs`][validate-inputs] | Centralized Python-based input validation for GitH... | YAML, GitHub Actions | Token auth, Outputs |

### Feature Matrix

| Action                                               | Caching | Auto-detection | Token auth | Outputs |
|:-----------------------------------------------------|:-------:|:--------------:|:----------:|:-------:|
| [`ansible-lint-fix`][ansible-lint-fix]               |    ✅    |       -        |     ✅      |    ✅    |
| [`biome-lint`][biome-lint]                           |    ✅    |       ✅        |     ✅      |    ✅    |
| [`codeql-analysis`][codeql-analysis]                 |    -    |       ✅        |     ✅      |    ✅    |
| [`compress-images`][compress-images]                 |    -    |       -        |     ✅      |    ✅    |
| [`csharp-build`][csharp-build]                       |    ✅    |       ✅        |     ✅      |    ✅    |
| [`csharp-lint-check`][csharp-lint-check]             |    ✅    |       ✅        |     ✅      |    ✅    |
| [`csharp-publish`][csharp-publish]                   |    ✅    |       ✅        |     ✅      |    ✅    |
| [`docker-build`][docker-build]                       |    ✅    |       ✅        |     ✅      |    ✅    |
| [`docker-publish`][docker-publish]                   |    -    |       -        |     ✅      |    ✅    |
| [`eslint-lint`][eslint-lint]                         |    ✅    |       ✅        |     ✅      |    ✅    |
| [`go-build`][go-build]                               |    ✅    |       ✅        |     ✅      |    ✅    |
| [`go-lint`][go-lint]                                 |    ✅    |       -        |     ✅      |    ✅    |
| [`language-version-detect`][language-version-detect] |    -    |       ✅        |     ✅      |    ✅    |
| [`npm-publish`][npm-publish]                         |    ✅    |       ✅        |     ✅      |    ✅    |
| [`npm-semantic-release`][npm-semantic-release]       |    ✅    |       ✅        |     -      |    ✅    |
| [`php-tests`][php-tests]                             |    ✅    |       ✅        |     ✅      |    ✅    |
| [`pr-lint`][pr-lint]                                 |    ✅    |       ✅        |     ✅      |    ✅    |
| [`pre-commit`][pre-commit]                           |    -    |       ✅        |     ✅      |    ✅    |
| [`prettier-lint`][prettier-lint]                     |    ✅    |       ✅        |     ✅      |    ✅    |
| [`python-lint-fix`][python-lint-fix]                 |    ✅    |       ✅        |     ✅      |    ✅    |
| [`release-monthly`][release-monthly]                 |    -    |       -        |     ✅      |    ✅    |
| [`security-scan`][security-scan]                     |    ✅    |       -        |     ✅      |    ✅    |
| [`stale`][stale]                                     |    -    |       -        |     ✅      |    ✅    |
| [`sync-labels`][sync-labels]                         |    -    |       -        |     ✅      |    ✅    |
| [`terraform-lint-fix`][terraform-lint-fix]           |    -    |       -        |     ✅      |    ✅    |
| [`validate-inputs`][validate-inputs]                 |    -    |       -        |     ✅      |    ✅    |

### Language Support

| Language             | Actions                                                                                                                                                            |
|:---------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| .NET                 | [`csharp-build`][csharp-build], [`csharp-lint-check`][csharp-lint-check], [`csharp-publish`][csharp-publish], [`language-version-detect`][language-version-detect] |
| Ansible              | [`ansible-lint-fix`][ansible-lint-fix]                                                                                                                             |
| C#                   | [`codeql-analysis`][codeql-analysis], [`csharp-build`][csharp-build], [`csharp-lint-check`][csharp-lint-check], [`csharp-publish`][csharp-publish]                 |
| C++                  | [`codeql-analysis`][codeql-analysis]                                                                                                                               |
| Conventional Commits | [`pr-lint`][pr-lint]                                                                                                                                               |
| Docker               | [`docker-build`][docker-build], [`docker-publish`][docker-publish]                                                                                                 |
| GitHub               | [`sync-labels`][sync-labels]                                                                                                                                       |
| GitHub Actions       | [`release-monthly`][release-monthly], [`stale`][stale], [`validate-inputs`][validate-inputs]                                                                       |
| Go                   | [`codeql-analysis`][codeql-analysis], [`go-build`][go-build], [`go-lint`][go-lint], [`language-version-detect`][language-version-detect]                           |
| HCL                  | [`terraform-lint-fix`][terraform-lint-fix]                                                                                                                         |
| Images               | [`compress-images`][compress-images]                                                                                                                               |
| JPEG                 | [`compress-images`][compress-images]                                                                                                                               |
| JSON                 | [`biome-lint`][biome-lint], [`prettier-lint`][prettier-lint]                                                                                                       |
| Java                 | [`codeql-analysis`][codeql-analysis]                                                                                                                               |
| JavaScript           | [`biome-lint`][biome-lint], [`codeql-analysis`][codeql-analysis], [`eslint-lint`][eslint-lint], [`prettier-lint`][prettier-lint]                                   |
| Laravel              | [`php-tests`][php-tests]                                                                                                                                           |
| Markdown             | [`prettier-lint`][prettier-lint]                                                                                                                                   |
| Multiple Languages   | [`pre-commit`][pre-commit]                                                                                                                                         |
| Node.js              | [`language-version-detect`][language-version-detect], [`npm-publish`][npm-publish]                                                                                 |
| PHP                  | [`language-version-detect`][language-version-detect], [`php-tests`][php-tests]                                                                                     |
| PNG                  | [`compress-images`][compress-images]                                                                                                                               |
| Python               | [`codeql-analysis`][codeql-analysis], [`language-version-detect`][language-version-detect], [`pre-commit`][pre-commit], [`python-lint-fix`][python-lint-fix]       |
| Ruby                 | [`codeql-analysis`][codeql-analysis]                                                                                                                               |
| Terraform            | [`terraform-lint-fix`][terraform-lint-fix]                                                                                                                         |
| TypeScript           | [`biome-lint`][biome-lint], [`codeql-analysis`][codeql-analysis], [`eslint-lint`][eslint-lint], [`prettier-lint`][prettier-lint]                                   |
| YAML                 | [`ansible-lint-fix`][ansible-lint-fix], [`prettier-lint`][prettier-lint], [`sync-labels`][sync-labels], [`validate-inputs`][validate-inputs]                       |
| npm                  | [`npm-publish`][npm-publish]                                                                                                                                       |

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

[ansible-lint-fix]: ansible-lint-fix/README.md
[biome-lint]: biome-lint/README.md
[codeql-analysis]: codeql-analysis/README.md
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
[npm-publish]: npm-publish/README.md
[npm-semantic-release]: npm-semantic-release/README.md
[php-tests]: php-tests/README.md
[pr-lint]: pr-lint/README.md
[pre-commit]: pre-commit/README.md
[prettier-lint]: prettier-lint/README.md
[python-lint-fix]: python-lint-fix/README.md
[release-monthly]: release-monthly/README.md
[security-scan]: security-scan/README.md
[stale]: stale/README.md
[sync-labels]: sync-labels/README.md
[terraform-lint-fix]: terraform-lint-fix/README.md
[validate-inputs]: validate-inputs/README.md

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
