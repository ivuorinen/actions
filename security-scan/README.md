# ivuorinen/actions/security-scan

## Description

Comprehensive security scanning for GitHub Actions including actionlint,
Gitleaks (optional), and Trivy vulnerability scanning. Requires
'security-events: write' and 'contents: read' permissions in the workflow.

## Inputs

| parameter          | description                                           | required | default            |
|--------------------|-------------------------------------------------------|----------|--------------------|
| gitleaks-license   | Gitleaks license key (required for Gitleaks scanning) | `false`  |                    |
| gitleaks-config    | Path to Gitleaks config file                          | `false`  | .gitleaks.toml     |
| trivy-severity     | Severity levels to scan for (comma-separated)         | `false`  | CRITICAL,HIGH      |
| trivy-scanners     | Types of scanners to run (comma-separated)            | `false`  | vuln,config,secret |
| trivy-timeout      | Timeout for Trivy scan                                | `false`  | 10m                |
| actionlint-enabled | Enable actionlint scanning                            | `false`  | true               |
| token              | GitHub token for authentication                       | `false`  |                    |

## Outputs

| parameter            | description                                  |
|----------------------|----------------------------------------------|
| has_trivy_results    | Whether Trivy scan produced valid results    |
| has_gitleaks_results | Whether Gitleaks scan produced valid results |
| total_issues         | Total number of security issues found        |
| critical_issues      | Number of critical security issues found     |

## Runs

This action is a `composite` action.
