# ivuorinen/actions/compress-images

## Compress Images

### Description

Compress images on demand (workflow_dispatch), and at 11pm every Sunday (schedule).

### Inputs

| name                | description                                               | required | default                            |
| ------------------- | --------------------------------------------------------- | -------- | ---------------------------------- |
| `token`             | <p>GitHub token for authentication</p>                    | `false`  | `${{ github.token }}`              |
| `username`          | <p>GitHub username for commits</p>                        | `false`  | `github-actions`                   |
| `email`             | <p>GitHub email for commits</p>                           | `false`  | `github-actions@github.com`        |
| `working-directory` | <p>Directory containing images to compress</p>            | `false`  | `.`                                |
| `image-quality`     | <p>JPEG compression quality (0-100)</p>                   | `false`  | `85`                               |
| `png-quality`       | <p>PNG compression quality (0-100)</p>                    | `false`  | `95`                               |
| `ignore-paths`      | <p>Paths to ignore during compression (glob patterns)</p> | `false`  | `node_modules/**,dist/**,build/**` |

### Outputs

| name                 | description                                         |
| -------------------- | --------------------------------------------------- |
| `images_compressed`  | <p>Whether any images were compressed (boolean)</p> |
| `compression_report` | <p>Markdown report of compression results</p>       |

### Runs

This action is a `composite` action.

### Usage

```yaml
- uses: ivuorinen/actions/compress-images@main
  with:
    token:
    # GitHub token for authentication
    #
    # Required: false
    # Default: ${{ github.token }}

    username:
    # GitHub username for commits
    #
    # Required: false
    # Default: github-actions

    email:
    # GitHub email for commits
    #
    # Required: false
    # Default: github-actions@github.com

    working-directory:
    # Directory containing images to compress
    #
    # Required: false
    # Default: .

    image-quality:
    # JPEG compression quality (0-100)
    #
    # Required: false
    # Default: 85

    png-quality:
    # PNG compression quality (0-100)
    #
    # Required: false
    # Default: 95

    ignore-paths:
    # Paths to ignore during compression (glob patterns)
    #
    # Required: false
    # Default: node_modules/**,dist/**,build/**
```
