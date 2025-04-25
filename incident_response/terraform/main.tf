terraform {
  required_providers {
    kubiya = {
      source = "kubiya-terraform/kubiya"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "kubiya" {
  // API key is set as an environment variable KUBIYA_API_KEY
}

# Configure various sources
resource "kubiya_source" "github_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/github"
}

resource "kubiya_source" "datadog_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/datadog"
}

resource "kubiya_source" "kubernetes_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/kubernetes"
}

resource "kubiya_source" "observe_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/observe"
}

resource "kubiya_source" "argocd_tooling" {
  url = "https://github.com/kubiyabot/community-tools/tree/main/argocd"
}

# Configure secrets
# GitHub token secret removed as we're exclusively using GitHub App

resource "kubiya_secret" "datadog_api_key" {
  name        = "DATADOG_API_KEY"
  value       = var.DATADOG_API_KEY
  description = "Datadog API key for monitoring and alerts"
}

resource "kubiya_secret" "datadog_app_key" {
  name        = "DATADOG_APP_KEY"
  value       = var.DATADOG_APP_KEY
  description = "Datadog application key for API access"
}

resource "kubiya_secret" "observe_api_key" {
  name        = "OBSERVE_API_KEY"
  value       = var.OBSERVE_API_KEY
  description = "Observe API key for log access"
}

resource "kubiya_secret" "argocd_token" {
  name        = "ARGOCD_TOKEN"
  value       = var.ARGOCD_TOKEN
  description = "ArgoCD token for deployment management"
}

# Configure the Incident Response agent
resource "kubiya_agent" "incident_response" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "The Incident Response teammate is an AI-powered assistant that helps investigate and resolve incidents. It can correlate data from Datadog, Observe, GitHub, Kubernetes, and ArgoCD to find the root cause and provide actionable insights."
  instructions = ""
  
  # Add secrets - GitHub token removed as we're using GitHub App
  secrets = [
    kubiya_secret.datadog_api_key.name,
    kubiya_secret.datadog_app_key.name,
    kubiya_secret.observe_api_key.name,
    kubiya_secret.argocd_token.name
  ]
  
  sources = [
    kubiya_source.github_tooling.name,
    kubiya_source.datadog_tooling.name,
    kubiya_source.kubernetes_tooling.name,
    kubiya_source.observe_tooling.name,
    kubiya_source.argocd_tooling.name
  ]

  # Always use GitHub App integration
  integrations = [
    "github_app",
    "slack"
  ]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
    DATADOG_SITE        = var.datadog_site
    ARGOCD_DOMAIN       = var.ARGOCD_DOMAIN
    OBSERVE_DATASET_ID  = var.OBSERVE_DATASET_ID
  }
  
  is_debug_mode = var.debug_mode
}

# Webhook configuration for Datadog incidents
resource "kubiya_webhook" "datadog_incident_webhook" {
  filter      = "event.alert.alert_type == 'error'"
  name        = "${var.teammate_name}-datadog-webhook"
  source      = "Datadog"
  
  # Set the communication method based on the MS Teams notification variable
  method      = var.ms_teams_notification ? "teams" : "Slack"
  
  # For Teams, include the team_name
  team_name   = var.ms_teams_notification ? var.ms_teams_team_name : null
  
  prompt      = <<-EOT
Your Goal: Given a Datadog incident that triggers you, use the tools you have to investigate and respond effectively.

Incident ID: {{.event.alert.id}}
Alert Type: {{.event.alert.alert_type}}
Service: {{.event.alert.service}}
Priority: {{.event.alert.priority}}

Instructions:

1. Fetch more data about the incident using Datadog tools
   - Get detailed alert information
   - Analyze the affected services using the service map
   - Check metrics and monitors related to the issue

2. Investigate logs to understand the problem
   - Use Observe to fetch logs about this service with this specific error
   - Filter logs by errors and relevant timeframes
   - Look for patterns and correlations

3. Find the root cause in the codebase
   - Access the GitHub repository to find the PR that may have caused this issue
   - Identify the problematic code changes
   - Check deployment information using ArgoCD

4. Check Kubernetes resources if applicable
   - Examine pod status, logs, and events
   - Analyze resource utilization and constraints

5. Summarize your findings in a clear, actionable format
   - What's the issue? Provide a concise description
   - What caused it? Link to specific code/deployment/configuration
   - How to fix it? Recommend concrete steps
   - Who should be involved? Tag relevant teams or individuals if known

Make your response focused and actionable. Format it clearly with headers, bullet points, and code blocks where appropriate. Prioritize information that helps resolve the incident quickly.
  EOT
  agent       = kubiya_agent.incident_response.name
  destination = var.notification_channel
}

# Output the teammate details
output "incident_response_teammate" {
  sensitive = true
  value = {
    name                 = kubiya_agent.incident_response.name
    debug_mode           = var.debug_mode
    notification_platform = var.ms_teams_notification ? "teams" : "Slack"
    notification_channel = var.notification_channel
    datadog_site         = var.datadog_site
    observe_dataset      = var.OBSERVE_DATASET_ID
    argocd_domain        = var.ARGOCD_DOMAIN
  }
} 