# ivuorinen/actions/go-lint

## Description

Run golangci-lint with advanced configuration, caching, and reporting

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| working-directory | Directory containing Go files | `false` | . |
| golangci-lint-version | Version of golangci-lint to use | `false` | latest |
| go-version | Go version to use | `false` | stable |
| config-file | Path to golangci-lint config file | `false` | .golangci.yml |
| timeout | Timeout for analysis (e.g., 5m, 1h) | `false` | 5m |
| cache | Enable golangci-lint caching | `false` | true |
| fail-on-error | Fail workflow if issues are found | `false` | true |
| report-format | Output format (json, sarif, github-actions) | `false` | sarif |
| max-retries | Maximum number of retry attempts | `false` | 3 |
| only-new-issues | Report only new issues since main branch | `false` | true |
| disable-all | Disable all linters (useful with --enable-*) | `false` | false |
| enable-linters | Comma-separated list of linters to enable | `false` |  |
| disable-linters | Comma-separated list of linters to disable | `false` |  |
| token | GitHub token for authentication | `false` |  |

## Outputs

| parameter | description |
| --- | --- |
| error-count | Number of errors found |
| sarif-file | Path to SARIF report file |
| cache-hit | Indicates if there was a cache hit |
| analyzed-files | Number of files analyzed |

## Runs

This action is a `composite` action.
