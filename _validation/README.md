# `_validation/` — per-action input validation

Each action validates its own inputs with a **self-contained `validate.py`** — pure-stdlib
Python, no third-party packages, no `uv`, and no dependency on any other action. Those
validators are **generated** from a single source of truth that lives here.

## Why

Previously every action called a shared `validate-inputs` action. That coupled each action
to a separately-pinned dependency (so a stale pin could silently skip new validation), and
it pulled in `astral-sh/setup-uv` + a network install + PyYAML on every run. The
self-contained model removes all of that: validation ships _atomically_ with each action.

## Layout

| File          | Role                                                                                                                  |
|---------------|-----------------------------------------------------------------------------------------------------------------------|
| `kit.py`      | Canonical check functions — `CHECKS[type](value) -> error \| None`. Every regex/enum/range is defined here, **once**. |
| `spec.py`     | Hand-edited map: `SPECS[action] = {"required": [...], "checks": {input: type}}`.                                      |
| `generate.py` | Inlines the exact source of the checks each action needs into `<action>/validate.py`.                                 |
| `tests/`      | pytest: kit unit tests, a drift test, and spec/coverage tests.                                                        |

A generated `<action>/validate.py` contains: a small preamble (`_is_expr`, `_skip`, …),
only the checks that action uses (copied verbatim from `kit.py`), a `CHECKS` map, a
`REQUIRED` set, and a `main()` that reads `INPUT_*` env vars and exits non-zero with
`::error::` annotations on any failure.

## Contract every check follows

- **Empty** value → accepted (inputs are optional unless listed in `REQUIRED`).
- **`${{ … }}` expression** → accepted unchanged (its real value is substituted at runtime).
- Tokens additionally accept `$VAR` / `${VAR}` env references.

Validation is **fail-closed**: an invalid value prints `::error::` and exits 1 before the
action does any work.

## Changing what an action validates

1. Edit `spec.py` (to change an input→check mapping or required list) or `kit.py` (to change
   a check's logic — affects every action that uses it).
2. Run `make update-validators` (regenerates every `<action>/validate.py`).
3. Review `git diff '*/validate.py'`.

Never hand-edit a generated `<action>/validate.py` — a PreToolUse hook blocks it, and
`python3 _validation/generate.py --check` fails CI if any committed validator is stale.

## How an action runs it

```yaml
- name: Validate Inputs
  shell: sh
  working-directory: ${{ github.action_path }}
  env:
    INPUT_TOKEN: ${{ inputs.token }}
    # … one INPUT_<UPPER_SNAKE> per input …
  run: |
    set -eu
    if ! command -v python3 >/dev/null 2>&1; then
      echo "::error::python3 is required to validate inputs"
      exit 1
    fi
    python3 validate.py
```

## Versions read from repository files

Some actions also read a tool version from a file in the checked-out repository
(`.tool-versions`, `global.json`, `go.mod`, ...). That value is untrusted and is not an
input, so it has its own rule: `is_detected_version` or `is_detected_dotnet_version` in
`kit.py`, named by `detected_version` in `spec.py`. Neither has the `_skip` gate, and a
rejected value is not an error: the step moves on to its next source.

`validate.py` and `python3` are the only things a step can rely on at runtime, so the rule
ships there and a step asks it by exit status:

```yaml
- name: Detect Version
  shell: sh
  env:
    ACTION_PATH: ${{ github.action_path }}
  run: |
    set -eu
    command -v python3 >/dev/null 2>&1 || { echo "::error::python3 is required to validate detected versions"; exit 1; }
    validate_version() {
      (cd "$ACTION_PATH" && python3 validate.py --detected-version "$1")
    }
```

Run it from the action directory, not the checkout: a checkout's `.python-version` or
`.tool-versions` would otherwise steer a `python3` version-manager shim.

## Tests

```sh
make test-python              # pytest _validation/tests (kit + drift + coverage)
make update-validators        # regenerate all validators
python3 _validation/generate.py --check   # fail if any committed validator is stale
```
