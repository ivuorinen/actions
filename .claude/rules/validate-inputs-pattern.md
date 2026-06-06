# Self-Contained Validation Pattern

Every action that accepts user inputs must have a generated `<action>/validate.py` and
run it as its first real step (a `shell: sh` step that runs `python3 validate.py`).
The validator is self-contained pure-stdlib Python: it reads each input from its
`INPUT_*` env var and fails with `::error::` + exit 1 on invalid input — never skip
validation even when inputs seem optional.

Never inline validation logic in `action.yml`; it belongs in the generated validator,
which is produced from the canonical sources under `_validation/`.

The input → check mapping lives in `_validation/spec.py` (the single source: which
inputs each action has, which check type each uses, and which are required); the check
implementations (every regex, enum, and range) live in `_validation/kit.py`.

Never hand-edit a generated `<action>/validate.py` — it is auto-generated and a
PreToolUse hook blocks editing it. Edit `_validation/spec.py` and/or `_validation/kit.py`,
then run `make update-validators` to regenerate. Verify the committed validators are
current with `python3 _validation/generate.py --check`.
