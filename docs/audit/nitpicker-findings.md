# Nitpicker Findings

Generated: 2026-04-30
Last validated: 2026-04-30

## Summary

- Total: 10 | Open: 0 | Fixed: 10 | Invalid: 0

## Open Findings

No open findings.

## Fixed

### Pass 1 — 2026-04-30

#### [N-001] Missing explicit `shell:` on 6 composite action `run:` blocks

Fixed: 2026-04-30
Notes: Added `shell: sh` to `docker-build/action.yml:415`,
`eslint-lint/action.yml:115,381`, `go-lint/action.yml:104,340`,
`prettier-lint/action.yml:109`. All 6 blocks confirmed gone (corrected scan returns
0 hits).

#### [N-002] `file_path` validator allows whitespace including newlines

Fixed: 2026-04-30
Notes: Changed regex from `r"^[a-zA-Z0-9._/\-\s]+$"` to
`r"^[a-zA-Z0-9._/\- ]+$"` in `validate-inputs/validators/file.py:91`. Verified:
`re.match(r"^[a-zA-Z0-9._/\- ]+$", "dir\nEVIL=x")` now returns `None` (rejected);
valid path `"legit-dir/subpath"` still accepted.

#### [N-003] GITHUB_ENV writes use `echo "KEY=$VAR"` without newline protection

Fixed: 2026-04-30
Notes: Replaced grouped `echo` blocks with individual `printf 'KEY=%s\n' "$VAR" >>
"$GITHUB_ENV"` in `terraform-lint-fix/action.yml:103-107` and
`release-monthly/action.yml:75-77`. Confirmed no `echo "VALIDATED_` pattern remains
in any action.yml.

#### [N-004] No unit tests for `npm-semantic-release`

Fixed: 2026-04-30
Notes: Created `_tests/unit/npm-semantic-release/validation.spec.sh` with 21 test
cases. A defect in those tests was found in Pass 2 and tracked as N-008.

#### [N-005] `${{ env.VALIDATED_TOKEN }}` pattern allows caller-level env override

Fixed: 2026-04-30
Notes: Changed `token: ${{ env.VALIDATED_TOKEN }}` to `token: ${{ inputs.token }}`
in `release-monthly/action.yml:81`. Changed
`sarif_file: ${{ env.VALIDATED_WORKING_DIR }}/reports/tflint.sarif` to
`sarif_file: ${{ inputs.working-directory }}/reports/tflint.sarif` in
`terraform-lint-fix/action.yml:259`. Confirmed: `rg '\$\{\{ env\.VALIDATED_'`
returns 0 hits in any action.yml.

#### [N-006] No `actionlint` configuration file

Fixed: 2026-04-30
Notes: Created `.github/actionlint.yaml` with shellcheck integration enabled.

#### [N-007] 91 `TODO` occurrences in auto-generated test files are intentional

Fixed: 2026-04-30
Notes: Renamed all 5 TODO template strings to `CUSTOMIZE:` in
`validate-inputs/scripts/generate-tests.py`. Updated the assertion in
`validate-inputs/tests/test_generate_tests.py:275` from `"TODO: Add specific test
cases"` to `"CUSTOMIZE: Add specific test cases"`. No TODO occurrences remain in
generate-tests.py.

### Pass 2 — 2026-04-30

#### [N-008] npm-semantic-release unit tests: 4 fail, 6 pass for wrong reason

Fixed: 2026-04-30
Notes: Added `"npm-semantic-release"` to the `setup_default_inputs` and
`cleanup_default_inputs` case statements in `_tests/unit/spec_helper.sh` (lines 92,
151), defaulting `INPUT_NPM_TOKEN` when testing non-token inputs. Also added `../`
and `..\` to the URL injection pattern check in
`validate-inputs/validators/network.py:131` so the path-traversal test case
correctly exercises the validator. All 24 examples now pass.

#### [N-009] `shell: bash` and `[[` bash-isms in setup-test-environment action

Fixed: 2026-04-30
Notes: Changed all 8 `shell: bash` to `shell: sh` in
`.github/actions/setup-test-environment/action.yml`. Replaced
`[[ "${ACTUAL_CHECKSUM}" != "${EXPECTED_CHECKSUM}" ]]` with `[ ... ]` (line 95)
and `[[ "${{ inputs.install-act }}" == "true" ]]` with `[ ... = ... ]` (line 166).
Changed 2 instances of `set -euo pipefail` to `set -eu`. Added `set -eu` to the 6
blocks that were missing it.

#### [N-010] `set -eu` missing from 4 production run blocks

Fixed: 2026-04-30
Notes: Added `set -eu` as first line of run body in:
`csharp-publish/action.yml:48` (mask step), `csharp-publish/action.yml:247`
(status output, also converted `run: |-` to `run: |`),
`pr-lint/action.yml:718` (error+exit step),
`docker-build/action.yml:165` (Dockerfile existence check).

## Invalid

### Pass 1 — 2026-04-30

No findings invalidated in this pass.
