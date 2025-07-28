terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

# Local variable to create the workflow using templatefile
locals {
  # Create the final workflow using templatefile to preserve JSON data types
  workflow_json = templatefile("${path.module}/workflow.tftpl", {
    # Workflow metadata
    workflow_name         = "${var.region}-incident-workflow-dag"
    workflow_description  = "${title(var.region)} Production incident response workflow with AI investigation and Slack integration"
    
    # Template variables
    kubiya_api_key        = var.kubiya_api_key
    incident_priority     = var.incident_priority
    region                = var.region
    incident_owner        = var.incident_owner
    notification_channels = var.notification_channels
    escalation_channel    = var.escalation_channel
    investigation_timeout = var.investigation_timeout
    max_retries          = var.max_retries
    dd_environment       = var.dd_environment
    k8s_environment      = var.k8s_environment
    agent_uuid           = var.agent_uuid
    default_incident_severity = var.default_incident_severity
    default_incident_priority = var.default_incident_priority
    
    # Cluster topology context
    cluster_topology_context = var.cluster_topology_context
  })
}

# Datadog Webhook Integration for Kubiya Incident Response
resource "datadog_webhook" "kubiya_incident_response" {
  name = var.webhook_name
  url  = var.kubiya_webhook_url

  # Payload containing the incident response workflow
  payload = local.workflow_json

  # Headers for authentication (no Content-Type for Datadog webhooks)
  custom_headers = jsonencode({
    "Authorization" = "UserKey ${var.kubiya_api_key}"
  })

  # Encode variables for webhook payload
  encode_as = "json"
}

# Optional: Create a Datadog Service for the webhook
resource "datadog_service_definition_yaml" "kubiya_incident_service" {
  count           = var.create_service_definition ? 1 : 0
  service_definition = yamlencode({
    schema-version = "v2.2"
    dd-service     = var.service_name
    team           = var.team_name
    description    = "Kubiya AI-powered incident response service"
    tier           = "1"
    type           = "automation"
    languages      = ["terraform"]
    tags = [
      "env:${var.environment}",
      "team:${var.team_name}",
      "service:incident-response",
      "automation:kubiya"
    ]
    integrations = {
      kubiya = {
        webhook-url = datadog_webhook.kubiya_incident_response.url
      }
    }
    contacts = var.service_contacts
  })
}