# GitHub Webhooks Batch Creation Module

This module provides an efficient way to create GitHub webhooks for a large number of repositories (200-250+) without hitting Terraform's limitations when using the standard GitHub provider resources.

## Architecture

Instead of using the standard `github_repository_webhook` resource for each repository, this module:

1. Takes a comma-separated list of repositories
2. Creates a script that uses GitHub's API directly
3. Creates webhooks in parallel batches to avoid rate limiting
4. Provides proper cleanup during terraform destroy

## Usage

```hcl
module "github_webhooks" {
  source = "./batch_webhooks"

  repositories = "org/repo1,org/repo2,org/repo3,...,org/repo250"
  webhook_url  = "https://your-webhook-endpoint.com"
  github_token = var.GITHUB_TOKEN
  events       = ["check_run", "workflow_run"]
}
```

## Requirements

- The GitHub token used must have permissions to create webhooks on all repositories
- `jq` must be installed on the system where Terraform runs
- Bash shell environment

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repositories | Comma-separated list of repositories in 'org/repo' format | `string` | n/a | yes |
| webhook_url | URL to which GitHub will send webhook payloads | `string` | n/a | yes |
| github_token | GitHub token with permissions to create webhooks | `string` | n/a | yes |
| events | List of GitHub events that trigger the webhook | `list(string)` | `["check_run", "workflow_run"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| repositories_count | Number of repositories configured with webhooks |
| webhook_url | URL to which GitHub will send webhook payloads |
| events | List of GitHub events that trigger the webhook |

## Implementation Details

The module works by:
- Splitting the repositories list into individual repos
- Creating a local file with the repository list
- Using a null_resource with local-exec provisioners to run a script that creates webhooks in batches
- The script processes repositories in parallel (up to 10 at a time by default)
- Includes proper cleanup during terraform destroy 