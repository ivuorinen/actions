# Contributing to ivuorinen/actions

Thank you for your interest in contributing to this GitHub Actions monorepo.

## Reporting Issues

- **Bugs**: Open an issue using the bug report template.
- **Security vulnerabilities**: See [SECURITY.md](SECURITY.md) for responsible disclosure.
- **Feature requests**: Open an issue describing the use case.

## Development Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/ivuorinen/actions.git
   cd actions
   ```

2. Install dependencies (Node.js, Python 3, ShellSpec, shellcheck, actionlint, ruff, prettier, markdownlint, yamllint).
3. Run formatting, linting, and pre-commit checks:

   ```bash
   make all
   ```

4. Run the test suite:

   ```bash
   make test
   ```

## Code Style

- **EditorConfig**: 2-space indentation, UTF-8, LF line endings, max 200 chars.
- **Shell scripts**: POSIX `sh` with `set -eu`. No bash-only syntax.
- **Python**: Formatted and linted with `ruff`.
- **YAML/JSON/Markdown**: Formatted with `prettier`; linted with `yamllint` and `markdownlint`.
- **Action references**: SHA-pinned in `action.yml` files. Date-based tags or commit SHAs for published refs.

Run `make dev` (format + lint) to check your changes.

## Pull Request Process

1. Branch from `main`.
2. Make focused changes (one feature or fix per PR).
3. Ensure all checks pass: `make all` and `make test`.
4. Follow existing patterns in the codebase.
5. Update documentation if adding or modifying actions.

## Testing

```bash
make test              # All tests (ShellSpec + pytest)
make test-actions      # GitHub Actions tests only
make test-python       # Python validation tests only
make test-coverage     # All tests with coverage
```

See [\_tests/README.md](_tests/README.md) for details on the ShellSpec testing framework.

## Adding a New Action

Each action is a self-contained directory at the repository root containing:

- `action.yml` with inputs, outputs, and runs definition
- `README.md` generated via `action-docs` (`make docs`)
- Tests in `_tests/`

Do not manually edit sections between `<!--LISTING-->` markers in the root README.
Use `npm run update-catalog` to regenerate the catalog.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE.md).
