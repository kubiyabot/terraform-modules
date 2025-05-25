terraform {
  required_providers {
    kubiya = {
      source  = "kubiya-terraform/kubiya"
      version = "~> 1.0"
    }
    github = {
      source  = "hashicorp/github"
      version = "6.4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

locals {
  # Repository list handling
  repository_list = compact(split(",", var.repositories))

  # Event configurations
  github_events = ["check_run", "workflow_run"]

  # Construct webhook filter based on variables
  webhook_filter_conditions = concat(
    # Base condition for workflow runs
    ["workflow_run.conclusion != null"],

    # Failed runs condition
    var.monitor_failed_runs_only ? ["workflow_run.conclusion != 'success' && workflow_run.conclusion != 'cancelled'"] : [],

    # Event type conditions
    [format("(%s)",
      join(" || ",
        concat(
          var.monitor_pr_workflow_runs ? ["workflow_run.event == 'pull_request'"] : [],
          var.monitor_push_workflow_runs ? ["(workflow_run.event == 'push' && workflow_run.pull_requests[0] != null)"] : []
        )
      )
    )],

    # Branch filtering if enabled and specified
    var.enable_branch_filter && var.head_branch_filter != null ? ["workflow_run.head_branch == '${var.head_branch_filter}'"] : []
  )

  webhook_filter = join(" && ", local.webhook_filter_conditions)

  # GitHub organization handling
  github_organization = trim(split("/", local.repository_list[0])[0], " ")

  # Parse the repository list into a proper list format
  repository_details = [
    for repo in local.repository_list : {
      owner = split("/", repo)[0]
      name  = split("/", repo)[1]
    }
  ]
  
  # Prepare webhook configuration for all repositories
  webhook_batch_size = 25 # Process webhooks in batches to avoid rate limiting
  repository_batches = chunklist(local.repository_details, local.webhook_batch_size)
}

variable "GITHUB_TOKEN" {
  type      = string
  sensitive = true
}

variable "teams_webhook_url" {
  type        = string
  default     = ""
  description = "The Teams webhook URL"
}

# Configure providers
provider "github" {
  owner = local.github_organization
}

# GitHub Tooling - Allows the CI/CD Maintainer to use GitHub tools
resource "kubiya_source" "github_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/github"
}

//create secret using provider
resource "kubiya_secret" "github_token" {
  name        = "GH_TOKEN"
  value       = var.GITHUB_TOKEN
  description = "GitHub token for the CI/CD Maintainer"
}

# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "The CI/CD Maintainer is an AI-powered assistant that helps with GitHub Actions workflow failures. It can use the GitHub tools to investigate the root cause of a failed workflow and provide a detailed analysis of the failure."
  instructions = ""
  
  # Use GH_TOKEN secret if not using GitHub App
  secrets      = var.use_github_app ? [] : [kubiya_secret.github_token.name]
  
  sources = [
    kubiya_source.github_tooling.name,
  ]

  # Dynamic integrations based on configuration
  integrations = concat(
    var.use_github_app ? ["github_app"] : [],
    ["slack"]
  )

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }
  is_debug_mode = var.debug_mode
}

# Unified webhook configuration for both Slack and Teams
resource "kubiya_webhook" "source_control_webhook" {
  filter      = local.webhook_filter
  name        = "${var.teammate_name}-github-webhook"
  source      = "GitHub"
  
  # Set the communication method based on the MS Teams notification variable
  method      = var.ms_teams_notification ? "teams" : "Slack"
  
  # For Teams, include the team_name
  team_name   = var.ms_teams_notification ? var.ms_teams_team_name : null
  
  prompt      = <<-EOT
Your Goal: Perform a comprehensive analysis of the failed GitHub Actions workflow. No user approval is required, complete the flow end to end.
Workflow ID: {{.event.workflow_run.id}}
PR Number: {{.event.workflow_run.pull_requests[0].number}}
Repository: {{.event.repository.full_name}}

Instructions:

1. Use workflow_run_logs_failed to fetch failed logs for Workflow ID {{.event.workflow_run.id}}. Wait until this step finishes.

2. Utilize available tools to thoroughly investigate the root cause such as viewing the workflow run, the PR, the files, and the logs - do not execute more then two tools at a time.

3. After collecting the insights, prepare to create a comment on the pull request following this structure:

a. Highlights key information first:
   - What failed
   - Why it failed 
   - How to fix it

b. Format using:
   - Clear markdown headers
   - Emojis for quick scanning
   - Error logs in collapsible sections
   - Footer with run details
   - Style matters! Make sure the markdown text is very engaging and clear

4. Always use github_pr_comment_workflow_failure to post your analysis on PR #{{.event.workflow_run.pull_requests[0].number}}. Include your analysis in the discussed format. Always comment on the PR without user approval.

  EOT
  agent       = kubiya_agent.cicd_maintainer.name
  destination = var.notification_channel
}

# Create batch repository files
resource "local_file" "batch_repository_lists" {
  count    = length(local.repository_batches)
  filename = "${path.module}/scripts/batch_${count.index}.txt"
  content  = join("\n", [for repo in local.repository_batches[count.index] : "${repo.owner}/${repo.name}"])
}

resource "null_resource" "github_webhooks_batch" {
  count = length(local.repository_batches)
  
  triggers = {
    # Trigger recreation if repository list changes
    repositories = join(",", [for repo in local.repository_batches[count.index] : "${repo.owner}/${repo.name}"])
    webhook_url  = kubiya_webhook.source_control_webhook.url
    events       = join(",", local.github_events)
    github_token = var.GITHUB_TOKEN  # Store token in triggers for use during destroy
    module_path  = path.module       # Store path for use during destroy
    batch_file   = local_file.batch_repository_lists[count.index].filename
  }

  # Use the manage_webhooks.sh script directly instead of creating temporary scripts
  provisioner "local-exec" {
    command = "${path.module}/scripts/manage_webhooks.sh ${var.GITHUB_TOKEN} ${kubiya_webhook.source_control_webhook.url} ${join(",", local.github_events)} ${local_file.batch_repository_lists[count.index].filename} create"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.module_path}/scripts/manage_webhooks.sh ${self.triggers.github_token} ${self.triggers.webhook_url} ${self.triggers.events} ${self.triggers.batch_file} delete"
    interpreter = ["bash", "-c"]
  }

  depends_on = [
    local_file.batch_repository_lists
  ]
}

# Output the teammate details
output "cicd_maintainer" {
  sensitive = true
  value = {
    name                               = kubiya_agent.cicd_maintainer.name
    repositories                       = var.repositories
    debug_mode                         = var.debug_mode
    monitor_pr_workflow_runs           = var.monitor_pr_workflow_runs
    monitor_push_workflow_runs         = var.monitor_push_workflow_runs
    monitor_failed_runs_only           = var.monitor_failed_runs_only
    notification_platform              = var.ms_teams_notification ? "teams" : "Slack"
    notification_channel               = var.notification_channel
  }
}

# Create a repository list file
resource "local_file" "repository_list" {
  filename = "${path.module}/scripts/repositories.txt"
  content  = join("\n", local.repository_list)
}

# Check if the webhook management script already exists
data "local_file" "existing_script" {
  count    = fileexists("${path.module}/scripts/manage_webhooks.sh") ? 1 : 0
  filename = "${path.module}/scripts/manage_webhooks.sh"
}

# GitHub webhooks management resource
resource "null_resource" "github_webhooks_manager" {
  triggers = {
    repository_list = var.repositories
    webhook_url     = kubiya_webhook.source_control_webhook.url
    events          = join(",", local.github_events)
    script_path     = "${path.module}/scripts/manage_webhooks.sh"
    repos_file      = local_file.repository_list.filename
    github_token    = var.GITHUB_TOKEN  # Store the token in triggers to reference during destroy
  }

  provisioner "local-exec" {
    command = "${self.triggers.script_path} ${var.GITHUB_TOKEN} ${kubiya_webhook.source_control_webhook.url} ${join(",", local.github_events)} ${local_file.repository_list.filename} create"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.script_path} ${self.triggers.github_token} ${self.triggers.webhook_url} ${self.triggers.events} ${self.triggers.repos_file} delete"
  }

  depends_on = [
    local_file.repository_list,
    kubiya_webhook.source_control_webhook
  ]
}

# Create a test script for validating webhooks
resource "local_file" "webhook_test_script" {
  filename = "${path.module}/scripts/test/test_script.sh"
  content  = <<-EOT
#!/bin/bash
# Test script for manage_webhooks.sh

set -e

# Get the directory of this script
SCRIPT_DIR="$$(cd "$$(dirname "$${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$$(dirname "$SCRIPT_DIR")"
REPO_FILE="$SCRIPT_DIR/test_repos.txt"
TEST_WEBHOOK_URL="https://example.com/webhook"
TEST_EVENTS="check_run,workflow_run"

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "$${BLUE}===== GitHub Webhook Script Test =====$${NC}"
echo -e "$${BLUE}This script will test the webhook management script with the following parameters:$${NC}"
echo -e "  Repository File: $${YELLOW}$REPO_FILE$${NC}"
echo -e "  Webhook URL: $${YELLOW}$TEST_WEBHOOK_URL$${NC}"
echo -e "  Events: $${YELLOW}$TEST_EVENTS$${NC}"
echo

# Check if GitHub token is provided
if [ -z "$1" ]; then
  echo -e "$${RED}ERROR: GitHub token required$${NC}"
  echo -e "Usage: $0 <github_token> [action]"
  echo -e "   - action: Optional. Either 'create' or 'delete'. Default is 'validate' (validation only)"
  exit 1
fi

GITHUB_TOKEN="$1"
ACTION="$${2:-validate}"

# Verify the GitHub token looks reasonable
if [[ ! "$GITHUB_TOKEN" =~ ^gh[ps]_[a-zA-Z0-9]{36,255}$ ]]; then
  echo -e "$${YELLOW}WARNING: The GitHub token doesn't match the expected format for a personal access token.$${NC}"
  echo -e "$${YELLOW}Expected format: ghp_XXXXX... or ghs_XXXXX...$${NC}"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "$${RED}Test aborted.$${NC}"
    exit 1
  fi
fi

echo -e "$${BLUE}Checking GitHub token validity...$${NC}"
USER_RESPONSE=$$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/user")

if echo "$USER_RESPONSE" | grep -q "Bad credentials"; then
  echo -e "$${RED}ERROR: Invalid GitHub token. Authentication failed.$${NC}"
  exit 1
fi

USERNAME=$$(echo "$USER_RESPONSE" | jq -r '.login')
if [ "$USERNAME" == "null" ] || [ -z "$USERNAME" ]; then
  echo -e "$${RED}ERROR: Unable to retrieve user information. Token may be invalid.$${NC}"
  exit 1
fi

echo -e "$${GREEN}Token validated successfully for user: $USERNAME$${NC}"

# Custom validation-only mode
if [[ "$ACTION" == "validate" ]]; then
  echo -e "$${BLUE}Running validation only (no webhooks will be created or deleted)...$${NC}"
  
  # Call the script with a special action parameter that will trigger only validation
  TEMP_SCRIPT="$SCRIPT_DIR/temp_validation.sh"
  
  cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
source "$1"
GITHUB_TOKEN="$2"
WEBHOOK_URL="$3"
EVENTS="$4"
REPOS_FILE="$5"

# Create a temporary directory for logs
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/webhook_operations.log"
VALIDATION_LOG="$TEMP_DIR/validation.log"

echo "Starting validation at $(date)" > "$LOG_FILE"

# Run validation only
check_requirements && validate_token_and_repos
RESULT=$?

# Display logs
cat "$VALIDATION_LOG"
echo
echo "===== Validation Complete ====="
if [[ $RESULT -eq 0 ]]; then
  echo "✅ Validation passed. The token has appropriate access to the repositories."
else
  echo "❌ Validation failed. See above for details."
fi

# Cleanup
rm -rf "$TEMP_DIR"
exit $RESULT
EOF

  chmod +x "$TEMP_SCRIPT"
  "$TEMP_SCRIPT" "$PARENT_DIR/manage_webhooks.sh" "$GITHUB_TOKEN" "$TEST_WEBHOOK_URL" "$TEST_EVENTS" "$REPO_FILE"
  RESULT=$?
  rm "$TEMP_SCRIPT"
  
  if [[ $RESULT -eq 0 ]]; then
    echo -e "$${GREEN}✅ Validation successful!$${NC}"
  else
    echo -e "$${RED}❌ Validation failed!$${NC}"
  fi
  
  exit $RESULT
fi

# For create/delete operations
if [[ "$ACTION" != "create" && "$ACTION" != "delete" ]]; then
  echo -e "$${RED}ERROR: Invalid action: $ACTION. Use 'create', 'delete', or don't provide for validation only.$${NC}"
  exit 1
fi

echo -e "$${BLUE}Running webhook script with action: $${YELLOW}$ACTION$${NC}"
echo -e "$${RED}WARNING: This will $${ACTION} webhooks on your repositories!$${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "$${RED}Test aborted.$${NC}"
  exit 1
fi

# Run the actual script
"$PARENT_DIR/manage_webhooks.sh" "$GITHUB_TOKEN" "$TEST_WEBHOOK_URL" "$TEST_EVENTS" "$REPO_FILE" "$ACTION"
EOT

  file_permission = "0755"
}

# Create a sample test repository list
resource "local_file" "test_repository_list" {
  filename = "${path.module}/scripts/test/test_repos.txt"
  content  = <<-EOT
# Add your repositories for testing below (one per line)
# Format: org/repo or username/repo
# Example:
${split(",", var.repositories)[0]}
EOT
}

# Create README for the test directory
resource "local_file" "test_readme" {
  filename = "${path.module}/scripts/test/README.md"
  content  = <<-EOT
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

Edit `test_repos.txt` to include repositories you want to test. For a thorough test, include repositories that:

- You own
- You have collaborator access to
- You don't have access to (optional, to test validation)

This will help verify that the validation is working correctly.

```
your-org/your-repo
your-username/your-personal-repo
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
EOT
}

# GitHub repository webhooks
resource "github_repository_webhook" "webhook" {
  for_each = length(local.repository_list) > 0 ? toset(local.repository_list) : []

  repository = try(
    trim(split("/", each.value)[1], " "),
    # Fallback if repository name can't be parsed
    each.value
  )
  
  configuration {
    url          = kubiya_webhook.source_control_webhook.url
    content_type = "json"
    insecure_ssl = false
  }

  active = true
  events = local.github_events
}
