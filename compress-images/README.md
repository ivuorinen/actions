# ivuorinen/actions/compress-images

## Description

Compress images on demand (workflow_dispatch), and at 11pm every Sunday (schedule).

## Inputs

| parameter         | description                                        | required | default                            |
|-------------------|----------------------------------------------------|----------|------------------------------------|
| token             | GitHub token for authentication                    | `false`  | ${{ github.token }}                |
| username          | GitHub username for commits                        | `false`  | github-actions                     |
| email             | GitHub email for commits                           | `false`  | <github-actions@github.com>        |
| working-directory | Directory containing images to compress            | `false`  | .                                  |
| image-quality     | JPEG compression quality (0-100)                   | `false`  | 85                                 |
| png-quality       | PNG compression quality (0-100)                    | `false`  | 95                                 |
| ignore-paths      | Paths to ignore during compression (glob patterns) | `false`  | node_modules/**,dist/**,build/\*\* |

## Outputs

| parameter          | description                                  |
|--------------------|----------------------------------------------|
| images_compressed  | Whether any images were compressed (boolean) |
| compression_report | Markdown report of compression results       |

## Runs

This action is a `composite` action.
