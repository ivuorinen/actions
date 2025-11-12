# ivuorinen/actions/codeql-analysis

## CodeQL Analysis

### Description

Run CodeQL security analysis for a single language with configurable query suites

### Inputs

| name                | description                                                                                 | required | default               |
|---------------------|---------------------------------------------------------------------------------------------|----------|-----------------------|
| `language`          | <p>Language to analyze (javascript, python, actions, java, csharp, cpp, ruby, go, etc.)</p> | `true`   | `""`                  |
| `queries`           | <p>Comma-separated list of additional queries to run</p>                                    | `false`  | `""`                  |
| `packs`             | <p>Comma-separated list of CodeQL query packs to run</p>                                    | `false`  | `""`                  |
| `config-file`       | <p>Path to CodeQL configuration file</p>                                                    | `false`  | `""`                  |
| `config`            | <p>Configuration passed as a YAML string</p>                                                | `false`  | `""`                  |
| `build-mode`        | <p>The build mode for compiled languages (none, manual, autobuild)</p>                      | `false`  | `""`                  |
| `source-root`       | <p>Path of the root source code directory</p>                                               | `false`  | `""`                  |
| `category`          | <p>Analysis category (default: /language:<language>)</p>                                    | `false`  | `""`                  |
| `checkout-ref`      | <p>Git reference to checkout (default: current ref)</p>                                     | `false`  | `""`                  |
| `token`             | <p>GitHub token for API access</p>                                                          | `false`  | `${{ github.token }}` |
| `working-directory` | <p>Working directory for the analysis</p>                                                   | `false`  | `.`                   |
| `upload-results`    | <p>Upload results to GitHub Security tab</p>                                                | `false`  | `true`                |
| `ram`               | <p>Amount of memory in MB that can be used by CodeQL</p>                                    | `false`  | `""`                  |
| `threads`           | <p>Number of threads that can be used by CodeQL</p>                                         | `false`  | `""`                  |
| `output`            | <p>Path to save SARIF results</p>                                                           | `false`  | `../results`          |
| `skip-queries`      | <p>Build database but skip running queries</p>                                              | `false`  | `false`               |
| `add-snippets`      | <p>Add code snippets to SARIF output</p>                                                    | `false`  | `false`               |

### Outputs

| name                | description                           |
|---------------------|---------------------------------------|
| `language-analyzed` | <p>Language that was analyzed</p>     |
| `analysis-category` | <p>Category used for the analysis</p> |
| `sarif-file`        | <p>Path to generated SARIF file</p>   |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/codeql-analysis@main
  with:
    language:
    # Language to analyze (javascript, python, actions, java, csharp, cpp, ruby, go, etc.)
    #
    # Required: true
    # Default: ""

    queries:
    # Comma-separated list of additional queries to run
    #
    # Required: false
    # Default: ""

    packs:
    # Comma-separated list of CodeQL query packs to run
    #
    # Required: false
    # Default: ""

    config-file:
    # Path to CodeQL configuration file
    #
    # Required: false
    # Default: ""

    config:
    # Configuration passed as a YAML string
    #
    # Required: false
    # Default: ""

    build-mode:
    # The build mode for compiled languages (none, manual, autobuild)
    #
    # Required: false
    # Default: ""

    source-root:
    # Path of the root source code directory
    #
    # Required: false
    # Default: ""

    category:
    # Analysis category (default: /language:<language>)
    #
    # Required: false
    # Default: ""

    checkout-ref:
    # Git reference to checkout (default: current ref)
    #
    # Required: false
    # Default: ""

    token:
    # GitHub token for API access
    #
    # Required: false
    # Default: ${{ github.token }}

    working-directory:
    # Working directory for the analysis
    #
    # Required: false
    # Default: .

    upload-results:
    # Upload results to GitHub Security tab
    #
    # Required: false
    # Default: true

    ram:
    # Amount of memory in MB that can be used by CodeQL
    #
    # Required: false
    # Default: ""

    threads:
    # Number of threads that can be used by CodeQL
    #
    # Required: false
    # Default: ""

    output:
    # Path to save SARIF results
    #
    # Required: false
    # Default: ../results

    skip-queries:
    # Build database but skip running queries
    #
    # Required: false
    # Default: false

    add-snippets:
    # Add code snippets to SARIF output
    #
    # Required: false
    # Default: false
```
