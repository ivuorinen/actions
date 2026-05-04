# Workflow Inputs Safety

Never interpolate `${{ github.event.inputs.* }}` or `${{ inputs.* }}` directly into shell `run:` steps.
Always pass workflow_dispatch and action inputs through an `env:` block, then reference the env var in the shell command.
Always use `type: choice` with an `options:` allowlist for workflow_dispatch inputs that feed into shell commands or ref/tag values.
