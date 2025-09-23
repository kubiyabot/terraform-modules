terraform {
  required_providers {
    kubiya = {
      source  = "kubiya-terraform/kubiya"
      version = "~> 1.0"
    }
    github = {
      source  = "hashicorp/github"
      version = "~> 6.4"
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
  type        = string
  sensitive   = true
  description = "GitHub Personal Access Token for repository access. Required when not using GitHub App integration."
}

variable "teams_webhook_url" {
  type        = string
  default     = ""
  description = "Microsoft Teams webhook URL for notifications (optional)"
}

# Configure providers
provider "github" {
  owner = local.github_organization
}

# GitHub Tooling - Allows the CI/CD Maintainer to use GitHub tools
resource "kubiya_source" "github_tooling" {
  url         = "https://github.com/kubiyabot/community-tools/tree/main/github"
  description = "GitHub community tools for CI/CD operations"
}

# Optional: Additional tooling sources for enhanced capabilities
resource "kubiya_source" "git_tooling" {
  url         = "https://github.com/kubiyabot/community-tools/tree/main/git"
  description = "Git tools for repository operations"
}

resource "kubiya_source" "docker_tooling" {
  url         = "https://github.com/kubiyabot/community-tools/tree/main/docker"
  description = "Docker tools for containerized CI/CD workflows"
}

# Create secret for GitHub token when not using GitHub App
resource "kubiya_secret" "github_token" {
  count       = var.use_github_app ? 0 : 1
  name        = "GH_TOKEN"
  value       = var.GITHUB_TOKEN
  description = "GitHub Personal Access Token for the CI/CD Maintainer"
}

# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered CI/CD maintainer that monitors GitHub Actions workflows, analyzes failures, and provides detailed solutions directly in pull requests."
  instructions = "You are a CI/CD expert specializing in GitHub Actions workflow analysis and troubleshooting. Your primary role is to investigate failed workflows, analyze error logs, identify root causes, and provide comprehensive solutions with actionable recommendations."
  model        = var.llm_model

  # Conditional secrets based on GitHub App usage
  secrets = var.use_github_app ? [] : [kubiya_secret.github_token[0].name]

  sources = [
    kubiya_source.github_tooling.name,
    kubiya_source.git_tooling.name,
    kubiya_source.docker_tooling.name,
  ]

  # Dynamic integrations based on configuration
  integrations = concat(
    var.use_github_app ? ["github_app"] : [],
    var.enable_slack_notifications ? ["slack"] : [],
    var.enable_teams_notifications ? ["teams"] : []
  )

  users  = var.kubiya_users
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT        = tostring(var.tool_timeout)
    DESTINATION_CHANNEL        = var.summary_channel
    ENABLE_DETAILED_ANALYSIS   = tostring(var.enable_detailed_analysis)
    ENABLE_SECURITY_SCANNING   = tostring(var.enable_security_scanning)
    ENABLE_PERFORMANCE_METRICS = tostring(var.enable_performance_metrics)
    LOG_LEVEL                  = var.log_level
  }

  is_debug_mode = var.debug_mode

  labels = ["ci-cd", "github-actions", "devops", "workflow-analysis"]
}

# Knowledge base for CI/CD best practices
resource "kubiya_knowledge" "cicd_best_practices" {
  name             = "CI/CD Best Practices"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Comprehensive knowledge base covering CI/CD best practices, common patterns, and troubleshooting guidelines"
  labels           = ["ci-cd", "best-practices", "troubleshooting"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = file("${path.module}/knowledge/cicd_best_practices.md")
}

# Knowledge base for GitHub Actions troubleshooting
resource "kubiya_knowledge" "github_actions_troubleshooting" {
  name             = "GitHub Actions Troubleshooting"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Detailed troubleshooting guide for common GitHub Actions issues and error patterns"
  labels           = ["github-actions", "troubleshooting", "error-patterns"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = file("${path.module}/knowledge/github_actions_troubleshooting.md")
}

# Knowledge base for workflow optimization
resource "kubiya_knowledge" "workflow_optimization" {
  name             = "Workflow Optimization Strategies"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Performance optimization techniques for GitHub Actions workflows"
  labels           = ["optimization", "performance", "github-actions"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = file("${path.module}/knowledge/workflow_optimization.md")
}

# Knowledge base for security best practices
resource "kubiya_knowledge" "security_practices" {
  count            = var.enable_security_scanning ? 1 : 0
  name             = "CI/CD Security Best Practices"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Security guidelines and best practices for CI/CD pipelines"
  labels           = ["security", "ci-cd", "compliance"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = file("${path.module}/knowledge/security_practices.md")
}

# Enhanced webhook configuration with improved prompt
resource "kubiya_webhook" "source_control_webhook" {
  filter    = local.webhook_filter
  name      = "${var.teammate_name}-github-webhook"
  source    = "GitHub"
  method    = var.ms_teams_notification ? "teams" : "Slack"
  team_name = var.ms_teams_notification ? var.ms_teams_team_name : null

  prompt = var.custom_webhook_prompt != null ? var.custom_webhook_prompt : templatefile("${path.module}/prompts/workflow_analysis.tpl", {
    enable_summary_channel     = var.enable_summary_channel
    enable_detailed_analysis   = var.enable_detailed_analysis
    enable_security_scanning   = var.enable_security_scanning
    enable_performance_metrics = var.enable_performance_metrics
  })

  agent       = kubiya_agent.cicd_maintainer.name
  destination = var.notification_channel

  labels = ["ci-cd", "github-webhook", "workflow-monitoring"]
}

# GitHub repository webhooks with enhanced configuration
resource "github_repository_webhook" "webhook" {
  for_each = length(local.repository_list) > 0 ? toset(local.repository_list) : []

  repository = try(
    trim(split("/", each.value)[1], " "),
    each.value
  )

  configuration {
    url          = kubiya_webhook.source_control_webhook.url
    content_type = "json"
    insecure_ssl = false
    secret       = var.webhook_secret
  }

  active = true
  events = local.github_events
}