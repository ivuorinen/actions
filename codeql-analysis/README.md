# ivuorinen/actions/codeql-analysis

## Description

Run CodeQL security analysis for a single language with configurable query suites

## Inputs

| parameter         | description                                                                          | required | default             |
|-------------------|--------------------------------------------------------------------------------------|----------|---------------------|
| language          | Language to analyze (javascript, python, actions, java, csharp, cpp, ruby, go, etc.) | `true`   |                     |
| queries           | Comma-separated list of additional queries to run                                    | `false`  |                     |
| packs             | Comma-separated list of CodeQL query packs to run                                    | `false`  |                     |
| config-file       | Path to CodeQL configuration file                                                    | `false`  |                     |
| config            | Configuration passed as a YAML string                                                | `false`  |                     |
| build-mode        | The build mode for compiled languages (none, manual, autobuild)                      | `false`  |                     |
| source-root       | Path of the root source code directory                                               | `false`  |                     |
| category          | Analysis category (default: /language:<language>)                                    | `false`  |                     |
| checkout-ref      | Git reference to checkout (default: current ref)                                     | `false`  |                     |
| token             | GitHub token for API access                                                          | `false`  | ${{ github.token }} |
| working-directory | Working directory for the analysis                                                   | `false`  | .                   |
| upload-results    | Upload results to GitHub Security tab                                                | `false`  | true                |
| ram               | Amount of memory in MB that can be used by CodeQL                                    | `false`  |                     |
| threads           | Number of threads that can be used by CodeQL                                         | `false`  |                     |
| output            | Path to save SARIF results                                                           | `false`  | ../results          |
| skip-queries      | Build database but skip running queries                                              | `false`  | false               |

## Outputs

| parameter         | description                    |
|-------------------|--------------------------------|
| language-analyzed | Language that was analyzed     |
| analysis-category | Category used for the analysis |
| sarif-file        | Path to generated SARIF file   |

## Runs

This action is a `composite` action.
