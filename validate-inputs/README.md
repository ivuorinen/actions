# ivuorinen/actions/validate-inputs

## Validate Inputs

### Description

Centralized Python-based input validation for GitHub Actions with PCRE regex support

### Inputs

| name                | description                                                                        | required | default |
| ------------------- | ---------------------------------------------------------------------------------- | -------- | ------- |
| `action`            | <p>Action name to validate (alias for action-type)</p>                             | `false`  | `""`    |
| `action-type`       | <p>Type of action to validate (e.g., csharp-publish, docker-build, eslint-fix)</p> | `false`  | `""`    |
| `rules-file`        | <p>Path to validation rules file</p>                                               | `false`  | `""`    |
| `fail-on-error`     | <p>Whether to fail on validation errors</p>                                        | `false`  | `true`  |
| `token`             | <p>GitHub token for authentication</p>                                             | `false`  | `""`    |
| `namespace`         | <p>Namespace/username for validation</p>                                           | `false`  | `""`    |
| `email`             | <p>Email address for validation</p>                                                | `false`  | `""`    |
| `username`          | <p>Username for validation</p>                                                     | `false`  | `""`    |
| `dotnet-version`    | <p>.NET version string</p>                                                         | `false`  | `""`    |
| `terraform-version` | <p>Terraform version string</p>                                                    | `false`  | `""`    |
| `tflint-version`    | <p>TFLint version string</p>                                                       | `false`  | `""`    |
| `node-version`      | <p>Node.js version string</p>                                                      | `false`  | `""`    |
| `force-version`     | <p>Force version override</p>                                                      | `false`  | `""`    |
| `default-version`   | <p>Default version fallback</p>                                                    | `false`  | `""`    |
| `image-name`        | <p>Docker image name</p>                                                           | `false`  | `""`    |
| `tag`               | <p>Docker image tag</p>                                                            | `false`  | `""`    |
| `architectures`     | <p>Target architectures</p>                                                        | `false`  | `""`    |
| `dockerfile`        | <p>Dockerfile path</p>                                                             | `false`  | `""`    |
| `context`           | <p>Docker build context</p>                                                        | `false`  | `""`    |
| `build-args`        | <p>Docker build arguments</p>                                                      | `false`  | `""`    |
| `buildx-version`    | <p>Docker Buildx version</p>                                                       | `false`  | `""`    |
| `max-retries`       | <p>Maximum retry attempts</p>                                                      | `false`  | `""`    |
| `image-quality`     | <p>Image quality percentage</p>                                                    | `false`  | `""`    |
| `png-quality`       | <p>PNG quality percentage</p>                                                      | `false`  | `""`    |
| `parallel-builds`   | <p>Number of parallel builds</p>                                                   | `false`  | `""`    |
| `days-before-stale` | <p>Number of days before marking as stale</p>                                      | `false`  | `""`    |
| `days-before-close` | <p>Number of days before closing stale items</p>                                   | `false`  | `""`    |
| `pre-commit-config` | <p>Pre-commit configuration file path</p>                                          | `false`  | `""`    |
| `base-branch`       | <p>Base branch name</p>                                                            | `false`  | `""`    |
| `dry-run`           | <p>Dry run mode</p>                                                                | `false`  | `""`    |
| `is_fiximus`        | <p>Use Fiximus bot</p>                                                             | `false`  | `""`    |
| `prefix`            | <p>Release tag prefix</p>                                                          | `false`  | `""`    |
| `language`          | <p>Language to analyze (for CodeQL)</p>                                            | `false`  | `""`    |
| `queries`           | <p>CodeQL queries to run</p>                                                       | `false`  | `""`    |
| `packs`             | <p>CodeQL query packs</p>                                                          | `false`  | `""`    |
| `config-file`       | <p>CodeQL configuration file path</p>                                              | `false`  | `""`    |
| `config`            | <p>CodeQL configuration YAML string</p>                                            | `false`  | `""`    |
| `build-mode`        | <p>Build mode for compiled languages</p>                                           | `false`  | `""`    |
| `source-root`       | <p>Source code root directory</p>                                                  | `false`  | `""`    |
| `category`          | <p>Analysis category</p>                                                           | `false`  | `""`    |
| `checkout-ref`      | <p>Git reference to checkout</p>                                                   | `false`  | `""`    |
| `working-directory` | <p>Working directory for analysis</p>                                              | `false`  | `""`    |
| `upload-results`    | <p>Upload results to GitHub Security</p>                                           | `false`  | `""`    |
| `ram`               | <p>Memory in MB for CodeQL</p>                                                     | `false`  | `""`    |
| `threads`           | <p>Number of threads for CodeQL</p>                                                | `false`  | `""`    |
| `output`            | <p>Output path for SARIF results</p>                                               | `false`  | `""`    |
| `skip-queries`      | <p>Skip running queries</p>                                                        | `false`  | `""`    |
| `add-snippets`      | <p>Add code snippets to SARIF</p>                                                  | `false`  | `""`    |

### Outputs

| name                | description                                        |
| ------------------- | -------------------------------------------------- |
| `validation-status` | <p>Overall validation status (success/failure)</p> |
| `error-message`     | <p>Validation error message if failed</p>          |
| `validation-result` | <p>Detailed validation result</p>                  |
| `errors-found`      | <p>Number of validation errors found</p>           |
| `rules-applied`     | <p>Number of validation rules applied</p>          |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/validate-inputs@main
  with:
    action:
    # Action name to validate (alias for action-type)
    #
    # Required: false
    # Default: ""

    action-type:
    # Type of action to validate (e.g., csharp-publish, docker-build, eslint-fix)
    #
    # Required: false
    # Default: ""

    rules-file:
    # Path to validation rules file
    #
    # Required: false
    # Default: ""

    fail-on-error:
    # Whether to fail on validation errors
    #
    # Required: false
    # Default: true

    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ""

    namespace:
    # Namespace/username for validation
    #
    # Required: false
    # Default: ""

    email:
    # Email address for validation
    #
    # Required: false
    # Default: ""

    username:
    # Username for validation
    #
    # Required: false
    # Default: ""

    dotnet-version:
    # .NET version string
    #
    # Required: false
    # Default: ""

    terraform-version:
    # Terraform version string
    #
    # Required: false
    # Default: ""

    tflint-version:
    # TFLint version string
    #
    # Required: false
    # Default: ""

    node-version:
    # Node.js version string
    #
    # Required: false
    # Default: ""

    force-version:
    # Force version override
    #
    # Required: false
    # Default: ""

    default-version:
    # Default version fallback
    #
    # Required: false
    # Default: ""

    image-name:
    # Docker image name
    #
    # Required: false
    # Default: ""

    tag:
    # Docker image tag
    #
    # Required: false
    # Default: ""

    architectures:
    # Target architectures
    #
    # Required: false
    # Default: ""

    dockerfile:
    # Dockerfile path
    #
    # Required: false
    # Default: ""

    context:
    # Docker build context
    #
    # Required: false
    # Default: ""

    build-args:
    # Docker build arguments
    #
    # Required: false
    # Default: ""

    buildx-version:
    # Docker Buildx version
    #
    # Required: false
    # Default: ""

    max-retries:
    # Maximum retry attempts
    #
    # Required: false
    # Default: ""

    image-quality:
    # Image quality percentage
    #
    # Required: false
    # Default: ""

    png-quality:
    # PNG quality percentage
    #
    # Required: false
    # Default: ""

    parallel-builds:
    # Number of parallel builds
    #
    # Required: false
    # Default: ""

    days-before-stale:
    # Number of days before marking as stale
    #
    # Required: false
    # Default: ""

    days-before-close:
    # Number of days before closing stale items
    #
    # Required: false
    # Default: ""

    pre-commit-config:
    # Pre-commit configuration file path
    #
    # Required: false
    # Default: ""

    base-branch:
    # Base branch name
    #
    # Required: false
    # Default: ""

    dry-run:
    # Dry run mode
    #
    # Required: false
    # Default: ""

    is_fiximus:
    # Use Fiximus bot
    #
    # Required: false
    # Default: ""

    prefix:
    # Release tag prefix
    #
    # Required: false
    # Default: ""

    language:
    # Language to analyze (for CodeQL)
    #
    # Required: false
    # Default: ""

    queries:
    # CodeQL queries to run
    #
    # Required: false
    # Default: ""

    packs:
    # CodeQL query packs
    #
    # Required: false
    # Default: ""

    config-file:
    # CodeQL configuration file path
    #
    # Required: false
    # Default: ""

    config:
    # CodeQL configuration YAML string
    #
    # Required: false
    # Default: ""

    build-mode:
    # Build mode for compiled languages
    #
    # Required: false
    # Default: ""

    source-root:
    # Source code root directory
    #
    # Required: false
    # Default: ""

    category:
    # Analysis category
    #
    # Required: false
    # Default: ""

    checkout-ref:
    # Git reference to checkout
    #
    # Required: false
    # Default: ""

    working-directory:
    # Working directory for analysis
    #
    # Required: false
    # Default: ""

    upload-results:
    # Upload results to GitHub Security
    #
    # Required: false
    # Default: ""

    ram:
    # Memory in MB for CodeQL
    #
    # Required: false
    # Default: ""

    threads:
    # Number of threads for CodeQL
    #
    # Required: false
    # Default: ""

    output:
    # Output path for SARIF results
    #
    # Required: false
    # Default: ""

    skip-queries:
    # Skip running queries
    #
    # Required: false
    # Default: ""

    add-snippets:
    # Add code snippets to SARIF
    #
    # Required: false
    # Default: ""
```
