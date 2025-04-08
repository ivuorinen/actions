#!/usr/bin/env bash

# Error handling
set -euo pipefail

# Log file
log_file="update_$(date +%Y%m%d_%H%M%S).log"
exec 1> >(tee -a "$log_file") 2>&1

# Error handling function
handle_error() {
  echo "❌ Error on line $1" | tee -a "$log_file"
  exit 1
}
trap 'handle_error $LINENO' ERR

echo "🚀 Starting update $(date)"

# Check required tools
for cmd in npx sed find grep; do
  if ! command -v $cmd &>/dev/null; then
    echo "- ⚠️ Error: $cmd not found" | tee -a "$log_file"
    exit 1
  fi
done

# Check if the OS is macOS or Linux
if [[ $OSTYPE == "darwin"* ]]; then
  # macOS needs -i .bak because it doesn't support -i without arguments
  SED_CMD="sed -i .bak"
else
  # Linux supports -i without arguments
  SED_CMD="sed -i"
fi

# Iterate over directories
echo "📂 Iterating over directories..."
find . -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
  (
    echo "🔍 Found directory: $dir"
    dir=${dir#./}
    action="./$dir/action.yml"

    if [ -f "$action" ]; then
      echo "- 📄 Found action.yml in $dir"

      repo="ivuorinen/actions/$dir"
      readme="./$dir/README.md"
      version=$(grep -E '^# version:' "$action" | cut -d ' ' -f 2)

      # if version doesn't exist, use 'main'
      if [ -z "$version" ]; then
        version="main"
        echo "- ℹ️ Version not set in $dir/action.yml, using 'main'"
      fi

      echo "- 📝 Updating $readme..."

      printf "# %s\n\n" "$repo" >"$readme"

      echo "- 📄 Generating action documentation..."
      if ! npx --yes action-docs@latest \
        --source="$action" \
        --no-banner \
        --include-name-header >>"$readme"; then
        echo "- ⚠️ Warning: action-docs failed in $dir directory" | tee -a "$log_file"
      fi

      echo "- 🔄 Replacing placeholders in $readme..."
      $SED_CMD "s|PROJECT|$repo|g; s|VERSION|$version|g; s|\*\*\*||g" "$readme"

      if [ -f "$readme.bak" ]; then
        rm "$readme.bak"
        echo "- 🗑️  Removed $readme.bak"
      fi
    else
      # if action doesn't exist, skip
      echo "- ⏩ Skipping $dir - action.yml missing"
    fi
  ) || {
    echo "- ⚠️ Warning: Error processing directory $dir" |
      tee -a "$log_file"
  }
  echo ""
done
echo ""

echo "🔍 Running markdownlint..."
if ! npx --yes markdownlint-cli --fix \
  --ignore "**/node_modules/**" "**/README.md"; then
  echo "⚠️ Warning: markdownlint found issues" | tee -a "$log_file"
fi
echo ""

echo "✨ Running prettier..."
if ! npx --yes prettier --write \
  "**/README.md" "**/action.yml" ".github/workflows/*.yml"; then
  echo "- ⚠️ Warning: prettier formatting failed" | tee -a "$log_file"
fi
echo ""

# Run markdown-table-formatter
echo "🔍 Running markdown-table-formatter..."
if ! npx --yes markdown-table-formatter "**/README.md"; then
  echo "- ⚠️ Warning: markdown-table-formatter found issues" | tee -a "$log_file"
fi
echo ""

echo "🔎 Running MegaLinter..."
if ! npx --yes mega-linter-runner --flavor cupcake --fix --remove-container --container-name cupcake; then
  echo "- ⚠️ Warning: MegaLinter found issues" | tee -a "$log_file"
fi
echo ""

# Summary report
echo "📊 Summary $(date):"
echo "- Log file: $log_file"
if [ -f "$log_file" ]; then
  warnings=$(grep -c "⚠️ Warning" "$log_file" || true)
  echo "- Warnings: $warnings"
fi
echo "- Status: ✅ Ready"
