terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
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

# Instead of using github_repository_webhook for each repository,
# we'll use a null_resource to create webhooks in batches via GitHub API
resource "null_resource" "github_webhooks_batch" {
  count = length(local.repository_batches)
  
  triggers = {
    # Trigger recreation if repository list changes
    repositories = join(",", [for repo in local.repository_batches[count.index] : "${repo.owner}/${repo.name}"])
    webhook_url  = kubiya_webhook.source_control_webhook.url
    events       = join(",", local.github_events)
  }

  provisioner "local-exec" {
    command = <<EOF
#!/bin/bash
set -e

# Path to script that will create webhooks in batches
SCRIPT_PATH="${path.module}/scripts/create_webhooks.sh"

# Create script if it doesn't exist
cat > $SCRIPT_PATH << 'SCRIPT'
#!/bin/bash
# Script to create GitHub webhooks in batches

GITHUB_TOKEN="$1"
WEBHOOK_URL="$2"
EVENTS="$3"
REPOS="$4"

IFS=',' read -ra REPO_ARRAY <<< "$REPOS"
for REPO in "${REPO_ARRAY[@]}"; do
  OWNER=$(echo $REPO | cut -d'/' -f1)
  REPO_NAME=$(echo $REPO | cut -d'/' -f2)
  
  echo "Creating webhook for $OWNER/$REPO_NAME"
  
  # Convert events string to JSON array
  IFS=',' read -ra EVENT_ARRAY <<< "$EVENTS"
  EVENTS_JSON=$(printf '"%s",' "${EVENT_ARRAY[@]}" | sed 's/,$//')
  
  # Create webhook via GitHub API
  curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks" \
    -d "{
      \"name\": \"web\",
      \"active\": true,
      \"events\": [$EVENTS_JSON],
      \"config\": {
        \"url\": \"$WEBHOOK_URL\",
        \"content_type\": \"json\",
        \"insecure_ssl\": \"0\"
      }
    }"
  
  # Avoid rate limiting
  sleep 0.5
done
SCRIPT

# Make script executable
chmod +x $SCRIPT_PATH

# Execute script with appropriate parameters
$SCRIPT_PATH "${var.GITHUB_TOKEN}" "${kubiya_webhook.source_control_webhook.url}" "${join(",", local.github_events)}" "${join(",", [for repo in local.repository_batches[count.index] : "${repo.owner}/${repo.name}"])}"
EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
#!/bin/bash
set -e

# Script to clean up webhooks when terraform destroy is called
SCRIPT_PATH="${path.module}/scripts/delete_webhooks.sh"

# Create deletion script
cat > $SCRIPT_PATH << 'SCRIPT'
#!/bin/bash
# Script to delete GitHub webhooks in batches

GITHUB_TOKEN="$1"
WEBHOOK_URL="$2"
REPOS="$3"

IFS=',' read -ra REPO_ARRAY <<< "$REPOS"
for REPO in "${REPO_ARRAY[@]}"; do
  OWNER=$(echo $REPO | cut -d'/' -f1)
  REPO_NAME=$(echo $REPO | cut -d'/' -f2)
  
  echo "Deleting webhooks for $OWNER/$REPO_NAME"
  
  # Get all webhooks for repo
  HOOKS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks")
  
  # Find and delete webhook with matching URL
  echo $HOOKS | jq -c '.[]' | while read HOOK; do
    HOOK_URL=$(echo $HOOK | jq -r '.config.url')
    HOOK_ID=$(echo $HOOK | jq -r '.id')
    
    if [ "$HOOK_URL" == "$WEBHOOK_URL" ]; then
      curl -s -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks/$HOOK_ID"
      echo "Deleted webhook $HOOK_ID from $OWNER/$REPO_NAME"
    fi
  done
  
  # Avoid rate limiting
  sleep 0.5
done
SCRIPT

# Make script executable
chmod +x $SCRIPT_PATH

# Execute deletion script
$SCRIPT_PATH "${var.GITHUB_TOKEN}" "${self.triggers.webhook_url}" "${self.triggers.repositories}"
EOF
  }
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

# Create a GitHub webhooks management solution that can handle a large number of repositories
resource "local_file" "webhook_management_script" {
  filename = "${path.module}/scripts/manage_webhooks.sh"
  content  = <<-EOT
#!/bin/bash
# Script to manage GitHub webhooks in batches
# This script can efficiently create webhooks for 200-250 repositories

# Usage: ./manage_webhooks.sh <github_token> <webhook_url> <events> <repos_file> <action>
# action: create or delete

GITHUB_TOKEN="$1"
WEBHOOK_URL="$2"
EVENTS="$3"
REPOS_FILE="$4"
ACTION="$5"

# Rate limit settings
MAX_CONCURRENT=10
RATE_LIMIT_DELAY=0.5

# Create a temporary directory for logs
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/webhook_operations.log"

# Function to create a webhook
create_webhook() {
  local REPO="$1"
  local OWNER=$(echo $REPO | cut -d'/' -f1)
  local REPO_NAME=$(echo $REPO | cut -d'/' -f2)
  local LOGFILE="$TEMP_DIR/$OWNER-$REPO_NAME.log"
  
  echo "Creating webhook for $OWNER/$REPO_NAME" >> "$LOGFILE"
  
  # Prepare events array for JSON
  local EVENTS_JSON=""
  IFS=',' read -ra EVENT_ARRAY <<< "$EVENTS"
  for EVENT in "${EVENT_ARRAY[@]}"; do
    EVENTS_JSON="$EVENTS_JSON\"$EVENT\","
  done
  EVENTS_JSON=$(echo $EVENTS_JSON | sed 's/,$//')
  
  # Create webhook via GitHub API
  HTTP_CODE=$(curl -s -o "$LOGFILE" -w "%{http_code}" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks" \
    -d "{
      \"name\": \"web\",
      \"active\": true,
      \"events\": [$EVENTS_JSON],
      \"config\": {
        \"url\": \"$WEBHOOK_URL\",
        \"content_type\": \"json\",
        \"insecure_ssl\": \"0\"
      }
    }")
  
  if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    echo "SUCCESS: Created webhook for $OWNER/$REPO_NAME" >> "$LOG_FILE"
  else
    echo "ERROR: Failed to create webhook for $OWNER/$REPO_NAME - HTTP $HTTP_CODE" >> "$LOG_FILE"
    cat "$LOGFILE" >> "$LOG_FILE"
  fi
}

# Function to delete a webhook
delete_webhook() {
  local REPO="$1"
  local OWNER=$(echo $REPO | cut -d'/' -f1)
  local REPO_NAME=$(echo $REPO | cut -d'/' -f2)
  local LOGFILE="$TEMP_DIR/$OWNER-$REPO_NAME.log"
  
  echo "Deleting webhooks for $OWNER/$REPO_NAME" >> "$LOGFILE"
  
  # Get all webhooks for repo
  HOOKS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks")
  
  # Find and delete webhook with matching URL
  echo "$HOOKS" | jq -c '.[]' 2>/dev/null | while read HOOK; do
    HOOK_URL=$(echo "$HOOK" | jq -r '.config.url')
    HOOK_ID=$(echo "$HOOK" | jq -r '.id')
    
    if [[ "$HOOK_URL" == "$WEBHOOK_URL" ]]; then
      HTTP_CODE=$(curl -s -o "$LOGFILE" -w "%{http_code}" \
        -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks/$HOOK_ID")
      
      if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
        echo "SUCCESS: Deleted webhook $HOOK_ID from $OWNER/$REPO_NAME" >> "$LOG_FILE"
      else
        echo "ERROR: Failed to delete webhook $HOOK_ID from $OWNER/$REPO_NAME - HTTP $HTTP_CODE" >> "$LOG_FILE"
      fi
    fi
  done
}

# Process repositories in parallel
process_repos() {
  local ACTION="$1"
  local COUNT=0
  
  while read REPO; do
    # Skip empty lines
    [[ -z "$REPO" ]] && continue
    
    # Process in background to run in parallel
    if [[ "$ACTION" == "create" ]]; then
      create_webhook "$REPO" &
    else
      delete_webhook "$REPO" &
    fi
    
    # Increment counter and check if we need to wait
    COUNT=$((COUNT+1))
    if [[ $COUNT -eq $MAX_CONCURRENT ]]; then
      wait
      COUNT=0
      sleep $RATE_LIMIT_DELAY
    fi
  done < "$REPOS_FILE"
  
  # Wait for any remaining background jobs
  wait
}

# Main execution
if [[ "$ACTION" == "create" ]]; then
  echo "Starting webhook creation process at $(date)" > "$LOG_FILE"
  process_repos "create"
elif [[ "$ACTION" == "delete" ]]; then
  echo "Starting webhook deletion process at $(date)" > "$LOG_FILE"
  process_repos "delete"
else
  echo "Invalid action: $ACTION. Use 'create' or 'delete'" > "$LOG_FILE"
  exit 1
fi

echo "Operation completed at $(date)" >> "$LOG_FILE"
cat "$LOG_FILE"
EOT

  file_permission = "0755"
}

# Create a repository list file
resource "local_file" "repository_list" {
  filename = "${path.module}/scripts/repositories.txt"
  content  = join("\n", local.repository_list)
}

# GitHub webhooks management resource
resource "null_resource" "github_webhooks_manager" {
  triggers = {
    repository_list = var.repositories
    webhook_url     = kubiya_webhook.source_control_webhook.url
    events          = join(",", local.github_events)
    script_hash     = filemd5(local_file.webhook_management_script.filename)
  }

  provisioner "local-exec" {
    command = "${local_file.webhook_management_script.filename} ${var.GITHUB_TOKEN} ${kubiya_webhook.source_control_webhook.url} ${join(",", local.github_events)} ${local_file.repository_list.filename} create"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.script_path} ${var.GITHUB_TOKEN} ${self.triggers.webhook_url} ${self.triggers.events} ${self.triggers.repos_file} delete"
    environment = {
      script_path = local_file.webhook_management_script.filename
      repos_file  = local_file.repository_list.filename
    }
  }

  depends_on = [
    local_file.webhook_management_script,
    local_file.repository_list,
    kubiya_webhook.source_control_webhook
  ]
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
