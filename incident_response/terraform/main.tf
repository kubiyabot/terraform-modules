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

# Configure individual agents for each tool

# GitHub Agent
resource "kubiya_agent" "github_teammate" {
  name         = "${var.teammate_name}-github"
  runner       = var.kubiya_runner
  description  = "GitHub teammate that helps investigate code-related incidents. It can analyze repositories, PRs, issues, and code changes to identify potential causes of incidents."
  instructions = ""
  
  secrets = split(",", var.secrets_list)
  
  sources = [
    kubiya_source.github_tooling.name
  ]

  integrations = [
    "github_app",
    "slack"
  ]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }
  
  is_debug_mode = var.debug_mode
}

# Datadog Agent
resource "kubiya_agent" "datadog_teammate" {
  name         = "${var.teammate_name}-datadog"
  runner       = var.kubiya_runner
  description  = "Datadog teammate that helps investigate monitoring and alerting incidents. It can analyze metrics, logs, and alerts to identify performance issues and service disruptions."
  instructions = ""
  
  secrets = split(",", var.secrets_list)
  
  sources = [
    kubiya_source.datadog_tooling.name
  ]

  integrations = [
    "github_app",
    "slack"
  ]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
    DD_SITE             = var.datadog_site
  }
  
  is_debug_mode = var.debug_mode
}

# Kubernetes Agent
resource "kubiya_agent" "kubernetes_teammate" {
  name         = "${var.teammate_name}-kubernetes"
  runner       = var.kubiya_runner
  description  = "Kubernetes teammate that helps investigate infrastructure incidents. It can analyze cluster health, pod status, resource utilization, and configuration issues."
  instructions = ""
  
  secrets = split(",", var.secrets_list)
  
  sources = [
    kubiya_source.kubernetes_tooling.name
  ]

  integrations = [
    "github_app",
    "slack"
  ]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
  }
  
  is_debug_mode = var.debug_mode
}

# Observe Agent
resource "kubiya_agent" "observe_teammate" {
  name         = "${var.teammate_name}-observe"
  runner       = var.kubiya_runner
  description  = "Observe teammate that helps investigate log-based incidents. It can analyze logs, events, and traces to identify errors and unusual patterns."
  instructions = ""
  
  secrets = split(",", var.secrets_list)
  
  sources = [
    kubiya_source.observe_tooling.name
  ]

  integrations = [
    "github_app",
    "slack"
  ]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
    OBSERVE_DATASET_ID  = var.observe_dataset_id
  }
  
  is_debug_mode = var.debug_mode
}

# ArgoCD Agent
resource "kubiya_agent" "argocd_teammate" {
  name         = "${var.teammate_name}-argocd"
  runner       = var.kubiya_runner
  description  = "ArgoCD teammate that helps investigate deployment incidents. It can analyze deployment status, sync issues, and configuration problems."
  instructions = ""
  
  secrets = split(",", var.secrets_list)
  
  sources = [
    kubiya_source.argocd_tooling.name
  ]

  integrations = [
    "github_app",
    "slack"
  ]

  users  = []
  groups = var.kubiya_groups_allowed_groups

  environment_variables = {
    KUBIYA_TOOL_TIMEOUT = "500"
    ARGOCD_DOMAIN       = var.argocd_domain
  }
  
  is_debug_mode = var.debug_mode
}

# Webhook configuration for Datadog incidents now routes to the Datadog teammate
resource "kubiya_webhook" "datadog_incident_webhook" {
  filter      = ""
  name        = "${var.teammate_name}-datadog-webhook"
  source      = "Datadog"
  
  # Set the communication method based on the MS Teams notification variable
  method      = var.ms_teams_notification ? "teams" : "Slack"
  
  # For Teams, include the team_name
  team_name   = var.ms_teams_notification ? var.ms_teams_team_name : null
  
  prompt      = <<-EOT
Your Goal: Given a Datadog incident that triggers you, use the tools you have to investigate and respond effectively.

Incident ID: {{.id}}
Incident Title: {{.title}}
Incident URL: {{.url}}
Severity: {{.severity}}
Description: {{.body}}

Context:
- Observe Dataset ID: ${var.observe_dataset_id}

Instructions:

1. Fetch more data about the incident using Datadog tools
   - Get detailed alert information
   - Analyze the affected services using the service map
   - Check metrics and monitors related to the issue

2. Investigate logs to understand the problem
   - Filter logs by errors and relevant timeframes
   - Look for patterns and correlations

3. Summarize your findings in a clear, actionable format
   - What's the issue? Provide a concise description
   - What caused it? Link to specific metrics/logs
   - How to fix it? Recommend concrete steps
   - Who should be involved? Tag relevant teams or individuals if known

IMPORTANT: Run all necessary steps in sequence without waiting for user approval. Continue the investigation process until you have reached a conclusion and provided a full analysis.

Make your response focused and actionable. Format it clearly with headers, bullet points, and code blocks where appropriate. Prioritize information that helps resolve the incident quickly.
  EOT
  agent       = kubiya_agent.datadog_teammate.name
  destination = var.notification_channel
}

# Output the teammate details
output "incident_response_teammates" {
  sensitive = true
  value = {
    github_teammate = {
      name = kubiya_agent.github_teammate.name
    }
    datadog_teammate = {
      name = kubiya_agent.datadog_teammate.name
      datadog_site = var.datadog_site
    }
    kubernetes_teammate = {
      name = kubiya_agent.kubernetes_teammate.name
    }
    observe_teammate = {
      name = kubiya_agent.observe_teammate.name
      observe_dataset = var.observe_dataset_id
    }
    argocd_teammate = {
      name = kubiya_agent.argocd_teammate.name
      argocd_domain = var.argocd_domain
    }
    debug_mode = var.debug_mode
    notification_platform = var.ms_teams_notification ? "teams" : "Slack"
    notification_channel = var.notification_channel
  }
} 