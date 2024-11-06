terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
    }
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

data "http" "health_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/health_check.md"
}

data "http" "resource_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/resource_check.md"
}

data "http" "cleanup_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/cleanup.md"
}

data "http" "network_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/network_check.md"
}

data "http" "security_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/security_check.md"
}

data "http" "backup_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/backup_check.md"
}

data "http" "cost_analysis_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/cost_analysis.md"
}

data "http" "compliance_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/compliance_check.md"
}

data "http" "update_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/update_check.md"
}

data "http" "capacity_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/capacity_check.md"
}

data "http" "scaling_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/scaling_check.md"
}

data "http" "upgrade_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/prompts/upgrade_check.md"
}

data "http" "kubernetes_ops" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/knowledge/kubernetes_ops.md"
}

data "http" "kubernetes_security" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/knowledge/kubernetes_security.md"
}

data "http" "kubernetes_troubleshooting" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/knowledge/kubernetes_troubleshooting.md"
}

resource "kubiya_source" "source" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/kubernetes"
}

resource "kubiya_agent" "kubernetes_crew" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = var.teammate_description
  instructions = ""
  model        = "azure/gpt-4o"
  integrations = ["kubernetes", "slack"]
  users        = var.kubiya_users
  groups       = var.kubiya_groups
  sources      = [kubiya_source.source.name]

  environment_variables = {
    LOG_LEVEL            = var.log_level
    NOTIFICATION_CHANNEL = var.notification_slack_channel
  }
}

resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "Kubernetes Operations and Housekeeping Guide"
  groups           = var.kubiya_groups
  description      = "Knowledge base for Kubernetes housekeeping operations"
  labels           = ["kubernetes", "operations", "housekeeping"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_ops.response_body
}

# Additional knowledge resources
resource "kubiya_knowledge" "kubernetes_security" {
  name             = "Kubernetes Security Guide"
  groups           = var.kubiya_groups
  description      = "Security best practices and compliance guidelines"
  labels           = ["kubernetes", "security"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_security.response_body
}

resource "kubiya_knowledge" "kubernetes_troubleshooting" {
  name             = "Kubernetes Troubleshooting Guide"
  groups           = var.kubiya_groups
  description      = "Common issues and resolution procedures"
  labels           = ["kubernetes", "troubleshooting"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_troubleshooting.response_body
}

# Core Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.enable_health_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_one, "daily")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.health_check_prompt.response_body
}

# Resource Optimization Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.enable_resource_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_one, "daily")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.resource_check_prompt.response_body

}

# Cleanup Task
resource "kubiya_scheduled_task" "cleanup" {
  count          = var.enable_cleanup_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_two, "weekly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.cleanup_prompt.response_body
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.enable_network_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_one, "daily")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.network_check_prompt.response_body
}

# Security Check Task
resource "kubiya_scheduled_task" "security_check" {
  count          = var.enable_security_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_two, "weekly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.security_check_prompt.response_body
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_check" {
  count          = var.enable_backup_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_one, "daily")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.backup_check_prompt.response_body
}

# Cost Analysis Task
resource "kubiya_scheduled_task" "cost_analysis" {
  count          = var.enable_cost_analysis_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_two, "weekly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.cost_analysis_prompt.response_body
}

# Compliance Check Task
resource "kubiya_scheduled_task" "compliance_check" {
  count          = var.enable_compliance_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_three, "monthly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.compliance_check_prompt.response_body
}

# Update Check Task
resource "kubiya_scheduled_task" "update_check" {
  count          = var.enable_update_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_two, "weekly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.update_check_prompt.response_body
}

# Capacity Planning Task
resource "kubiya_scheduled_task" "capacity_check" {
  count          = var.enable_capacity_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_three, "monthly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.capacity_check_prompt.response_body
}

# Upgrade Assessment Task
resource "kubiya_scheduled_task" "upgrade_check" {
  count          = var.enable_upgrade_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_three, "monthly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.upgrade_check_prompt.response_body
}

# Scaling Check Task
resource "kubiya_scheduled_task" "scaling_check" {
  count          = var.enable_network_check_task ? 1 : 0
  scheduled_time = try(var.cronjob_start_time, "2024-11-05T08:00:00")
  repeat         = try(var.cronjob_repeat_scenario_three, "monthly")
  channel_id     = var.scheduled_task_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.scaling_check_prompt.response_body
}

output "kubernetes_crew" {
  value = kubiya_agent.kubernetes_crew
}
