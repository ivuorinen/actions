"""Test data for version validation tests."""

# CalVer test cases
CALVER_VALID = [
    ("2024.3.1", "YYYY.MM.PATCH format"),
    ("2024.03.15", "YYYY.MM.DD format"),
    ("2024.03.05", "YYYY.0M.0D format"),
    ("24.3.1", "YY.MM.MICRO format"),
    ("2024.3", "YYYY.MM format"),
    ("2024-03-15", "YYYY-MM-DD format"),
    ("v2024.3.1", "CalVer with v prefix"),
    ("2023.12.31", "Year-end date"),
    ("2024.1.1", "Year start date"),
]

CALVER_INVALID = [
    ("2024.13.1", "Invalid month (13)"),
    ("2024.0.1", "Invalid month (0)"),
    ("2024.3.32", "Invalid day (32)"),
    ("2024.2.30", "Invalid day for February"),
    ("24.13.1", "Invalid month in YY format"),
    ("2024-13-15", "Invalid month in YYYY-MM-DD"),
    ("2024.3.1.1", "Too many components"),
    ("24.3", "YY.MM without patch"),
]

# SemVer test cases
SEMVER_VALID = [
    ("1.0.0", "Basic SemVer"),
    ("1.2.3", "Standard SemVer"),
    ("10.20.30", "Multi-digit versions"),
    ("1.1.2-prerelease", "Prerelease version"),
    ("1.1.2+meta", "Build metadata"),
    ("1.1.2-prerelease+meta", "Prerelease with metadata"),
    ("1.0.0-alpha", "Alpha version"),
    ("1.0.0-beta", "Beta version"),
    ("1.0.0-alpha.beta", "Complex prerelease"),
    ("1.0.0-alpha.1", "Numeric prerelease"),
    ("1.0.0-alpha0.beta", "Mixed prerelease"),
    ("1.0.0-alpha.1", "Alpha with number"),
    ("1.0.0-alpha.1.2", "Complex alpha"),
    ("1.0.0-rc.1", "Release candidate"),
    ("2.0.0-rc.1+build.1", "RC with build"),
    ("2.0.0+build.1", "Build metadata only"),
    ("1.2.3-beta", "Beta prerelease"),
    ("10.2.3-DEV-SNAPSHOT", "Dev snapshot"),
    ("1.2.3-SNAPSHOT-123", "Snapshot build"),
    ("v1.2.3", "SemVer with v prefix"),
    ("v1.0.0-alpha", "v prefix with prerelease"),
    ("1.0", "Major.minor only"),
    ("1", "Major only"),
]

SEMVER_INVALID = [
    ("1.2.a", "Non-numeric patch"),
    ("a.b.c", "Non-numeric versions"),
    ("1.2.3-", "Empty prerelease"),
    ("1.2.3+", "Empty build metadata"),
    ("1.2.3-+", "Empty prerelease and metadata"),
    ("+invalid", "Invalid start"),
    ("-invalid", "Invalid start"),
    ("-invalid+invalid", "Invalid format"),
    ("1.2.3.DEV.SNAPSHOT", "Too many dots"),
]

# Flexible version test cases (should accept both CalVer and SemVer)
FLEXIBLE_VALID = CALVER_VALID + SEMVER_VALID + [("latest", "Latest tag")]

FLEXIBLE_INVALID = [
    ("not-a-version", "Random string"),
    ("", "Empty string"),
    ("1.2.3.4.5", "Too many components"),
    ("1.2.-3", "Negative number"),
    ("1.2.3-", "Trailing dash"),
    ("1.2.3+", "Trailing plus"),
    ("1..2", "Double dot"),
    ("v", "Just v prefix"),
    ("version", "Word version"),
]

# Docker version test cases
DOCKER_VALID = [
    ("latest", "Latest tag"),
    ("v1.0.0", "Version tag"),
    ("1.0.0", "SemVer tag"),
    ("2024.3.1", "CalVer tag"),
    ("main", "Branch name"),
    ("feature-branch", "Feature branch"),
    ("sha-1234567", "SHA tag"),
]

DOCKER_INVALID = [
    ("", "Empty tag"),
    ("invalid..tag", "Double dots"),
    ("invalid tag", "Spaces not allowed"),
    ("INVALID", "All caps not preferred"),
]

# GitHub token test cases
GITHUB_TOKEN_VALID = [
    ("github_pat_" + "a" * 71, "Fine-grained PAT"),  # 11 + 71 = 82 chars total
    ("ghp_" + "a" * 36, "Classic PAT"),  # 4 + 36 = 40 chars total
    ("gho_" + "a" * 36, "OAuth token"),  # 4 + 36 = 40 chars total
    ("ghu_" + "a" * 36, "User token"),
    ("ghs_" + "a" * 36, "Installation token"),
    ("ghr_" + "a" * 36, "Refresh token"),
    ("${{ github.token }}", "GitHub Actions expression"),
    ("${{ secrets.GITHUB_TOKEN }}", "Secrets expression"),
]

GITHUB_TOKEN_INVALID = [
    ("", "Empty token"),
    ("invalid-token", "Invalid format"),
    ("ghp_short", "Too short"),
    ("wrong_prefix_" + "a" * 36, "Wrong prefix"),
    ("github_pat_" + "a" * 50, "Wrong length for PAT"),
]

# Email test cases
EMAIL_VALID = [
    ("user@example.com", "Basic email"),
    ("test.email@domain.co.uk", "Complex email"),
    ("user+tag@example.org", "Email with plus"),
    ("123@example.com", "Numeric local part"),
]

EMAIL_INVALID = [
    ("", "Empty email"),
    ("notanemail", "No @ symbol"),
    ("@example.com", "Missing local part"),
    ("user@", "Missing domain"),
    ("user@@example.com", "Double @ symbol"),
]

# Username test cases
USERNAME_VALID = [
    ("user", "Simple username"),
    ("user123", "Username with numbers"),
    ("user-name", "Username with dash"),
    ("user_name", "Username with underscore"),
    ("a" * 39, "Maximum length"),
]

USERNAME_INVALID = [
    ("", "Empty username"),
    ("user;name", "Command injection"),
    ("user&&name", "Command injection"),
    ("user|name", "Command injection"),
    ("user`name", "Command injection"),
    ("user$(name)", "Command injection"),
    ("a" * 40, "Too long"),
]

# File path test cases
FILE_PATH_VALID = [
    ("file.txt", "Simple file"),
    ("path/to/file.txt", "Relative path"),
    ("folder/subfolder/file.ext", "Deep path"),
    ("", "Empty path (optional)"),
]

FILE_PATH_INVALID = [
    ("../file.txt", "Path traversal"),
    ("/absolute/path", "Absolute path"),
    ("path/../file.txt", "Path traversal in middle"),
    ("path/../../file.txt", "Multiple path traversal"),
]

# Numeric range test cases
NUMERIC_RANGE_VALID = [
    ("0", "Minimum value"),
    ("50", "Middle value"),
    ("100", "Maximum value"),
    ("42", "Answer to everything"),
]

NUMERIC_RANGE_INVALID = [
    ("", "Empty value"),
    ("-1", "Below minimum"),
    ("101", "Above maximum"),
    ("abc", "Non-numeric"),
    ("1.5", "Decimal not allowed"),
]

# Boolean test cases
BOOLEAN_VALID = [
    ("true", "Boolean true"),
    ("false", "Boolean false"),
    ("True", "Capitalized true"),
    ("False", "Capitalized false"),
    ("TRUE", "Uppercase true"),
    ("FALSE", "Uppercase false"),
]

BOOLEAN_INVALID = [
    ("", "Empty boolean"),
    ("yes", "Yes not allowed"),
    ("no", "No not allowed"),
    ("1", "Numeric not allowed"),
    ("0", "Numeric not allowed"),
    ("maybe", "Invalid value"),
]
