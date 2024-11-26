terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
    github = {
      source = "hashicorp/github"
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
  # Determine source control type based on provided token
  source_control_type = var.github_token != "" ? "github" : null
  
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
    var.monitor_pull_requests ? ["pull_request", "pull_request_review", "pull_request_review_comment"] : [],
    var.monitor_pipeline_events ? ["check_run", "check_suite", "workflow_job", "workflow_run"] : [],
    var.monitor_deployment_events ? ["deployment", "deployment_status"] : [],
    var.monitor_security_events ? ["repository_vulnerability_alert"] : [],
    var.monitor_issue_events ? ["issues", "issue_comment"] : [],
    var.monitor_release_events ? ["release"] : []
  )

  # GitHub organization handling
  github_organization = trim(split("/", local.repository_list[0])[0], " ")

}

# Configure providers
provider "github" {
  token = var.github_token != "" ? var.github_token : null
  owner = local.github_organization
}

# Validation block
check "token_validation" {
  assert {
    condition     = var.github_token != ""
    error_message = "Must provide GitHub token"
  }
}


# Configure sources
resource "kubiya_source" "cicd_workflow_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/cicd"
}

resource "kubiya_source" "github_tooling" {
  url   = "https://github.com/kubiyabot/community-tools/tree/main/github"
}


# Configure the CI/CD Maintainer agent
resource "kubiya_agent" "cicd_maintainer" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered CI/CD maintenance assistant"
  model        = "azure/gpt-4"
  instructions = ""
  
  sources = [
    kubiya_source.cicd_workflow_tooling.name,
    kubiya_source.github_tooling.name
  ]

  # Dynamic integrations based on configuration
  integrations = concat(
    ["slack"],
    var.github_enable_oauth ? ["github"] : []
  )

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    NOTIFICATION_CHANNEL            = var.notification_channel
    PIPELINE_NOTIFICATION_CHANNEL   = local.effective_pipeline_channel
    SECURITY_NOTIFICATION_CHANNEL   = local.effective_security_channel
    REPOSITORIES                    = var.repositories
    SOURCE_CONTROL_TYPE             = local.source_control_type
    AUTO_FIX_ENABLED                = tostring(var.auto_fix_enabled)
    MAX_CONCURRENT_FIXES            = tostring(var.max_concurrent_fixes)
    SCAN_INTERVAL                   = var.scan_interval
    GITHUB_OAUTH_ENABLED            = tostring(var.github_enable_oauth)
  }
}

# # Pipeline Health Check Task
# resource "kubiya_scheduled_task" "pipeline_health" {
#   count          = var.pipeline_health_check_enabled ? 1 : 0
#   scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
#   repeat         = var.pipeline_health_check_repeat
#   channel_id     = local.effective_pipeline_channel
#   agent          = kubiya_agent.cicd_maintainer.name
#   description    = replace(
#     data.http.pipeline_health_check.response_body,
#     "$${pipeline_notification_channel}",
#     local.effective_pipeline_channel
#   )
# }

# # Repository Security Scan Task
# resource "kubiya_scheduled_task" "security_scan" {
#   count          = var.security_scan_enabled ? 1 : 0
#   scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "5m"))
#   repeat         = var.security_scan_repeat
#   channel_id     = local.effective_security_channel
#   agent          = kubiya_agent.cicd_maintainer.name
#   description    = replace(
#     replace(
#       data.http.security_scan.response_body,
#       "$${security_notification_channel}",
#       local.effective_security_channel
#     ),
#     "$${REPOSITORIES}",
#     var.repositories
#   )
# }

# # Dependency Update Check Task
# resource "kubiya_scheduled_task" "dependency_check" {
#   count          = var.dependency_check_enabled ? 1 : 0
#   scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
#   repeat         = var.dependency_check_repeat
#   channel_id     = var.notification_channel
#   agent          = kubiya_agent.cicd_maintainer.name
#   description    = replace(
#     replace(
#       data.http.dependency_check.response_body,
#       "$${notification_channel}",
#       var.notification_channel
#     ),
#     "$${REPOSITORIES}",
#     var.repositories
#   )
# }

# Unified webhook configuration
resource "kubiya_webhook" "source_control_webhook" {
  count = local.webhook_enabled ? 1 : 0

  filter = var.webhook_filter
  
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
    ${var.auto_fix_enabled ? "Auto-Fix Mode Enabled: If the solution is clear and safe to implement automatically, create a pull request with the proposed fixes. Include detailed explanation of changes in the PR description." : ""}

  EOT
  agent       = kubiya_agent.cicd_maintainer.name
  destination = local.effective_pipeline_channel
}

# GitHub webhook setup
resource "github_repository_webhook" "webhook" {
  for_each = local.webhook_enabled ? toset(local.repository_list) : []

  repository = trim(split("/", each.value)[1], " ")
  
  configuration {
    url          = kubiya_webhook.source_control_webhook[0].url
    content_type = var.webhook_content_type
    insecure_ssl = false

  }

  active = true
  events = local.github_events
}

# Replace the kubiya_agent_environment resource with this null_resource
resource "null_resource" "agent_environment_setup" {
  triggers = {
    runner = var.kubiya_runner
    agent_id = kubiya_agent.cicd_maintainer.id
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
          "NOTIFICATION_CHANNEL": "${var.notification_channel}",
          "REPOSITORIES": "${var.repositories}",
          "SOURCE_CONTROL_TYPE": "${local.source_control_type}",
          "AUTO_FIX_ENABLED": "${tostring(var.auto_fix_enabled)}",
          "MAX_CONCURRENT_FIXES": "${tostring(var.max_concurrent_fixes)}",
          "SCAN_INTERVAL": "${var.scan_interval}"
          ${local.webhook_enabled ? ", \"GITHUB_WEBHOOK_URL\": \"${kubiya_webhook.source_control_webhook[0].url}\"" : ""}
          ${local.webhook_enabled ? ", \"GITHUB_TOKEN\": \"${var.github_token}\"" : ""}
          "PIPELINE_NOTIFICATION_CHANNEL": "${local.effective_pipeline_channel}",
          "SECURITY_NOTIFICATION_CHANNEL": "${local.effective_security_channel}",
          "GITHUB_OAUTH_ENABLED": "${tostring(var.github_enable_oauth)}"
        }
      }' \
      "https://api.kubiya.ai/api/v1/agents/${kubiya_agent.cicd_maintainer.id}"
    EOT
  }

  depends_on = [
    kubiya_agent.cicd_maintainer,
    kubiya_webhook.source_control_webhook
  ]
}

# Output the teammate details
output "cicd_maintainer" {
  sensitive = true
  value = {
    name                         = kubiya_agent.cicd_maintainer.name
    notification_channel         = var.notification_channel
    pipeline_notification_channel = local.effective_pipeline_channel
    security_notification_channel = local.effective_security_channel
    repositories                 = var.repositories
    source_control_type          = local.source_control_type
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
