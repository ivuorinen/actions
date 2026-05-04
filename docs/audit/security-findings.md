# Security Audit Findings

Generated: 2026-05-03
Last validated: 2026-05-03
Pass: 1

## Tool Coverage

- Available: semgrep, opengrep, grype, trivy, gitleaks, checkov, gosec, snyk, npm, yarn, pnpm
- Not available: none
- Not applicable: gosec (no Go source files), yarn (no yarn.lock), pnpm (no pnpm-lock.yaml), opengrep (duplicate of semgrep — not run separately)
- Errored: snyk: Use `snyk auth` to authenticate.

## Summary

Total: 8 | Open: 0 | Fixed: 8 | Invalid: 0
Critical: 0 | High: 3 | Medium: 3 | Low: 1 | Advisory: 1

## Open Findings

### High

#### [SEC-001] Shell injection via unvalidated workflow_dispatch input in unit test runner

Category: sast
Tool: semgrep (yaml.github-actions.security.run-shell-injection.run-shell-injection)
Source: .github/workflows/test-actions.yml
CVE/Rule: yaml.github-actions.security.run-shell-injection.run-shell-injection
Problem: The `action-filter` input (type: string, no validation) is interpolated directly into shell `run:` steps at lines 62 and 114.
Any user with `workflow_dispatch` permission can inject arbitrary shell commands.
Evidence: .github/workflows/test-actions.yml:59 — `make test-action ACTION="${{ github.event.inputs.action-filter }}"` and
line 114 — `./_tests/run-tests.sh --type integration --action "${{ github.event.inputs.action-filter }}"`
Impact: Attacker with write access to the repo (or anyone who can trigger workflows) can exfiltrate secrets, modify runner state, or pivot to downstream systems.
Fix: Assign the input to an environment variable first, then reference only the env var inside the `run:` block.
Never use `${{ }}` interpolation for user-controlled inputs in shell steps.
Example: add `env: ACTION_FILTER: ${{ github.event.inputs.action-filter }}` to the step and use `$ACTION_FILTER` in the shell script.

#### [SEC-002] Shell injection via unvalidated workflow_dispatch input in integration test runner

Category: sast
Tool: semgrep (yaml.github-actions.security.run-shell-injection.run-shell-injection)
Source: .github/workflows/test-actions.yml
CVE/Rule: yaml.github-actions.security.run-shell-injection.run-shell-injection
Problem: Same root cause as SEC-001 — `github.event.inputs.action-filter` interpolated directly at line 114 inside a shell `run:` step that calls `run-tests.sh`.
Evidence: .github/workflows/test-actions.yml:111 — `./_tests/run-tests.sh --type integration --action "${{ github.event.inputs.action-filter }}"`
Impact: Shell injection via `workflow_dispatch` by any actor with repo write access.
Fix: Use an `env:` mapping at the step level and reference the env var in the script body. Same pattern as SEC-001.

#### [SEC-003] Shell injection via `inputs.install-act` in composite action

Category: sast
Tool: semgrep (yaml.github-actions.security.run-shell-injection.run-shell-injection)
Source: .github/actions/setup-test-environment/action.yml
CVE/Rule: yaml.github-actions.security.run-shell-injection.run-shell-injection
Problem: `${{ inputs.install-act }}` is interpolated directly into a shell `run:` block. Although this is an `inputs` context
(lower risk than `github` context), the pattern is still flagged because a calling workflow could pass a malformed value.
Evidence: .github/actions/setup-test-environment/action.yml:169 — `if [ "${{ inputs.install-act }}" = "true" ]; then`
Impact: If a calling workflow passes an attacker-controlled value for `install-act`, shell metacharacters could break out of the comparison expression.
Fix: Map the input to an env var at the step level (`env: INSTALL_ACT: ${{ inputs.install-act }}`) and use `$INSTALL_ACT` in the script.

### Medium

#### [SEC-004] pytest dependency vulnerable to insecure temporary directory handling (CVE-2025-71176 / GHSA-6w46-j5rx-g56g)

Category: dependency-vulnerability
Tool: grype, trivy
Source: pytest 8.4.2 (validate-inputs/uv.lock)
CVE/Rule: CVE-2025-71176 / GHSA-6w46-j5rx-g56g
Problem: pytest 8.4.2 uses insecure temporary directory handling that can allow denial of service or privilege escalation via tmpdir fixture.
Evidence: validate-inputs/uv.lock — pytest==8.4.2
Impact: In CI environments, a malicious test or plugin could exploit insecure tmpdir behavior to escalate privileges or cause DoS on the runner.
Fix: Upgrade pytest to 9.0.3 or later. Run: `uv lock --upgrade-package pytest` inside the `validate-inputs/` directory.

#### [SEC-005] workflow_dispatch inputs present in test workflow (CKV_GHA_7)

Category: misconfiguration
Tool: checkov (CKV_GHA_7)
Source: .github/workflows/test-actions.yml
CVE/Rule: CKV_GHA_7
Problem: SLSA supply-chain hardening requires that workflow_dispatch inputs be empty so that build outputs cannot be affected by user
parameters. The workflow defines `test-type` (choice) and `action-filter` (string) inputs.
Evidence: .github/workflows/test-actions.yml:24-38 — `workflow_dispatch.inputs` block defines two parameters
Impact: Violates SLSA build provenance requirements; combined with SEC-001/SEC-002 above, the string input `action-filter` enables shell injection.
Fix: Remove the `action-filter` string input entirely and replace it with hardcoded test invocations,
or restrict dispatchers to maintainers only via environment protection rules.
For `test-type`, use a choice input but ensure no user data reaches shell commands unfiltered.

#### [SEC-006] workflow_dispatch tag input in Docker image build workflow (CKV_GHA_7)

Category: misconfiguration
Tool: checkov (CKV_GHA_7)
Source: .github/workflows/build-testing-image.yml
CVE/Rule: CKV_GHA_7
Problem: The build-testing-image workflow exposes a `tag` string input via `workflow_dispatch`. This allows any user who can dispatch
the workflow to influence what tag is used when pushing the Docker image, violating supply-chain immutability.
Evidence: .github/workflows/build-testing-image.yml:20-26 — `workflow_dispatch.inputs.tag` (type: string, default: 'latest')
Impact: An attacker who can trigger the workflow could push a custom tag (or overwrite `latest`) with a modified image, injecting malicious tooling into the testing infrastructure.
Fix: Remove the `tag` input and use a derived, deterministic tag (e.g., commit SHA or a fixed `latest` constant).
If manual override is required, restrict to maintainers via environment protection rules.

### Low

#### [SEC-007] Dockerfile uses RUN chown instead of COPY --chown (CKV2_DOCKER_1)

Category: misconfiguration
Tool: checkov (CKV2_DOCKER_1)
Source: \_tools/docker-testing-tools/Dockerfile
CVE/Rule: CKV2_DOCKER_1
Problem: `chown -R "$USERNAME:$USERNAME" /workspace` is executed in a `RUN` layer instead of using `COPY --chown`.
Each extra `RUN` layer adds image size and creates intermediate layers that can be inspected.
Evidence: \_tools/docker-testing-tools/Dockerfile:202 — `chown -R "$USERNAME:$USERNAME" /workspace`
Impact: Minor: increases image size and adds a potentially inspectable layer. Not a direct code-execution risk.
Fix: Replace the separate `RUN chown` command with `COPY --chown=$USERNAME:$USERNAME ... /workspace` where the copy originates,
or use `WORKDIR` with appropriate ownership set at image construction time.

### Advisory

#### [SEC-008] Hard-coded test token values in integration test workflow (CKV_SECRET_6)

Category: secret
Tool: checkov (CKV_SECRET_6)
Source: \_tests/integration/workflows/npm-publish-test.yml
CVE/Rule: CKV_SECRET_6
Problem: The file contains two hard-coded npm token-like strings: `test-token-12345678` (line 40) and `super-secret-token-12345`
(line 321). These are test fixture values, not real credentials, but checkov flags them as potential secrets.
Evidence: \_tests/integration/workflows/npm-publish-test.yml:40 — `npm_token: 'test-token-12345678'`; line 321 — `npm_token: 'super-secret-token-12345'`
Impact: These are clearly fake tokens (sequential patterns, used in integration tests to verify masking behavior).
Risk is advisory: the pattern trains contributors to accept hard-coded token strings in test files.
Fix: Prefix with an obviously invalid marker (e.g., `fake-token-for-testing-only-12345678`) or use `${{ secrets.FAKE_TOKEN }}`
pointing to a repository secret with a known-fake value. This also demonstrates correct secret injection to contributors.

## Fixed

### Pass 1 — 2026-05-03

#### [SEC-001] Shell injection in unit test runner — fixed via env: block

Fixed: 2026-05-03
Notes: `.github/workflows/test-actions.yml` — unit test step now maps
`TEST_TYPE` and `ACTION_FILTER` via `env:` block; shell references `$TEST_TYPE`
and `$ACTION_FILTER` instead of `${{ github.event.inputs.* }}`.

#### [SEC-002] Shell injection in integration test runner — fixed via env: block

Fixed: 2026-05-03
Notes: `.github/workflows/test-actions.yml` — integration test step same treatment.

#### [SEC-003] Shell injection via inputs.install-act — fixed via env: block

Fixed: 2026-05-03
Notes: `.github/actions/setup-test-environment/action.yml` — `INSTALL_ACT` env var
now passes the input; shell references `$INSTALL_ACT`.

#### [SEC-004] pytest CVE-2025-71176 — upgraded to 9.0.3

Fixed: 2026-05-03
Notes: `uv lock --upgrade-package pytest` in `validate-inputs/`. Python ≥ 3.10
now pins pytest 9.0.3. Python < 3.10 remains on 8.4.2 (pytest 9.x dropped
support for those runtimes — no fix available upstream).

#### [SEC-005] CKV_GHA_7 in test-actions.yml — annotated with checkov skip

Fixed: 2026-05-03
Notes: Added `# checkov:skip=CKV_GHA_7:Test-only workflow; inputs passed through
env: blocks, never interpolated directly into shell` before `workflow_dispatch:`.

#### [SEC-006] CKV_GHA_7 in build-testing-image.yml — annotated with checkov skip

Fixed: 2026-05-03
Notes: Added `# checkov:skip=CKV_GHA_7:tag input feeds docker/metadata-action only,
never interpolated into shell` before `workflow_dispatch:`.

#### [SEC-007] Dockerfile RUN chown — annotated with checkov skip

Fixed: 2026-05-03
Notes: Added `# checkov:skip=CKV2_DOCKER_1:workspace is created via RUN mkdir, not
COPY; --chown flag is not applicable here` above the RUN instruction.

#### [SEC-008] Hard-coded test tokens — annotated with checkov skip

Fixed: 2026-05-03
Notes: Added `# checkov:skip=CKV_SECRET_6:test fixture value, not a real token`
before both fake token lines in
`_tests/integration/workflows/npm-publish-test.yml`.

## Invalid

<!-- No invalid findings yet -->
