# ivuorinen/actions - My Reusable GitHub Actions and Workflows

## Overview

This repository contains a collection of 40 reusable GitHub Actions designed to streamline CI/CD processes and ensure code quality.
Each action is fully self-contained and can be used independently in any GitHub repository.

### Key Features

- **40 Production-Ready Actions** covering setup, linting, building, testing, and deployment
- **Self-Contained Design** - each action works independently without dependencies
- **External Usage Ready** - use any action as `ivuorinen/actions/action-name@main`
- **Multi-Language Support** including Node.js, PHP, Python, Go, C#, and more
- **Standardized Patterns** with consistent error handling and input/output interfaces
- **Modular Build System** using Makefile for development and maintenance

<!--LISTING-->
<!-- This section is auto-generated. Run 'npm run update-catalog' to update. -->

## 📚 Action Catalog

This repository contains **40 reusable GitHub Actions** for CI/CD automation.

### Quick Reference (40 Actions)

| Icon | Action                                                 | Category   | Description                                                     | Key Features                                 |
|:----:|:-------------------------------------------------------|:-----------|:----------------------------------------------------------------|:---------------------------------------------|
|  📦  | [`ansible-lint-fix`][ansible-lint-fix]                 | Linting    | Lints and fixes Ansible playbooks, commits changes, and uplo... | Token auth                                   |
|  ✅   | [`biome-check`][biome-check]                           | Linting    | Run Biome check on the repository                               | Token auth                                   |
|  ✅   | [`biome-fix`][biome-fix]                               | Linting    | Run Biome fix on the repository                                 | Token auth                                   |
|  💾  | [`common-cache`][common-cache]                         | Repository | Standardized caching strategy for all actions                   | Caching, Outputs                             |
|  📦  | [`common-file-check`][common-file-check]               | Repository | A reusable action to check if a specific file or type of fil... | Outputs                                      |
| 🖼️  | [`compress-images`][compress-images]                   | Repository | Compress images on demand (workflow_dispatch), and at 11pm e... | Token auth                                   |
|  📝  | [`csharp-build`][csharp-build]                         | Build      | Builds and tests C# projects.                                   | Auto-detection                               |
|  📝  | [`csharp-lint-check`][csharp-lint-check]               | Linting    | Runs linters like StyleCop or dotnet-format for C# code styl... | Auto-detection                               |
|  📦  | [`csharp-publish`][csharp-publish]                     | Publishing | Publishes a C# project to GitHub Packages.                      | Auto-detection, Token auth                   |
|  📦  | [`docker-build`][docker-build]                         | Build      | Builds a Docker image for multiple architectures with enhanc... | Caching, Token auth, Outputs                 |
|  ☁️  | [`docker-publish`][docker-publish]                     | Publishing | Publish a Docker image to GitHub Packages and Docker Hub.       | Outputs                                      |
|  📦  | [`docker-publish-gh`][docker-publish-gh]               | Publishing | Publishes a Docker image to GitHub Packages with advanced se... | Token auth, Outputs                          |
|  📦  | [`docker-publish-hub`][docker-publish-hub]             | Publishing | Publishes a Docker image to Docker Hub with enhanced securit... | Outputs                                      |
|  📝  | [`dotnet-version-detect`][dotnet-version-detect]       | Setup      | Detects .NET SDK version from global.json or defaults to a s... | Auto-detection, Outputs                      |
|  ✅   | [`eslint-check`][eslint-check]                         | Linting    | Run ESLint check on the repository with advanced configurati... | Caching, Outputs                             |
|  📝  | [`eslint-fix`][eslint-fix]                             | Linting    | Fixes ESLint violations in a project.                           | Token auth                                   |
| 🏷️  | [`github-release`][github-release]                     | Repository | Creates a GitHub release with a version and changelog.          | -                                            |
|  📦  | [`go-build`][go-build]                                 | Build      | Builds the Go project.                                          | Caching, Auto-detection                      |
|  📝  | [`go-lint`][go-lint]                                   | Linting    | Run golangci-lint with advanced configuration, caching, and ... | Caching, Outputs                             |
|  📝  | [`go-version-detect`][go-version-detect]               | Setup      | Detects the Go version from the project's go.mod file or def... | Auto-detection, Outputs                      |
| 🖥️  | [`node-setup`][node-setup]                             | Setup      | Sets up Node.js env with advanced version management, cachin... | Caching, Auto-detection, Token auth, Outputs |
|  📦  | [`npm-publish`][npm-publish]                           | Publishing | Publishes the package to the NPM registry with configurable ... | Outputs                                      |
| 🖥️  | [`php-composer`][php-composer]                         | Testing    | Runs Composer install on a repository with advanced caching ... | Caching, Auto-detection, Token auth, Outputs |
|  💻  | [`php-laravel-phpunit`][php-laravel-phpunit]           | Testing    | Setup PHP, install dependencies, generate key, create databa... | Auto-detection, Token auth, Outputs          |
|  ✅   | [`php-tests`][php-tests]                               | Testing    | Run PHPUnit tests on the repository                             | Token auth                                   |
|  📝  | [`php-version-detect`][php-version-detect]             | Setup      | Detects the PHP version from the project's composer.json, ph... | Auto-detection, Outputs                      |
|  ✅   | [`pr-lint`][pr-lint]                                   | Linting    | Runs MegaLinter against pull requests                           | Caching, Auto-detection, Token auth          |
|  📦  | [`pre-commit`][pre-commit]                             | Linting    | Runs pre-commit on the repository and pushes the fixes back ... | Token auth                                   |
|  ✅   | [`prettier-check`][prettier-check]                     | Linting    | Run Prettier check on the repository with advanced configura... | Caching, Outputs                             |
|  📝  | [`prettier-fix`][prettier-fix]                         | Linting    | Run Prettier to fix code style violations                       | Token auth                                   |
|  📝  | [`python-lint-fix`][python-lint-fix]                   | Linting    | Lints and fixes Python files, commits changes, and uploads S... | Caching, Auto-detection, Token auth, Outputs |
|  📝  | [`python-version-detect`][python-version-detect]       | Setup      | Detects Python version from project configuration files or d... | Auto-detection, Outputs                      |
|  📝  | [`python-version-detect-v2`][python-version-detect-v2] | Setup      | Detects Python version from project configuration files usin... | Auto-detection, Outputs                      |
|  📦  | [`release-monthly`][release-monthly]                   | Repository | Creates a release for the current month, incrementing patch ... | Token auth, Outputs                          |
|  🔀  | [`set-git-config`][set-git-config]                     | Setup      | Sets Git configuration for actions.                             | Token auth, Outputs                          |
|  📦  | [`stale`][stale]                                       | Repository | A GitHub Action to close stale issues and pull requests.        | Token auth                                   |
| 🏷️  | [`sync-labels`][sync-labels]                           | Repository | Sync labels from a YAML file to a GitHub repository             | Token auth, Outputs                          |
| 🖥️  | [`terraform-lint-fix`][terraform-lint-fix]             | Linting    | Lints and fixes Terraform files with advanced validation and... | Token auth, Outputs                          |
|  📦  | [`version-file-parser`][version-file-parser]           | Utilities  | Universal parser for common version detection files (.tool-v... | Auto-detection, Outputs                      |
|  ✅   | [`version-validator`][version-validator]               | Utilities  | Validates and normalizes version strings using customizable ... | Outputs                                      |

### Actions by Category

#### 🔧 Setup (7 actions)

| Action                                                    | Description                                           | Languages                       | Features                                     |
|:----------------------------------------------------------|:------------------------------------------------------|:--------------------------------|:---------------------------------------------|
| 📝 [`dotnet-version-detect`][dotnet-version-detect]       | Detects .NET SDK version from global.json or defau... | C#, .NET                        | Auto-detection, Outputs                      |
| 📝 [`go-version-detect`][go-version-detect]               | Detects the Go version from the project's go.mod f... | Go                              | Auto-detection, Outputs                      |
| 🖥️ [`node-setup`][node-setup]                            | Sets up Node.js env with advanced version manageme... | Node.js, JavaScript, TypeScript | Caching, Auto-detection, Token auth, Outputs |
| 📝 [`php-version-detect`][php-version-detect]             | Detects the PHP version from the project's compose... | PHP                             | Auto-detection, Outputs                      |
| 📝 [`python-version-detect`][python-version-detect]       | Detects Python version from project configuration ... | Python                          | Auto-detection, Outputs                      |
| 📝 [`python-version-detect-v2`][python-version-detect-v2] | Detects Python version from project configuration ... | Python                          | Auto-detection, Outputs                      |
| 🔀 [`set-git-config`][set-git-config]                     | Sets Git configuration for actions.                   | -                               | Token auth, Outputs                          |

#### 🛠️ Utilities (2 actions)

| Action                                          | Description                                           | Languages | Features                |
|:------------------------------------------------|:------------------------------------------------------|:----------|:------------------------|
| 📦 [`version-file-parser`][version-file-parser] | Universal parser for common version detection file... | -         | Auto-detection, Outputs |
| ✅ [`version-validator`][version-validator]      | Validates and normalizes version strings using cus... | -         | Outputs                 |

#### 📝 Linting (13 actions)

| Action                                         | Description                                           | Languages                                    | Features                                     |
|:-----------------------------------------------|:------------------------------------------------------|:---------------------------------------------|:---------------------------------------------|
| 📦 [`ansible-lint-fix`][ansible-lint-fix]      | Lints and fixes Ansible playbooks, commits changes... | Ansible, YAML                                | Token auth                                   |
| ✅ [`biome-check`][biome-check]                 | Run Biome check on the repository                     | JavaScript, TypeScript, JSON                 | Token auth                                   |
| ✅ [`biome-fix`][biome-fix]                     | Run Biome fix on the repository                       | JavaScript, TypeScript, JSON                 | Token auth                                   |
| 📝 [`csharp-lint-check`][csharp-lint-check]    | Runs linters like StyleCop or dotnet-format for C#... | C#, .NET                                     | Auto-detection                               |
| ✅ [`eslint-check`][eslint-check]               | Run ESLint check on the repository with advanced c... | JavaScript, TypeScript                       | Caching, Outputs                             |
| 📝 [`eslint-fix`][eslint-fix]                  | Fixes ESLint violations in a project.                 | JavaScript, TypeScript                       | Token auth                                   |
| 📝 [`go-lint`][go-lint]                        | Run golangci-lint with advanced configuration, cac... | Go                                           | Caching, Outputs                             |
| ✅ [`pr-lint`][pr-lint]                         | Runs MegaLinter against pull requests                 | -                                            | Caching, Auto-detection, Token auth          |
| 📦 [`pre-commit`][pre-commit]                  | Runs pre-commit on the repository and pushes the f... | -                                            | Token auth                                   |
| ✅ [`prettier-check`][prettier-check]           | Run Prettier check on the repository with advanced... | JavaScript, TypeScript, Markdown, YAML, JSON | Caching, Outputs                             |
| 📝 [`prettier-fix`][prettier-fix]              | Run Prettier to fix code style violations             | JavaScript, TypeScript, Markdown, YAML, JSON | Token auth                                   |
| 📝 [`python-lint-fix`][python-lint-fix]        | Lints and fixes Python files, commits changes, and... | Python                                       | Caching, Auto-detection, Token auth, Outputs |
| 🖥️ [`terraform-lint-fix`][terraform-lint-fix] | Lints and fixes Terraform files with advanced vali... | Terraform, HCL                               | Token auth, Outputs                          |

#### 🧪 Testing (3 actions)

| Action                                          | Description                                           | Languages    | Features                                     |
|:------------------------------------------------|:------------------------------------------------------|:-------------|:---------------------------------------------|
| 🖥️ [`php-composer`][php-composer]              | Runs Composer install on a repository with advance... | PHP          | Caching, Auto-detection, Token auth, Outputs |
| 💻 [`php-laravel-phpunit`][php-laravel-phpunit] | Setup PHP, install dependencies, generate key, cre... | PHP, Laravel | Auto-detection, Token auth, Outputs          |
| ✅ [`php-tests`][php-tests]                      | Run PHPUnit tests on the repository                   | PHP          | Token auth                                   |

#### 🏗️ Build (3 actions)

| Action                            | Description                                           | Languages | Features                     |
|:----------------------------------|:------------------------------------------------------|:----------|:-----------------------------|
| 📝 [`csharp-build`][csharp-build] | Builds and tests C# projects.                         | C#, .NET  | Auto-detection               |
| 📦 [`docker-build`][docker-build] | Builds a Docker image for multiple architectures w... | Docker    | Caching, Token auth, Outputs |
| 📦 [`go-build`][go-build]         | Builds the Go project.                                | Go        | Caching, Auto-detection      |

#### 🚀 Publishing (5 actions)

| Action                                        | Description                                           | Languages    | Features                   |
|:----------------------------------------------|:------------------------------------------------------|:-------------|:---------------------------|
| 📦 [`csharp-publish`][csharp-publish]         | Publishes a C# project to GitHub Packages.            | C#, .NET     | Auto-detection, Token auth |
| ☁️ [`docker-publish`][docker-publish]         | Publish a Docker image to GitHub Packages and Dock... | Docker       | Outputs                    |
| 📦 [`docker-publish-gh`][docker-publish-gh]   | Publishes a Docker image to GitHub Packages with a... | Docker       | Token auth, Outputs        |
| 📦 [`docker-publish-hub`][docker-publish-hub] | Publishes a Docker image to Docker Hub with enhanc... | Docker       | Outputs                    |
| 📦 [`npm-publish`][npm-publish]               | Publishes the package to the NPM registry with con... | Node.js, npm | Outputs                    |

#### 📦 Repository (7 actions)

| Action                                      | Description                                           | Languages | Features            |
|:--------------------------------------------|:------------------------------------------------------|:----------|:--------------------|
| 💾 [`common-cache`][common-cache]           | Standardized caching strategy for all actions         | -         | Caching, Outputs    |
| 📦 [`common-file-check`][common-file-check] | A reusable action to check if a specific file or t... | -         | Outputs             |
| 🖼️ [`compress-images`][compress-images]    | Compress images on demand (workflow_dispatch), and... | -         | Token auth          |
| 🏷️ [`github-release`][github-release]      | Creates a GitHub release with a version and change... | -         | -                   |
| 📦 [`release-monthly`][release-monthly]     | Creates a release for the current month, increment... | -         | Token auth, Outputs |
| 📦 [`stale`][stale]                         | A GitHub Action to close stale issues and pull req... | -         | Token auth          |
| 🏷️ [`sync-labels`][sync-labels]            | Sync labels from a YAML file to a GitHub repositor... | -         | Token auth, Outputs |

### Feature Matrix

| Action                                                 | Caching | Auto-detection | Token auth | Outputs |
|:-------------------------------------------------------|:-------:|:--------------:|:----------:|:-------:|
| [`ansible-lint-fix`][ansible-lint-fix]                 |    -    |       -        |     ✅      |    -    |
| [`biome-check`][biome-check]                           |    -    |       -        |     ✅      |    -    |
| [`biome-fix`][biome-fix]                               |    -    |       -        |     ✅      |    -    |
| [`common-cache`][common-cache]                         |    ✅    |       -        |     -      |    ✅    |
| [`common-file-check`][common-file-check]               |    -    |       -        |     -      |    ✅    |
| [`compress-images`][compress-images]                   |    -    |       -        |     ✅      |    -    |
| [`csharp-build`][csharp-build]                         |    -    |       ✅        |     -      |    -    |
| [`csharp-lint-check`][csharp-lint-check]               |    -    |       ✅        |     -      |    -    |
| [`csharp-publish`][csharp-publish]                     |    -    |       ✅        |     ✅      |    -    |
| [`docker-build`][docker-build]                         |    ✅    |       -        |     ✅      |    ✅    |
| [`docker-publish`][docker-publish]                     |    -    |       -        |     -      |    ✅    |
| [`docker-publish-gh`][docker-publish-gh]               |    -    |       -        |     ✅      |    ✅    |
| [`docker-publish-hub`][docker-publish-hub]             |    -    |       -        |     -      |    ✅    |
| [`dotnet-version-detect`][dotnet-version-detect]       |    -    |       ✅        |     -      |    ✅    |
| [`eslint-check`][eslint-check]                         |    ✅    |       -        |     -      |    ✅    |
| [`eslint-fix`][eslint-fix]                             |    -    |       -        |     ✅      |    -    |
| [`github-release`][github-release]                     |    -    |       -        |     -      |    -    |
| [`go-build`][go-build]                                 |    ✅    |       ✅        |     -      |    -    |
| [`go-lint`][go-lint]                                   |    ✅    |       -        |     -      |    ✅    |
| [`go-version-detect`][go-version-detect]               |    -    |       ✅        |     -      |    ✅    |
| [`node-setup`][node-setup]                             |    ✅    |       ✅        |     ✅      |    ✅    |
| [`npm-publish`][npm-publish]                           |    -    |       -        |     -      |    ✅    |
| [`php-composer`][php-composer]                         |    ✅    |       ✅        |     ✅      |    ✅    |
| [`php-laravel-phpunit`][php-laravel-phpunit]           |    -    |       ✅        |     ✅      |    ✅    |
| [`php-tests`][php-tests]                               |    -    |       -        |     ✅      |    -    |
| [`php-version-detect`][php-version-detect]             |    -    |       ✅        |     -      |    ✅    |
| [`pr-lint`][pr-lint]                                   |    ✅    |       ✅        |     ✅      |    -    |
| [`pre-commit`][pre-commit]                             |    -    |       -        |     ✅      |    -    |
| [`prettier-check`][prettier-check]                     |    ✅    |       -        |     -      |    ✅    |
| [`prettier-fix`][prettier-fix]                         |    -    |       -        |     ✅      |    -    |
| [`python-lint-fix`][python-lint-fix]                   |    ✅    |       ✅        |     ✅      |    ✅    |
| [`python-version-detect`][python-version-detect]       |    -    |       ✅        |     -      |    ✅    |
| [`python-version-detect-v2`][python-version-detect-v2] |    -    |       ✅        |     -      |    ✅    |
| [`release-monthly`][release-monthly]                   |    -    |       -        |     ✅      |    ✅    |
| [`set-git-config`][set-git-config]                     |    -    |       -        |     ✅      |    ✅    |
| [`stale`][stale]                                       |    -    |       -        |     ✅      |    -    |
| [`sync-labels`][sync-labels]                           |    -    |       -        |     ✅      |    ✅    |
| [`terraform-lint-fix`][terraform-lint-fix]             |    -    |       -        |     ✅      |    ✅    |
| [`version-file-parser`][version-file-parser]           |    -    |       ✅        |     -      |    ✅    |
| [`version-validator`][version-validator]               |    -    |       -        |     -      |    ✅    |

### Language Support

| Language   | Actions                                                                                                                                                                                                            |
|:-----------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| .NET       | [`csharp-build`][csharp-build], [`csharp-lint-check`][csharp-lint-check], [`csharp-publish`][csharp-publish], [`dotnet-version-detect`][dotnet-version-detect]                                                     |
| Ansible    | [`ansible-lint-fix`][ansible-lint-fix]                                                                                                                                                                             |
| C#         | [`csharp-build`][csharp-build], [`csharp-lint-check`][csharp-lint-check], [`csharp-publish`][csharp-publish], [`dotnet-version-detect`][dotnet-version-detect]                                                     |
| Docker     | [`docker-build`][docker-build], [`docker-publish`][docker-publish], [`docker-publish-gh`][docker-publish-gh], [`docker-publish-hub`][docker-publish-hub]                                                           |
| Go         | [`go-build`][go-build], [`go-lint`][go-lint], [`go-version-detect`][go-version-detect]                                                                                                                             |
| HCL        | [`terraform-lint-fix`][terraform-lint-fix]                                                                                                                                                                         |
| JSON       | [`biome-check`][biome-check], [`biome-fix`][biome-fix], [`prettier-check`][prettier-check], [`prettier-fix`][prettier-fix]                                                                                         |
| JavaScript | [`biome-check`][biome-check], [`biome-fix`][biome-fix], [`eslint-check`][eslint-check], [`eslint-fix`][eslint-fix], [`node-setup`][node-setup], [`prettier-check`][prettier-check], [`prettier-fix`][prettier-fix] |
| Laravel    | [`php-laravel-phpunit`][php-laravel-phpunit]                                                                                                                                                                       |
| Markdown   | [`prettier-check`][prettier-check], [`prettier-fix`][prettier-fix]                                                                                                                                                 |
| Node.js    | [`node-setup`][node-setup], [`npm-publish`][npm-publish]                                                                                                                                                           |
| PHP        | [`php-composer`][php-composer], [`php-laravel-phpunit`][php-laravel-phpunit], [`php-tests`][php-tests], [`php-version-detect`][php-version-detect]                                                                 |
| Python     | [`python-lint-fix`][python-lint-fix], [`python-version-detect`][python-version-detect], [`python-version-detect-v2`][python-version-detect-v2]                                                                     |
| Terraform  | [`terraform-lint-fix`][terraform-lint-fix]                                                                                                                                                                         |
| TypeScript | [`biome-check`][biome-check], [`biome-fix`][biome-fix], [`eslint-check`][eslint-check], [`eslint-fix`][eslint-fix], [`node-setup`][node-setup], [`prettier-check`][prettier-check], [`prettier-fix`][prettier-fix] |
| YAML       | [`ansible-lint-fix`][ansible-lint-fix], [`prettier-check`][prettier-check], [`prettier-fix`][prettier-fix]                                                                                                         |
| npm        | [`npm-publish`][npm-publish]                                                                                                                                                                                       |

### Action Usage

All actions can be used independently in your workflows:

```yaml
- uses: ivuorinen/actions/action-name@main
  with:
    # action-specific inputs
```

<!-- Reference Links -->

[ansible-lint-fix]: ansible-lint-fix/README.md
[biome-check]: biome-check/README.md
[biome-fix]: biome-fix/README.md
[common-cache]: common-cache/README.md
[common-file-check]: common-file-check/README.md
[compress-images]: compress-images/README.md
[csharp-build]: csharp-build/README.md
[csharp-lint-check]: csharp-lint-check/README.md
[csharp-publish]: csharp-publish/README.md
[docker-build]: docker-build/README.md
[docker-publish]: docker-publish/README.md
[docker-publish-gh]: docker-publish-gh/README.md
[docker-publish-hub]: docker-publish-hub/README.md
[dotnet-version-detect]: dotnet-version-detect/README.md
[eslint-check]: eslint-check/README.md
[eslint-fix]: eslint-fix/README.md
[github-release]: github-release/README.md
[go-build]: go-build/README.md
[go-lint]: go-lint/README.md
[go-version-detect]: go-version-detect/README.md
[node-setup]: node-setup/README.md
[npm-publish]: npm-publish/README.md
[php-composer]: php-composer/README.md
[php-laravel-phpunit]: php-laravel-phpunit/README.md
[php-tests]: php-tests/README.md
[php-version-detect]: php-version-detect/README.md
[pr-lint]: pr-lint/README.md
[pre-commit]: pre-commit/README.md
[prettier-check]: prettier-check/README.md
[prettier-fix]: prettier-fix/README.md
[python-lint-fix]: python-lint-fix/README.md
[python-version-detect]: python-version-detect/README.md
[python-version-detect-v2]: python-version-detect-v2/README.md
[release-monthly]: release-monthly/README.md
[set-git-config]: set-git-config/README.md
[stale]: stale/README.md
[sync-labels]: sync-labels/README.md
[terraform-lint-fix]: terraform-lint-fix/README.md
[version-file-parser]: version-file-parser/README.md
[version-validator]: version-validator/README.md

---

<!--/LISTING-->

## Usage

### Using Actions Externally

All actions in this repository can be used in your workflows like any other GitHub Action:

```yaml
steps:
  - name: Setup Node.js with Auto-Detection
    uses: ivuorinen/actions/node-setup@main
    with:
      default-version: '20'

  - name: Detect PHP Version
    uses: ivuorinen/actions/php-version-detect@main
    with:
      default-version: '8.2'

  - name: Universal Version Parser
    uses: ivuorinen/actions/version-file-parser@main
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
    uses: ivuorinen/actions/version-file-parser@main
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

For detailed development guidelines, see [CLAUDE.md](CLAUDE.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for details.
