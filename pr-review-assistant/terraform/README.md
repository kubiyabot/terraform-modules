# Simple PR Review Assistant

Automated PR reviewer that triggers on GitHub webhook events, analyzes pull requests, and sends notifications via Slack.

## Features

- 🔄 **Automatic Triggering** - GitHub webhook on PR opened/synchronized/reopened
- ✅ **PR Analysis** - Fetches and analyzes PR details from GitHub
- 👥 **Smart Tagging** - Identifies and tags repo owner and reviewers
- 🔍 **Security Scanning** - Analyzes for security and quality issues
- 💬 **GitHub Comments** - Posts recommendations directly on PRs
- 📢 **Slack Notifications** - Sends detailed analysis to Slack

## Prerequisites

- Terraform >= 1.0.0
- Kubiya API key
- GitHub personal access token with repo permissions
- Slack API token (bot token with chat:write scope)
- Kubiya runner configured

## Quick Start

### 1. Deploy with Terraform

Clone the repository:
```bash
git clone https://github.com/kubiyabot/terraform-modules.git
cd terraform-modules/simple-pr-review-assistant/terraform
```

Set environment variables:
```bash
export KUBIYA_API_KEY="your-api-key"
export TF_VAR_github_token="github-token"
export TF_VAR_slack_token="slack-token"
export TF_VAR_kubiya_runner="your-runner"
```

Deploy the module:
```bash
terraform init
terraform plan
terraform apply
```

### 2. Configure GitHub Webhook

After deployment, get the webhook URL:
```bash
terraform output webhook_url
```

In your GitHub repository:
1. Go to **Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: Paste the webhook URL from terraform output
3. **Content type**: `application/json`
4. **Secret**: (leave blank or add if you want extra security)
5. **Which events?**: Select "Let me select individual events"
   - Check: **Pull requests**
6. **Active**: ✓ Check this box
7. Click **Add webhook**

### 3. Test the Integration

Create or update a pull request in your repository. The assistant will:
1. Automatically trigger when PR is opened/synchronized/reopened
2. Analyze the code for security issues
3. Calculate risk score
4. Post a comment with recommendation (APPROVE/REQUEST_CHANGES/COMMENT)
5. Send notification to Slack with full details

## Configuration Examples

### Basic Setup
```hcl
module "simple_pr_reviewer" {
  source = "./simple-pr-review-assistant/terraform"
  
  kubiya_runner         = "default"
  github_token          = var.github_token
  slack_token           = var.slack_token
  default_slack_channel = "#pr-reviews"
}
```

### Repository-Specific Configuration
```hcl
module "simple_pr_reviewer" {
  source = "./simple-pr-review-assistant/terraform"
  
  agent_name               = "myrepo-pr-reviewer"
  kubiya_runner            = "production"
  github_token             = var.github_token
  slack_token              = var.slack_token
  github_repository_filter = "myorg/myrepo"  # Only this repo
  default_slack_channel    = "#myrepo-prs"
  
  # Optional: restrict to specific users/groups
  kubiya_groups = ["backend-team", "qa-team"]
  kubiya_users  = ["john.doe", "jane.smith"]
}
```

### Debug Configuration
```hcl
module "simple_pr_reviewer" {
  source = "./simple-pr-review-assistant/terraform"
  
  kubiya_runner         = "default"
  github_token          = var.github_token
  slack_token           = var.slack_token
  default_slack_channel = "#pr-reviews"
  
  # Enable debug logging
  log_level  = "DEBUG"
  debug_mode = true
}
```

## Webhook Events

The assistant automatically triggers on:
- `pull_request.opened` - New PR created
- `pull_request.synchronize` - PR updated with new commits
- `pull_request.reopened` - Previously closed PR reopened

## Manual Usage

You can also trigger reviews manually using the Kubiya CLI:

```bash
# Review a specific PR
kubiya run review_and_notify_pr \
  --pr_url "https://github.com/org/repo/pull/123" \
  --slack_channel "#team-reviews"

# Use default Slack channel
kubiya run review_and_notify_pr \
  --pr_url "https://github.com/org/repo/pull/456"
```

## Event Flow

```
GitHub PR Event
     ↓
GitHub Webhook
     ↓
Kubiya Webhook (receives payload)
     ↓
Kubiya Agent (triggered via prompt)
     ↓
review_and_notify_pr Tool
     ↓
┌────────────────────────┐
│  5 Step Review Process │
├────────────────────────┤
│ 1. Fetch PR details    │
│ 2. Identify reviewers  │
│ 3. Analyze code        │
│ 4. Post GitHub comment │
│ 5. Send Slack message  │
└────────────────────────┘
```

## Security Analysis

The assistant checks for:

| Issue Type | Risk Score | Description |
|------------|------------|-------------|
| Hardcoded Credentials | +30 | Detects passwords, API keys, secrets in code |
| SQL Injection | +25 | Identifies potential SQL injection vulnerabilities |
| Eval/Exec Usage | +20 | Flags dangerous eval() or exec() calls |
| Large PR Size | +10 | Warns when >50 files changed |
| Large Changeset | +10 | Warns when >1000 lines changed |

### Risk Score Thresholds

- **0-24**: ✅ APPROVE - Low risk changes
- **25-49**: 💬 COMMENT - Medium risk, needs review
- **50+**: ❌ REQUEST_CHANGES - High risk, changes required

## Slack Notification Format

The Slack notification includes:
- PR title and number
- Repository name
- Author
- Risk score
- Recommendation (APPROVE/REQUEST_CHANGES/COMMENT)
- List of issues found
- List of warnings
- Direct link to PR
- Tagged reviewers

## Troubleshooting

### Webhook Not Triggering
1. Verify webhook URL is correct: `terraform output webhook_url`
2. Check webhook is active in GitHub settings
3. Verify webhook events include "Pull requests"
4. Check GitHub webhook delivery history for errors

### No GitHub Comments
1. Verify GitHub token has `repo` scope
2. Check agent logs: `kubiya logs <agent_name>`
3. Ensure PR URL is accessible with the token

### No Slack Notifications
1. Verify Slack token has `chat:write` scope
2. Ensure bot is invited to the channel
3. Check channel name format (should include #)
4. Verify Slack token in environment variables

### Agent Not Found
1. Ensure terraform apply completed successfully
2. Verify agent name: `terraform output agent_name`
3. Check runner status: `kubiya runner status <runner_name>`

## Module Outputs

| Output | Description |
|--------|-------------|
| agent_id | ID of the PR review agent |
| agent_name | Name of the PR review agent |
| webhook_id | ID of the GitHub webhook |
| webhook_url | URL to configure in GitHub |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| KUBIYA_API_KEY | Yes | Kubiya platform API key |
| TF_VAR_github_token | Yes | GitHub personal access token |
| TF_VAR_slack_token | Yes | Slack bot token |
| TF_VAR_kubiya_runner | Yes | Name of Kubiya runner |

## Support

- Documentation: https://docs.kubiya.ai
- Community: https://slack.kubiya.ai
- Issues: https://github.com/kubiyabot/terraform-modules/issues

## License

MIT License - see LICENSE file for details.