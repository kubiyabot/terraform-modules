# Testing the GitHub Webhook Management Script

This directory contains tools for testing the webhook management script locally before using it in production.

## Prerequisites

1. A GitHub Personal Access Token (PAT) with appropriate permissions:
   - For public repositories: `public_repo` scope
   - For private repositories: `repo` scope
   - You can create a token at: https://github.com/settings/tokens

2. Required tools:
   - `curl`
   - `jq`
   - Bash shell

## Test Files

- `test_repos.txt`: Sample list of repositories to test with
- `test_script.sh`: Test runner script with validation capabilities

## How to Test

### 1. Edit the Repository List

Edit `test_repos.txt` to include repositories you want to test. The default file includes some popular public repositories, but for a thorough test, include repositories that:

- You own
- You have collaborator access to
- You don't have access to

This will help verify that the validation is working correctly.

```
your-org/your-repo
your-username/your-personal-repo
public-org/public-repo
```

### 2. Run Validation Only (Recommended)

To test the script's validation functionality without creating any webhooks:

```bash
./test_script.sh YOUR_GITHUB_TOKEN
```

This will:
- Validate your GitHub token
- Check access to each repository
- Verify admin permissions where needed
- Report any issues without creating webhooks

### 3. Test Creating Webhooks (Optional)

To test creating actual webhooks:

```bash
./test_script.sh YOUR_GITHUB_TOKEN create
```

> **Warning**: This will create real webhooks on the repositories you have access to!

The test uses `https://example.com/webhook` as the webhook URL, which won't receive any events (it's not a real endpoint).

### 4. Test Deleting Webhooks (Cleanup)

If you created webhooks with the previous step:

```bash
./test_script.sh YOUR_GITHUB_TOKEN delete
```

This will remove any webhooks pointing to the test URL.

## Understanding Test Results

The test script provides color-coded output:
- 🟢 Green: Success
- 🔴 Red: Errors
- 🟡 Yellow: Warnings
- 🔵 Blue: Information

### Example Output - Successful Validation

```
===== GitHub Webhook Script Test =====
This script will test the webhook management script with the following parameters:
  Repository File: /path/to/test_repos.txt
  Webhook URL: https://example.com/webhook
  Events: check_run,workflow_run

Checking GitHub token validity...
Token validated successfully for user: your-username

Running validation only (no webhooks will be created or deleted)...
Validating GitHub token and repository access...
Checking GitHub token validity...
Token validated successfully for user: your-username
Checking repository access...
Validated 5 repositories so far...
Repository validation complete.
Total repositories: 5
Failed validations: 1
ERROR: Validation failed for 1 out of 5 repositories.
Failed repositories:
  - some-org/private-repo (HTTP 404)
WARNING: Some repositories failed validation but continuing as failure rate is below 10%.

===== Validation Complete =====
✅ Validation passed. The token has appropriate access to the repositories.
✅ Validation successful!
```

### Example Output - Failed Validation

```
===== GitHub Webhook Script Test =====
This script will test the webhook management script with the following parameters:
  Repository File: /path/to/test_repos.txt
  Webhook URL: https://example.com/webhook
  Events: check_run,workflow_run

Checking GitHub token validity...
Token validated successfully for user: your-username

Running validation only (no webhooks will be created or deleted)...
Validating GitHub token and repository access...
Checking GitHub token validity...
Token validated successfully for user: your-username
Checking repository access...
Repository validation complete.
Total repositories: 5
Failed validations: 3
ERROR: Validation failed for 3 out of 5 repositories.
Failed repositories:
  - org1/repo1 (No admin rights)
  - org2/repo2 (HTTP 404)
  - org3/repo3 (HTTP 403)
ERROR: More than 10% of repositories failed validation. Aborting.

===== Validation Complete =====
❌ Validation failed. See above for details.
❌ Validation failed!
```

## Troubleshooting

1. **Missing jq error**: Install jq with your package manager (e.g., `apt install jq`, `brew install jq`)

2. **Token permission errors**: Ensure your token has the correct scopes

3. **Repository access issues**: Make sure you have the correct permissions on the repositories 