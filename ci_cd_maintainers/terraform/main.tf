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
  # GitHub organization handling
  # Extract from the first repository if provided, otherwise use the variable
  github_org_from_repos = var.repositories != "" ? trim(split("/", split(",", var.repositories)[0])[0], " ") : ""
  github_organization   = var.github_organization != "" ? var.github_organization : local.github_org_from_repos

  # Repository list handling - depends on organization
  repository_list = var.repositories != "" ? compact(split(",", var.repositories)) : (
    local.github_organization != "" ? data.github_repositories.available[0].full_names : []
  )

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
}

# Configure providers
provider "github" {
  owner = local.github_organization
  token = var.GITHUB_TOKEN
}

# Fetch available repositories if no specific repositories provided
data "github_repositories" "available" {
  count = var.repositories == "" && local.github_organization != "" ? 1 : 0
  query = "org:${local.github_organization} fork:true"
}

# Validate repositories exist using HTTP data source (more reliable than github_repository)
data "http" "repo_validator" {
  for_each = toset(local.repository_list)

  url = "https://api.github.com/repos/${each.value}"

  request_headers = {
    Accept        = "application/vnd.github.v3+json"
    Authorization = "token ${var.GITHUB_TOKEN}"
  }
}

locals {
  # Check which repositories are valid based on HTTP response
  valid_repositories = {
    for repo, response in data.http.repo_validator : repo =>
    can(jsondecode(response.body)) && response.status_code == 200
  }

  # Filter repository list to only include valid repositories
  validated_repository_list = [
    for repo in local.repository_list :
    repo if lookup(local.valid_repositories, repo, false)
  ]
}

# GitHub Tooling - Allows the CI/CD Maintainer to use GitHub tools
resource "kubiya_source" "github_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/github"
}

# Create secret using provider
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
  secrets = var.use_github_app ? [] : [kubiya_secret.github_token.name]

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
  filter = local.webhook_filter
  name   = "${var.teammate_name}-github-webhook"
  source = "GitHub"

  # Set the communication method based on the MS Teams notification variable
  method = var.ms_teams_notification ? "teams" : "Slack"

  # For Teams, include the team_name
  team_name = var.ms_teams_notification ? var.ms_teams_team_name : null

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

# GitHub repository webhooks - using for_each approach
resource "github_repository_webhook" "webhook" {
  for_each = length(local.validated_repository_list) > 0 ? toset(local.validated_repository_list) : []

  # This depends on repository validation
  depends_on = [data.http.repo_validator]

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
    name                       = kubiya_agent.cicd_maintainer.name
    repositories               = var.repositories == "" && length(local.validated_repository_list) > 0 ? join(",", local.validated_repository_list) : var.repositories
    debug_mode                 = var.debug_mode
    monitor_pr_workflow_runs   = var.monitor_pr_workflow_runs
    monitor_push_workflow_runs = var.monitor_push_workflow_runs
    monitor_failed_runs_only   = var.monitor_failed_runs_only
    notification_platform      = var.ms_teams_notification ? "teams" : "Slack"
    notification_channel       = var.notification_channel
  }
}
