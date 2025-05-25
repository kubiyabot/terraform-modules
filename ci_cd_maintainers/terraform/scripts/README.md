# GitHub Webhook Management Scripts

This directory contains scripts used for efficient management of GitHub webhooks at scale.

## Overview

These scripts provide a solution for managing GitHub webhooks across large numbers of repositories (200-250+) without hitting Terraform state limitations. Instead of using individual `github_repository_webhook` resources that would create hundreds of resources in the Terraform state, this approach uses a more efficient pattern with bash scripts and API calls.

## Scripts

### manage_webhooks.sh

This script efficiently creates or deletes GitHub webhooks in parallel batches. It's designed to work with the Terraform module as an alternative to using individual `github_repository_webhook` resources.

#### Features

- **Parallel Processing**: Processes webhooks in parallel (10 concurrent by default)
- **Rate Limit Management**: Includes delays between batches to avoid hitting rate limits
- **Error Handling**: Captures success/failure for each operation
- **Logging**: Detailed logs for debugging
- **Token Validation**: Validates the GitHub token before proceeding
- **Repository Access Validation**: Verifies that the token has appropriate access to each repository
- **Admin Permissions Check**: Ensures the token has admin rights needed for webhook management

### Test Scripts

The `test/` directory contains scripts for validating GitHub token access and testing webhook operations:

- `test_script.sh`: A test runner that can validate token access without creating webhooks
- `test_repos.txt`: A sample repository list for testing

## Usage

The scripts are typically called from Terraform, but can also be used directly:

```bash
# Create webhooks
./manage_webhooks.sh <github_token> <webhook_url> <events> <repos_file> create

# Delete webhooks
./manage_webhooks.sh <github_token> <webhook_url> <events> <repos_file> delete
```

## Testing

Before applying in production, you can test your GitHub token and repository access:

```bash
cd test
# Edit test_repos.txt with your repositories
./test_script.sh <github_token>
```

This validation-only mode will check your token permissions without creating actual webhooks.

## Integration with Terraform

These scripts are designed to be called from a Terraform `null_resource` with `local-exec` provisioners as defined in the parent module. 