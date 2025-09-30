# GitHub Actions: Expressions and Contexts Reference

## Expression Syntax

GitHub Actions expressions are written using `${{ <expression> }}` syntax.

### Literals

**Supported Types:**

- Boolean: `true`, `false`
- Null: `null`
- Number: Integer or floating-point
- String: Single or double quotes

**Falsy Values:**

- `false`, `0`, `-0`, `""`, `''`, `null`

**Truthy Values:**

- `true` and all non-falsy values

## Operators

### Logical Operators

- `( )` - Grouping
- `!` - NOT
- `&&` - AND
- `||` - OR

### Comparison Operators

- `==` - Equal (case-insensitive for strings)
- `!=` - Not equal
- `<` - Less than
- `<=` - Less than or equal
- `>` - Greater than
- `>=` - Greater than or equal

## Built-in Functions

### String Functions

```yaml
contains(search, item)        # Check if item exists in search string/array
startsWith(searchString, searchValue)  # Check prefix
endsWith(searchString, searchValue)    # Check suffix
format(string, replaceValue0, replaceValue1, ...)  # String formatting
join(array, optionalSeparator)  # Join array elements
```

### Conversion Functions

```yaml
toJSON(value)     # Convert to JSON string
fromJSON(value)   # Parse JSON string to object/type
```

### Status Check Functions

```yaml
success()    # True if no previous step failed
always()     # Always returns true, step always runs
cancelled()  # True if workflow cancelled
failure()    # True if any previous step failed
```

### Hash Functions

```yaml
hashFiles(path) # Generate SHA-256 hash of files matching pattern
```

## Type Casting Rules

GitHub Actions performs **loose equality comparisons**:

- Numbers compared as floating-point
- Strings are case-insensitive when compared
- Type mismatches coerced to numbers:
  - Null → `0`
  - Boolean → `1` (true) or `0` (false)
  - String → Parsed as number, or `NaN` if invalid
  - Array/Object → `NaN`
- Objects/arrays only equal if same instance reference

**Best Practice:** Use `fromJSON()` for precise numerical comparisons

## Contexts

### `github` Context

Workflow run and event information:

```yaml
${{ github.event }}          # Full webhook payload
${{ github.actor }}          # User who triggered workflow
${{ github.ref }}            # Branch/tag reference (e.g., refs/heads/main)
${{ github.repository }}     # owner/repo format
${{ github.sha }}            # Commit SHA
${{ github.token }}          # Automatic GITHUB_TOKEN
${{ github.event_name }}     # Event that triggered workflow
${{ github.run_id }}         # Unique workflow run ID
${{ github.run_number }}     # Run number for this workflow
${{ github.job }}            # Job ID
${{ github.workflow }}       # Workflow name
```

### `env` Context

Environment variables (workflow → job → step scope):

```yaml
${{ env.MY_VARIABLE }}
```

### `vars` Context

Configuration variables (organization/repo/environment level):

```yaml
${{ vars.MY_CONFIG_VAR }}
```

### `secrets` Context

Secret values (never printed to logs):

```yaml
${{ secrets.MY_SECRET }}
${{ secrets.GITHUB_TOKEN }} # Automatic token
```

### `inputs` Context

Inputs for reusable workflows or workflow_dispatch:

```yaml
${{ inputs.deploy_target }}
${{ inputs.environment }}
```

### `steps` Context

Information from previous steps in same job:

```yaml
${{ steps.step_id.outputs.output_name }}
${{ steps.step_id.outcome }}     # success, failure, cancelled, skipped
${{ steps.step_id.conclusion }}  # success, failure, cancelled, skipped
```

### `job` Context

Current job information:

```yaml
${{ job.status }}           # success, failure, cancelled
${{ job.container.id }}     # Container ID if running in container
${{ job.services }}         # Service containers
```

### `runner` Context

Runner environment details:

```yaml
${{ runner.os }}            # Linux, Windows, macOS
${{ runner.arch }}          # X86, X64, ARM, ARM64
${{ runner.temp }}          # Temporary directory path
${{ runner.tool_cache }}    # Tool cache directory
```

### `needs` Context

Outputs from jobs that current job depends on:

```yaml
${{ needs.job_id.outputs.output_name }}
${{ needs.job_id.result }} # success, failure, cancelled, skipped
```

### `matrix` Context

Matrix strategy values:

```yaml
${{ matrix.os }}
${{ matrix.version }}
```

## Common Patterns

### Conditional Execution

```yaml
if: github.ref == 'refs/heads/main'
if: success()
if: failure() && steps.test.outcome == 'failure'
if: always()
```

### Ternary-like Logic

```yaml
env:
  DEPLOY_ENV: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
```

### String Manipulation

```yaml
if: startsWith(github.ref, 'refs/tags/')
if: contains(github.event.head_commit.message, '[skip ci]')
if: endsWith(github.repository, '-prod')
```

### Array/Object Access

```yaml
${{ github.event.pull_request.title }}
${{ fromJSON(steps.output.outputs.json_data).key }}
```

### Combining Conditions

```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
if: (github.event_name == 'pull_request' || github.event_name == 'push') && !cancelled()
```

## Security Best Practices

1. **Environment Variables for Shell Scripts:**
   - ✅ Use `env:` block to pass inputs to shell scripts
   - ❌ Avoid direct `${{ inputs.* }}` in shell commands (script injection risk)

2. **Secret Masking:**

   ```yaml
   - run: echo "::add-mask::${{ secrets.MY_SECRET }}"
   ```

3. **Input Validation:**
   - Always validate user inputs before use
   - Use dedicated validation steps
   - Check for command injection patterns

4. **Type Safety:**
   - Use `fromJSON()` for structured data
   - Cast to expected types explicitly
   - Validate ranges and formats

## Common Pitfalls

1. **String Comparison Case Sensitivity:**
   - GitHub Actions comparisons are case-insensitive
   - Be careful with exact matches

2. **Type Coercion:**
   - Empty string `""` is falsy, not truthy
   - Number `0` is falsy
   - Use `fromJSON()` for precise comparisons

3. **Object/Array Equality:**
   - Objects/arrays compared by reference, not value
   - Use `toJSON()` to compare by value

4. **Status Functions:**
   - `success()` checks ALL previous steps
   - Use `steps.id.outcome` for specific step status

5. **Context Availability:**
   - Not all contexts available in all places
   - `env` context not available in `if:` at workflow/job level
   - `secrets` should never be used in `if:` conditions (may leak)

## Examples from Project

### Input Validation Pattern

```yaml
- name: Validate Inputs
  env:
    VERSION: ${{ inputs.version }}
    EMAIL: ${{ inputs.email }}
  run: |
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
      echo "::error::Invalid version: $VERSION"
      exit 1
    fi
```

### Conditional Steps

```yaml
- name: Deploy Production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: ./deploy.sh production

- name: Cleanup
  if: always()
  run: ./cleanup.sh
```

### Dynamic Outputs

```yaml
- name: Set Environment
  id: env
  run: |
    if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
      echo "environment=production" >> $GITHUB_OUTPUT
    else
      echo "environment=staging" >> $GITHUB_OUTPUT
    fi

- name: Deploy
  run: ./deploy.sh ${{ steps.env.outputs.environment }}
```

## References

- [GitHub Actions Expressions](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions)
- [GitHub Actions Contexts](https://docs.github.com/en/actions/learn-github-actions/contexts)
- Project validation patterns in `validate-inputs/` directory
- Security patterns documented in `CLAUDE.md`
