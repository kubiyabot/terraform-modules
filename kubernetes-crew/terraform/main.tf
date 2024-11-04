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

# Load prompts from GitHub
data "http" "health_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/health_check.md"
}

data "http" "resource_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/resource_check.md"
}

data "http" "cleanup" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/cleanup.md"
}

data "http" "network_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/network_check.md"
}

data "http" "security_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/security_check.md"
}

data "http" "backup_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/backup_check.md"
}

data "http" "cost_analysis" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/cost_analysis.md"
}

data "http" "compliance_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/compliance_check.md"
}

data "http" "update_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/update_check.md"
}

data "http" "capacity_check" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/prompts/capacity_check.md"
}

data "http" "kubernetes_ops" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/knowledge/kubernetes_ops.md"
}

data "http" "kubernetes_security" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/knowledge/kubernetes_security.md"
}

data "http" "kubernetes_troubleshooting" {
  url = "https://raw.githubusercontent.com/kubiyabot/community-tools/main/kubernetes/knowledge/kubernetes_troubleshooting.md"
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
  content          = data.http.kubernetes_ops.response_body
}

# Additional knowledge resources
resource "kubiya_knowledge" "kubernetes_security" {
  name             = "Kubernetes Security Guide"
  groups           = var.groups
  description      = "Security best practices and compliance guidelines"
  labels           = ["kubernetes", "security"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_security.response_body
}

resource "kubiya_knowledge" "kubernetes_troubleshooting" {
  name             = "Kubernetes Troubleshooting Guide"
  groups           = var.groups
  description      = "Common issues and resolution procedures"
  labels           = ["kubernetes", "troubleshooting"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_troubleshooting.response_body
}


# Core Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.enabled_tasks.health_check ? 1 : 0
  scheduled_time = var.task_schedules.health_check.start_time
  repeat         = var.task_schedules.health_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.health_check_prompt.response_body
}

# Resource Optimization Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.enabled_tasks.resource_check ? 1 : 0
  scheduled_time = var.task_schedules.resource_check.start_time
  repeat         = var.task_schedules.resource_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.resource_check_prompt.response_body
}

# Cleanup Task
resource "kubiya_scheduled_task" "cleanup" {
  count          = var.enabled_tasks.cleanup ? 1 : 0
  scheduled_time = var.task_schedules.cleanup.start_time
  repeat         = var.task_schedules.cleanup.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.cleanup_prompt.response_body
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.enabled_tasks.network_check ? 1 : 0
  scheduled_time = var.task_schedules.network_check.start_time
  repeat         = var.task_schedules.network_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.network_check_prompt.response_body
}

# Security Check Task
resource "kubiya_scheduled_task" "security_check" {
  count          = var.enabled_tasks.security_check ? 1 : 0
  scheduled_time = var.task_schedules.security_check.start_time
  repeat         = var.task_schedules.security_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.security_check_prompt.response_body
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_check" {
  count          = var.enabled_tasks.backup_check ? 1 : 0
  scheduled_time = var.task_schedules.backup_check.start_time
  repeat         = var.task_schedules.backup_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.backup_check_prompt.response_body
}

# Cost Analysis Task
resource "kubiya_scheduled_task" "cost_analysis" {
  count          = var.enabled_tasks.cost_analysis ? 1 : 0
  scheduled_time = var.task_schedules.cost_analysis.start_time
  repeat         = var.task_schedules.cost_analysis.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.cost_analysis_prompt.response_body
}

# Compliance Check Task
resource "kubiya_scheduled_task" "compliance_check" {
  count          = var.enabled_tasks.compliance_check ? 1 : 0
  scheduled_time = var.task_schedules.compliance_check.start_time
  repeat         = var.task_schedules.compliance_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.compliance_check_prompt.response_body
}

# Update Check Task
resource "kubiya_scheduled_task" "update_check" {
  count          = var.enabled_tasks.update_check ? 1 : 0
  scheduled_time = var.task_schedules.update_check.start_time
  repeat         = var.task_schedules.update_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.update_check_prompt.response_body
}

# Capacity Planning Task
resource "kubiya_scheduled_task" "capacity_check" {
  count          = var.enabled_tasks.capacity_check ? 1 : 0
  scheduled_time = var.task_schedules.capacity_check.start_time
  repeat         = var.task_schedules.capacity_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.capacity_check_prompt.response_body
}

# Upgrade Assessment Task
resource "kubiya_scheduled_task" "upgrade_check" {
  count          = var.enabled_tasks.upgrade_check ? 1 : 0
  scheduled_time = var.task_schedules.upgrade_check.start_time
  repeat         = var.task_schedules.upgrade_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.upgrade_check_prompt.response_body
}

# Scaling Check Task
resource "kubiya_scheduled_task" "scaling_check" {
  count          = var.enabled_tasks.scaling_check ? 1 : 0
  scheduled_time = var.task_schedules.scaling_check.start_time
  repeat         = var.task_schedules.scaling_check.repeat
  channel_id     = var.notification_slack_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.scaling_check_prompt.response_body
}

output "kubernetes_crew" {
  value = kubiya_agent.kubernetes_crew
}
