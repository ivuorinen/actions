# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

1. **Do Not** open a public issue
2. Email security concerns to <ismo@ivuorinen.net>
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours and work on a fix if validated.

## Security Measures

This repository implements:

- CodeQL scanning
- Opengrep static analysis (open-source fork of Semgrep CE)
- Gitleaks secret scanning
- Dependency Review
- MegaLinter code analysis
- Regular security updates
- Automated fix PRs
- Continuous security scanning on PRs

## Security Best Practices

When using these actions:

1. Pin to commit hashes instead of tags
2. Use least-privilege token permissions
3. Validate all inputs
4. Set appropriate timeouts
5. Configure security scanners:
   - Add `.gitleaks.toml` to customize Gitleaks rules (its default rules apply without one)

## Required Secrets

> **Note**: `GITHUB_TOKEN` is automatically provided by GitHub Actions and does
> not require manual repository secret configuration.

The workflows need no other secret:

| Secret Name    | Description                                                       | Requirement |
| -------------- | ----------------------------------------------------------------- | ----------- |
| `GITHUB_TOKEN` | GitHub token for workflow authentication (automatically provided) | Auto        |

## Security Workflows

This repository includes several security-focused workflows:

1. **PR Security Analysis** (`security-suite.yml`)
   - Runs OWASP Dependency Check, Opengrep static analysis and a TruffleHog secret scan on pull requests that change a
     `package.json`, `package-lock.json`, `Dockerfile`, or a `.py`, `.js`, `.yml` or `.yaml` file; a pull request that
     changes only other files, such as shell scripts, gets none of them
   - Posts a summary comment on the pull request
   - Fails on a critical finding, or when a scanner did not finish

2. **Action Security** (`action-security.yml`)
   - Runs security-scan on this repository, on pushes to `main`, pull requests and merge groups that change an action,
     a workflow or a scanner config
   - jactionlint checks the workflow files
   - Gitleaks scans the commits for secrets
   - Trivy scans the files for vulnerabilities, misconfigurations and secrets
   - Opens an issue when it finds critical issues

3. **CodeQL Analysis** (`codeql-new.yml`)
   - Runs this repository's `codeql-analysis` action for Actions workflows, JavaScript and Python
   - On pushes to `main`, pull requests, merge groups and weekly on Sundays
   - Uploads SARIF reports to code scanning

4. **Dependency Review** (the `pr-lint` action, run by `pr-lint.yml`)
   - Reviews the dependency changes of a pull request in this public repository and comments a summary
   - Fails the pull request on a dependency with a critical vulnerability

5. **OpenSSF Scorecard** (`scorecard.yml`)
   - Runs on pushes to `main` and weekly on Saturdays
   - Uploads its SARIF report to code scanning

## Security Reports

Security scan results are available as:

1. SARIF reports in the GitHub Security tab: security-scan's Trivy and Gitleaks reports, CodeQL and Scorecard
2. Artifacts in workflow runs: security-scan's reports and Scorecard's results
3. An issue for critical findings, opened by Action Security
4. Comments on pull requests from PR Security Analysis and Dependency Review

## Dependency Updates

Renovate opens pull requests for dependency and pin updates, and labels the ones that fix a known vulnerability
`security`.

## Regular Reviews

We conduct:

1. Scans of every pull request and push to `main`
2. Weekly scheduled scans: CodeQL on Sundays, Scorecard on Saturdays
3. Monthly suppression reviews
4. Regular dependency updates

## Contributing

When contributing to this repository:

1. Follow security best practices
2. Do not commit sensitive information
3. Use provided security tools
4. Review security documentation

## Support

For security-related questions:

1. Review existing security documentation
2. Check closed security issues
3. Contact security team at <ismo@ivuorinen.net>

Do not open public issues for security concerns.

## License

The security policy and associated tools are covered under the repository's MIT license.
