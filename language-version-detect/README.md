# ivuorinen/actions/language-version-detect

## Description

DEPRECATED: This action is deprecated. Inline version detection directly in your actions instead. Detects language version from project configuration files with support for PHP, Python, Go, and .NET.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| language | Language to detect version for (php, python, go, dotnet) | `true` |  |
| default-version | Default version to use if no version is detected | `false` |  |
| token | GitHub token for authentication | `false` |  |

## Outputs

| parameter | description |
| --- | --- |
| detected-version | Detected or default language version |
| package-manager | Detected package manager (python: pip/poetry/pipenv, php: composer) |

## Runs

This action is a `composite` action.
