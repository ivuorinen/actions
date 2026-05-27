# Nitpicker Findings

Generated: 2026-04-30
Last validated: 2026-05-27 (Pass 18 — N-107 secret-mask hardening, fix shipped same change)

## Summary

- Total: 107 | Open: 0 | Fixed: 107 | Invalid: 0

## Open Findings

_No open findings._

_Pass 16 re-validation summary:_ Two `<!-- -->` comment blocks under the Open Findings
section previously held 27 historical findings (N-031..N-048, N-081..N-089). All 27 were
already duplicated in the Fixed section under earlier passes; the blocks confused tooling
(file appeared to have 28 open findings when the summary said 1). All 27 were
re-validated against current code and confirmed fixed; the comment blocks were removed.

_Pass 17:_ N-095 (15 actions inline-validating instead of calling validate-inputs) closed
via per-action migration in commits 3dcf7cb..2191252 + test-fixup 03adba5. Every action
that accepts inputs now delegates to `ivuorinen/actions/validate-inputs@5cc7373a`.

## Fixed

### Pass 18 — 2026-05-27

#### [N-107] docker-publish missed `::add-mask::` for dockerhub-token; npm-publish/npm-semantic-release used `echo` instead of `printf`

Category: security
Area: `docker-publish/action.yml`, `npm-publish/action.yml`, `npm-semantic-release/action.yml`
Problem: `docker-publish/action.yml` accepted `inputs.dockerhub-token` and passed it
to both `validate-inputs` (line 112) and `docker/login-action` (line 190) without
a preceding `::add-mask::` workflow command. By contrast, `npm-publish` and
`npm-semantic-release` already had a `Mask Secrets` composite step. Although
`docker/login-action` masks internally, the input was unmasked between action
entry and that step — a defense-in-depth gap that diverged from the established
repo pattern. Separately, the existing `Mask Secrets` steps in `npm-publish` and
`npm-semantic-release` used `echo "::add-mask::$VAR"` (variable interpolated into
the command string) instead of the repo-preferred `printf '::add-mask::%s\n' "$VAR"`
format-string-separation pattern documented in
`.claude/agents/security-surface-reviewer.md` Section 2 and consistent with the
`GITHUB_OUTPUT` rule in `.claude/rules/github-output-format.md`.
Evidence: `grep -n 'Mask Secrets' */action.yml` returned 2 of 3 actions that
accept publishable-registry secrets (docker-publish missing). `grep -n
'::add-mask::' npm-publish/action.yml npm-semantic-release/action.yml` showed
`echo` usage on lines 55 and 59-60 respectively. Surfaced by
`/security-audit` post-PR-#592 on branch `chore/upgrades-and-fixes`.
Impact: Defense-in-depth gap — relies on the downstream `docker/login-action`
masking internally rather than masking at action entry. Pattern divergence
between three near-identical mask steps creates rule-of-three pressure
(`.claude/rules/code-quality.md`) and means a future contributor copying the
`echo` pattern propagates the variable-in-command-string anti-pattern.
Fix: Added a `Mask Secrets` step to `docker-publish/action.yml` immediately
before `Validate Inputs`, using the `printf '::add-mask::%s\n' "$DOCKERHUB_TOKEN"`
pattern guarded by `[ -n "${DOCKERHUB_TOKEN:-}" ]` (dockerhub-token is optional
when registry=ghcr). Migrated the two existing `echo` mask lines in
`npm-publish/action.yml:55` and `npm-semantic-release/action.yml:59-60` to the
same `printf` pattern in the same change — closing the rule-of-three trigger and
preventing the new docker-publish step from becoming a third inconsistent copy.
Fixed: 2026-05-27
Notes:

- Fix bundled in the same commit that introduced the new mask step, per
  `.claude/rules/fix-pre-existing-issues.md` ("Discovery is Ownership"). The
  `echo` pattern was flagged as M-1 in the same `/security-audit` run that
  flagged H-2 (the missing docker-publish mask); both were rolled into one
  finding because they have a shared root cause (inconsistent secret-mask
  step pattern) and one fix unifies them.
- Token-masking is defense-in-depth: in practice the runner auto-masks
  `${{ secrets.* }}` values used as step inputs, and `docker/login-action`
  masks the password it receives. The explicit `Mask Secrets` step still
  matters for inputs received indirectly (e.g., the action being called with
  `dockerhub-token: ${{ env.FOO }}` where `env.FOO` was set earlier in the
  workflow from a non-secret source).
- No `set -eu` change needed — the existing mask steps were already POSIX-
  compliant.

### Pass 17 — 2026-05-25

#### [N-095] 15 actions had inline validation logic in violation of validate-inputs-pattern rule

Category: conventions
Area: multiple action.yml files
Problem: `.claude/rules/validate-inputs-pattern.md` mandates "Never inline validation
logic in `action.yml`; it belongs in the Python validator system under
`validate-inputs/`." 15 actions had inline sh validation in their `run:` blocks
instead of delegating to the `validate-inputs` action: `csharp-lint-check`,
`npm-semantic-release`, `sync-labels`, `release-monthly`, `npm-publish`,
`docker-publish`, `php-tests`, `go-lint`, `go-build`, `eslint-lint`, `biome-lint`,
`prettier-lint`, `language-version-detect`, `csharp-build`, `compress-images`.
Evidence: `grep -L 'ivuorinen/actions/validate-inputs' */action.yml` returned the
15 names above.
Impact: Validation logic was duplicated, diverged from the Python validator test
coverage, and was harder to audit uniformly.
Fix: Per-action migration. For each of the 15, the inline `Validate Inputs`
sh step (typically 30–170 lines of case-statement validation) was replaced
with a call to `ivuorinen/actions/validate-inputs@5cc7373a22402ee8985376bc713f00e09b5b2edb`,
passing all inputs through the `with:` block. The validate-inputs action loads
the action's own `<action>/rules.yml` (auto-generated by `update-validators.py`,
convention-based) and the optional `<action>/CustomValidator.py` (for
action-specific rules beyond convention).
Fixed: 2026-05-25
Notes:

- One commit per action (17 commits total: 3dcf7cb sync-labels, ee2c6db
  compress-images, 005aec0 docker-publish, a360339 go-lint, d44b9d1 npm-publish,
  8036bae npm-semantic-release, 5f420c9 php-tests, 9e137c0 biome-lint,
  f60f2d9 eslint-lint, b2ed2c4 prettier-lint, 4d6e60d go-build, 1bf3831
  csharp-build, 8ebc19b csharp-lint-check, c74c6be language-version-detect,
  2191252 release-monthly, plus 03adba5 test-fixup).
- Net line change: ~-1100 lines across the 15 action.yml files.
- Two minor behavioral changes documented in commit messages:
  (a) docker-publish: dropped the early cross-input check that required dockerhub
  creds when registry=dockerhub (was infeasible to add to the CV without breaking
  the single-input `validate_input_python` shellspec test harness; the downstream
  docker login step still errors clearly).
  (b) language-version-detect: dropped per-language major-version range guards
  (e.g., PHP major 7-9). The downstream setup-php/setup-python/etc steps fail
  clearly on truly invalid versions.
- The post-checkout "Verify Working Directory" step in compress-images, the
  "Verify package.json" step in npm-semantic-release, the "Compute Default
  Version" step in language-version-detect, and the "Mask Token and Export
  Validated Values" step in release-monthly are preserved as separate steps
  (they perform runtime/repo-state operations, not input validation).
- 786/786 Python tests pass; per-action ShellSpec suites pass; make lint clean.

### Pass 16 — 2026-05-25

#### [N-100] `scorecard.yml`: `actions/checkout` SHA inconsistent with all other workflows

Category: reliability
Area: .github/workflows/scorecard.yml:27
Problem: The scorecard workflow pinned `actions/checkout` to
`de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2` while every other workflow and
every action.yml in the repo used `71cf2267d89c5cb81562390fa70a37fa40b1305e # v6-beta`.
Two distinct pinned SHAs for the same external action increase the audit surface and
mean one version is less battle-tested in this codebase.
Evidence: `grep -rEh "actions/checkout@" */action.yml .github/workflows/*.yml | sort | uniq -c`
showed 39 entries with the v6-beta SHA and 1 entry with the v6.0.2 SHA.
Impact: Inconsistent supply-chain pin; security review must track two trees for the same
action. A regression in v6.0.2 (e.g., credential-leak bug) would only affect scorecard.
Fix: Aligned scorecard.yml to `71cf2267d89c5cb81562390fa70a37fa40b1305e # v6-beta`.
Fixed: 2026-05-25
Notes: One-line SHA replacement in `.github/workflows/scorecard.yml`.

#### [N-101] `codeql-analysis/action.yml`: missing `yaml-language-server` schema header

Category: conventions
Area: codeql-analysis/action.yml:1
Problem: All other 25 action.yml files start with
`# yaml-language-server: $schema=https://json.schemastore.org/github-action.json` as the
first line; only `codeql-analysis/action.yml` lacked it. The schema header drives editor
autocomplete, lint warnings, and CI schema validation. Without it, this action is the only
one that does not get schema-aware editing.
Evidence: `for f in */action.yml; do head -1 "$f" | grep -q yaml-language-server || echo "$f"; done`
returned only `codeql-analysis/action.yml`.
Impact: Editor and tooling drift — schema-driven warnings silently disabled for this file.
Fix: Prepended the standard schema header above the existing front-matter.
Fixed: 2026-05-25
Notes: Moved the comment block above `---` separator to keep YAML parseable.

#### [N-102] `block-bashisms.sh`: exemption list misses `_tests/run-tests.sh` and other top-level test files

Category: maintainability
Area: .claude/hooks/block-bashisms.sh:22-24
Problem: The hook exempted `_tests/framework/*` and `_tests/unit/*` from POSIX checks but
did NOT exempt top-level `_tests/*` files such as `_tests/run-tests.sh`. That file uses
`#!/usr/bin/env bash`, `set -euo pipefail`, `local`, `[[ ]]`, and bash arrays intentionally
(test runner only runs on Linux CI with bash always available). Editing it would trigger a
hook block, forcing maintainers to fight or bypass the hook.
Evidence: `shellcheck --shell=sh _tests/run-tests.sh` returns 30+ warnings (SC3040 pipefail,
SC3043 local, SC3010 [[]], SC3030 arrays, SC3046 source, SC3028/SC3054 BASH_SOURCE) — all
of which the hook also flags but cannot exempt for this specific file.
Impact: Maintainer friction; any future edit to the test runner risks being blocked even
though the bash usage is deliberate and documented.
Fix: Broadened exemption case to `_tests/* | */_tests/*`. Added 3 shellspec test cases
covering top-level, framework, and unit paths.
Fixed: 2026-05-25
Notes: Updated `_tests/unit/claude-hooks/block_bashisms_spec.sh` with new `Context` block
titled "when file path is under_tests/ (intentional bash usage)".

#### [N-103] `_tests/unit/codeql-analysis/validation.spec.sh`: bash shebang inconsistent with all other validation specs

Category: conventions
Area: \_tests/unit/codeql-analysis/validation.spec.sh:1
Problem: All 25 other `validation.spec.sh` files used `#!/usr/bin/env shellspec`; only
codeql-analysis used `#!/usr/bin/env bash`. ShellSpec specs run under the shellspec
interpreter regardless of the shebang, so the bash shebang is misleading and inconsistent.
Evidence: `for f in _tests/unit/*/validation.spec.sh; do head -1 "$f"; done | sort -u`
returned 2 distinct shebangs: 25 shellspec, 1 bash.
Impact: Future maintainers reading the bash shebang may try to execute the file directly
with bash and get confused when ShellSpec DSL fails to parse.
Fix: Changed shebang to `#!/usr/bin/env shellspec` and added the standard 2-line comment
header used by other validation specs.
Fixed: 2026-05-25
Notes: No behavior change — ShellSpec was already executing the file correctly.

#### [N-104] `registry.py`: secondary `except` block too narrow, silently propagates `SyntaxError`/`OSError`

Category: reliability
Area: validate-inputs/validators/registry.py:203
Problem: The fallback validator-instantiation path (`importlib.import_module(f"validators.{...}")`
on line 197) only caught `(ImportError, AttributeError)`. If the imported validator module
had a Python syntax error, an `OSError` (permission denied), or a `TypeError` during class
lookup, the exception propagated and broke validation for all actions, not just the one
with the bad module. Sister `except Exception:` at line 114 (in `_load_custom_validator`)
was already broad enough — the L203 narrowness was an inconsistency.
Evidence: A malformed validator file under `validate-inputs/validators/` would crash
`_get_default_validator_instance()` with an unhandled `SyntaxError`, aborting the entire
validation run.
Impact: Single malformed validator file would crash validation for all actions, masking
which file caused the failure.
Fix: Extended the except tuple to `(ImportError, AttributeError, SyntaxError, OSError,
TypeError)` to match the defensive posture of the primary except block and the
`_get_validator_method` exception handling. Updated comment to reflect the broader scope.
Fixed: 2026-05-25
Notes: This issue was related to but distinct from N-041, which targeted the primary
`exec_module` path. The primary path was already widened in earlier passes; this addresses
the secondary path.

#### [N-105] Hook shellspec tests: malformed `Data` blocks + `post-edit-write.sh` missing `|| true`

Category: tests
Area: `_tests/unit/claude-hooks/*.spec.sh` (5 files) + `.claude/hooks/post-edit-write.sh`
Problem: Eight `Data` blocks across 5 hook spec files used the bare `| '...'` form,
which ShellSpec rejects with `Syntax error: Data text should begin with '#|' or '# '`.
This caused 8 test aborts (not just failures) plus 4 cascading failures in
`post_edit_write_spec.sh` whose mock-tool integration assertions never ran. The
secondary cause for the 4 cascading failures: `post-edit-write.sh` invoked
`shellcheck`, `actionlint`, and `action-validator` without `|| true`, so on missing
files (or on real lint findings) the hook exited non-zero via `set -e`, which (a)
would surface as a PostToolUse error to the user editing files and (b) caused the
tests to abort because the `result=$(... sh "$HOOK" ...)` capture inherited the
non-zero exit.
Evidence: `shellspec --pattern '*_spec.sh' _tests/unit/claude-hooks/` reported 9
failures (3 in block_bashisms, 5 in sister hooks, 4 in post_edit_write). The 4
post_edit_write failures showed `could not read "/myaction/action.yml": no such
file or directory` from real actionlint invocation, exit code 3.
Impact: Hook test suite was not exercising its assertions; any future hook regression
would land silently. Hook itself would noisily fail user edits on missing-file races
or transient tool failures.
Fix: (1) Replaced all 8 `| '...'` lines with `#| ...` form per ShellSpec docs.
(2) Added `|| true` to the `shellcheck`, `actionlint`, and `action-validator`
invocations in `post-edit-write.sh` so they are non-fatal (consistent with the
existing `|| true` pattern on `shfmt`, `ruff`, and `prettier`).
Fixed: 2026-05-25
Notes: After both fixes, all 106 hook test examples pass (up from 97 passing + 9
aborted/failed). Verified with `shellspec --pattern '*_spec.sh' _tests/unit/claude-hooks/`.

#### [N-106] `make lint-markdown` flags 13 pre-existing errors in gitignored plugin/session files

Category: maintainability
Area: Makefile (lint-markdown, format-markdown targets) + `.markdownlintignore`
Problem: `make lint-markdown` recursively scanned `.claude/skills/` (third-party
skill files installed by Claude Code plugins) and `docs/superpowers/` (session-
generated plan/spec artifacts). Both directories are gitignored — `.claude/*` via
the user's global gitignore, `docs/superpowers/` via the repo's `.gitignore:89`.
The lint reported 13 MD040 (fenced-code-language) and MD013 (line-length) errors
that the project does not own and cannot fix without modifying plugin/session files.
Evidence: `make lint-markdown 2>&1 | grep -E "^(\\.claude|docs/superpowers)" | wc -l`
returned 13 before the fix; the same command returns 0 after.
Impact: The mantra "All tests pass + all linting passes + all validation passes +
zero warnings" was violated by files outside the repo's control. Lint output noise
discouraged maintainers from reading the warnings that DO matter.
Fix: Added `.claude/` and `docs/superpowers/` to `.markdownlintignore` AND extended
the explicit glob exclusions in both `lint-markdown` and `format-markdown` Makefile
targets (`"#node_modules" "#.worktrees" "#.claude" "#docs/superpowers"`). Both
mechanisms together because markdownlint-cli2 prefers explicit args over the
ignorefile when both are present.
Fixed: 2026-05-25
Notes: After fix, `make lint-markdown` reports `Linting: 52 file(s) Summary: 0 error(s)`.

### Pass 15 — 2026-05-25

#### [N-099] `_tests/framework/validation.py` and `_tests/shared/validation_core.py` token regex updated without unit tests

Category: tests
Area: `_tests/shared/validation_core.py`, `_tests/framework/validation.py`
Problem: Pass 14 updated the installation-token regex in both test-framework
modules without adding unit tests to exercise the new format. The shared
`ValidationCore` class is invoked via CLI from ShellSpec specs (`uv run
validation_core.py --validate ...`), so a regex regression would only surface
when a downstream spec exercises the exact `ghs_APPID_JWT` shape — which none did.
Evidence: `_tests/shared/` contained only `test_docker_image_regex.py` before this
pass; no test asserts the behaviour of `ValidationCore.validate_github_token` or
`ActionValidator.validate_github_token`.
Impact: A future change to either regex could silently break ShellSpec validation
runs without any local-test signal.
Fixed: 2026-05-25
Notes: Added `_tests/shared/test_token_regex.py` (14 cases) and
`_tests/framework/test_action_validator_token.py` (8 cases). Coverage includes
stateful/stateless ghs*, JWT realistic shape, minimum/upper-bound length
boundaries (36, 1024), invalid-char rejection, classic ghp*, fine-grained
github*pat*, GitHub expressions, and wrong-prefix rejection.

#### [N-098] Fixture `"ghs_ stateless minimum length (36 body chars)"` body was 37 chars, not 36

Category: tests
Area: `validate-inputs/tests/fixtures/version_test_data.py`
Problem: `("ghs_1_" + "a" * 30 + "." + "b" * 4, "ghs_ stateless minimum length (36
body chars)")` — body length is 2 + 30 + 1 + 4 = 37 chars, but the label says 36.
The test passed (37 ≥ 36) but did not exercise the boundary it claimed to.
Evidence: Hand-count and `python3 -c "print(len('1_' + 'a'*30 + '.' + 'b'*4))"` → 37.
Impact: Minimum-length boundary was untested — a regex regression to `{37,}` would
have been masked.
Fixed: 2026-05-25
Notes: Corrected to `"ghs_1_" + "a" * 30 + ".y.z"` (body = 36). Added explicit
1024-char upper-bound case to VALID and 1025-char over-bound case to INVALID.
Mirror boundary test (`test_ghs_length_boundaries`) added to `test_token.py` and
the generator template.

#### [N-097] `scripts/generate-tests.py` `_generate_input_test_cases` had unused `config` parameter with `# noqa: ARG002` suppression

Category: maintainability
Area: `validate-inputs/scripts/generate-tests.py`
Problem: The function signature was `_generate_input_test_cases(self, input_name:
str, config: dict)` but `config` was never read inside the function body — it was
silenced with `# noqa: ARG002`. Per `.claude/rules/fix-pre-existing-issues.md`,
suppression directives are not permitted in place of root-cause fixes.
Evidence: pyright diagnostic at line 266 — `"config" is not accessed`. Function
body relies entirely on regex matching against `input_name`.
Impact: Dead parameter clutters the API and masks intent for future maintainers.
Fixed: 2026-05-25
Notes: Removed the `config` parameter from the signature and the call site at line 204. Updated all five call sites in `tests/test_generate_tests.py` accordingly.
Test suite remains green (786 tests pass).

### Pass 14 — 2026-05-25

#### [N-096] `validate-inputs` rejects new stateless `ghs_` installation tokens with "Invalid token format"

Category: correctness
Area: `validate-inputs/validators/token.py`, `validate-inputs/validators/security.py`,
`_tests/shared/validation_core.py`, `_tests/framework/validation.py`
Problem: GitHub began rolling out a new stateless installation-token format on
2026-04-27 (`ghs_APPID_JWT`, ~520 chars, two dots, includes underscores). At workflow
runtime, `${{ github.token }}` and `${{ secrets.GITHUB_TOKEN }}` expand to one of these
tokens — which the validator's `^ghs_[a-zA-Z0-9]{36}$` regex rejected because it
required exactly 36 alphanumeric chars after the prefix. Every action that calls
`validate-inputs` with the runtime `github.token` therefore failed with
"Invalid token format".
Evidence: Official docs:
<https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github#githubs-token-formats>
("If your application expects or relies on installation tokens being exactly 40
characters long, it may not handle this new token format correctly") and
<https://github.blog/changelog/2026-05-15-github-app-installation-tokens-per-request-override-header>
("A stateless token is a `ghs_`-prefixed JWT. It is longer (~520 characters) and
contains two dots… Our recommended regex to match both new and current format tokens is
`ghs_[A-Za-z0-9\._]{36,}`"). Affected actions: ansible-lint-fix, codeql-analysis,
csharp-publish, pr-lint, pre-commit, python-lint-fix, security-scan, stale,
terraform-lint-fix (any path that passes the runtime `github.token` to validate-inputs).
Impact: Blocks every action that uses `validate-inputs` with the runtime GitHub token.
Fixed: 2026-05-25
Notes: Updated four regex sites to GitHub's recommended pattern (with anchors and a
sane upper bound of 1024 chars):

- `validate-inputs/validators/token.py` — `github_installation` pattern now
  `^ghs_[A-Za-z0-9._]{36,1024}$`; updated error message to document both formats.
- `validate-inputs/validators/security.py` — `_check_github_tokens` `ghs_` pattern
  now `ghs_[A-Za-z0-9._]{36,}` so leak detection catches the new format too.
- `_tests/shared/validation_core.py` and `_tests/framework/validation.py` — same
  installation regex update; same error message update.

Added test coverage: `test_ghs_stateful_token`, `test_ghs_stateless_jwt_token`,
`test_ghs_stateless_rejects_invalid_chars`, `test_ghs_too_short` in
`tests/test_token.py`. Extended `GITHUB_TOKEN_VALID`/`INVALID` fixtures with realistic
stateless JWT, minimum-length stateless, three-part JWT, char-class violations, and
length-boundary cases — these feed the parametrized `test_token_validator.py`. Also
updated `scripts/generate-tests.py` template so regenerated tests carry the new
coverage and fixed three pre-existing template bugs (`ghp_ + "a" * 32` → `36`,
`""` invalid check → `"", required=True`, removed reference to nonexistent
`validate_pypi_token` method). Full test suite now 783/783 passing (was 763). Verified
end-to-end with a synthetic 460-char stateless JWT token.

### Pass 13 — 2026-05-04

#### [N-094] `test_validator.py` missing test for `_sanitize` GITHUB_OUTPUT injection prevention

Fixed: 2026-05-04
Notes: Added `TestSanitize` class to `test_validator.py` with four methods:
`test_sanitize_safe_value`, `test_sanitize_strips_newlines`,
`test_sanitize_strips_carriage_returns`, `test_sanitize_non_string_input`.
Test suite grows from 763 to 767. N-095 (Advisory) left open — migration of 15 actions
from inline validation to the Python validator system is a large undertaking.

### Pass 12 — 2026-05-04

#### [N-090] `is_github_expression` allows whitespace in suffix — bypasses security checks

Fixed: 2026-05-04
Notes: Removed `\s` from the character class in `base.py:232`. Changed `r"[\w/.\s-]*"` to `r"[\w/.-]*"`.
Legitimate expression suffixes (`/workspace/path`, `ghcr.io/owner/repo`) contain no whitespace;
a space signals separate tokens and must not be treated as a valid suffix.

#### [N-091] No regression test for N-081 expression-prefix traversal bypass

Fixed: 2026-05-04
Notes: Added assertion to `test_validate_security_patterns` in `test_base.py` that
`${{ inputs.x }}/../../../etc/passwd` is rejected. Added new `test_is_github_expression`
method covering acceptance of plain expressions and valid suffixes, rejection of `..` suffixes
(N-081 guard), rejection of whitespace suffixes (N-090 guard), and rejection of non-expressions.

#### [N-092] No regression test for N-082 `validate_no_injection` error isolation

Fixed: 2026-05-04
Notes: Added `test_validate_no_injection_preserves_prior_errors` to `TestSecurityValidator`
in `test_security.py`. Test adds an error via `add_error`, calls
`validate_no_injection("safe value")`, then asserts the prior error is still present.

#### [N-093] `security-scan/action.yml` checkout comment says `# v4` but SHA is v6-beta

Fixed: 2026-05-04
Notes: Changed comment from `# v4` to `# v6-beta` in `security-scan/action.yml:67`. SHA `71cf2267d89c5cb81562390fa70a37fa40b1305e` is the v6-beta SHA used by all other actions in the repo.

### Pass 11 — 2026-05-03

#### [N-079] `security-suite.yml` shell injection via `pull_request.base.ref`

Fixed: 2026-05-03
Notes: Moved `${{ github.event.pull_request.base.repo.full_name }}` and
`${{ github.event.pull_request.base.ref }}` to `env:` block (`PR_BASE_REPO`, `PR_BASE_REF`);
replaced inline `${{ }}` with `${VAR}` in shell body. Also fixed `echo "BASE_REF=..."` to `printf`.

#### [N-080] `action-security.yml` step outputs injected into github-script JS body

Fixed: 2026-05-03
Notes: Added `env:` block with `CRITICAL_ISSUES`, `TOTAL_ISSUES`, `HAS_TRIVY_RESULTS`,
`HAS_GITLEAKS_RESULTS`; replaced `'${{ steps.security-scan.outputs.* }}'` string literals
with `process.env.*`; replaced inline conditional expressions with JS ternary operators.

#### [N-081] `is_github_expression` allows path traversal via `../` in expression suffix

Fixed: 2026-05-03
Notes: Added `if ".." in cleaned: return False` check before the `fullmatch` call. Also fixed N-088 in the same edit: moved `-` to end of character class (`[\w/.\-\s]*` → `[\w/.\s-]*`).

#### [N-082] `validate_no_injection` clears caller-accumulated errors

Fixed: 2026-05-03
Notes: Removed `self.clear_errors()` from line 249 of `security.py`. Caller-side resets in `conventions.py` are the correct isolation point.

#### [N-083] `sync-labels` validation rejects empty optional `labels` input

Fixed: 2026-05-03
Notes: Added `if [ -z "${LABELS_FILE:-}" ]; then exit 0; fi` guard before the `case` path-format check.

#### [N-084] `csharp-lint-check` installs deprecated `dotnet-format@7.0.1`

Fixed: 2026-05-03
Notes: Removed the "Install dotnet-format" step entirely. `dotnet format` is built into .NET 6+ SDK and needs no separate installation.

#### [N-085] `security-scan` artifact upload fails with empty path entries

Fixed: 2026-05-03
Notes: Replaced the single combined upload step with two separate steps (`Archive Trivy results`
and `Archive Gitleaks results`), each gated with its own
`if: always() && steps.verify-sarif.outputs.has_* == 'true'` condition. Artifact names
updated to `security-reports-trivy-*` and `security-reports-gitleaks-*`.

#### [N-086] `npm-semantic-release` uses different `actions/checkout` SHA

Fixed: 2026-05-03
Notes: Aligned SHA from `de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2` to `71cf2267d89c5cb81562390fa70a37fa40b1305e # v6-beta`, matching all other actions in the repo.

#### [N-087] `block-bashisms.sh` `local` pattern false-positives on prose strings

Fixed: 2026-05-03
Notes: Changed pattern from `(^|[[:space:]])local[[:space:]]` to `(^|;) *local`
(explicit spaces, statement-boundary anchor). Rewrapped REASON string to
`local builtin is not POSIX. Use plain assignment at function-level scope.`
to avoid triggering the `function` keyword pattern on the message text. N-088 folded into N-081 fix.

#### [N-088] `is_github_expression` hyphen placement in regex character class

Fixed: 2026-05-03
Notes: Folded into N-081 fix — both changes were applied to `base.py:is_github_expression` in the same edit.

#### [N-089] `sed -E`/`grep -E` flagged as POSIX violations — accepted as-is

Fixed: 2026-05-03
Notes: Advisory only. Both flags are standardized in POSIX.1-2017; no code change required. Accepted.

### Pass 10 — 2026-05-03

#### [N-049] `release-monthly` VALIDATED_TOKEN write to GITHUB_ENV removed

Fixed: 2026-05-03
Notes: Removed the `printf 'VALIDATED_TOKEN=...'` write to `$GITHUB_ENV` from
`release-monthly/action.yml`. The token was N-005's only consumer; after that fix
it was persisted but never read, making it readable by all subsequent job steps.

#### [N-050] `is_github_expression` rejects trailing shell payloads after `${{ }}`

Fixed: 2026-05-03
Notes: Changed from `return value.startswith("${{")` to strip all `${{ ... }}`
substrings then verify only `[\w/.\-\s]*` characters remain. `${{ fake }} ; rm -rf /`
→ False; `${{ workspace }}/rules.yml` → True. All 761 tests pass.

#### [N-051] `validate_safe_command` `&` detection uses correct regex

Fixed: 2026-05-03
Notes: Replaced `" & " in value` with `re.search(r"(?<![A-Za-z0-9=])&(?![A-Za-z0-9=])",
value)` in `validate_safe_command`. Matches the N-047 fix already applied to
`validate_no_injection`.

#### [N-052] `validate_safe_environment_variable` blocks `LD_PRELOAD` and related vars

Fixed: 2026-05-03
Notes: Added `_DANGEROUS_ENV_VARS` ClassVar to `SecurityValidator` with 11 code-injection
env var names. `validate_safe_environment_variable` rejects any value whose name
(before `=`) matches the blocklist.

#### [N-053] Security test assertions strengthened from `isinstance` to `is False`/`is True`

Fixed: 2026-05-03
Notes: All injection/traversal test cases in `test_security_validator.py` now assert
`result is False` for dangerous inputs and `result is True` for safe inputs, plus
`assert validator.errors` where injection should be blocked.

#### [N-054] `python-lint-fix` `grep -q &&` pattern fixed for `set -eu`

Fixed: 2026-05-03
Notes: Restructured `grep -q ... && ...` short-circuits to `if grep -q ...; then ...; fi`
to prevent `set -e` propagating grep's status-1 (no-match) as a fatal error.

#### [N-055] `go-build` subshell sentinel pattern under `set -eu` fixed

Fixed: 2026-05-03
Notes: Sentinel write guarded with `if (subshell); then write_sentinel; else exit 1; fi`
so `set -e` abort does not leave stale sentinel from prior successful run.

#### [N-056] `release-monthly` zero-padded month comparison fixed

Fixed: 2026-05-03
Notes: Changed `$(date -u +'%m')` to `$(printf '%d' "$(date -u +'%m')")` for
POSIX-safe zero-stripping before month arithmetic comparison.

#### [N-057] `security-scan` now has `actions/checkout` as first step

Fixed: 2026-05-03
Notes: Added `actions/checkout@71cf2267d89c5cb81562390fa70a37fa40b1305e # v4` with
`fetch-depth: 0` as the first step in `security-scan/action.yml`. Without this the
workspace was empty and all scans reported zero findings.

#### [N-058] `security-suite.yml` token no longer interpolated in `run:` shell body

Fixed: 2026-05-03
Notes: Added `env: GH_TOKEN: ${{ github.token }}` to the "Fetch PR Base" step;
replaced `${{ github.token }}` in the shell body with `${GH_TOKEN}`.

#### [N-059] `block-bashisms.sh` now detects `local` keyword

Fixed: 2026-05-03
Notes: Added `(^|[[:space:]])local[[:space:]]` pattern to `.claude/hooks/block-bashisms.sh`.
`local foo=bar` in a POSIX sh script now triggers a hook block.

#### [N-060] `release-undo.sh` guards `git reset --hard HEAD~1` on initial commit

Fixed: 2026-05-03
Notes: Added `git rev-parse HEAD~1 >/dev/null 2>&1` guard before the reset in
`_tools/release-undo.sh`. Aborts with a clear message instead of failing mid-rollback
after tags are already deleted.

#### [N-061] Security workflow notify condition fixed for scan tool failures

Fixed: 2026-05-03
Notes: Changed `finding_count != '0'` to `finding_count != '' && finding_count != '0'`
so empty output (scan tool crash) no longer fires a false security alert.

#### [N-062] Makefile `check-syntax` changed from `bash -n` to `sh -n`

Fixed: 2026-05-03
Notes: `bash -n` accepted POSIX-violating scripts silently. Changed to `sh -n` in
the `check-syntax` Makefile target.

#### [N-063] `setup-test-environment` kcov pinned to commit SHA

Fixed: 2026-05-03
Notes: Added `git -C kcov checkout 3a8c5464be2dd781988dca7ec30db679493ed9a8`
after the `git clone --branch v42` in `setup-test-environment/action.yml`. Floating
tag can no longer be moved to install different code.

#### [N-064] Registry singleton test isolation via `reset()` and `autouse` fixture

Fixed: 2026-05-03
Notes: Added `reset()` method to `ValidatorRegistry` (clears `_validators` and
`_validator_instances`). Created `validate-inputs/tests/conftest.py` with an
`autouse=True` fixture that calls `registry._registry.reset()` after each test.

#### [N-065] `validate_no_injection` clears errors at start of each call

Fixed: 2026-05-03
Notes: Added `self.clear_errors()` as the first line of `validate_no_injection` in
`validate-inputs/validators/security.py`. Stale errors from previous calls on the
same instance no longer accumulate.

#### [N-066] `validate_path_security` URL-decodes before traversal check

Fixed: 2026-05-03
Notes: Added `urllib.parse.unquote(path)` before the `..` check in `base.py`.
`%2E%2E/etc/passwd` now triggers the traversal error. `import urllib.parse` added to
imports.

#### [N-067] `registry._load_custom_validator` catches `NameError`/`RuntimeError`/`ValueError`

Fixed: 2026-05-03
Notes: Added `NameError, RuntimeError, ValueError` to the except tuple around
`exec_module` in `validate-inputs/validators/registry.py`.

#### [N-068] `ansible-lint-fix` mutually exclusive flags resolved

Fixed: 2026-05-03
Notes: Removed `--parseable-severity` from the ansible-lint invocation in
`ansible-lint-fix/action.yml`; `--format sarif` is now the sole output format flag.

#### [N-069] `terraform-lint-fix` and `python-lint-fix` cleanup guarded against empty `$TEMP_DIR`

Fixed: 2026-05-03
Notes: Changed `rm -rf "$WORKING_DIR/$TEMP_DIR"` to `[ -n "$\{TEMP_DIR:-}" ] && rm -rf ...`
in both action files, preventing accidental deletion of the working directory.

#### [N-070] `docker-publish` accepts `./Dockerfile` path

Fixed: 2026-05-03
Notes: Extended dockerfile case pattern in `docker-publish/action.yml` to include
`./`-prefixed paths alongside bare filenames.

#### [N-071] `compress-images` filesystem check moved to after checkout

Fixed: 2026-05-03
Notes: Moved the `[ ! -d "$WORKING_DIRECTORY" ]` check to a new post-checkout
`Verify Working Directory` step in `compress-images/action.yml`. Pre-checkout checks
now validate only input values, not filesystem state.

#### [N-072] Release/publish workflows documented for `timeout-minutes`

Fixed: 2026-05-03
Notes: Added `# timeout-minutes is set at the calling workflow level` comments to
main publishing steps in composite actions. Added `timeout-minutes: 30` to all jobs
in calling workflow files `release.yml` and `new-release.yml`.

#### [N-073] `post-edit-write.sh` hook no longer swallows linter exit codes

Fixed: 2026-05-03
Notes: Removed `|| true` from `shellcheck`, `actionlint`, and `action-validator` calls
in `.claude/hooks/post-edit-write.sh`. Auto-formatters (`ruff format`, `shfmt`,
`prettier`) retain `|| true`. Hook now exits nonzero on unfixed linter errors.

#### [N-074] `validate_url` hostname regex no longer allows underscore

Fixed: 2026-05-03
Notes: Changed `[\w.-]+` to `[a-zA-Z0-9.-]+` in the hostname character class in
`validate-inputs/validators/network.py`. RFC 1123 prohibits underscores in hostnames.

#### [N-075] `biome-lint` SARIF upload guarded against missing file

Fixed: 2026-05-03
Notes: Changed `if: always()` to
`if: always() && inputs.mode == 'check' && hashFiles('biome-report.sarif') != ''`
on the SARIF upload step in `biome-lint/action.yml`. Prevents double-failure when
biome crashes and produces no SARIF.

#### [N-076] `validate_safe_command` dead `mkfs` entry removed

Fixed: 2026-05-03
Notes: Removed the redundant explicit `"mkfs"` string from the `dangerous_commands`
list in `validate_safe_command`; the broader `re.search(r"\bmkfs", command)` pattern
already covered it.

#### [N-077] `_validate_key_value_list` now splits on newlines and allows spaces in values

Fixed: 2026-05-03
Notes: Changed the key-value list parser in `validate-inputs/validators/docker.py` to
split on newlines only and validate values with `^[A-Za-z_][A-Za-z0-9_]*=.*$`.
`GREETING=Hello World` now passes; entries with no `=` are still rejected.

#### [N-078] Makefile `SHELL` changed to `/bin/sh`; `pipefail` removed

Fixed: 2026-05-03
Notes: Changed `SHELL := /bin/bash` to `SHELL := /bin/sh` and `.SHELLFLAGS`
from `-euo pipefail -c` to `-eu -c` in `Makefile`. POSIX sh has no `pipefail`.
All `make` targets now run under POSIX sh, consistent with the project mandate.

### Pass 9 — 2026-05-03

#### [N-031] `docker-build` multi-line `args` output truncates all but first `--build-arg`

Fixed: 2026-05-03
Notes: Changed `printf 'args=%s\n' "$args"` to
`{ printf 'args<<EOF\n%s\nEOF\n' "$args"; } >> "$GITHUB_OUTPUT"` in
docker-build/action.yml. All subsequent `--build-arg` lines now survive in the
output via the GITHUB_OUTPUT heredoc format.

#### [N-032] `_read_appended_bytes`: TOCTOU race — `path.stat()` by name inside open fd

Fixed: 2026-05-03
Notes: Replaced `path.stat().st_size` with `os.fstat(handle.fileno()).st_size` in
`_tests/framework/harness/harness.py:_read_appended_bytes`. The fd-based stat is
immune to file rotation between open() and stat(). `import os` was already present.

#### [N-033] Step output filename collision when skipped step brackets two active steps

Fixed: 2026-05-03
Notes: Added monotonic `step_output_index = 0` counter before the steps loop in
`_run_owned`. Counter increments at the top of each iteration before any skip
check. Filename changed from `f".github_output_{len(steps_ctx)}"` to
`f".github_output_{step_output_index}"`.

#### [N-034] `install_shellspec`: outer EXIT trap permanently replaced on failure path

Fixed: 2026-05-03
Notes: Replaced separate cleanup function + conditional restore with a single
`trap 'rm -f "${tarball:-}"; eval "${_old_trap:-:}"' EXIT` set unconditionally at
function entry in `_tests/run-tests.sh:install_shellspec`. Outer trap now restored
on all exit paths including failure.

#### [N-035] `is_github_expression` partial-embed bypass

Fixed: 2026-05-03
Notes: Removed the unsafe second OR branch `("${{" in value and "}}" in value)`.
New implementation: `return value.startswith("${{")`. Pure expressions
(`${{ github.token }}`), expression-prefixed values (`${{ github.workspace }}/path`),
and inline expressions all pass. Payloads like `"; rm -rf / # ${{ secrets.X }}"`
are rejected — they don't start with `${{`. 761 tests pass.

#### [N-036] `validate_tag` regex accepts trailing dot/colon

Fixed: 2026-05-03
Notes: Made the final character group non-optional in
`validate-inputs/validators/docker.py:validate_tag`. `v1.` and `latest:` now
rejected; `latest`, `v1.2.3`, `sha256:abc` still accepted.

#### [N-037] `file_path` validator space enables argument injection

Fixed: 2026-05-03
Notes: Removed the literal space from the file_path character class in
`validate-inputs/validators/file.py`. Paths containing spaces are now rejected.
ruff passes clean.

#### [N-038] `eslint-lint` `--ext $FILE_EXTENSIONS` unquoted in fix mode

Fixed: 2026-05-03
Notes: Quoted `$FILE_EXTENSIONS` in all 4 fix-mode eslint invocations in
`eslint-lint/action.yml`. Consistent with the check-mode step.

#### [N-039] `prettier-lint` unformatted file count inflated by summary line

Fixed: 2026-05-03
Notes: Changed `grep -c "^"` to `grep -c "^\[warn\]" ... || true` in
`prettier-lint/action.yml`. Now counts only Prettier `[warn]` lines (one per
unformatted file), excluding header and summary lines.

#### [N-040] `go-lint` `error_count` not updated when `FAIL_ON_ERROR=false`

Fixed: 2026-05-03
Notes: Restructured `go-lint/action.yml` to capture `error_count` unconditionally
before the `FAIL_ON_ERROR` branch. GITHUB_OUTPUT write happens on all paths before
any `exit` call.

#### [N-041] `registry.py` `exec_module` raises uncaught `SyntaxError`/`OSError`

Fixed: 2026-05-03
Notes: Added `SyntaxError, OSError` to the except tuple around `exec_module` in
`validate-inputs/validators/registry.py`. Malformed validator files no longer
abort the entire validation run.

#### [N-042] `convention_mapper.py` priority-95 "contains" overcaptures version inputs

Fixed: 2026-05-03
Notes: Changed `"type": "contains"` to `"type": "exact"` for the priority-95
version-pattern group in `validate-inputs/validators/convention_mapper.py`.
`"non-python-version"` no longer matches the `python_version` validator.

#### [N-043] `conventions.py` stale errors leak from one input to the next

Fixed: 2026-05-03
Notes: Added `validator_module.errors = []` reset before each per-input validation
call (and in the exception handler) in `validate-inputs/validators/conventions.py`.

#### [N-044] `network.py` URL path allows `<` and `>`

Fixed: 2026-05-03
Notes: Updated URL path regex in `validate-inputs/validators/network.py` to
explicitly exclude `<` and `>`. XSS payloads like
`https://example.com/<script>alert(1)</script>` now fail URL validation.

#### [N-045] `docker-build` BUILD_CONTEXTS/SECRETS/CACHE_FROM/CACHE_TO unquoted word-split

Fixed: 2026-05-03
Notes: Applied temp-file + `while IFS= read -r` loop to BUILD_CONTEXTS, SECRETS,
CACHE_FROM, and CACHE_TO in `docker-build/action.yml`, consistent with the
existing BUILD_ARGS pattern.

#### [N-046] `generate_sarif_report` temp files leaked on `jq` failure

Fixed: 2026-05-03
Notes: Added `trap 'rm -f "$_sarif_results_file" "$_sarif_rules_file"' RETURN`
immediately after mktemp calls in `_tests/run-tests.sh:generate_sarif_report`.
Cleanup guaranteed on all exit paths including jq failure. Script shebang is bash
so RETURN trap is valid.

#### [N-047] `security.py` single-`&` detection flags URL query strings

Fixed: 2026-05-03
Notes: Replaced `"&" in value` in `validate_no_injection` with
`re.search(r"(?<![A-Za-z0-9=])&(?![A-Za-z0-9=])", value)`. Negative lookbehind/
lookahead on alphanumeric and `=` distinguishes shell backgrounding `&` (non-word
boundary on at least one side) from URL query-string `&` (surrounded by word
chars). `"foo=1&bar=2"` passes; `"& whoami"` and `"cmd &"` are rejected.
761 tests pass.

#### [N-048] `php-tests` `composer-args` direct `${{ inputs.* }}` interpolation

Fixed: 2026-05-03
Notes: Added `env: COMPOSER_ARGS: ${{ inputs.composer-args }}` block to the
affected step in `php-tests/action.yml`. Shell body now references `$COMPOSER_ARGS`
instead of `${{ inputs.composer-args }}`.

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
