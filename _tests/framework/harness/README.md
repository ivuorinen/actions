# Composite-Step Harness

Test harness for composite GitHub Action `run:` steps. Lets ShellSpec specs
execute real action code against a real `$GITHUB_OUTPUT` with mocked external
commands.

## Spec-author API (bash)

Sourced automatically by `_tests/unit/spec_helper.sh`.

- `run_step <action-dir> <step-id>` — execute one `run:` step.
- `run_all_owned_steps <action-dir>` — execute every `run:` step in order,
  honoring `if:`. Skips `uses:` steps.
- `mock_command <cmd> <argv-glob> <stdout> [exit=0]` — register a shell stub
  for an external command. Glob is `fnmatch` against the joined argv. First
  registered glob that matches wins.
- `expect_output <key> <value>` — assert `key=value` is present as a whole
  line in `$GITHUB_OUTPUT`.
- `harness_reset` — clear per-test session state. Call this from `BeforeEach`
  and `AfterEach`.

## Example

    Describe "release-monthly"
      It "bumps the patch when a release exists for the current month"
        shellspec_setup_test_env "release-monthly"
        harness_reset
        export INPUT_TOKEN="ghp_fixture_0000000000000000000000000000"
        export INPUT_PREFIX="v"
        export INPUT_DRY_RUN="true"

        mock_command gh "release list --limit 1*" "v2026.4.0"
        mock_command gh "release create*"        ""

        When call run_step "release-monthly" "create-release"
        The status should be success
        Assert expect_output release_tag "v2026.4.1"
      End
    End

## Supported expression subset

`${{ inputs.X }}`, `${{ steps.X.outputs.Y }}`, `${{ github.X }}`,
`${{ env.X }}`, string literals, `||` (default fallback), `==`, `!=`.

Anything else raises `UnsupportedExpressionError` and fails the test loudly.

## PATH restriction

When the harness executes a step, it restricts `$PATH` to
`<mock-dir>:/usr/bin:/bin:/usr/sbin:/sbin`. Standard coreutils stay available
(`sh`, `printf`, `grep`, `awk`, etc.), but external tools like `gh`, `git`,
`docker`, `kubectl` are absent unless registered via `mock_command`. Steps
that rely on these tools without a mock fail with a "not found" error, not
silently.

## Fixture tests

`_tests/fixtures/harness/` contains three toy actions used by
`_tests/unit/_harness/harness.spec.sh` as the harness's regression bed. If
those stay green, `run_step` on real actions is trustworthy.
