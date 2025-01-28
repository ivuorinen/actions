# ivuorinen/actions/release-monthly

## Do Monthly Release

### Inputs

| name    | description         | type     | required | default               |
| ------- | ------------------- | -------- | -------- | --------------------- |
| `token` | <p>GitHub Token</p> | `string` | `false`  | `${{ github.token }}` |

### Usage

```yaml
jobs:
    job1:
        uses: ivuorinen/actions/release-monthly@main
        with:
            token:
            # GitHub Token
            #
            # Type: string
            # Required: false
            # Default: ${{ github.token }}
```
