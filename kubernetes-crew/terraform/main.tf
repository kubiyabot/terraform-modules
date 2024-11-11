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

resource "kubiya_source" "k8s_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/kubernetes"
}
resource "kubiya_source" "diagramming_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/mermaid"
}

resource "kubiya_agent" "kubernetes_crew" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered Kubernetes operations assistant"
  model        = "azure/gpt-4"
  instructions = "" #file("${path.module}/prompts/instructions.md")

  integrations = ["kubernetes", "slack"]
  users        = var.kubiya_users_allowed_users
  groups       = var.kubiya_groups_allowed_groups

  environment_variables = {
    NOTIFICATION_CHANNEL = var.notification_channel
    SECURITY_CHANNEL    = var.security_channel
    ENVIRONMENT         = var.environment
    CRITICAL_NAMESPACES = var.critical_namespaces
    CPU_THRESHOLD       = var.cpu_threshold
    MEMORY_THRESHOLD    = var.memory_threshold
    POD_THRESHOLD       = var.pod_threshold
  }
}

# Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.health_check_enabled ? 1 : 0
  scheduled_time = var.health_check_start_time
  repeat         = var.health_check_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = file("${path.module}/prompts/health_check.md")
}

# Security Scan Task
resource "kubiya_scheduled_task" "security_scan" {
  count          = var.security_scan_enabled ? 1 : 0
  scheduled_time = var.security_scan_time
  repeat         = var.security_scan_repeat
  channel_id     = var.security_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = file("${path.module}/prompts/security_check.md")
}

# Resource Check Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.resource_check_enabled ? 1 : 0
  scheduled_time = var.resource_check_time
  repeat         = var.resource_check_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = file("${path.module}/prompts/resource_check.md")
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_verify" {
  count          = var.backup_verify_enabled ? 1 : 0
  scheduled_time = var.backup_verify_time
  repeat         = var.backup_verify_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = file("${path.module}/prompts/backup_check.md")
}

# Compliance Audit Task
resource "kubiya_scheduled_task" "compliance_audit" {
  count          = var.compliance_audit_enabled ? 1 : 0
  scheduled_time = var.compliance_audit_time
  repeat         = var.compliance_audit_repeat
  channel_id     = var.compliance_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = file("${path.module}/prompts/compliance_check.md")
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.network_check_enabled ? 1 : 0
  scheduled_time = var.network_check_time
  repeat         = var.network_check_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = file("${path.module}/prompts/network_check.md")
}

# Scaling Analysis Task
resource "kubiya_scheduled_task" "scaling_analysis" {
  count          = var.scaling_analysis_enabled ? 1 : 0
  scheduled_time = var.scaling_analysis_time
  repeat         = var.scaling_analysis_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = file("${path.module}/prompts/scaling_check.md")
}

# Output the teammate details
output "kubernetes_crew" {
  value = {
    name                 = kubiya_agent.kubernetes_crew.name
    notification_channel = var.notification_channel
    security_channel     = var.security_channel
    environment          = var.environment
    critical_namespaces  = var.critical_namespaces
  }
}
