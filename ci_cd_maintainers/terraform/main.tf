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

# Load knowledge sources
data "http" "cicd_knowledge" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/knowledge/cicd_management.md"
}

# Configure sources
resource "kubiya_source" "cicd_workflow_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/cicd"
}

resource "kubiya_source" "github_tooling" {
  count = var.source_control_type == "github" ? 1 : 0
  url   = "https://github.com/kubiyabot/community-tools/tree/main/github"
}

resource "kubiya_source" "gitlab_tooling" {
  count = var.source_control_type == "gitlab" ? 1 : 0
  url   = "https://github.com/kubiyabot/community-tools/tree/main/gitlab"
}

# Create knowledge base
resource "kubiya_knowledge" "cicd_management" {
  name             = "CI/CD Management Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for CI/CD management and troubleshooting"
  labels           = ["cicd", "pipeline", "source-control"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = data.http.cicd_knowledge.response_body
}

# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered CI/CD maintenance assistant"
  model        = "azure/gpt-4"
  instructions = ""
  
  sources = concat(
    [kubiya_source.cicd_workflow_tooling.name],
    var.source_control_type == "github" ? [kubiya_source.github_tooling[0].name] : [],
    var.source_control_type == "gitlab" ? [kubiya_source.gitlab_tooling[0].name] : []
  )

  integrations = concat(
    ["slack"],
    var.source_control_type == "github" ? ["github"] : [],
    var.source_control_type == "gitlab" ? ["gitlab"] : []
  )

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    NOTIFICATION_CHANNEL            = var.notification_channel
    PIPELINE_NOTIFICATION_CHANNEL   = var.pipeline_notification_channel
    SECURITY_NOTIFICATION_CHANNEL   = var.security_notification_channel
    REPOSITORIES                    = var.repositories
    SOURCE_CONTROL_TYPE            = var.source_control_type
    AUTO_FIX_ENABLED               = var.auto_fix_enabled
    MAX_CONCURRENT_FIXES           = var.max_concurrent_fixes
    SCAN_INTERVAL                  = var.scan_interval
  }
}

# Pipeline Health Check Task
resource "kubiya_scheduled_task" "pipeline_health" {
  count          = var.pipeline_health_check_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
  repeat         = var.pipeline_health_check_repeat
  channel_id     = var.pipeline_notification_channel
  agent          = kubiya_agent.cicd_maintainer.name
  description    = replace(
    data.http.pipeline_health_check.response_body,
    "$${pipeline_notification_channel}",
    var.pipeline_notification_channel
  )
}

# Repository Security Scan Task
resource "kubiya_scheduled_task" "security_scan" {
  count          = var.security_scan_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "5m"))
  repeat         = var.security_scan_repeat
  channel_id     = var.security_notification_channel
  agent          = kubiya_agent.cicd_maintainer.name
  description    = replace(
    replace(
      data.http.security_scan.response_body,
      "$${security_notification_channel}",
      var.security_notification_channel
    ),
    "$${REPOSITORIES}",
    var.repositories
  )
}

# Dependency Update Check Task
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

# GitHub Webhook Configuration
resource "kubiya_webhook" "github_webhook" {
  count = var.source_control_type == "github" && var.webhook_enabled ? 1 : 0
  
  name        = "${var.teammate_name}-github-webhook"
  source      = "GitHub"
  prompt      = <<-EOT
    Analyze this GitHub event and determine if action is needed:
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
  destination = var.pipeline_notification_channel
}

# GitLab Webhook Configuration
resource "kubiya_webhook" "gitlab_webhook" {
  count = var.source_control_type == "gitlab" && var.webhook_enabled ? 1 : 0
  
  name        = "${var.teammate_name}-gitlab-webhook"
  source      = "GitLab"
  prompt      = <<-EOT
    Analyze this GitLab event and determine if action is needed:
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
  destination = var.pipeline_notification_channel
}

# GitHub Webhook Setup
resource "github_repository_webhook" "webhook" {
  for_each = var.source_control_type == "github" && var.webhook_enabled && var.github_token != "" ? (
    toset(split(",", var.repositories))
  ) : toset([])

  repository = trim(split("/", each.value)[1], " ")
  
  configuration {
    url          = kubiya_webhook.github_webhook[0].url
    content_type = var.webhook_content_type
    insecure_ssl = false
  }

  active = true
  events = local.github_events
}

# GitLab Webhook Setup
resource "gitlab_project_hook" "webhook" {
  for_each = var.source_control_type == "gitlab" && var.webhook_enabled && var.gitlab_token != "" ? (
    toset(split(",", var.repositories))
  ) : toset([])

  project = each.value
  url     = kubiya_webhook.gitlab_webhook[0].url
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

# Update teammate environment variables using the Kubiya provider
resource "kubiya_agent_environment" "cicd_maintainer_env" {
  agent_id = kubiya_agent.cicd_maintainer.id
  
  environment_variables = merge(
    {
      "KUBIYA_TOOL_TIMEOUT": "300",
      "NOTIFICATION_CHANNEL": var.notification_channel,
      "PIPELINE_NOTIFICATION_CHANNEL": var.pipeline_notification_channel,
      "SECURITY_NOTIFICATION_CHANNEL": var.security_notification_channel,
      "REPOSITORIES": var.repositories,
      "SOURCE_CONTROL_TYPE": var.source_control_type,
      "AUTO_FIX_ENABLED": tostring(var.auto_fix_enabled),
      "MAX_CONCURRENT_FIXES": tostring(var.max_concurrent_fixes),
      "SCAN_INTERVAL": var.scan_interval
    },
    var.source_control_type == "github" && var.webhook_enabled ? {
      "GITHUB_WEBHOOK_URL": kubiya_webhook.github_webhook[0].url,
      "GITHUB_TOKEN": var.github_token
    } : {},
    var.source_control_type == "gitlab" && var.webhook_enabled ? {
      "GITLAB_WEBHOOK_URL": kubiya_webhook.gitlab_webhook[0].url,
      "GITLAB_TOKEN": var.gitlab_token,
      "GITLAB_WEBHOOK_SECRET": random_password.webhook_secret[0].result
    } : {}
  )

  depends_on = [
    kubiya_webhook.github_webhook,
    kubiya_webhook.gitlab_webhook,
    random_password.webhook_secret
  ]
}

# Output the teammate details
output "cicd_maintainer" {
  value = {
    name                         = kubiya_agent.cicd_maintainer.name
    notification_channel         = var.notification_channel
    pipeline_notification_channel = var.pipeline_notification_channel
    security_notification_channel = var.security_notification_channel
    repositories                 = var.repositories
    source_control_type         = var.source_control_type
  }
}

# Add additional knowledge base
resource "kubiya_knowledge" "pipeline_management" {
  name             = "Pipeline Management Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for pipeline management and optimization"
  labels           = ["cicd", "pipeline", "optimization"]
  supported_agents = [kubiya_agent.cicd_maintainer.name]
  content          = data.http.pipeline_management.response_body
}

# Add this locals block at the top of the file
locals {
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
    security_events = var.monitor_security_events
    issues_events = var.monitor_issue_events
    releases_events = var.monitor_release_events
    job_events = var.monitor_pipeline_events
    tag_push_events = var.monitor_push_events
  }
}

# Generate webhook secret for GitLab
resource "random_password" "webhook_secret" {
  count   = var.source_control_type == "gitlab" && var.webhook_enabled && var.gitlab_token != "" ? 1 : 0
  length  = 32
  special = false
}

# Add this data source near the other HTTP data sources at the top of the file
data "http" "pipeline_management" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/knowledge/pipeline_management.md"
}

# Add these missing data sources as well
data "http" "pipeline_health_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/prompts/pipeline_health_check.md"
}

data "http" "security_scan" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/prompts/security_scan.md"
}

data "http" "dependency_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/ci_cd_maintainers/terraform/prompts/dependency_check.md"
} 