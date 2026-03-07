---
name: validate
description: Run full validation pipeline (docs, format, lint, test)
disable-model-invocation: true
---

# Full Validation Pipeline

Run the complete validation pipeline:

```bash
make all
```

This runs in order: `install-tools` -> `update-validators` -> `docs` -> `update-catalog` -> `format` -> `lint` -> `precommit`

**Note:** `make test` must be run separately.

## If validation fails

### Formatting issues

```bash
make format
```

Then re-run `make all`.

### Linting issues

- **actionlint**: Check action.yml syntax, step IDs, expression usage
- **shellcheck**: POSIX compliance, quoting, variable usage
- **ruff**: Python style and errors
- **markdownlint**: Markdown formatting
- **prettier**: YAML/JSON/MD formatting

### Test failures

```bash
make test
```

Read the failing test output and fix the underlying action or test.

### Documentation drift

```bash
make docs
```

Regenerates READMEs from action.yml files.
