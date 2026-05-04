# Validate-Inputs Pattern

Every action that accepts user inputs must call `validate-inputs` — never skip validation even when inputs seem optional.
Never inline validation logic in `action.yml`; it belongs in the Python validator system under `validate-inputs/`.
Never hand-edit `*/rules.yml` — it is auto-generated; run `make update-validators` instead.
