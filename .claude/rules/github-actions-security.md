# GitHub Actions Security

Pin all external actions to full SHA commits — never use `@main` or `@v1` floating refs.
In `.github/workflows/`, reference internal actions as `./<action-name>` — this avoids Renovate creating an endless self-update loop.
In `action.yml` files (used externally), reference internal actions as `ivuorinen/actions/<name>@<40-char-sha>`.
Always add `id:` to a step when its outputs are referenced via `steps.<id>.outputs.<key>`.
Always test regex patterns against pre-release inputs (`1.0.0-rc.1`, `1.0.0+build`).
