# Webhook Outputs
output "webhook_id" {
  description = "The ID of the created Kubiya webhook"
  value       = kubiya_webhook.datadog_incident_response.id
}

output "webhook_name" {
  description = "The name of the created Kubiya webhook"
  value       = kubiya_webhook.datadog_incident_response.name
}

output "webhook_url" {
  description = "The URL of the Kubiya webhook endpoint"
  value       = kubiya_webhook.datadog_incident_response.url
}

# Service Definition Outputs
output "service_definition_id" {
  description = "The ID of the created service definition (if enabled)"
  value       = var.create_service_definition ? datadog_service_definition_yaml.kubiya_incident_service[0].id : null
}

output "service_name" {
  description = "The name of the service definition"
  value       = var.service_name
}

# Configuration Outputs
output "workflow_name" {
  description = "The name of the incident response workflow"
  value       = "${var.region}-incident-workflow-dag"
}

output "incident_owner" {
  description = "The configured incident owner"
  value       = var.incident_owner
}

output "notification_channels" {
  description = "The configured Slack notification channels"
  value       = var.notification_channels
}

output "escalation_channel" {
  description = "The configured Slack escalation channel"
  value       = var.escalation_channel
}

output "investigation_timeout" {
  description = "The configured investigation timeout in seconds"
  value       = var.investigation_timeout
}

# Environment Configuration Outputs
output "dd_environment" {
  description = "The configured Datadog environment"
  value       = var.dd_environment
}

output "k8s_environment" {
  description = "The configured Kubernetes environment"
  value       = var.k8s_environment
}

output "environment" {
  description = "The deployment environment"
  value       = var.environment
}

# Team and Contact Information
output "team_name" {
  description = "The responsible team name"
  value       = var.team_name
}

output "service_contacts" {
  description = "The configured service contacts"
  value       = var.service_contacts
  sensitive   = true
}