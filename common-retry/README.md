# Common Retry

Standardized retry utility for network operations and flaky commands.

## Inputs

| name                | description                                                         | required | default             |
|---------------------|---------------------------------------------------------------------|----------|---------------------|
| `command`           | <p>Command to execute with retry logic</p>                          | `true`   |                     |
| `max-retries`       | <p>Maximum number of retry attempts</p>                             | `false`  | `3`                 |
| `retry-delay`       | <p>Initial delay between retries in seconds</p>                     | `false`  | `5`                 |
| `backoff-strategy`  | <p>Backoff strategy (linear, exponential, fixed)</p>                | `false`  | `exponential`       |
| `timeout`           | <p>Timeout for each attempt in seconds</p>                          | `false`  | `300`               |
| `working-directory` | <p>Working directory to execute command in</p>                      | `false`  | `.`                 |
| `shell`             | <p>Shell to use for command execution</p>                           | `false`  | `bash`              |
| `success-codes`     | <p>Comma-separated list of success exit codes</p>                   | `false`  | `0`                 |
| `retry-codes`       | <p>Comma-separated list of exit codes that should trigger retry</p> | `false`  | `1,2,126,127`       |
| `description`       | <p>Human-readable description of the operation for logging</p>      | `false`  | `Command execution` |

## Outputs

| name        | description                                       |
|-------------|---------------------------------------------------|
| `success`   | <p>Whether the command succeeded (true/false)</p> |
| `attempts`  | <p>Number of attempts made</p>                    |
| `exit-code` | <p>Final exit code of the command</p>             |
| `duration`  | <p>Total execution duration in seconds</p>        |

## Runs

This action is a `composite` action.

## Usage

### Basic Retry

```yaml
- uses: ivuorinen/actions/common-retry@main
  with:
    command: 'npm install'
    description: 'Installing Node.js dependencies'
```

### Custom Retry Configuration

```yaml
- uses: ivuorinen/actions/common-retry@main
  with:
    command: 'curl -sSL https://example.com/api/data'
    max-retries: 5
    retry-delay: 10
    backoff-strategy: 'exponential'
    timeout: 60
    description: 'Fetching API data'
```

### Package Installation with Custom Success Codes

```yaml
- uses: ivuorinen/actions/common-retry@main
  with:
    command: 'pip install -r requirements.txt'
    max-retries: 3
    success-codes: '0'
    retry-codes: '1,2,23' # Network-related pip errors
    description: 'Installing Python dependencies'
```

## Backoff Strategies

- **`fixed`**: Same delay between each retry
- **`linear`**: Delay increases linearly (5s, 10s, 15s...)
- **`exponential`**: Delay doubles each time (5s, 10s, 20s...) - Default

## Common Use Cases

### Network Operations

- Package installations (`npm install`, `pip install`, `composer install`)
- API calls and downloads
- Docker operations

### Example with Outputs

```yaml
- id: retry-install
  uses: ivuorinen/actions/common-retry@main
  with:
    command: 'npm install'
    max-retries: 3
    description: 'Installing Node.js dependencies'

- name: Check Results
  run: |
    echo "Success: ${{ steps.retry-install.outputs.success }}"
    echo "Attempts: ${{ steps.retry-install.outputs.attempts }}"
    echo "Duration: ${{ steps.retry-install.outputs.duration }}s"
```
