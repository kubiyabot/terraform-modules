output "teammate_id" {
  description = "ID of the created Kubiya teammate"
  value       = kubiya_teammate.teammate.id
}

output "source_id" {
  description = "ID of the created Kubiya source"
  value       = kubiya_source.source.id
}

output "webhook_id" {
  description = "ID of the created Kubiya webhook"
  value       = kubiya_webhook.webhook.id
} 