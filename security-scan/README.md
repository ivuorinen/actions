# ivuorinen/actions/security-scan

## Security Scan

### Description

Comprehensive security scanning for GitHub Actions including actionlint,
Gitleaks (optional), and Trivy vulnerability scanning. Requires
'security-events: write' and 'contents: read' permissions in the workflow.

### Inputs

| name                 | description                                                  | required | default              |
|----------------------|--------------------------------------------------------------|----------|----------------------|
| `gitleaks-license`   | <p>Gitleaks license key (required for Gitleaks scanning)</p> | `false`  | `""`                 |
| `gitleaks-config`    | <p>Path to Gitleaks config file</p>                          | `false`  | `.gitleaks.toml`     |
| `trivy-severity`     | <p>Severity levels to scan for (comma-separated)</p>         | `false`  | `CRITICAL,HIGH`      |
| `trivy-scanners`     | <p>Types of scanners to run (comma-separated)</p>            | `false`  | `vuln,config,secret` |
| `trivy-timeout`      | <p>Timeout for Trivy scan</p>                                | `false`  | `10m`                |
| `actionlint-enabled` | <p>Enable actionlint scanning</p>                            | `false`  | `true`               |
| `token`              | <p>GitHub token for authentication</p>                       | `false`  | `""`                 |

### Outputs

| name                   | description                                         |
|------------------------|-----------------------------------------------------|
| `has_trivy_results`    | <p>Whether Trivy scan produced valid results</p>    |
| `has_gitleaks_results` | <p>Whether Gitleaks scan produced valid results</p> |
| `total_issues`         | <p>Total number of security issues found</p>        |
| `critical_issues`      | <p>Number of critical security issues found</p>     |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/security-scan@main
  with:
    gitleaks-license:
    # Gitleaks license key (required for Gitleaks scanning)
    #
    # Required: false
    # Default: ""

    gitleaks-config:
    # Path to Gitleaks config file
    #
    # Required: false
    # Default: .gitleaks.toml

    trivy-severity:
    # Severity levels to scan for (comma-separated)
    #
    # Required: false
    # Default: CRITICAL,HIGH

    trivy-scanners:
    # Types of scanners to run (comma-separated)
    #
    # Required: false
    # Default: vuln,config,secret

    trivy-timeout:
    # Timeout for Trivy scan
    #
    # Required: false
    # Default: 10m

    actionlint-enabled:
    # Enable actionlint scanning
    #
    # Required: false
    # Default: true

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""
```
