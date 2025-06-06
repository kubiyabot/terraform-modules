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
    KUBIYA_TOOL_TIMEOUT = "500",
    DESTINATION_CHANNEL = var.summary_channel
  }
  is_debug_mode = var.debug_mode
}

# Unified webhook configuration for both Slack and Teams
resource "kubiya_webhook" "source_control_webhook" {
  filter      = local.webhook_filter
  name        = "${var.teammate_name}-github-webhook"
  source      = "GitHub"
  # For Teams, include the team_name
  method      = var.ms_teams_notification ? "teams" : "Slack"
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

b. ${var.enable_summary_channel ? "use slack_workflow_summary tool to send a summary to slack." : "Format using:\n   - Clear markdown headers\n   - Emojis for quick scanning\n   - Error logs in collapsible sections\n   - Footer with run details\n   - Style matters! Make sure the markdown text is very engaging and clear"}

4. Always use github_pr_comment_workflow_failure to post your analysis on PR #{{.event.workflow_run.pull_requests[0].number}}. Include your analysis in the discussed format. Always comment on the PR without user approval.

  EOT
  agent       = kubiya_agent.cicd_maintainer.name
  destination = var.notification_channel
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
