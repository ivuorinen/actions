# Tech Stack and Development Tools

## Core Technologies

- **GitHub Actions**: YAML-based workflow automation
- **Shell/Bash**: Action scripts with `set -euo pipefail` for error handling
- **Python 3.8+**: Centralized validation system with PyYAML
- **Node.js**: JavaScript tooling and npm packages (managed via nvm)
- **Make**: Build automation and task management

## Development Tools (Darwin/macOS)

### Available Tools

- **ripgrep (`rg`)**: `/Users/ivuorinen/.local/share/cargo/bin/rg` - Fast code search
- **fd**: `/Users/ivuorinen/.local/share/cargo/bin/fd` - Fast file finding
- **uv**: `/Users/ivuorinen/.local/bin/uv` - Python package management and execution
- **shellcheck**: `/Users/ivuorinen/.local/share/nvim/mason/bin/shellcheck` - Shell script linting
- **yamlfmt**: `/Users/ivuorinen/.local/share/nvim/mason/bin/yamlfmt` - YAML formatting
- **actionlint**: `/Users/ivuorinen/.local/share/nvim/mason/bin/actionlint` - GitHub Actions linting
- **git**: `/opt/homebrew/bin/git` - Version control
- **npm/npx**: `/Users/ivuorinen/.local/share/nvm/versions/node/v22.19.0/bin/npm` - Node.js package management
- **make**: `/usr/bin/make` - Build automation

### Python Stack

- **uv**: Modern Python package management
- **ruff**: Fast Python linting and formatting
- **pytest**: Testing framework with coverage reporting
- **PyYAML**: YAML parsing for validation rules

### JavaScript/Node.js Stack

- **Node.js v22.19.0**: Managed via nvm at `/Users/ivuorinen/.local/share/nvm/`
- **npx**: For running npm packages without installation
- **markdownlint-cli2**: Markdown linting
- **prettier**: Code formatting
- **markdown-table-formatter**: Table formatting
- **yaml-lint**: YAML validation
- **action-docs**: Auto-generate README.md files

### Testing Framework

- **ShellSpec**: Shell script testing framework
- **pytest**: Python testing with coverage support
- **nektos/act** (optional): Local GitHub Actions testing

## Language Support

Multi-language ecosystem supporting:

- **Shell/Bash**: Action scripts and utilities
- **Python**: Validation system and testing
- **JavaScript/TypeScript**: Linting and formatting actions
- **PHP**: Composer, Laravel, PHPUnit support
- **Go**: Build, linting, version detection
- **C#/.NET**: Build, lint, publish actions
- **Docker**: Multi-architecture build and publish
- **Terraform/HCL**: Infrastructure linting
- **Ansible**: Playbook linting
- **YAML/JSON/Markdown**: Configuration and documentation
