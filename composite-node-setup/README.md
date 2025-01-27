# Node Setup (ivuorinen/actions/composite-node-setup)

## Overview

This action sets up a Node.js environment based on the configuration files in
the repository.
It supports `.nvmrc` and `.tool-versions` files and falls back to a default
version if no configuration files are found.

## Features

- Automatically detects Node.js version from `.nvmrc` or `.tool-versions`.
- Uses a default Node.js version if no configuration files are found.
- Integrates seamlessly with `actions/setup-node`.

## Inputs

The following inputs are supported by the action:

- `default-version` (optional): Default Node.js version to use if no
  configuration file is found. Default is `22`.

## Usage

### Example Workflow

```yaml
steps:
    -   name: Checkout Code
        uses: actions/checkout@v4

    -   name: Setup Node.js
        uses: ivuorinen/actions/composite-node-setup@main

    -   name: Install Dependencies
        run: npm install

    -   name: Run Build
        run: npm run build
```

## Notes

- Ensure that your `.nvmrc` or `.tool-versions` files are correctly formatted
  for automatic detection.
- The default version will be used if no configuration files are present.

## Troubleshooting

1. **Node.js Version Not Detected:**
    - Verify that `.nvmrc` or `.tool-versions` exists and is correctly
      formatted.
    - Ensure the `default-version` input is set to a valid Node.js version.

2. **Permission Issues:**
    - Make sure the runner has access to modify files and install Node.js.

## License

This action is licensed under the MIT License. See
the [LICENSE](../LICENSE.md) file for details.
