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
- Give a token input `default: ''` and read it as `${{ inputs.token || github.token }}`, so an empty value gets
  the job token; its description ends with "Defaults to the workflow token.", after "Stays in git config after
  checkout." when a checkout persists it
- Pin all external action references to SHA commits
- Pin internal action references using `ivuorinen/actions/action-name@<SHA>`
- Add `id:` to steps whose outputs are referenced

## 3. Generate the input validator

Add the new action to `_validation/spec.py` — list its required inputs and map each
input to a check type from `_validation/kit.py` (add a new check to `kit.py` if none
fits). Then:

```bash
make update-validators
```

This generates `<action-name>/validate.py` (self-contained pure-stdlib validator) from
`_validation/spec.py` + `_validation/kit.py`. Never hand-edit the generated `validate.py`.
Add a `shell: sh` step that runs `python3 validate.py` as the action's first real step.

## 4. Write the tests

Write the action's ShellSpec specs under `_tests/unit/<action-name>/` (`_tests/README.md` describes
the harness and its patterns); the test runner reports any action without them. Then run them:

```bash
make test-action ACTION=<action-name>
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
