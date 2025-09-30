# Security Policy

## Supported Versions

All actions in this repository are actively maintained. Security updates are applied to all actions as needed.

| Version | Supported          |
|---------|--------------------|
| Latest  | :white_check_mark: |

## Security Features

This repository implements multiple layers of security controls to protect against common vulnerabilities:

### 1. Script Injection Prevention

**Status**: ✅ Implemented across all 43 actions

All shell scripts use environment variables instead of direct `${{ inputs.* }}` interpolation to prevent command injection attacks.

**Before** (vulnerable):

```yaml
run: |
  version="${{ inputs.version }}"
  echo "Version: $version"
```

**After** (secure):

```yaml
env:
  VERSION: ${{ inputs.version }}
run: |
  version="$VERSION"
  echo "Version: $version"
```

### 2. Secret Masking

**Status**: ✅ Implemented in 6 critical actions

Actions that handle sensitive data use GitHub Actions secret masking to prevent accidental exposure in logs:

- `npm-publish` - NPM authentication tokens
- `docker-publish-hub` - Docker Hub passwords
- `docker-publish-gh` - GitHub tokens
- `csharp-publish` - NuGet API keys
- `php-composer` - Composer authentication tokens
- `php-laravel-phpunit` - Database credentials

**Implementation**:

```yaml
run: |
  echo "::add-mask::$SECRET_VALUE"
```

### 3. SHA Pinning

All third-party actions are pinned to specific commit SHAs to prevent supply chain attacks:

```yaml
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

### 4. Input Validation

**Status**: ✅ Centralized validation system

All actions use comprehensive input validation to prevent:

- Path traversal attacks
- Command injection patterns
- ReDoS (Regular Expression Denial of Service)
- Malformed version strings
- Invalid URLs and file paths

**Key validation patterns**:

- Version strings: Semantic versioning, CalVer, flexible formats
- File paths: Path traversal prevention, absolute path validation
- Tokens: Format validation, injection pattern detection
- Boolean values: Strict true/false validation
- URLs: Protocol validation, basic structure checks

### 5. Permissions Documentation

**Status**: ✅ All 43 actions documented

Every action includes explicit permissions comments documenting required GitHub token permissions:

```yaml
# permissions:
#   - contents: write  # Required for creating releases
#   - packages: write  # Required for publishing packages
```

### 6. Official Action Usage

Third-party security tools use official maintained actions:

- **Bun**: `oven-sh/setup-bun@v2.0.2` (SHA-pinned)
- **Trivy**: `aquasecurity/trivy-action@0.33.1` (SHA-pinned)

## Security Best Practices

When using these actions in your workflows:

### 1. Use Least Privilege

Only grant the minimum required permissions:

```yaml
permissions:
  contents: write # Only if creating commits/releases
  packages: write # Only if publishing packages
  security-events: write # Only if uploading SARIF reports
```

### 2. Protect Secrets

- Never log sensitive values
- Use GitHub Secrets for all credentials
- Avoid exposing secrets in error messages
- Use secret masking for custom secrets

```yaml
- name: Use Secret
  env:
    API_KEY: ${{ secrets.API_KEY }}
  run: |
    echo "::add-mask::$API_KEY"
    # Use API_KEY safely
```

### 3. Validate Inputs

When calling actions, validate inputs match expected patterns:

```yaml
- uses: ./version-validator
  with:
    version: ${{ github.event.inputs.version }}
    validation-regex: '^[0-9]+\.[0-9]+\.[0-9]+$'
```

### 4. Pin Action Versions

Always use specific versions or commit SHAs:

```yaml
# Good: SHA-pinned
- uses: owner/action@abc123def456...

# Good: Specific version
- uses: owner/action@v1.2.3

# Bad: Mutable reference
- uses: owner/action@main
```

### 5. Review Action Code

Before using any action:

- Review the source code
- Check permissions requirements
- Verify input validation
- Examine shell script patterns
- Look for secret handling

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue:

### Reporting Process

1. **DO NOT** open a public issue
2. **DO** email security concerns to the repository owner
3. **DO** include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Report

Report any security concerns including:

- Command injection vulnerabilities
- Path traversal issues
- Secret exposure in logs
- ReDoS vulnerabilities
- Unsafe input handling
- Supply chain security issues
- Privilege escalation risks

### Response Timeline

- **24 hours**: Initial response acknowledging receipt
- **7 days**: Assessment and severity classification
- **30 days**: Fix developed and tested (for confirmed vulnerabilities)
- **Public disclosure**: Coordinated after fix is released

### Security Updates

When security issues are fixed:

1. A patch is released
2. Affected actions are updated
3. Security advisory is published
4. Users are notified via GitHub Security Advisories

## Audit History

### Phase 1: Script Injection Prevention (2024)

- Converted 43 actions to use environment variables
- Eliminated all direct `${{ inputs.* }}` usage in shell scripts
- Added comprehensive input validation
- Status: ✅ Complete

### Phase 2: Enhanced Security (2024)

- Replaced custom Bun installation with official action
- Replaced custom Trivy installation with official action
- Added secret masking to 6 critical actions
- Optimized file hashing in common-cache
- Status: ✅ Complete

### Phase 3: Documentation & Policy (2024)

- Added permissions comments to all 43 actions
- Created security policy (this document)
- Documented best practices
- Status: ✅ Complete

## Security Testing

All actions include:

- **Unit tests**: ShellSpec tests for action logic
- **Integration tests**: End-to-end workflow validation
- **Validation tests**: pytest tests for input validation
- **Security tests**: Command injection prevention tests

Run security tests:

```bash
make test
```

## Additional Resources

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [CWE-78: OS Command Injection](https://cwe.mitre.org/data/definitions/78.html)
- [Supply Chain Security](https://slsa.dev/)

## License

This security policy is part of the repository and follows the same license.

## Contact

For security concerns: Create a private security advisory in the repository's Security tab.

---

**Last Updated**: 2025-09-29
**Policy Version**: 1.0.0
