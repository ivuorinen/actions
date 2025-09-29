# GitHub Actions Security Best Practices

Comprehensive guide for secure use of GitHub Actions workflows.

## Core Security Principles

1. **Principle of Least Privilege** - Grant minimum necessary permissions
2. **Defense in Depth** - Layer multiple security controls
3. **Zero Trust** - Verify explicitly, never assume trust
4. **Audit and Monitor** - Track and review all security-relevant events

## Secrets Management

### Storing Secrets

✅ **DO:**

- Store sensitive data in GitHub Secrets
- Use organization-level secrets for shared values
- Use environment-specific secrets
- Register all secrets used in workflows

❌ **DON'T:**

- Hard-code secrets in workflow files
- Echo secrets to logs
- Store secrets in environment variables without masking
- Use structured data (JSON, YAML) as secrets

**Example:**

```yaml
- name: Use secret
  env:
    API_KEY: ${{ secrets.API_KEY }}
  run: |
    echo "::add-mask::$API_KEY"
    curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

### Masking Sensitive Data

Always mask secrets before using them:

```bash
# Mask the secret
echo "::add-mask::$SECRET_VALUE"

# Now it's safe to use
echo "Using secret: $SECRET_VALUE"  # Shows: Using secret: ***
```

### Secret Rotation

1. **Immediately rotate** exposed secrets
2. **Delete** compromised secrets from GitHub
3. **Audit** workflow runs that used the secret
4. **Review** access logs
5. **Update** all systems using the secret

## Script Injection Prevention

### The Problem

User input can inject malicious code:

```yaml
# VULNERABLE
- name: Greet user
  run: echo "Hello ${{ github.event.issue.title }}"
```

If issue title is: `"; rm -rf / #`, the command becomes:

```bash
echo "Hello "; rm -rf / #"
```

### Solution 1: Use Intermediate Environment Variables

```yaml
# SAFE
- name: Greet user
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Hello $TITLE"
```

### Solution 2: Use Actions Instead of Scripts

```yaml
# SAFE - Use action instead of inline script
- name: Comment on PR
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `Hello ${context.payload.issue.title}`
      })
```

### Solution 3: Proper Quoting

Always use double quotes for variables:

```bash
# VULNERABLE
echo Hello $USER_INPUT

# SAFE
echo "Hello $USER_INPUT"
```

### High-Risk Inputs

Be especially careful with:

- `github.event.issue.title`
- `github.event.issue.body`
- `github.event.pull_request.title`
- `github.event.pull_request.body`
- `github.event.comment.body`
- `github.event.review.body`
- `github.event.head_commit.message`
- Any user-provided input

## Third-Party Actions Security

### Pinning Actions

✅ **BEST: Pin to full commit SHA**

```yaml
- uses: actions/checkout@8e5e7e5ab8b370d6c329ec480221332ada57f0ab  # v3.5.2
```

⚠️ **ACCEPTABLE: Pin to tag (for verified creators only)**

```yaml
- uses: actions/checkout@v3.5.2
```

❌ **DANGEROUS: Use branch or mutable tag**

```yaml
- uses: actions/checkout@main  # DON'T DO THIS
```

### Auditing Actions

Before using third-party actions:

1. **Review source code** - Check the action's repository
2. **Check maintainer** - Look for "Verified creator" badge
3. **Read reviews** - Check community feedback
4. **Verify permissions** - Understand what the action accesses
5. **Check dependencies** - Review what the action installs

### Verified Creators

Actions from these sources are generally safer:

- GitHub Official (`actions/*`)
- Major cloud providers (AWS, Azure, Google)
- Well-known organizations with verified badges

## Token and Permission Management

### GITHUB_TOKEN Permissions

Set restrictive defaults:

```yaml
permissions:
  contents: read  # Default to read-only

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write  # Only elevate what's needed
    steps:
      - uses: actions/checkout@v3
```

### Available Permissions

- `actions`: read|write
- `checks`: read|write
- `contents`: read|write
- `deployments`: read|write
- `issues`: read|write
- `packages`: read|write
- `pages`: read|write
- `pull-requests`: read|write
- `repository-projects`: read|write
- `security-events`: read|write
- `statuses`: read|write

### Principle of Least Privilege

```yaml
# GOOD - Minimal permissions
permissions:
  contents: read
  pull-requests: write  # Only what's needed

# BAD - Overly permissive
permissions: write-all
```

## Runner Security

### GitHub-Hosted Runners (Recommended)

✅ **Advantages:**

- Isolated, ephemeral environments
- Automatic patching and updates
- No infrastructure management
- Better security by default

### Self-Hosted Runners

⚠️ **Use with extreme caution:**

**Risks:**

- Persistent environments can retain secrets
- Accessible to all workflows in repository (public repos)
- Requires security hardening
- Manual patching and updates

**If you must use self-hosted:**

1. **Use JIT (Just-In-Time) runners**
   - Ephemeral, created on-demand
   - Automatically destroyed after use

2. **Never use self-hosted runners for public repositories**

3. **Organize into groups with restricted access**

4. **Implement network isolation**

5. **Use minimal, hardened OS images**

6. **Rotate regularly**

### Runner Groups

```yaml
# Restrict workflow to specific runner group
runs-on:
  group: private-runners
  labels: ubuntu-latest
```

## Code Scanning and Vulnerability Detection

### Enable CodeQL

```yaml
name: "Code Scanning"
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v3
      - uses: github/codeql-action/init@v2
      - uses: github/codeql-action/autobuild@v2
      - uses: github/codeql-action/analyze@v2
```

### Dependabot for Actions

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## OpenID Connect (OIDC)

Use OIDC for cloud authentication (no long-lived credentials):

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # Required for OIDC
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/MyRole
          aws-region: us-east-1
```

## Environment Protection Rules

Use environments for sensitive deployments:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - name: Deploy
        run: ./deploy.sh
```

**Configure in repository settings:**

- Required reviewers
- Wait timer
- Deployment branches
- Environment secrets

## Security Checklist

### For Every Workflow

- [ ] Pin all third-party actions to commit SHAs
- [ ] Set minimal `permissions` at workflow/job level
- [ ] Use intermediate environment variables for user input
- [ ] Mask all secrets with `::add-mask::`
- [ ] Never echo secrets to logs
- [ ] Use double quotes for shell variables
- [ ] Prefer actions over inline scripts
- [ ] Use GitHub-hosted runners when possible
- [ ] Enable code scanning (CodeQL)
- [ ] Configure Dependabot for actions

### For Self-Hosted Runners

- [ ] Never use for public repositories
- [ ] Use JIT runners when possible
- [ ] Implement network isolation
- [ ] Use minimal, hardened OS images
- [ ] Rotate runners regularly
- [ ] Organize into restricted groups
- [ ] Monitor and audit runner activity
- [ ] Implement resource limits

### For Secrets

- [ ] Use GitHub Secrets (not environment variables)
- [ ] Rotate secrets regularly
- [ ] Delete exposed secrets immediately
- [ ] Audit secret usage
- [ ] Use environment-specific secrets
- [ ] Never use structured data as secrets
- [ ] Implement secret scanning

## Common Vulnerabilities

### Command Injection

```yaml
# VULNERABLE
run: echo "${{ github.event.comment.body }}"

# SAFE
env:
  COMMENT: ${{ github.event.comment.body }}
run: echo "$COMMENT"
```

### Secret Exposure

```yaml
# VULNERABLE
run: |
  echo "API Key: ${{ secrets.API_KEY }}"

# SAFE
run: |
  echo "::add-mask::${{ secrets.API_KEY }}"
  echo "API Key: ${{ secrets.API_KEY }}"
```

### Privilege Escalation

```yaml
# VULNERABLE - Too permissive
permissions: write-all

# SAFE - Minimal permissions
permissions:
  contents: read
  pull-requests: write
```

## Supply Chain Security

### OpenSSF Scorecard

Monitor your security posture:

```yaml
name: Scorecard
on:
  schedule:
    - cron: '0 0 * * 0'

jobs:
  analysis:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      id-token: write
    steps:
      - uses: actions/checkout@v3
      - uses: ossf/scorecard-action@v2
      - uses: github/codeql-action/upload-sarif@v2
```

### Software Bill of Materials (SBOM)

Track dependencies:

```yaml
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    path: ./
    format: spdx-json
```

## Incident Response

If a security incident occurs:

1. **Immediately rotate** all potentially compromised secrets
2. **Disable** affected workflows
3. **Review** workflow run logs
4. **Audit** repository access
5. **Check** for unauthorized changes
6. **Investigate** all workflow runs during incident window
7. **Document** findings and remediation
8. **Update** security controls to prevent recurrence

## Additional Resources

- [GitHub Security Advisories](https://github.com/advisories)
- [Actions Security Hardening](https://docs.github.com/actions/security-guides)
- [OIDC with Cloud Providers](https://docs.github.com/actions/deployment/security-hardening-your-deployments)
- [Self-Hosted Runner Security](https://docs.github.com/actions/hosting-your-own-runners/about-self-hosted-runners#self-hosted-runner-security)
