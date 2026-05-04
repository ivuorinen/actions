# GitHub Output Format

Always use printf with format-string separation for GITHUB_OUTPUT — never echo:
`printf 'key=%s\n' "$value" >> "$GITHUB_OUTPUT"`
Never use: `echo "key=$value" >> "$GITHUB_OUTPUT"`
Never nest `${{ }}` expressions inside quoted YAML strings (breaks hashFiles).
