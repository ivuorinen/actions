---
name: new-action
description: Scaffold a new GitHub Action with all required files
disable-model-invocation: true
---

# Scaffold a New GitHub Action

## 1. Gather information

Ask the user for:

- **Action name** (kebab-case, e.g. `my-new-action`)
- **Description** (one line)
- **Category** (setup, linting, testing, build, publishing, repository, utility)
- **Inputs** (name, description, required, default for each)
- **What it does** (shell commands, composite steps, etc.)

## 2. Create directory and action.yml

Create `<action-name>/action.yml` following the existing action patterns:

- Use `composite` runs type
- Include `set -eu` in shell scripts (POSIX sh, not bash)
- Use `${{ github.token }}` for token defaults
- Pin all external action references to SHA commits
- Pin internal action references using `ivuorinen/actions/action-name@<SHA>`
- Add `id:` to steps whose outputs are referenced

## 3. Generate validation rules

```bash
make update-validators
```

This generates `<action-name>/rules.yml` from the action's inputs.

## 4. Generate test scaffolding

```bash
make generate-tests
```

## 5. Generate README

```bash
make docs
```

## 6. Run validation

```bash
make all
```

Fix any issues before considering the action complete.

## 7. Update repository overview

Remind the user to update the Serena memory `repository_overview` if they use Serena.
