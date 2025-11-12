# ivuorinen/actions/common-retry

## Common Retry

### Description

Standardized retry utility for network operations and flaky commands

### Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `command` | <p>Command to execute with retry logic</p> | `true` | `""` |
| `max-retries` | <p>Maximum number of retry attempts</p> | `false` | `3` |
| `retry-delay` | <p>Initial delay between retries in seconds</p> | `false` | `5` |
| `backoff-strategy` | <p>Backoff strategy (linear, exponential, fixed)</p> | `false` | `exponential` |
| `timeout` | <p>Timeout for each attempt in seconds</p> | `false` | `300` |
| `working-directory` | <p>Working directory to execute command in</p> | `false` | `.` |
| `shell` | <p>Shell to use for command execution</p> | `false` | `bash` |
| `success-codes` | <p>Comma-separated list of success exit codes</p> | `false` | `0` |
| `retry-codes` | <p>Comma-separated list of exit codes that should trigger retry</p> | `false` | `1,2,124,126,127` |
| `description` | <p>Human-readable description of the operation for logging</p> | `false` | `Command execution` |

### Outputs

| name | description |
| --- | --- |
| `success` | <p>Whether the command succeeded (true/false)</p> |
| `attempts` | <p>Number of attempts made</p> |
| `exit-code` | <p>Final exit code of the command</p> |
| `duration` | <p>Total execution duration in seconds</p> |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/common-retry@main
  with:
    command:
    # Command to execute with retry logic
    #
    # Required: true
    # Default: ""

    max-retries:
    # Maximum number of retry attempts
    #
    # Required: false
    # Default: 3

    retry-delay:
    # Initial delay between retries in seconds
    #
    # Required: false
    # Default: 5

    backoff-strategy:
    # Backoff strategy (linear, exponential, fixed)
    #
    # Required: false
    # Default: exponential

    timeout:
    # Timeout for each attempt in seconds
    #
    # Required: false
    # Default: 300

    working-directory:
    # Working directory to execute command in
    #
    # Required: false
    # Default: .

    shell:
    # Shell to use for command execution
    #
    # Required: false
    # Default: bash

    success-codes:
    # Comma-separated list of success exit codes
    #
    # Required: false
    # Default: 0

    retry-codes:
    # Comma-separated list of exit codes that should trigger retry
    #
    # Required: false
    # Default: 1,2,124,126,127

    description:
    # Human-readable description of the operation for logging
    #
    # Required: false
    # Default: Command execution
```
