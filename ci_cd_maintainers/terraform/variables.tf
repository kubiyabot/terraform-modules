terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 16.0"
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

provider "github" {
  token = var.github_token
}

provider "gitlab" {
  token = var.gitlab_token
}

# Locals block for configuration
locals {
  # Determine source control type based on provided token
  source_control_type = (
    var.github_token != "" ? "github" : 
    var.gitlab_token != "" ? "gitlab" : 
    null
  )
  
  # Validate that exactly one token is provided
  validate_tokens = (
    var.github_token != "" && var.gitlab_token != "" ? file("ERROR: Cannot provide both GitHub and GitLab tokens") :
    var.github_token == "" && var.gitlab_token == "" ? file("ERROR: Must provide either GitHub or GitLab token") :
    null
  )
  
  # Webhook configuration
  webhook_enabled = var.webhook_enabled && local.source_control_type != null

  # Channel configuration
  effective_pipeline_channel = coalesce(var.pipeline_notification_channel, var.notification_channel)
  effective_security_channel = coalesce(var.security_notification_channel, var.notification_channel)

  # Repository list handling
  repository_list = compact(split(",", var.repositories))

  # Event configurations
  github_events = concat(
    var.monitor_push_events ? ["push"] : [],
    var.monitor_pull_requests ? ["pull_request", "pull_request_review"] : [],
    var.monitor_pipeline_events ? ["workflow_run", "workflow_job", "check_run", "check_suite"] : [],
    var.monitor_deployment_events ? ["deployment", "deployment_status"] : [],
    var.monitor_security_events ? ["security_advisory", "repository_vulnerability_alert"] : [],
    var.monitor_issue_events ? ["issues", "issue_comment"] : [],
    var.monitor_release_events ? ["release"] : []
  )

  gitlab_event_config = {
    push_events = var.monitor_push_events
    merge_requests_events = var.monitor_pull_requests
    pipeline_events = var.monitor_pipeline_events
    deployment_events = var.monitor_deployment_events
    issues_events = var.monitor_issue_events
    releases_events = var.monitor_release_events
    job_events = var.monitor_pipeline_events
    tag_push_events = var.monitor_push_events
  }
}

# Data sources
data "http" "cicd_knowledge" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/knowledge/cicd_management.md"
}

data "http" "pipeline_management" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/knowledge/pipeline_management.md"
}

data "http" "pipeline_health_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/prompts/pipeline_health_check.md"
}

data "http" "security_scan" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/prompts/security_scan.md"
}

data "http" "dependency_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/prompts/dependency_check.md"
}

# Configure sources
resource "kubiya_source" "cicd_workflow_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/cicd"
}

resource "kubiya_source" "github_tooling" {
  count = local.source_control_type == "github" ? 1 : 0
  url   = "https://github.com/kubiyabot/community-tools/tree/main/github"
}

resource "kubiya_source" "gitlab_tooling" {
  count = local.source_control_type == "gitlab" ? 1 : 0
  url   = "https://github.com/kubiyabot/community-tools/tree/main/gitlab"
}

# Knowledge bases
resource "kubiya_knowledge" "cicd_management" {
  name             = "CI/CD Management Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for CI/CD management and troubleshooting"
  labels           = ["cicd", "pipeline", "source-control"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = data.http.cicd_knowledge.response_body
}

resource "kubiya_knowledge" "pipeline_management" {
  name             = "Pipeline Management Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for pipeline management and optimization"
  labels           = ["cicd", "pipeline", "optimization"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = data.http.pipeline_management.response_body
}

# CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered CI/CD maintenance assistant"
  model        = "azure/gpt-4"
  instructions = ""
  
  sources = concat(
    [kubiya_source.cicd_workflow_tooling.name],
    local.source_control_type == "github" ? [kubiya_source.github_tooling[0].name] : [],
    local.source_control_type == "gitlab" ? [kubiya_source.gitlab_tooling[0].name] : []
  )

  integrations = concat(
    ["slack"],
    (local.source_control_type == "github" && var.github_enable_oauth) ? ["github"] : []
  )

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    NOTIFICATION_CHANNEL            = var.notification_channel
    PIPELINE_NOTIFICATION_CHANNEL   = local.effective_pipeline_channel
    SECURITY_NOTIFICATION_CHANNEL   = local.effective_security_channel
    REPOSITORIES                    = var.repositories
    SOURCE_CONTROL_TYPE            = local.source_control_type
    AUTO_FIX_ENABLED               = tostring(var.auto_fix_enabled)
    MAX_CONCURRENT_FIXES           = tostring(var.max_concurrent_fixes)
    SCAN_INTERVAL                  = var.scan_interval
  }
}

# Unified webhook configuration
resource "kubiya_webhook" "source_control_webhook" {
  count = local.webhook_enabled ? 1 : 0
  
  name        = "${var.teammate_name}-${local.source_control_type}-webhook"
  source      = local.source_control_type == "github" ? "GitHub" : "GitLab"
  prompt      = <<-EOT
    Analyze this ${local.source_control_type == "github" ? "GitHub" : "GitLab"} event and determine if action is needed:
    Event: {{.event}}
    
    If this is a pipeline failure:
    1. Analyze the failure cause
    2. Check for common patterns
    3. Suggest potential fixes
    4. If auto-fix is enabled and the fix is safe, apply it
    
    If this is a security alert:
    1. Assess the severity
    2. Check if it affects other repositories
    3. Propose remediation steps
    
    Notify the appropriate channel based on the event type.
  EOT
  agent       = kubiya_agent.cicd_maintainer.name
  destination = local.effective_pipeline_channel
}

# Generate webhook secret for GitLab
resource "random_password" "webhook_secret" {
  count   = local.source_control_type == "gitlab" && local.webhook_enabled ? 1 : 0
  length  = 32
  special = false
}

# GitHub webhook setup
resource "github_repository_webhook" "webhook" {
  for_each = local.source_control_type == "github" && local.webhook_enabled ? toset(local.repository_list) : []

  repository = trim(split("/", each.value)[1], " ")
  
  configuration {
    url          = kubiya_webhook.source_control_webhook[0].url
    content_type = var.webhook_content_type
    insecure_ssl = false
  }

  active = true
  events = local.github_events
}

# GitLab webhook setup
resource "gitlab_project_hook" "webhook" {
  for_each = local.source_control_type == "gitlab" && local.webhook_enabled ? toset(local.repository_list) : []

  project = each.value
  url     = kubiya_webhook.source_control_webhook[0].url
  token   = random_password.webhook_secret[0].result

  push_events            = local.gitlab_event_config.push_events
  merge_requests_events  = local.gitlab_event_config.merge_requests_events
  pipeline_events        = local.gitlab_event_config.pipeline_events
  deployment_events      = local.gitlab_event_config.deployment_events
  issues_events         = local.gitlab_event_config.issues_events
  tag_push_events       = local.gitlab_event_config.tag_push_events
  job_events            = local.gitlab_event_config.job_events
  releases_events       = local.gitlab_event_config.releases_events
  enable_ssl_verification = true
}

# Scheduled tasks
resource "kubiya_scheduled_task" "pipeline_health" {
  count          = var.pipeline_health_check_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
  repeat         = var.pipeline_health_check_repeat
  channel_id     = local.effective_pipeline_channel
  agent          = kubiya_agent.cicd_maintainer.name
  description    = replace(
    data.http.pipeline_health_check.response_body,
    "$${pipeline_notification_channel}",
    local.effective_pipeline_channel
  )
}

resource "kubiya_scheduled_task" "security_scan" {
  count          = var.security_scan_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "5m"))
  repeat         = var.security_scan_repeat
  channel_id     = local.effective_security_channel
  agent          = kubiya_agent.cicd_maintainer.name
  description    = replace(
    replace(
      data.http.security_scan.response_body,
      "$${security_notification_channel}",
      local.effective_security_channel
    ),
    "$${REPOSITORIES}",
    var.repositories
  )
}

resource "kubiya_scheduled_task" "dependency_check" {
  count          = var.dependency_check_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
  repeat         = var.dependency_check_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.cicd_maintainer.name
  description    = replace(
    replace(
      data.http.dependency_check.response_body,
      "$${notification_channel}",
      var.notification_channel
    ),
    "$${REPOSITORIES}",
    var.repositories
  )
}

# Update teammate environment variables
resource "kubiya_agent_environment" "cicd_maintainer_env" {
  agent_id = kubiya_agent.cicd_maintainer.id
  
  environment_variables = merge(
    {
      "KUBIYA_TOOL_TIMEOUT": "300",
      "NOTIFICATION_CHANNEL": var.notification_channel,
      "REPOSITORIES": var.repositories,
      "SOURCE_CONTROL_TYPE": local.source_control_type,
      "AUTO_FIX_ENABLED": tostring(var.auto_fix_enabled),
      "MAX_CONCURRENT_FIXES": tostring(var.max_concurrent_fixes),
      "SCAN_INTERVAL": var.scan_interval
    },
    local.webhook_enabled ? {
      "${upper(local.source_control_type)}_WEBHOOK_URL": kubiya_webhook.source_control_webhook[0].url,
      "${upper(local.source_control_type)}_TOKEN": local.source_control_type == "github" ? var.github_token : var.gitlab_token
    } : {},
    local.source_control_type == "gitlab" && local.webhook_enabled ? {
      "GITLAB_WEBHOOK_SECRET": random_password.webhook_secret[0].result
    } : {}
  )

  depends_on = [
    kubiya_webhook.source_control_webhook,
    random_password.webhook_secret
  ]
}

# Output the teammate details
output "cicd_maintainer" {
  value = {
    name                         = kubiya_agent.cicd_maintainer.name
    notification_channel         = var.notification_channel
    pipeline_notification_channel = local.effective_pipeline_channel
    security_notification_channel = local.effective_security_channel
    repositories                 = var.repositories
    source_control_type         = local.source_control_type
  }
}

# Required Core Configuration
variable "teammate_name" {
  description = "Name of your CI/CD maintainer teammate (e.g., 'cicd-crew' or 'pipeline-guardian'). Used to identify the teammate in logs, notifications, and webhooks."
  type        = string
  default     = "cicd-crew"
}

variable "repositories" {
  description = "Comma-separated list of repositories to monitor in 'org/repo' format (e.g., 'mycompany/backend-api,mycompany/frontend-app'). Ensure you have appropriate permissions."
  type        = string
}

variable "notification_channel" {
  description = "Primary Slack channel for notifications with '#' prefix (e.g., '#cicd-alerts'). Bot must be invited to this channel."
  type        = string
}

# Authentication Tokens
variable "github_token" {
  description = "GitHub Personal Access Token with repo and admin:repo_hook permissions. Required for GitHub repositories. Generate at: https://github.com/settings/tokens"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitlab_token" {
  description = "GitLab Personal Access Token with api, read_repository, and write_repository permissions. Required for GitLab repositories. Generate at: https://gitlab.com/-/profile/personal_access_tokens"
  type        = string
  default     = ""
  sensitive   = true
}

# Optional Configuration
variable "github_enable_oauth" {
  description = "Enable GitHub OAuth integration for enhanced API capabilities and direct repository access. Default: true"
  type        = bool
  default     = true
}

variable "webhook_enabled" {
  description = "Enable webhook creation for repositories to receive real-time events. Default: true"
  type        = bool
  default     = true
}

variable "webhook_content_type" {
  description = "Content type for webhook payloads (json/form). Default: json"
  type        = string
  default     = "json"
}

variable "auto_fix_enabled" {
  description = "Enable automatic fixing of minor issues like non-breaking dependency updates and common pipeline problems. Default: false"
  type        = bool
  default     = false
}

variable "max_concurrent_fixes" {
  description = "Maximum number of automatic fixes that can be applied simultaneously. Default: 3"
  type        = number
  default     = 3
}

variable "scan_interval" {
  description = "Interval between repository scans (e.g., '30m', '1h', '6h'). Default: 1h"
  type        = string
  default     = "1h"
}

# Channel Configuration
variable "pipeline_notification_channel" {
  description = "Dedicated Slack channel for pipeline alerts. Falls back to notification_channel if not set."
  type        = string
  default     = ""
}

variable "security_notification_channel" {
  description = "Dedicated Slack channel for security alerts. Falls back to notification_channel if not set."
  type        = string
  default     = ""
}

# Access Control
variable "kubiya_groups_allowed_groups" {
  description = "Groups allowed to interact with the teammate (e.g., ['Admin', 'DevOps']). Default: ['Admin']"
  type        = list(string)
  default     = ["Admin"]
}

variable "kubiya_runner" {
  description = "Runner to use for the teammate. Change only if using custom runners. Default: default"
  type        = string
  default     = "default"
}

# Task Schedule Settings
variable "pipeline_health_check_enabled" {
  description = "Enable regular pipeline health check task. Default: true"
  type        = bool
  default     = true
}

variable "pipeline_health_check_repeat" {
  description = "How often to run pipeline health checks. Default: hourly"
  type        = string
  default     = "hourly"
}

variable "security_scan_enabled" {
  description = "Enable regular security scanning task. Default: true"
  type        = bool
  default     = true
}

variable "security_scan_repeat" {
  description = "How often to run security scans. Default: daily"
  type        = string
  default     = "daily"
}

variable "dependency_check_enabled" {
  description = "Enable regular dependency checking task. Default: true"
  type        = bool
  default     = true
}

variable "dependency_check_repeat" {
  description = "How often to check for dependency updates. Default: daily"
  type        = string
  default     = "daily"
}

# Event Monitoring Configuration
variable "monitor_push_events" {
  description = "Monitor repository push events for direct commits and policy violations. Default: true"
  type        = bool
  default     = true
}

variable "monitor_pull_requests" {
  description = "Monitor pull request/merge request events for reviews and CI status. Default: true"
  type        = bool
  default     = true
}

variable "monitor_pipeline_events" {
  description = "Monitor CI/CD pipeline events for failures and performance issues. Default: true"
  type        = bool
  default     = true
}

variable "monitor_deployment_events" {
  description = "Monitor deployment events and status changes. Default: true"
  type        = bool
  default     = true
}

variable "monitor_security_events" {
  description = "Monitor security alerts and vulnerability notifications. Default: true"
  type        = bool
  default     = true
}

variable "monitor_issue_events" {
  description = "Monitor repository issue events and comments. Default: false"
  type        = bool
  default     = false
}

variable "monitor_release_events" {
  description = "Monitor repository release events. Default: false"
  type        = bool
  default     = false
}