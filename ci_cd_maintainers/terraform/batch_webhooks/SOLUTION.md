# Efficient GitHub Webhook Management for Large Numbers of Repositories

## Problem Statement

The current implementation uses Terraform's `github_repository_webhook` resource in a loop with `for_each` to create webhooks for repositories. This approach has limitations when dealing with a large number of repositories (200-250+):

1. **Terraform State Size**: Each webhook becomes a resource in Terraform state, leading to large state files
2. **Memory Usage**: Terraform needs to keep all these resources in memory during operations
3. **API Rate Limiting**: GitHub may rate-limit API calls during apply/destroy operations
4. **Apply Time**: Creating resources one by one can take a long time
5. **Terraform Resource Limits**: There can be practical limits to how many resources Terraform can efficiently manage in a single configuration

## Solution: Batch Webhook Management

This module provides an alternative approach by leveraging GitHub's API directly through a shell script, which can process webhooks in parallel batches:

### Key Components

1. **External Script**: A Bash script (`manage_webhooks.sh`) that uses cURL to interact with GitHub's API
2. **Parallel Processing**: Creates/deletes webhooks in parallel (10 concurrent by default)
3. **Rate Limit Management**: Includes delays between batches to avoid hitting rate limits
4. **Single Terraform Resource**: Uses just one `null_resource` instead of hundreds of resources
5. **Clean Teardown**: Includes proper cleanup during terraform destroy
6. **Error Handling**: Logs failures for debugging

### Architecture

```
┌───────────────────┐      ┌───────────────────┐     ┌───────────────────┐
│                   │      │                   │     │                   │
│  Terraform        │─────▶│  Bash Script      │────▶│  GitHub API       │
│  null_resource    │      │  (parallel calls) │     │                   │
│                   │      │                   │     │                   │
└───────────────────┘      └───────────────────┘     └───────────────────┘
```

### Performance Comparison

| Metric                 | Standard Approach         | Batch Approach               |
|------------------------|---------------------------|------------------------------|
| Terraform State Size   | Grows with each webhook   | Constant (single resource)   |
| Memory Usage           | High for many repos       | Low (constant)              |
| Apply Time (200 repos) | ~15-30 minutes           | ~1-3 minutes                |
| Rate Limit Handling    | None (potential failures) | Built-in retry/throttling   |
| Parallel Execution     | None                      | Configurable (default: 10)  |

## Implementation Details

### Script Functionality

The external script (`manage_webhooks.sh`) handles:

1. **Webhook Creation**: Uses GitHub's REST API to create webhooks
2. **Webhook Deletion**: Queries existing webhooks and deletes matching ones
3. **Parallel Processing**: Processes multiple repositories simultaneously 
4. **Rate Limiting**: Throttles requests to avoid hitting GitHub API limits
5. **Logging**: Captures success/failure for each operation

### Terraform Integration

The module integrates with Terraform through:

1. A `local_file` resource to create the repository list file
2. A `null_resource` with `local-exec` provisioners to run the script
3. Proper `triggers` to ensure script runs when needed
4. Clean destroy provisioning

## How to Use

1. Replace the standard webhook resources with this module
2. Pass the same parameters you would use for the individual resources
3. No changes to your code that uses the webhook URL

## Advantages

1. **Scalability**: Easily handles hundreds of repositories
2. **Performance**: Much faster than creating individual resources
3. **Reliability**: Better handling of API rate limits
4. **Simplicity**: Reduced Terraform complexity
5. **Maintenance**: Single module to maintain vs many resources

## Limitations

1. Requires `jq` and Bash on the system running Terraform
2. Less visibility into individual webhook statuses in Terraform state
3. GitHub token must have permissions on all repositories

## Future Improvements

1. Support for more webhook configuration options
2. More detailed status reporting back to Terraform
3. Option to skip existing webhooks instead of recreating 