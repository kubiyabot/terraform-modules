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
  users        = var.kubiya_users
  groups       = var.kubiya_groups
  sources      = [kubiya_source.source.name]

  environment_variables = {
    LOG_LEVEL                = var.log_level
    NOTIFICATION_CHANNEL     = var.notification_slack_channel
  }
}

resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "Kubernetes Operations Guide"
  groups           = var.kubiya_groups
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
}

# Core Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.enable_health_check_task ? 1 : 0
  scheduled_time = var.health_check_start_time
  repeat         = var.health_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.health_check_prompt != "" ? var.health_check_prompt : local.health_check_prompt
}

# Resource Optimization Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.enable_resource_check_task ? 1 : 0
  scheduled_time = var.resource_check_start_time
  repeat         = var.resource_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.resource_check_prompt != "" ? var.resource_check_prompt : local.resource_check_prompt
}

# Cleanup Task
resource "kubiya_scheduled_task" "cleanup" {
  count          = var.enable_cleanup_task ? 1 : 0
  scheduled_time = var.cleanup_start_time
  repeat         = var.cleanup_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.cleanup_prompt != "" ? var.cleanup_prompt : local.cleanup_prompt
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.enable_network_check_task ? 1 : 0
  scheduled_time = var.network_check_start_time
  repeat         = var.network_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.network_check_prompt != "" ? var.network_check_prompt : local.network_check_prompt
}

# Security Check Task
resource "kubiya_scheduled_task" "security_check" {
  count          = var.enable_security_check_task ? 1 : 0
  scheduled_time = var.security_check_start_time
  repeat         = var.security_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.security_check_prompt != "" ? var.security_check_prompt : local.security_check_prompt
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_check" {
  count          = var.enable_backup_check_task ? 1 : 0
  scheduled_time = var.backup_check_start_time
  repeat         = var.backup_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.backup_check_prompt != "" ? var.backup_check_prompt : local.backup_check_prompt
}

# Cost Analysis Task
resource "kubiya_scheduled_task" "cost_analysis" {
  count          = var.enable_cost_analysis_task ? 1 : 0
  scheduled_time = var.cost_analysis_start_time
  repeat         = var.cost_analysis_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.cost_analysis_prompt != "" ? var.cost_analysis_prompt : local.cost_analysis_prompt
}

# Compliance Check Task
resource "kubiya_scheduled_task" "compliance_check" {
  count          = var.enable_compliance_check_task ? 1 : 0
  scheduled_time = var.compliance_check_start_time
  repeat         = var.compliance_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.compliance_check_prompt != "" ? var.compliance_check_prompt : local.compliance_check_prompt
}

# Update Check Task
resource "kubiya_scheduled_task" "update_check" {
  count          = var.enable_update_check_task ? 1 : 0
  scheduled_time = var.update_check_start_time
  repeat         = var.update_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.update_check_prompt != "" ? var.update_check_prompt : local.update_check_prompt
}

# Capacity Planning Task
resource "kubiya_scheduled_task" "capacity_check" {
  count          = var.enable_capacity_check_task ? 1 : 0
  scheduled_time = var.capacity_check_start_time
  repeat         = var.capacity_check_repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = var.capacity_check_prompt != "" ? var.capacity_check_prompt : local.capacity_check_prompt
}

output "kubernetes_crew" {
  value = kubiya_agent.kubernetes_crew
}
