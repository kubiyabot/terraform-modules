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
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/health_check.md"
}

data "http" "resource_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/resource_check.md"
}

data "http" "cleanup_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/cleanup.md"
}

data "http" "network_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/network_check.md"
}

data "http" "security_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/security_check.md"
}

data "http" "backup_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/backup_check.md"
}

data "http" "cost_analysis_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/cost_analysis.md"
}

data "http" "compliance_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/compliance_check.md"
}

data "http" "update_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/update_check.md"
}

data "http" "capacity_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/capacity_check.md"
}

data "http" "scaling_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/scaling_check.md"
}

data "http" "upgrade_check_prompt" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/prompts/upgrade_check.md"
}

data "http" "kubernetes_ops" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/knowledge/kubernetes_ops.md"
}

data "http" "kubernetes_security" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/knowledge/kubernetes_security.md"
}

data "http" "kubernetes_troubleshooting" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/improvments/kubernetes-crew/terraform/knowledge/kubernetes_troubleshooting.md"
}

resource "kubiya_source" "k8s_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/improvments/kubernetes"
}
resource "kubiya_source" "diagramming_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/improvments/mermaid"
}
resource "kubiya_source" "slack_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/slack-tools/slack"
}
resource "kubiya_agent" "kubernetes_crew" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered Kubernetes operations assistant"
  model        = "azure/gpt-4"
  instructions = ""
  sources      = [kubiya_source.k8s_capabilities.name, kubiya_source.diagramming_capabilities.name, kubiya_source.slack_capabilities.name]


  integrations = ["kubernetes", "slack"]
  users        = []
  groups       = var.kubiya_groups_allowed_groups

  environment_variables = {
    NOTIFICATION_CHANNEL = var.notification_channel
    SECURITY_CHANNEL    = var.security_channel
    ENVIRONMENT         = var.environment
    CRITICAL_NAMESPACES = var.critical_namespaces
    CPU_THRESHOLD       = var.cpu_threshold
    MEMORY_THRESHOLD    = var.memory_threshold
    POD_THRESHOLD       = var.pod_threshold
    KUBIYA_TOOL_TIMEOUT = "300"
  }
}

resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "Kubernetes Operations and Housekeeping Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for Kubernetes housekeeping operations"
  labels           = ["kubernetes", "operations", "housekeeping"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_ops.response_body
}

resource "kubiya_knowledge" "kubernetes_security" {
  name             = "Kubernetes Security Best Practices"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for Kubernetes security practices"
  labels           = ["kubernetes", "security", "best-practices"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_security.response_body
}

resource "kubiya_knowledge" "kubernetes_troubleshooting" {
  name             = "Kubernetes Troubleshooting Guide"
  groups           = var.kubiya_groups_allowed_groups
  description      = "Knowledge base for Kubernetes troubleshooting techniques"
  labels           = ["kubernetes", "troubleshooting", "debugging"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = data.http.kubernetes_troubleshooting.response_body
}

# Health Check Task
resource "kubiya_scheduled_task" "health_check" {
  count          = var.health_check_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
  repeat         = var.health_check_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
    description = replace(
    replace(
      data.http.security_check_prompt.response_body,
      "$${security_channel}",
      var.security_channel
    ),
    "$${notification_channel}",
    var.notification_channel
  )
}

# Security Scan Task
resource "kubiya_scheduled_task" "security_scan" {
  count          = var.security_scan_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "5m"))
  repeat         = var.security_scan_repeat
  channel_id     = var.security_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description = replace(
    replace(
      data.http.security_check_prompt.response_body,
      "$${security_channel}",
      var.security_channel
    ),
    "$${notification_channel}",
    var.notification_channel
  )
}

# Resource Check Task
resource "kubiya_scheduled_task" "resource_check" {
  count          = var.resource_check_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
  repeat         = var.resource_check_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.resource_check_prompt.response_body
}

# Backup Verification Task
resource "kubiya_scheduled_task" "backup_verify" {
  count          = var.backup_verify_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "5m"))
  repeat         = var.backup_verify_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.backup_check_prompt.response_body
}

# Compliance Audit Task
resource "kubiya_scheduled_task" "compliance_audit" {
  count          = var.compliance_audit_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
  repeat         = var.compliance_audit_repeat
  channel_id     = var.compliance_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.compliance_check_prompt.response_body
}

# Network Check Task
resource "kubiya_scheduled_task" "network_check" {
  count          = var.network_check_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "5m"))
  repeat         = var.network_check_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.network_check_prompt.response_body
}

# Scaling Analysis Task
resource "kubiya_scheduled_task" "scaling_analysis" {
  count          = var.scaling_analysis_enabled ? 1 : 0
  scheduled_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "3m"))
  repeat         = var.scaling_analysis_repeat
  channel_id     = var.notification_channel
  agent          = kubiya_agent.kubernetes_crew.name
  description    = data.http.scaling_check_prompt.response_body
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
