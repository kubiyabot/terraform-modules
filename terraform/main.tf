resource "kubiya_agent" "kubernetes_crew" {
  name         = "K8s Crew"
  runner       = var.kubiya_runner
  description  = var.teammate_description
  instructions = ""
  model        = "azure/gpt-4"
  integrations = ["kubernetes", "slack"]
  users        = var.users
  groups       = var.groups
  sources      = [kubiya_source.kubernetes_tools.name]

  environment_variables = {
    LOG_LEVEL            = var.log_level
    NOTIFICATION_CHANNEL = var.notification_slack_channel
  }
}

resource "kubiya_source" "kubernetes_tools" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/kubernetes"
}

resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "Kubernetes Operations Guide"
  groups           = var.groups
  description      = "Knowledge base for Kubernetes operations and troubleshooting"
  labels           = ["kubernetes", "operations"]
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = file("${path.module}/knowledge/kubernetes_ops.md")
} 