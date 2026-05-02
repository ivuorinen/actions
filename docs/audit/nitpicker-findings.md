# Nitpicker Findings

Generated: 2026-04-30
Last validated: 2026-04-30 (Pass 8)

## Summary

- Total: 30 | Open: 0 | Fixed: 30 | Invalid: 0

## Open Findings

No open findings.

## Fixed

### Pass 8 — 2026-04-30

#### [N-029] `collect_inputs()` inflates `rules-applied` output count

Fixed: 2026-04-30
Notes: Changed `rules=len(inputs)` to `rules=sum(1 for k in inputs if "_" not in k)` at both
`write_output` call sites in `validator.py:main()`. Canonical (dash-normalised) keys have no
underscores; the underscore-aliased duplicates are excluded from the count. 760 Python tests pass.

#### [N-030] `is_fiximus` input uses snake_case; all other `validate-inputs` inputs use kebab-case

Fixed: 2026-04-30
Notes: Renamed `is_fiximus:` to `is-fiximus:` in the `inputs:` block of `validate-inputs/action.yml`
and updated the env block reference from `${{ inputs.is_fiximus }}` to `${{ inputs.is-fiximus }}`.
`make lint` passes clean (actionlint + action-validator).

### Pass 7 — 2026-04-30

#### [N-023] `fail-on-error: 'false'` is silently ignored — validator always exits 1 on failure

Fixed: 2026-04-30
Notes: Added `fail_on_error = os.environ.get("INPUT_FAIL_ON_ERROR", "true").lower() != "false"`
in `validator.py:main()`. Changed the failure branch to only call `sys.exit(1)` when
`fail_on_error` is True. Soft failures now write the failure output and return exit 0.

#### [N-024] `rules-file` input is silently ignored — custom rules are never loaded

Fixed: 2026-04-30
Notes: In `validator.py:main()`, after `get_validator(action_type)`, reads
`INPUT_RULES_FILE` and calls `validator.load_rules(Path(rules_file))` when non-empty.
`ConventionBasedValidator.load_rules()` already accepted a `rules_path` argument; no
registry API changes needed.

#### [N-025] `write_output` writes unsanitized user-controlled values to GITHUB_OUTPUT

Fixed: 2026-04-30
Notes: Added `_sanitize(value)` helper that replaces `\r` and `\n` with a space. Applied
to all three write sites in `write_output`: `status=`, `action=`, and the kwargs
comprehension. Confirmed: a value containing `\n` now produces a single-line entry in
GITHUB_OUTPUT.

#### [N-026] 2 declared action outputs are never written — callers always get empty strings

Fixed: 2026-04-30
Notes: Added `result="passed"` / `result=f"failed with {n} error(s)"` and
`rules=len(inputs)` to both `write_output` call sites in `validator.py:main()`. The
`steps.validate.outputs.result` and `steps.validate.outputs.rules` outputs are now
populated on every run.

#### [N-027] 6 security-scan inputs declared in `action.yml` but missing from `env:` block

Fixed: 2026-04-30
Notes: Added `INPUT_GITLEAKS_LICENSE`, `INPUT_GITLEAKS_CONFIG`, `INPUT_TRIVY_SEVERITY`,
`INPUT_TRIVY_SCANNERS`, `INPUT_TRIVY_TIMEOUT`, `INPUT_ACTIONLINT_ENABLED` to the env
block of the `Validate Action Inputs` step in `validate-inputs/action.yml`. Confirmed:
`grep -c 'GITLEAKS\|TRIVY\|ACTIONLINT' validate-inputs/action.yml` → 6 hits.

#### [N-028] `pip install pyyaml` without `--user` fails on PEP 668 systems

Fixed: 2026-04-30
Notes: Replaced `pip install pyyaml==6.0.3` with `astral-sh/setup-uv` + `uv sync`. Added
`uses: astral-sh/setup-uv@08807647e7069bb48b6ef5acd8ec9567f424441b # v8.1.0` step,
changed install to `uv sync --directory "${{ github.action_path }}"` (reads pyproject.toml),
and changed execution to `uv run validator.py`. No pip, no system-Python pollution, no
PEP 668 conflict. Consistent with the repo's uv-based local toolchain.

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

### Pass 3 — 2026-04-30

#### [N-011] `make test-python` breaks after clean `uv sync`

Fixed: 2026-04-30
Notes: Changed `test-python`, `test-python-coverage`, `test-update-validators`, and
`test-generate-tests` Makefile targets from `uv run pytest` (root venv, pytest not
in base deps) to `uv run --directory validate-inputs pytest` (subproject venv, which
always has pytest via `uv sync --all-extras`). All 4 targets verified: 828 Python
tests pass, 26 update-validator tests pass, 11 generate-tests tests pass.

### Pass 5 — 2026-04-30

#### [N-016] 3 PreToolUse hooks use `echo "$INPUT" | jq` — silent failure on control chars

Fixed: 2026-04-30
Notes: Added `CLEAN_INPUT=$(printf '%s' "$INPUT" | LC_ALL=C tr -d '\000-\010\013\014\016-\037')`
and switched `jq` calls to read from `$CLEAN_INPUT` with `2>/dev/null || true` in
`block-echo-github-output.sh`, `block-readme-edits.sh`, and `block-rules-yml.sh`.
Verified: hook now exits 0 (no jq parse error) when new_string contains 0x01 and
still correctly blocks `echo.*>>.*GITHUB_OUTPUT` and `rules.yml` patterns.

#### [N-017] `block-rules-yml.sh` had no unit test

Fixed: 2026-04-30
Notes: Created `_tests/unit/claude-hooks/block_rules_yml_spec.sh` with 9 test cases
covering: empty path (pass), `*/rules.yml` paths (deny), non-rules.yml paths (pass),
deny JSON format (hookEventName, permissionDecision, reason includes
"update-validators"). `make lint` passes clean.

### Pass 4 — 2026-04-30

#### [N-012] N-007 fix incomplete — 22 committed `_custom.py` files still contained `TODO:`

Fixed: 2026-04-30
Notes: `sed -i '' 's/# TODO:/# CUSTOMIZE:/g' validate-inputs/tests/*_custom.py`
replaced `TODO:` with `CUSTOMIZE:` in all 22 committed custom test files.
Confirmed: `rg -l 'TODO:' validate-inputs/tests/*_custom.py | wc -l` → 0.

#### [N-013] README "Actions by Category" omitted `npm-semantic-release`; count mismatch

Fixed: 2026-04-30
Notes: Added `npm-semantic-release` to the Publishing category table in
`README.md`, updated header from "Publishing (3 actions)" to "Publishing (4
actions)", and changed its Quick Reference category from "Other" to "Publishing".
Category section now totals 26, matching the Quick Reference header.

#### [N-014] `csharp-publish/action.yml:202` used GNU `find -printf` in POSIX sh block

Fixed: 2026-04-30
Notes: Replaced `find ... -printf '%T@ %p\n' | sort -rn | head -1 | cut ...` with
a POSIX sh loop using `-nt` test operator to find the newest `.nupkg` file. No
GNU find extensions remain. `make lint` (actionlint + shellcheck) passes clean.

#### [N-015] Orphaned `_tests/unit/action-versioning/` for deleted action

Fixed: 2026-04-30
Notes: Deleted `_tests/unit/action-versioning/` (24 tests for non-existent action).
The `action-versioning` action was removed in commit `ed3aed3`; the test directory
was left behind. `ls _tests/unit/action-versioning/` now returns "No such file or
directory".

### Pass 6 — 2026-04-30

#### [N-018] 11 phantom `_custom.py` test files silently test wrong `CustomValidator`

Fixed: 2026-04-30
Notes: Deleted all 11 phantom files: `test_common-file-check_custom.py`,
`test_docker-publish-gh_custom.py`, `test_docker-publish-hub_custom.py`,
`test_eslint-check_custom.py`, `test_go-version-detect_custom.py`,
`test_php-version-detect_custom.py`, `test_prettier-check_custom.py`,
`test_prettier-fix_custom.py`, `test_python-version-detect-v2_custom.py`,
`test_python-version-detect_custom.py`, `test_version-validator_custom.py`. Confirmed:
`ls validate-inputs/tests/*_custom.py | while read f; do ... done` → 0 phantom files.

#### [N-019] `spec_helper.sh` carries 9 phantom case entries for deleted actions

Fixed: 2026-04-30
Notes: Removed all 9 dead case branches from both `setup_default_inputs` and
`cleanup_default_inputs` in `_tests/unit/spec_helper.sh`: `github-release`,
`php-composer`, `php-laravel-phpunit` (from `php-tests` compound case),
`dotnet-version-detect`, `python-version-detect`, `python-version-detect-v2`,
`php-version-detect`, `go-version-detect`, `version-validator`. Also trimmed
`docker-publish-gh` and `docker-publish-hub` from the `docker-build | docker-publish`
compound case pattern. Confirmed: `grep -c 'github-release\|...' spec_helper.sh` → 0.

#### [N-020] `shellspec_mock_action_run` function is entirely dead code

Fixed: 2026-04-30
Notes: Deleted the entire `shellspec_mock_action_run` function (~135 lines including
mocks for node-setup, docker-build, common-file-check, csharp-build, csharp-lint-check,
csharp-publish, docker-publish, docker-publish-gh, docker-publish-hub,
dotnet-version-detect, eslint-check, eslint-fix, github-release, go-build, go-lint,
go-version-detect, npm-publish, php-composer). Removed from `export -f` line.
Confirmed: `rg 'shellspec_mock_action_run' _tests/ --glob='*.sh'` → 0 hits.

#### [N-021] Integration workflows reference non-existent `node-setup` and deleted `version-validator`

Fixed: 2026-04-30
Notes: (1) Deleted `_tests/integration/workflows/version-validator-test.yml` (entire
file tests a deleted action; 8 jobs, all broken). (2) Replaced all 3 `uses: ./node-setup`
in `lint-fix-chain-test.yml` with
`actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0` (same SHA
already used in `.github/actions/setup-test-environment/action.yml`); removed stale
`working-directory` input (not accepted by setup-node). (3) Removed `node-setup/**`
from `paths:` trigger in both `lint-fix-chain-test.yml` and `npm-publish-test.yml`.
Confirmed: `grep -rl 'node-setup\|version-validator' _tests/integration/workflows/`
→ 0 files.

#### [N-022] All integration test workflows used `actions/checkout@v4` without SHA pin

Fixed: 2026-04-30
Notes: Replaced all `actions/checkout@v4` instances in the 4 remaining integration
workflow files (`lint-fix-chain-test.yml`, `docker-build-publish-test.yml`,
`npm-publish-test.yml`, `pre-commit-test.yml`) with
`actions/checkout@71cf2267d89c5cb81562390fa70a37fa40b1305e # v6-beta` — the same SHA
used throughout `.github/workflows/`. 21 instances pinned (down from 29: 8 were in
the deleted `version-validator-test.yml`). Confirmed: `grep -rl 'checkout@v4'
_tests/integration/workflows/` → 0 files.

## Invalid

### Pass 1 — 2026-04-30

No findings invalidated in this pass.
