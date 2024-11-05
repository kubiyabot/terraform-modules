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
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/health_check.md"
}

data "http" "resource_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/resource_check.md"
}

data "http" "cleanup_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/cleanup.md"
}

data "http" "network_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/network_check.md"
}

data "http" "security_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/security_check.md"
}

data "http" "backup_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/backup_check.md"
}

data "http" "cost_analysis_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/cost_analysis.md"
}

data "http" "compliance_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/compliance_check.md"
}

data "http" "update_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/update_check.md"
}

data "http" "capacity_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/prompts/capacity_check.md"
}

data "http" "scaling_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/terraform/prompts/scaling_check.md"
}

data "http" "upgrade_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/terraform/prompts/upgrade_check.md"
}

data "http" "kubernetes_ops" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/knowledge/kubernetes_ops.md"
}

data "http" "kubernetes_security" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/knowledge/kubernetes_security.md"
}

data "http" "kubernetes_troubleshooting" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform/knowledge/kubernetes_troubleshooting.md"
}

resource "kubiya_source" "source" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/refinement-costa/kubernetes-crew/terraform"
}

resource "kubiya_agent" "kubernetes_crew" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = var.teammate_description
  instructions = ""
  model        = "azure/gpt-4"
  integrations = ["slack"]
  users        = var.users
  groups       = var.groups
  sources      = [kubiya_source.source.name]

  environment_variables = {
    LOG_LEVEL            = var.log_level
    NOTIFICATION_CHANNEL = var.notification_slack_channel
  }
}

resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "Kubernetes Operations and Housekeeping Guide - test"
  groups           = var.groups
  description      = "Knowledge base for Kubernetes housekeeping operations"
  labels           = ["kubernetes", "operations", "housekeeping"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_ops.response_body
}

# Additional knowledge resources
resource "kubiya_knowledge" "kubernetes_security" {
  name             = "Kubernetes Security Guide - test"
  groups           = var.groups
  description      = "Security best practices and compliance guidelines"
  labels           = ["kubernetes", "security"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_security.response_body
}

resource "kubiya_knowledge" "kubernetes_troubleshooting" {
  name             = "Kubernetes Troubleshooting Guide - test"
  groups           = var.groups
  description      = "Common issues and resolution procedures"
  labels           = ["kubernetes", "troubleshooting"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_troubleshooting.response_body
}


# Core Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.enabled_tasks.health_check ? 1 : 0
  scheduled_time = try(var.task_schedules.health_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.health_check.repeat, "daily")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.health_check_prompt.response_body
}

# Resource Optimization Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.enabled_tasks.resource_check ? 1 : 0
  scheduled_time = try(var.task_schedules.resource_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.resource_check.repeat, "daily")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.resource_check_prompt.response_body
}

# Cleanup Task
resource "kubiya_scheduled_task" "cleanup" {
  count          = var.enabled_tasks.cleanup ? 1 : 0
  scheduled_time = try(var.task_schedules.cleanup.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.cleanup.repeat, "weekly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.cleanup_prompt.response_body
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.enabled_tasks.network_check ? 1 : 0
  scheduled_time = try(var.task_schedules.network_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.network_check.repeat, "daily")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.network_check_prompt.response_body
}

# Security Check Task
resource "kubiya_scheduled_task" "security_check" {
  count          = var.enabled_tasks.security_check ? 1 : 0
  scheduled_time = try(var.task_schedules.security_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.security_check.repeat, "weekly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.security_check_prompt.response_body
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_check" {
  count          = var.enabled_tasks.backup_check ? 1 : 0
  scheduled_time = try(var.task_schedules.backup_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.backup_check.repeat, "daily")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.backup_check_prompt.response_body
}

# Cost Analysis Task
resource "kubiya_scheduled_task" "cost_analysis" {
  count          = var.enabled_tasks.cost_analysis ? 1 : 0
  scheduled_time = try(var.task_schedules.cost_analysis.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.cost_analysis.repeat, "weekly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.cost_analysis_prompt.response_body
}

# Compliance Check Task
resource "kubiya_scheduled_task" "compliance_check" {
  count          = var.enabled_tasks.compliance_check ? 1 : 0
  scheduled_time = try(var.task_schedules.compliance_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.compliance_check.repeat, "monthly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.compliance_check_prompt.response_body
}

# Update Check Task
resource "kubiya_scheduled_task" "update_check" {
  count          = var.enabled_tasks.update_check ? 1 : 0
  scheduled_time = try(var.task_schedules.update_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.update_check.repeat, "weekly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.update_check_prompt.response_body
}

# Capacity Planning Task
resource "kubiya_scheduled_task" "capacity_check" {
  count          = var.enabled_tasks.capacity_check ? 1 : 0
  scheduled_time = try(var.task_schedules.capacity_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.capacity_check.repeat, "monthly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.capacity_check_prompt.response_body
}

# Upgrade Assessment Task
resource "kubiya_scheduled_task" "upgrade_check" {
  count          = var.enabled_tasks.upgrade_check ? 1 : 0
  scheduled_time = try(var.task_schedules.upgrade_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.upgrade_check.repeat, "monthly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.upgrade_check_prompt.response_body
}

# Scaling Check Task
resource "kubiya_scheduled_task" "scaling_check" {
  count          = var.enabled_tasks.scaling_check ? 1 : 0
  scheduled_time = try(var.task_schedules.scaling_check.start_time, "2024-11-06T08:00:00")
  repeat         = try(var.task_schedules.scaling_check.repeat, "monthly")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.scaling_check_prompt.response_body
}

output "kubernetes_crew" {
  value = kubiya_agent.kubernetes_crew
}
