# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a collection of reusable GitHub Actions and workflows designed to streamline CI/CD processes. Each action is organized in its own directory with an `action.yml` file and a `README.md`.

## Repository Structure

- Each subdirectory represents a separate GitHub Action (e.g., `node-setup/`, `pr-lint/`, `docker-build/`)
- Actions are categorized by purpose: Setup & Caching, Linting & Formatting, Testing, Build & Package, Publish & Deployment, Release Management, and Repository Maintenance
- Each action directory contains:
  - `action.yml` - The main action definition
  - `README.md` - Auto-generated documentation

## Common Development Commands

### Documentation Generation and Code Quality

**Note:** Docker may not be available in the environment. Use individual CLI tools instead of Docker-based solutions.

```bash
# Generate documentation for all actions
find . -mindepth 2 -maxdepth 2 -name "action.yml" -exec sh -c 'dir=$(dirname "{}"); npx action-docs --source="{}" --no-banner --include-name-header > "$dir/README.md"' \;

# Or generate documentation for a single action
npx action-docs --source=./action-name/action.yml --no-banner --include-name-header > ./action-name/README.md

# Run linting and formatting tools individually
npx markdownlint-cli --fix --ignore "**/node_modules/**" "**/README.md"
npx prettier --write "**/README.md" "**/action.yml" ".github/workflows/*.yml"
npx markdown-table-formatter "**/README.md"

# Code quality checks (use individual tools instead of MegaLinter Docker)
npx eslint . --ext .js,.ts --fix
npx yamllint **/*.yml **/*.yaml
npx jsonlint **/*.json
```

### Alternative Quality Checks

Since MegaLinter requires Docker which may not be available, use these individual tools for code quality:

```bash
# YAML linting
npx yaml-lint **/*.yml **/*.yaml

# JSON validation
npx jsonlint **/*.json

# Shell script linting (if shellcheck is available)
shellcheck **/*.sh

# Markdown linting
npx markdownlint-cli **/*.md
```

## Action Development Patterns

### Version Management

- Each `action.yml` should include a version comment at the top: `# version: X.Y.Z`
- If no version is specified, `main` is used as the default
- README files should include version placeholders that get replaced during documentation generation

### Action Structure

- Use composite actions with shell scripts for flexibility
- Pin all external action versions using full SHA commits for security
- Include comprehensive input validation and error handling
- Provide meaningful outputs for downstream actions

### Node.js Actions

- Use the `node-setup` action for consistent Node.js environment setup
- Auto-detect package managers (npm, yarn, pnpm) based on lockfiles
- Support version detection from `.nvmrc`, `.tool-versions`, and `package.json`

### Multi-Language Support

- Actions like `pr-lint` automatically detect and setup environments for Node.js, PHP, Python, and Go
- Use conditional steps based on file detection (e.g., `package.json`, `composer.json`, `requirements.txt`, `go.mod`)

## Code Quality Standards

- All actions use pinned versions with SHA commits for security
- MegaLinter is used for comprehensive code quality checks
- Prettier handles code formatting
- Each action includes proper error handling with `set -euo pipefail`
- Actions provide detailed logging and status outputs

## Testing and Validation

- No automated test suite - actions are validated through usage in real workflows
- Use individual linting tools for validation since Docker-based solutions may not be available
- Validate YAML syntax, markdown formatting, and shell scripts using CLI tools
