# ivuorinen/actions/stale

## Description

A GitHub Action to close stale issues and pull requests.

## Inputs

| parameter         | description                                                     | required | default |
|-------------------|-----------------------------------------------------------------|----------|---------|
| token             | GitHub token for authentication                                 | `false`  |         |
| days-before-stale | Number of days of inactivity before an issue is marked as stale | `false`  | 30      |
| days-before-close | Number of days of inactivity before a stale issue is closed     | `false`  | 7       |

## Outputs

| parameter           | description                      |
|---------------------|----------------------------------|
| staled_issues_count | Number of issues marked as stale |
| closed_issues_count | Number of issues closed          |

## Runs

This action is a `composite` action.
