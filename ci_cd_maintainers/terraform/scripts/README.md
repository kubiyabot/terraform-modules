# GitHub Webhook Management Scripts

This directory contains scripts used for efficient management of GitHub webhooks at scale.

## Scripts

### manage_webhooks.sh

This script efficiently creates or deletes GitHub webhooks for large numbers of repositories (200-250+) in parallel. It's designed to work with the batch_webhooks Terraform module as an alternative to using individual `github_repository_webhook` resources.

#### Usage

```bash
./manage_webhooks.sh <github_token> <webhook_url> <events> <repos_file> <action>
```

Parameters:
- `github_token`: GitHub personal access token with permissions to manage webhooks
- `webhook_url`: The URL to which GitHub will send webhook payloads
- `events`: Comma-separated list of GitHub events to trigger the webhook
- `repos_file`: Path to a file containing one repository (in org/repo format) per line
- `action`: Either `create` or `delete`

#### Features

- **Parallel Processing**: Processes webhooks in parallel (10 concurrent by default)
- **Rate Limit Management**: Includes delays between batches to avoid hitting rate limits
- **Error Handling**: Captures success/failure for each operation
- **Logging**: Detailed logs for debugging
- **Token Validation**: Validates the GitHub token before proceeding
- **Repository Access Validation**: Verifies that the token has appropriate access to each repository
- **Admin Permissions Check**: Ensures the token has admin rights needed for webhook management
- **Graceful Failure Handling**: Can proceed if fewer than 10% of repositories fail validation

#### Validation Process

The script performs the following validation steps before making any changes:

1. **Tool Verification**: Checks that required tools (`curl`, `jq`) are installed
2. **Token Validation**: Verifies the GitHub token is valid by retrieving user information
3. **Repository Access Check**: Tests access to each repository
4. **Admin Rights Verification**: Confirms the token has admin permissions needed for webhook management
5. **Failure Threshold**: Aborts if more than 10% of repositories fail validation, otherwise provides warnings

#### Requirements

- `curl` for API calls
- `jq` for JSON parsing
- Bash shell environment
- GitHub token with admin permissions on repositories

#### Example

```bash
# Create webhooks for repositories in repos.txt
./manage_webhooks.sh ghp_abcdef1234567890 https://webhook.example.com/path check_run,workflow_run repos.txt create

# Delete webhooks
./manage_webhooks.sh ghp_abcdef1234567890 https://webhook.example.com/path check_run,workflow_run repos.txt delete
```

#### Logs and Output

The script creates several log files in a temporary directory:
- Main operation log (displayed at the end of execution)
- Validation log with detailed validation results
- Individual repository logs for debugging specific issues

## Integration with Terraform

This script is designed to be called from a Terraform `null_resource` with `local-exec` provisioners. See the `batch_webhooks` module for the implementation. 