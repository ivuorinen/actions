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
- Semgrep static analysis
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
5. Configure required security scanners:
   - Add `.gitleaks.toml` for Gitleaks configuration

## Required Secrets

> **Note**: `GITHUB_TOKEN` is automatically provided by GitHub Actions and does not require manual repository secret configuration.

The following table shows available secrets (auto-provisioned secrets are provided by GitHub, optional secrets require manual repository configuration):

| Secret Name         | Description                                                       | Requirement |
| ------------------- | ----------------------------------------------------------------- | ----------- |
| `GITHUB_TOKEN`      | GitHub token for workflow authentication (automatically provided) | Auto        |
| `GITLEAKS_LICENSE`  | License for Gitleaks scanning                                     | Optional    |
| `FIXIMUS_TOKEN`     | Enhanced token for automated fix PRs                              | Optional    |
| `SEMGREP_APP_TOKEN` | Token for Semgrep static analysis                                 | Optional    |

## Security Workflows

This repository includes several security-focused workflows:

1. **PR Security Analysis** (`security-suite.yml`)
   - Comprehensive security scanning on pull requests
   - Semgrep static analysis
   - Dependency vulnerability checks
   - Creates automated fix PRs

2. **Action Security** (`action-security.yml`)
   - Validates GitHub Action files
   - Checks for hardcoded credentials
   - Gitleaks secret scanning
   - Scans for vulnerabilities in action definitions

3. **CodeQL Analysis** (`codeql.yml` and `codeql-new.yml`)
   - Analyzes code for security issues
   - Runs on multiple languages (Python, JavaScript/TypeScript)
   - Automated on pushes and pull requests
   - SARIF report generation

4. **Dependency Review** (`dependency-review.yml`)
   - Reviews dependency changes in pull requests
   - Checks for known vulnerabilities
   - License compliance validation
   - Blocks PRs with critical vulnerabilities

## Security Reports

Security scan results are available as:

1. SARIF reports in GitHub Security tab
2. Artifacts in workflow runs
3. Automated issues for critical findings
4. Weekly trend reports
5. Security metrics dashboard

## Automated Fixes

The repository automatically:

1. Creates PRs for fixable vulnerabilities
2. Updates dependencies with security issues
3. Fixes code security issues
4. Creates detailed fix documentation

## Regular Reviews

We conduct:

1. Daily automated security scans
2. Weekly metrics analysis
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
