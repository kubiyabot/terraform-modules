terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
  }
}

provider "kubiya" {
  # API key is set via KUBIYA_API_KEY environment variable
}

# Core Kubernetes tools source
resource "kubiya_source" "kubernetes_tools" {
  name = "kubernetes-tools"
  url  = "https://github.com/kubiyabot/community-tools/tree/main/kubernetes"
}

# The Kubernetes Crew teammate
resource "kubiya_agent" "kubernetes_crew" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "Your AI-powered Kubernetes operations team"
  instructions = file("${path.module}/instructions.md")
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

# Core knowledge base
resource "kubiya_knowledge" "kubernetes_ops" {
  name             = "kubernetes-operations"
  description      = "Core Kubernetes operations knowledge"
  groups           = var.groups
  supported_agents = [kubiya_agent.kubernetes_crew.name]
  content          = file("${path.module}/knowledge/kubernetes_ops.md")
}

# Dynamic prompts from directory
locals {
  prompt_files = fileset("${path.module}/prompts", "*.md")
  prompts = {
    for file in local.prompt_files : 
    trimsuffix(file, ".md") => file("${path.module}/prompts/${file}")
  }
}

# Scheduled tasks based on prompts
resource "kubiya_scheduled_task" "kubernetes_tasks" {
  for_each = {
    for name, config in var.scheduled_tasks :
    name => config
    if config.enabled
  }

  agent         = kubiya_agent.kubernetes_crew.name
  channel_id    = var.notification_slack_channel
  scheduled_time = each.value.start_time
  repeat        = each.value.repeat
  description   = try(local.prompts[each.key], each.value.custom_prompt)
}

output "kubernetes_crew" {
  value = {
    name = kubiya_agent.kubernetes_crew.name
    id   = kubiya_agent.kubernetes_crew.id
  }
}
