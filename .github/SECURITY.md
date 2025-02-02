# Security Policy

## Supported Versions

| Version | Supported          |
|---------| ------------------ |
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
- OWASP Dependency Check
- Snyk vulnerability scanning
- Gitleaks secret scanning
- Trivy vulnerability scanner
- MegaLinter code analysis
- Regular security updates
- Automated fix PRs
- Daily security scans
- Weekly metrics collection

## Security Best Practices

When using these actions:

1. Pin to commit hashes instead of tags
2. Use least-privilege token permissions
3. Validate all inputs
4. Set appropriate timeouts
5. Configure required security scanners:
   - Add `.gitleaks.toml` for Gitleaks configuration

## Required Secrets

The following secrets should be configured in your repository:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `SNYK_TOKEN` | Token for Snyk vulnerability scanning | Optional |
| `GITLEAKS_LICENSE` | License for Gitleaks scanning | Optional |
| `SLACK_WEBHOOK` | Webhook URL for Slack notifications | Optional |
| `SONAR_TOKEN` | Token for SonarCloud analysis | Optional |
| `FIXIMUS_TOKEN` | Token for automated fixes | Optional |

## Security Workflows

This repository includes several security-focused workflows:

1. **Daily Security Checks** (`security.yml`)
   - Runs comprehensive security scans
   - Creates automated fix PRs
   - Generates security reports

2. **Action Security** (`action-security.yml`)
   - Validates GitHub Action files
   - Checks for hardcoded credentials
   - Scans for vulnerabilities

3. **CodeQL Analysis** (`codeql.yml`)
   - Analyzes code for security issues
   - Runs on multiple languages
   - Weekly scheduled scans

4. **Security Metrics** (`security-metrics.yml`)
   - Collects security metrics
   - Generates trend reports
   - Weekly analysis

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
