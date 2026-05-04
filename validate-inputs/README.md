# ivuorinen/actions/validate-inputs

## Description

Centralized Python-based input validation for GitHub Actions with PCRE regex support

## Inputs

| parameter          | description                                                                  | required | default |
|--------------------|------------------------------------------------------------------------------|----------|---------|
| action             | Action name to validate (alias for action-type)                              | `false`  |         |
| action-type        | Type of action to validate (e.g., csharp-publish, docker-build, eslint-lint) | `false`  |         |
| rules-file         | Path to validation rules file                                                | `false`  |         |
| fail-on-error      | Whether to fail on validation errors                                         | `false`  | true    |
| token              | GitHub token for authentication                                              | `false`  |         |
| namespace          | Namespace/username for validation                                            | `false`  |         |
| email              | Email address for validation                                                 | `false`  |         |
| username           | Username for validation                                                      | `false`  |         |
| dotnet-version     | .NET version string                                                          | `false`  |         |
| terraform-version  | Terraform version string                                                     | `false`  |         |
| tflint-version     | TFLint version string                                                        | `false`  |         |
| node-version       | Node.js version string                                                       | `false`  |         |
| force-version      | Force version override                                                       | `false`  |         |
| default-version    | Default version fallback                                                     | `false`  |         |
| image-name         | Docker image name                                                            | `false`  |         |
| tag                | Docker image tag                                                             | `false`  |         |
| architectures      | Target architectures                                                         | `false`  |         |
| dockerfile         | Dockerfile path                                                              | `false`  |         |
| context            | Docker build context                                                         | `false`  |         |
| build-args         | Docker build arguments                                                       | `false`  |         |
| buildx-version     | Docker Buildx version                                                        | `false`  |         |
| max-retries        | Maximum retry attempts                                                       | `false`  |         |
| image-quality      | Image quality percentage                                                     | `false`  |         |
| png-quality        | PNG quality percentage                                                       | `false`  |         |
| parallel-builds    | Number of parallel builds                                                    | `false`  |         |
| days-before-stale  | Number of days before marking as stale                                       | `false`  |         |
| days-before-close  | Number of days before closing stale items                                    | `false`  |         |
| pre-commit-config  | Pre-commit configuration file path                                           | `false`  |         |
| base-branch        | Base branch name                                                             | `false`  |         |
| dry-run            | Dry run mode                                                                 | `false`  |         |
| is-fiximus         | Use Fiximus bot                                                              | `false`  |         |
| is_fiximus         | Deprecated alias for is-fiximus (backward compatibility)                     | `false`  |         |
| prefix             | Release tag prefix                                                           | `false`  |         |
| language           | Language to analyze (for CodeQL)                                             | `false`  |         |
| queries            | CodeQL queries to run                                                        | `false`  |         |
| packs              | CodeQL query packs                                                           | `false`  |         |
| config-file        | CodeQL configuration file path                                               | `false`  |         |
| config             | CodeQL configuration YAML string                                             | `false`  |         |
| build-mode         | Build mode for compiled languages                                            | `false`  |         |
| source-root        | Source code root directory                                                   | `false`  |         |
| category           | Analysis category                                                            | `false`  |         |
| checkout-ref       | Git reference to checkout                                                    | `false`  |         |
| working-directory  | Working directory for analysis                                               | `false`  |         |
| upload-results     | Upload results to GitHub Security                                            | `false`  |         |
| ram                | Memory in MB for CodeQL                                                      | `false`  |         |
| threads            | Number of threads for CodeQL                                                 | `false`  |         |
| output             | Output path for SARIF results                                                | `false`  |         |
| skip-queries       | Skip running queries                                                         | `false`  |         |
| add-snippets       | Add code snippets to SARIF                                                   | `false`  |         |
| gitleaks-license   | Gitleaks license key                                                         | `false`  |         |
| gitleaks-config    | Gitleaks configuration file path                                             | `false`  |         |
| trivy-severity     | Trivy severity levels to scan                                                | `false`  |         |
| trivy-scanners     | Trivy scanner types to run                                                   | `false`  |         |
| trivy-timeout      | Trivy scan timeout                                                           | `false`  |         |
| actionlint-enabled | Enable actionlint scanning                                                   | `false`  |         |

## Outputs

| parameter         | description                                 |
|-------------------|---------------------------------------------|
| validation-status | Overall validation status (success/failure) |
| error-message     | Validation error message if failed          |
| validation-result | Detailed validation result                  |
| errors-found      | Number of validation errors found           |
| rules-applied     | Number of validation rules applied          |

## Runs

This action is a `composite` action.
