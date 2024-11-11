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
  name        = var.teammate_name
  runner      = var.kubiya_runner
  description = "AI-powered Kubernetes operations assistant"
  model       = "azure/gpt-4"
  
  integrations = ["kubernetes", "slack"]
  users        = var.allowed_users
  groups       = var.allowed_groups

  environment_variables = {
    NOTIFICATION_CHANNEL = var.notification_channel
    SECURITY_CHANNEL    = var.security_channel
    ENVIRONMENT        = var.cluster_context.environment
    CRITICAL_NAMESPACES = jsonencode(var.cluster_context.critical_namespaces)
    CPU_THRESHOLD      = var.cluster_context.resource_thresholds.cpu_threshold
    MEMORY_THRESHOLD   = var.cluster_context.resource_thresholds.memory_threshold
    POD_THRESHOLD      = var.cluster_context.resource_thresholds.pod_threshold
  }
}

# Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count         = var.schedule_config.health_check.enabled ? 1 : 0
  cron          = var.schedule_config.health_check.cron
  channel_id    = var.notification_channel
  agent         = kubiya_agent.kubernetes_crew.name
  description   = file("${path.module}/prompts/health_check.md")
}

# Security Scan Task
resource "kubiya_scheduled_task" "security_scan" {
  count         = var.schedule_config.security_scan.enabled ? 1 : 0
  cron          = var.schedule_config.security_scan.cron
  channel_id    = var.security_channel
  agent         = kubiya_agent.kubernetes_crew.name
  description   = file("${path.module}/prompts/security_check.md")
}

# Resource Check Task
resource "kubiya_scheduled_task" "resource_check" {
  count         = var.schedule_config.resource_check.enabled ? 1 : 0
  cron          = var.schedule_config.resource_check.cron
  channel_id    = var.notification_channel
  agent         = kubiya_agent.kubernetes_crew.name
  description   = file("${path.module}/prompts/resource_check.md")
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_verify" {
  count         = var.schedule_config.backup_verify.enabled ? 1 : 0
  cron          = var.schedule_config.backup_verify.cron
  channel_id    = var.notification_channel
  agent         = kubiya_agent.kubernetes_crew.name
  description   = file("${path.module}/prompts/backup_check.md")
}

# Compliance Audit Task
resource "kubiya_scheduled_task" "compliance_audit" {
  count         = var.schedule_config.compliance_audit.enabled ? 1 : 0
  cron          = var.schedule_config.compliance_audit.cron
  channel_id    = var.notification_channel
  agent         = kubiya_agent.kubernetes_crew.name
  description   = file("${path.module}/prompts/compliance_check.md")
}

# Output the teammate details
output "kubernetes_crew" {
  value = {
    name = kubiya_agent.kubernetes_crew.name
    notification_channel = var.notification_channel
    security_channel = var.security_channel
    environment = var.cluster_context.environment
    critical_namespaces = var.cluster_context.critical_namespaces
  }
}
