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

# Configure the Incident Response agent
resource "kubiya_agent" "incident_response" {
  name         = var.teammate_name
  runner       = var.kubiya_runner
  description  = "The Incident Response teammate is an AI-powered assistant that helps investigate and resolve incidents. It can correlate data from Datadog, Observe, GitHub, Kubernetes, and ArgoCD to find the root cause and provide actionable insights."
  instructions = ""
  
  secrets = split(",", var.secrets_list)
  
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
    DD_SITE        = var.datadog_site
    ARGOCD_DOMAIN       = var.argocd_domain
    OBSERVE_DATASET_ID  = var.observe_dataset_id
  }
  
  is_debug_mode = var.debug_mode
}

# Webhook configuration for Datadog incidents
resource "kubiya_webhook" "datadog_incident_webhook" {
  filter      = ""
  name        = "${var.teammate_name}-datadog-webhook"
  source      = "Datadog"
  
  # Set the communication method based on the MS Teams notification variable
  method      = var.ms_teams_notification ? "teams" : "Slack"
  
  # For Teams, include the team_name
  team_name   = var.ms_teams_notification ? var.ms_teams_team_name : null
  
  prompt      = <<-EOT
Your Goal:  
When triggered by a Datadog incident, begin by running key Kubernetes operational checks. Summarize the findings clearly. If further investigation is needed, suggest follow-up actions using tools like Datadog, ArgoCD, Observe, or GitHub.

Incident Details:  
- Incident ID: {{.event.id}}  
- Title: {{.event.title}}  
- URL: {{.event.url}}  
- Severity: {{.event.severity}}  
- Description:  
  {{.event.body}}

Investigation Instructions:

1. Run Kubernetes Operational Checks (Last 1–6 Hours):
   - Helm package deployment list in last 1 hour → use `list_helm_release`
   - Pod restarts across the cluster → use `check_pod_status`  
   - Node health and availability → use `node_status`  
   - Ingress controller health → use `ingress_analyzer`  
   - Cluster logs/events for suspicious or repeated errors → use `find_suspicious_errors`

2. Summarize Findings:  
   - Provide a concise summary of any anomalies or alerts.

3. Optional Deep-Dive:  
   - If issues are detected, suggest deeper investigation using Datadog, Observe, ArgoCD, or GitHub.

4. Use the Following Format:

"""
Analysis Summary:
helm package deployment list: OK ✅ - deployment 1 - deployment 2
pod restarts status: OK ✅  
node status: OK ✅  
ingress analyzer: OK ✅  
find suspicious errors: ERROR ❌ Short, clear description of the issue.

Do you want me to investigate further using Datadog, ArgoCD, Observe, or Kubernetes tools?
"""

IMPORTANT:  
Run all steps sequentially and automatically without waiting for input. Continue the investigation until a full and clear analysis is completed.

Tone & Focus:  
Keep responses concise, structured, and focused on resolution."""
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
    observe_dataset      = var.observe_dataset_id
    argocd_domain        = var.argocd_domain
  }
} 
