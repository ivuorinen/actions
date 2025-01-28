#!/usr/bin/env bash

# Check if the OS is macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS needs -i .bak because it doesn't support -i without arguments
    SED_CMD="sed -i .bak"
else
    # Linux supports -i without arguments
    SED_CMD="sed -i"
fi

find . -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    dir=${dir#./}
    action="./$dir/action.yml"

    # if action doesn't exist, skip
    if [ ! -f "$action" ]; then
        continue
    fi

    repo="ivuorinen/actions/$dir"
    readme="./$dir/README.md"
    version=$(grep -E '^# version:' "$action" | cut -d ' ' -f 2)

    # if version doesn't exist, use 'main'
    if [ -z "$version" ]; then
        version="main"
    fi

    echo "Updating $readme..."

    printf "# %s\n\n" "$repo" >"$readme"

    echo "- Generating action documentation..."
    npx --yes action-docs@latest \
        --source="$action" \
        --no-banner \
        --include-name-header >>"$readme"

    echo "- Replacing placeholders in $readme..."
    $SED_CMD "s|PROJECT|$repo|g; s|VERSION|$version|g; s|\*\*\*||g" "$readme"

    if [ -f "$readme.bak" ]; then
        rm "$readme.bak"
        echo "- Removed $readme.bak"
    fi
done
echo ""

echo "Running prettier..."
npx --yes prettier --write "**/README.md"
echo ""

echo "Running markdownlint..."
npx --yes markdownlint-cli --fix --ignore "**/node_modules/**" "**/README.md"
echo ""

echo "Done!"
