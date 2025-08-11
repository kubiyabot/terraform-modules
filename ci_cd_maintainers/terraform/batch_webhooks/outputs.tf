output "repositories_count" {
  description = "Number of repositories configured with webhooks"
  value       = length(local.repository_list)
}

output "webhook_url" {
  description = "URL to which GitHub will send webhook payloads"
  value       = var.webhook_url
}

output "events" {
  description = "List of GitHub events that trigger the webhook"
  value       = var.events
} 