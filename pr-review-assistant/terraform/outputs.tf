output "agent_id" {
  description = "ID of the simple PR review agent"
  value       = kubiya_agent.simple_pr_reviewer.id
}

output "agent_name" {
  description = "Name of the simple PR review agent"
  value       = kubiya_agent.simple_pr_reviewer.name
}

output "webhook_id" {
  description = "ID of the GitHub webhook"
  value       = kubiya_webhook.github_pr_webhook.id
}

output "webhook_url" {
  description = "Webhook URL to configure in GitHub"
  value       = kubiya_webhook.github_pr_webhook.url
}

output "configuration" {
  description = "Current configuration summary"
  value = {
    agent_name    = kubiya_agent.simple_pr_reviewer.name
    runner        = var.kubiya_runner
    slack_channel = var.default_slack_channel
    debug_mode    = var.debug_mode
  }
}