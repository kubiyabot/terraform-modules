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

#knowledge
data "http" "kubernetes_security" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/knowledge/kubernetes_security.md"
}

data "http" "kubernetes_troubleshooting" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/knowledge/kubernetes_troubleshooting.md"
}

data "http" "kubernetes_ops" {
  url = "https://raw.githubusercontent.com/kubiyabot/terraform-modules/refs/heads/main/kubernetes-crew/terraform/knowledge/kubernetes_ops.md"
}


resource "kubiya_source" "k8s_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/shaked/k8s-crew-v2/kubernetes"
}
resource "kubiya_source" "diagramming_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/mermaid"
}
resource "kubiya_source" "slack_capabilities" {
  url = "https://github.com/kubiyabot/community-tools/tree/slack-tools/slack"
}

resource "kubiya_agent" "kubernetes_crew" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "AI-powered Kubernetes operations assistant"
  model        = "azure/gpt-4o"
  instructions = ""
  sources      = [kubiya_source.k8s_capabilities.name, kubiya_source.diagramming_capabilities.name, kubiya_source.slack_capabilities.name]


  integrations = ["kubernetes", "slack"]
  users        = []
  groups       = var.kubiya_groups_allowed_groups

  environment_variables = {
    NOTIFICATION_CHANNEL = var.notification_channel
    KUBIYA_TOOL_TIMEOUT = "300"
  }
}

# Unified webhook configuration
resource "kubiya_webhook" "source_control_webhook" {
  filter = ""
  
  name        = "${var.teammate_name}-k8s-webhook"
  source      = "K8S"
  prompt      = <<-EOT
    {{.event.text}}. use available tools to identify and troubleshoot the issue. 
    Aim to interpret the detected issue in a broader context to provide a more comprehensive understanding. 
    Check previous container logs and Check Pod Events.
  EOT
  agent       = kubiya_agent.kubernetes_crew.name
  destination = var.notification_channel
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

# Output the teammate details
output "kubernetes_crew" {
  value = {
    name                 = kubiya_agent.kubernetes_crew.name
    notification_channel = var.notification_channel
  }
}
