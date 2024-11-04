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

resource "kubiya_source" "source" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/kubernetes"
}

resource "kubiya_agent" "kubernetes_crew" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = var.teammate_description
  instructions = ""
  model        = "azure/gpt-4"
  integrations = ["kubernetes", "slack"]
  users        = var.users
  groups       = var.groups
  sources      = [kubiya_source.source.name]

  environment_variables = {
    LOG_LEVEL            = var.log_level
    NOTIFICATION_CHANNEL = var.notification_slack_channel
  }
}

resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "Kubernetes Operations and Housekeeping Guide"
  groups           = var.groups
  description      = "Knowledge base for Kubernetes housekeeping operations"
  labels           = ["kubernetes", "operations", "housekeeping"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = file("${path.module}/knowledge/kubernetes_ops.md")
}

# Additional knowledge resources
resource "kubiya_knowledge" "kubernetes_security" {
  name             = "Kubernetes Security Guide"
  groups           = var.groups
  description      = "Security best practices and compliance guidelines"
  labels           = ["kubernetes", "security"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = file("${path.module}/knowledge/kubernetes_security.md")
}

resource "kubiya_knowledge" "kubernetes_troubleshooting" {
  name             = "Kubernetes Troubleshooting Guide"
  groups           = var.groups
  description      = "Common issues and resolution procedures"
  labels           = ["kubernetes", "troubleshooting"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = file("${path.module}/knowledge/kubernetes_troubleshooting.md")
}

# Load prompts from files
locals {
  health_check_prompt     = file("${path.module}/prompts/health_check.md")
  resource_check_prompt   = file("${path.module}/prompts/resource_check.md")
  cleanup_prompt          = file("${path.module}/prompts/cleanup.md")
  network_check_prompt    = file("${path.module}/prompts/network_check.md")
  security_check_prompt   = file("${path.module}/prompts/security_check.md")
  backup_check_prompt     = file("${path.module}/prompts/backup_check.md")
  cost_analysis_prompt    = file("${path.module}/prompts/cost_analysis.md")
  compliance_check_prompt = file("${path.module}/prompts/compliance_check.md")
  update_check_prompt     = file("${path.module}/prompts/update_check.md")
  capacity_check_prompt   = file("${path.module}/prompts/capacity_check.md")
  upgrade_check_prompt    = file("${path.module}/prompts/upgrade_check.md")
  scaling_check_prompt    = file("${path.module}/prompts/scaling_check.md")
}

# Core Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.enabled_tasks.health_check ? 1 : 0
  scheduled_time = var.task_schedules.health_check.start_time
  repeat         = var.task_schedules.health_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.health_check_prompt
}

# Resource Optimization Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.enabled_tasks.resource_check ? 1 : 0
  scheduled_time = var.task_schedules.resource_check.start_time
  repeat         = var.task_schedules.resource_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.resource_check_prompt
}

# Cleanup Task
resource "kubiya_scheduled_task" "cleanup" {
  count          = var.enabled_tasks.cleanup ? 1 : 0
  scheduled_time = var.task_schedules.cleanup.start_time
  repeat         = var.task_schedules.cleanup.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.cleanup_prompt
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.enabled_tasks.network_check ? 1 : 0
  scheduled_time = var.task_schedules.network_check.start_time
  repeat         = var.task_schedules.network_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.network_check_prompt
}

# Security Check Task
resource "kubiya_scheduled_task" "security_check" {
  count          = var.enabled_tasks.security_check ? 1 : 0
  scheduled_time = var.task_schedules.security_check.start_time
  repeat         = var.task_schedules.security_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.security_check_prompt
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_check" {
  count          = var.enabled_tasks.backup_check ? 1 : 0
  scheduled_time = var.task_schedules.backup_check.start_time
  repeat         = var.task_schedules.backup_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.backup_check_prompt
}

# Cost Analysis Task
resource "kubiya_scheduled_task" "cost_analysis" {
  count          = var.enabled_tasks.cost_analysis ? 1 : 0
  scheduled_time = var.task_schedules.cost_analysis.start_time
  repeat         = var.task_schedules.cost_analysis.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.cost_analysis_prompt
}

# Compliance Check Task
resource "kubiya_scheduled_task" "compliance_check" {
  count          = var.enabled_tasks.compliance_check ? 1 : 0
  scheduled_time = var.task_schedules.compliance_check.start_time
  repeat         = var.task_schedules.compliance_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.compliance_check_prompt
}

# Update Check Task
resource "kubiya_scheduled_task" "update_check" {
  count          = var.enabled_tasks.update_check ? 1 : 0
  scheduled_time = var.task_schedules.update_check.start_time
  repeat         = var.task_schedules.update_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.update_check_prompt
}

# Capacity Planning Task
resource "kubiya_scheduled_task" "capacity_check" {
  count          = var.enabled_tasks.capacity_check ? 1 : 0
  scheduled_time = var.task_schedules.capacity_check.start_time
  repeat         = var.task_schedules.capacity_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.capacity_check_prompt
}

# Upgrade Assessment Task
resource "kubiya_scheduled_task" "upgrade_check" {
  count          = var.enabled_tasks.upgrade_check ? 1 : 0
  scheduled_time = var.task_schedules.upgrade_check.start_time
  repeat         = var.task_schedules.upgrade_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.upgrade_check_prompt
}

# Scaling Check Task
resource "kubiya_scheduled_task" "scaling_check" {
  count          = var.enabled_tasks.scaling_check ? 1 : 0
  scheduled_time = var.task_schedules.scaling_check.start_time
  repeat         = var.task_schedules.scaling_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = local.scaling_check_prompt
}

output "kubernetes_crew" {
  value = kubiya_agent.kubernetes_crew
}
