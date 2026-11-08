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

A generated `<action>/validate.py` contains: a small preamble (`_skip`, `_enum`, …),
only the checks that action uses (copied verbatim from `kit.py`), a `CHECKS` map, a
`REQUIRED` set, and a `main()` that reads `INPUT_*` env vars and exits non-zero with
`::error::` annotations on any failure.

## Contract every check follows

- **Empty or whitespace-only** value → accepted (inputs are optional unless listed in
  `REQUIRED`).
- **Everything else** → checked as literal data, exactly as the action will use it. The runner
  expands `${{ … }}` before `validate.py` reads `INPUT_*` and never expands `$VAR` in an input,
  so no check skips either as a reference. A value that still contains one passes only where
  that text fits the check's format: `url` accepts `https://example.com/$VAR`, while
  `file_path` rejects `src/$VAR`. Surrounding whitespace and newlines are rejected, except in
  the inputs that are multi-line by design.

Three checks look at less than the whole value, so callers must not rely on them to reject
everything else:

- **List checks** split the value on their separators and allow spaces or tabs around each item.
  They reject a newline, except `repository_list` and `key_value_list`, which take one entry per
  line.
- **`codeql_config`** holds inline YAML and rejects only unsafe YAML tags (`!!python/` and the
  like). Any other text passes, `${{ … }}` included.
- **`cache_config`** checks only the leading `type=<backend>`. The options after it reach buildx
  unchecked.

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

## Tests

```sh
make test-python              # pytest _validation/tests (kit + drift + coverage)
make update-validators        # regenerate all validators
python3 _validation/generate.py --check   # fail if any committed validator is stale
```
