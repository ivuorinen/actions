# GitHub Actions Workflow Commands

Comprehensive reference for GitHub Actions workflow commands in bash.

## Basic Syntax

```bash
::workflow-command parameter1={data},parameter2={data}::{command value}
```

- Commands are case-insensitive
- Works in Bash and PowerShell
- Use UTF-8 encoding
- Environment variables are case-sensitive

## Setting Outputs

**Syntax:**

```bash
echo "{name}={value}" >> "$GITHUB_OUTPUT"
```

**Multiline values:**

```bash
{
  echo 'JSON_RESPONSE<<EOF'
  echo "$response"
  echo EOF
} >> "$GITHUB_OUTPUT"
```

**Example:**

```bash
echo "action_fruit=strawberry" >> "$GITHUB_OUTPUT"
```

## Setting Environment Variables

**Syntax:**

```bash
echo "{name}={value}" >> "$GITHUB_ENV"
```

**Multiline values:**

```bash
{
  echo 'MY_VAR<<EOF'
  echo "line 1"
  echo "line 2"
  echo EOF
} >> "$GITHUB_ENV"
```

**Example:**

```bash
echo "BUILD_DATE=$(date +%Y-%m-%d)" >> "$GITHUB_ENV"
```

## Adding to System PATH

**Syntax:**

```bash
echo "{path}" >> "$GITHUB_PATH"
```

**Example:**

```bash
echo "$HOME/.local/bin" >> "$GITHUB_PATH"
```

## Logging Commands

### Debug Message

```bash
::debug::{message}
```

Only visible when debug logging is enabled.

### Notice Message

```bash
::notice file={name},line={line},col={col},endColumn={endColumn},title={title}::{message}
```

Parameters (all optional):

- `file`: Filename
- `line`: Line number
- `col`: Column number
- `endColumn`: End column number
- `title`: Custom title

**Example:**

```bash
echo "::notice file=app.js,line=42,col=5,endColumn=7::Variable 'x' is deprecated"
```

### Warning Message

```bash
::warning file={name},line={line},col={col},endColumn={endColumn},title={title}::{message}
```

Same parameters as notice.

**Example:**

```bash
echo "::warning::Missing semicolon"
echo "::warning file=config.yml,line=10::Using deprecated syntax"
```

### Error Message

```bash
::error file={name},line={line},col={col},endColumn={endColumn},title={title}::{message}
```

Same parameters as notice/warning.

**Example:**

```bash
echo "::error::Build failed"
echo "::error file=test.sh,line=15::Syntax error detected"
```

## Grouping Log Lines

Collapsible log sections in the GitHub Actions UI.

**Syntax:**

```bash
::group::{title}
# commands here
::endgroup::
```

**Example:**

```bash
echo "::group::Installing dependencies"
npm install
echo "::endgroup::"
```

## Masking Secrets

Prevents values from appearing in logs.

**Syntax:**

```bash
::add-mask::{value}
```

**Example:**

```bash
SECRET_TOKEN="abc123xyz"
echo "::add-mask::$SECRET_TOKEN"
echo "Token is: $SECRET_TOKEN"  # Will show: Token is: ***
```

## Stopping and Resuming Commands

Temporarily disable workflow command processing.

**Stop:**

```bash
::stop-commands::{endtoken}
```

**Resume:**

```bash
::{endtoken}::
```

**Example:**

```bash
STOP_TOKEN=$(uuidgen)
echo "::stop-commands::$STOP_TOKEN"
echo "::warning::This won't be processed"
echo "::$STOP_TOKEN::"
echo "::notice::Commands resumed"
```

## Echoing Command Output

Control whether action commands are echoed to the log.

**Enable:**

```bash
::echo::on
```

**Disable:**

```bash
::echo::off
```

## Job Summaries

Create Markdown summaries visible in the Actions UI.

**Syntax:**

```bash
echo "{markdown content}" >> "$GITHUB_STEP_SUMMARY"
```

**Example:**

```bash
echo "### Test Results :rocket:" >> "$GITHUB_STEP_SUMMARY"
echo "- Tests passed: 42" >> "$GITHUB_STEP_SUMMARY"
echo "- Tests failed: 0" >> "$GITHUB_STEP_SUMMARY"
```

**Multiline:**

```bash
cat << 'EOF' >> "$GITHUB_STEP_SUMMARY"
## Deployment Summary

| Environment | Status |
|-------------|--------|
| Staging     | ✅     |
| Production  | ✅     |
EOF
```

## Common Patterns

### Set multiple outputs

```bash
{
  echo "version=$(cat version.txt)"
  echo "build_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "commit_sha=$GITHUB_SHA"
} >> "$GITHUB_OUTPUT"
```

### Conditional error with file annotation

```bash
if ! npm test; then
  echo "::error file=tests/unit.test.js,line=23::Test suite failed"
  exit 1
fi
```

### Grouped logging with error handling

```bash
echo "::group::Build application"
if make build; then
  echo "::notice::Build completed successfully"
else
  echo "::error::Build failed"
  exit 1
fi
echo "::endgroup::"
```

### Mask and use secret

```bash
API_KEY=$(cat api-key.txt)
echo "::add-mask::$API_KEY"
echo "API_KEY=$API_KEY" >> "$GITHUB_ENV"
```

## Best Practices

1. **Always mask secrets** before using them
2. **Use groups** for long output sections
3. **Add file/line annotations** for code-related errors/warnings
4. **Use multiline syntax** for complex values
5. **Set outputs early** in the step
6. **Use GITHUB_ENV** for values needed in subsequent steps
7. **Use GITHUB_OUTPUT** for values consumed by other jobs/steps
8. **Validate paths** before adding to GITHUB_PATH
9. **Use unique tokens** for stop-commands
10. **Add summaries** for important results

## Environment Files Reference

- `$GITHUB_ENV` - Set environment variables
- `$GITHUB_OUTPUT` - Set step outputs
- `$GITHUB_PATH` - Add to system PATH
- `$GITHUB_STEP_SUMMARY` - Add Markdown summaries

## Security Considerations

- Never echo secrets without masking
- Validate all user input before using in commands
- Use `::add-mask::` immediately after reading secrets
- Be aware that environment variables persist across steps
- Outputs can be accessed by other jobs
