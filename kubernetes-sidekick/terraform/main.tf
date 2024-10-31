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
    LOG_LEVEL                = var.log_level
    NOTIFICATION_CHANNEL     = var.notification_slack_channel
  }
}

resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "Kubernetes Operations Guide"
  groups           = var.groups
  description      = "Knowledge base for Kubernetes operations and troubleshooting"
  labels           = ["kubernetes", "operations"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = file("${path.module}/knowledge/kubernetes_ops.md")
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

  # Mapping of schedule names to cron expressions
  schedule_cron = {
    "hourly"  = "0 * * * *"
    "daily"   = "0 0 * * *"
    "weekly"  = "0 0 * * 0"
    "monthly" = "0 0 1 * *"
  }
}

# Core Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.enable_health_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.health_check_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = "Kubernetes Cluster Health Check"
  task_content   = var.health_check_prompt != "" ? var.health_check_prompt : local.health_check_prompt
}

# Resource Optimization Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.enable_resource_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.resource_check_schedule, "0 0 * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = "Kubernetes Resource Optimization Check"
  prompt   = var.resource_check_prompt != "" ? var.resource_check_prompt : local.resource_check_prompt
}

# Cleanup Task
resource "kubiya_scheduled_task" "cleanup" {
  count          = var.enable_cleanup_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.cleanup_schedule, "0 0 * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = "Kubernetes Cluster Cleanup"
  task_content   = var.cleanup_prompt != "" ? var.cleanup_prompt : local.cleanup_prompt
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.enable_network_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.network_check_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = "Kubernetes Network Health Check"
  task_content   = var.network_check_prompt != "" ? var.network_check_prompt : local.network_check_prompt
}

# Security Check Task
resource "kubiya_scheduled_task" "security_check" {
  count          = var.enable_security_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.security_check_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = "Kubernetes Security Audit"
  task_content   = var.security_check_prompt != "" ? var.security_check_prompt : local.security_check_prompt
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_check" {
  count          = var.enable_backup_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.backup_check_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = "Kubernetes Backup Verification"
  task_content   = var.backup_check_prompt != "" ? var.backup_check_prompt : local.backup_check_prompt
}

# Cost Analysis Task
resource "kubiya_scheduled_task" "cost_analysis" {
  count          = var.enable_cost_analysis_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.cost_analysis_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.cost_analysis_prompt != "" ? var.cost_analysis_prompt : local.cost_analysis_prompt
}

# Compliance Check Task
resource "kubiya_scheduled_task" "compliance_check" {
  count          = var.enable_compliance_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.compliance_check_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.compliance_check_prompt != "" ? var.compliance_check_prompt : local.compliance_check_prompt
}
  
# Update Check Task
resource "kubiya_scheduled_task" "update_check" {
  count          = var.enable_update_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.update_check_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.update_check_prompt != "" ? var.update_check_prompt : local.update_check_prompt
}

# Capacity Planning Task
resource "kubiya_scheduled_task" "capacity_check" {
  count          = var.enable_capacity_check_task ? 1 : 0
  scheduled_time = lookup(local.schedule_cron, var.capacity_check_schedule, "0 * * * *")
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.capacity_check_prompt != "" ? var.capacity_check_prompt : local.capacity_check_prompt
}

output "kubernetes_crew" {
  value = kubiya_agent.kubernetes_crew
}
