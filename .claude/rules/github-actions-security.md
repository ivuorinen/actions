# GitHub Actions Security

Pin all external actions to full SHA commits — never use `@main` or `@v1` floating refs.
Reference internal actions as `ivuorinen/actions/<name>@<40-char-sha>` — never `./` or `@main`.
Always add `id:` to a step when its outputs are referenced via `steps.<id>.outputs.<key>`.
Always test regex patterns against pre-release inputs (`1.0.0-rc.1`, `1.0.0+build`).
