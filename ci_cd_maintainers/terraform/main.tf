terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
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

# Add after the webhook resources...

resource "null_resource" "runner_env_setup" {
  triggers = {
    runner = var.kubiya_runner
    github_webhook_id = var.source_control_type == "github" && var.webhook_enabled ? kubiya_webhook.github_webhook[0].id : ""
    gitlab_webhook_id = var.source_control_type == "gitlab" && var.webhook_enabled ? kubiya_webhook.gitlab_webhook[0].id : ""
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X PUT \
      -H "Authorization: UserKey $KUBIYA_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "uuid": "${kubiya_agent.cicd_maintainer.id}",
        "environment_variables": {
          "KUBIYA_TOOL_TIMEOUT": "300",
          %{if var.source_control_type == "github" && var.webhook_enabled~}
          "GITHUB_WEBHOOK_URL": "${kubiya_webhook.github_webhook[0].url}",
          %{endif~}
          %{if var.source_control_type == "gitlab" && var.webhook_enabled~}
          "GITLAB_WEBHOOK_URL": "${kubiya_webhook.gitlab_webhook[0].url}",
          %{endif~}
          "NOTIFICATION_CHANNEL": "${var.notification_channel}",
          "PIPELINE_NOTIFICATION_CHANNEL": "${var.pipeline_notification_channel}",
          "SECURITY_NOTIFICATION_CHANNEL": "${var.security_notification_channel}",
          "REPOSITORIES": "${var.repositories}",
          "SOURCE_CONTROL_TYPE": "${var.source_control_type}",
          "AUTO_FIX_ENABLED": "${var.auto_fix_enabled}",
          "MAX_CONCURRENT_FIXES": "${var.max_concurrent_fixes}",
          "SCAN_INTERVAL": "${var.scan_interval}"
        }
      }' \
      "https://api.kubiya.ai/api/v1/agents/${kubiya_agent.cicd_maintainer.id}"
    EOT
  }

  depends_on = [
    kubiya_webhook.github_webhook,
    kubiya_webhook.gitlab_webhook
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